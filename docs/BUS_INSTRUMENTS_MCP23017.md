# Pilote physique ISO1540 + MCP23017

Le brochage complet Arduino, ISO1540, MCP23017 et connecteur B1 est regroupé
dans [`BUS_INSTRUMENTS_MAPPING_HARDWARE.md`](BUS_INSTRUMENTS_MAPPING_HARDWARE.md).

## Décision d'architecture

Le premier prototype utilise l'I2C. L'API publique `InstrumentBus` ne contient
aucun type Arduino ou MCP23017 afin de pouvoir remplacer son implémentation par
un bus parallèle isolé avec des TLP281 sans modifier les encodeurs de
fréquence, niveau ou modulation.

Le raccordement retenu est :

```text
Mega D20 / SDA ---- ISO1540 ---- MCP23017 SDA
Mega D21 / SCL ---- ISO1540 ---- MCP23017 SCL

MCP GPIOA7..0  -> bus D7..D0
MCP GPIOB3..0  -> bus A3..A0
MCP GPIOB4     -> Chargt, inactif haut, front descendant actif
MCP GPIOB7..5  -> entrées réservées
```

Le MCP23017 est configuré à l'adresse `0x20` avec A2..A0 à zéro. Le domaine
côté instruments doit être alimenté en 5 V isolé ; l'ISO1540 n'isole pas
l'alimentation. Chaque côté de l'isolateur demande ses propres résistances de
tirage I2C.

## Initialisation sans écriture parasite

À la mise sous tension, toutes les broches du MCP23017 sont des entrées. Le
pilote effectue dans cet ordre :

1. normalisation sûre de la carte de registres en `BANK=0` ;
2. configuration `IOCON.BANK=1` et `IOCON.SEQOP=1` ;
3. préchargement de `OLATA=0x00` ;
4. préchargement de `OLATB=0x10`, donc `Chargt=1` ;
5. passage de GPIOA en sortie ;
6. passage de GPIOB4..0 en sortie, GPIOB7..5 restant en entrée.

Aucun front descendant de `Chargt` n'est produit par cette séquence. Une
résistance externe doit néanmoins maintenir `Chargt` au niveau haut pendant
la haute impédance initiale. Le brochage RESET du MCP23017 doit également être
maintenu proprement au niveau haut et rester accessible pour les essais de
récupération.

## Émission d'un mot

Pour chaque couple `(adresse, donnée)` :

1. mettre à jour `OLATA` si la donnée a changé ;
2. mettre à jour GPIOB3..0 si l'adresse a changé, avec GPIOB4 toujours haut ;
3. écrire deux octets successifs dans `OLATB` : `adresse`, puis
   `adresse|0x10`.

Avec `BANK=1`, `SEQOP=1` empêche l'auto-incrément du pointeur : les deux
derniers octets atteignent donc tous les deux `OLATB`. Ils produisent un unique
front descendant, puis libèrent immédiatement `Chargt`. Il ne faut pas utiliser
cette technique avec `BANK=0` : dans ce mode spécial, le MCP23017 alterne le
pointeur entre les registres A et B associés, et le second octet atteindrait
`OLATA` en laissant `Chargt` actif bas.

Le pilote conserve les images de GPIOA et GPIOB et ne fait aucune
lecture-modification-écriture. Il refuse les adresses supérieures à 15 et
expose le dernier défaut I2C ainsi que le nombre et la durée des écritures.
Après un défaut pendant l'impulsion, il tente une remise au niveau haut, puis
se déclare indisponible jusqu'à l'appel de `recover()`.

Le contrôleur borne la récupération à une tentative par configuration. Si le
bus était prêt puis échoue pendant une écriture, il réinitialise le MCP23017 et
réémet une fois la configuration complète depuis son premier mot. Si le bus
était déjà indisponible, il tente d'abord la récupération puis effectue une
seule émission. Il n'existe donc aucune boucle de relance infinie.

## Diagnostic série

La requête `IB?`, utilisable en mode local comme distant, retourne une ligne :

```text
IB READY=1 ERROR=0 FAULT=0 WRITES=6 FAILED=0 RECOVERY_ATTEMPTS=0 RECOVERY_SUCCESS=0 LAST_US=123 MAX_US=225 DATA=255 ADDRESS=15
```

`ERROR` décrit l'état de la dernière opération, tandis que `FAULT` conserve le
dernier défaut même après une récupération réussie. Les codes sont : 0 aucun,
1 non prêt, 2 adresse invalide, 3 débordement du tampon I2C, 4 NACK adresse,
5 NACK donnée, 6 autre erreur I2C et 7 timeout. Les compteurs ne sont remis à
zéro que par un reset du Mega.

## Budget temporel à 400 kHz

Un octet I2C avec acquittement occupe neuf périodes, soit 22,5 µs. Les deux
valeurs consécutives de `OLATB` donnent donc une durée basse théorique de
`Chargt` proche de 22,5 µs.

| Cas | Périodes I2C | Durée théorique hors logiciel |
| --- | ---: | ---: |
| donnée et adresse inchangées | 36 | 90 µs |
| donnée seule modifiée | 63 | 157,5 µs |
| donnée et adresse modifiées | 90 | 225 µs |
| séquence RF de 13 mots, pire cas | 1 170 | 2,925 ms |

Le comptage des 89 073 impulsions brutes de l'ancienne CPU donne :

| Largeur basse | Nombre |
| --- | ---: |
| moins de 2 µs | 683 |
| 2 à moins de 3 µs | 18 |
| 3 à moins de 4 µs | 24 293 |
| 4 à moins de 5 µs | 58 514 |
| 5 à moins de 6 µs | 5 540 |
| 6 à moins de 10 µs | 6 |
| 10 µs et plus | 19 |

La moyenne est 4,151 µs ; les extrêmes sont 0,1 et 197 µs. Les valeurs rares
sont à interpréter avec prudence compte tenu de la résolution des captures et
de l'état de la CPU d'origine. Le prototype I2C sera donc environ cinq fois
plus long sur l'impulsion typique. Les cartes chargent sur le front descendant
et l'interface du panneau fonctionne correctement après élargissement à
10 µs de son cycle d'acquittement. En l'absence temporaire des composants de
banc, le projet retient donc 22,5 µs comme **hypothèse acceptable provisoire**
et autorise le raccordement logiciel. La mesure électrique reste recommandée
lorsque le matériel sera disponible, mais ne bloque plus le développement.

## Procédure de validation

### Test I2C sans fond de panier

L'environnement `i2c_probe` permet le premier essai avec les sorties du
MCP23017 non raccordées. Il démarre à 100 kHz et recherche une réponse aux huit
adresses possibles `0x20` à `0x27`. L'ISO1540 lui-même n'a pas d'adresse I2C.

Avant la mise sous tension, vérifier :

- `RESET` du MCP23017 au niveau haut ;
- A0, A1 et A2 au niveau bas si l'adresse attendue est `0x20` ;
- une résistance de tirage de SDA et de SCL vers chaque alimentation, de
  chaque côté de l'ISO1540 ;
- environ 5 V entre VCC1/GND1, puis entre VCC2/GND2 et VDD/VSS du MCP23017 ;
- aucune continuité entre GND1 et GND2 si l'isolation galvanique doit être
  conservée.

VCC2 est une entrée d'alimentation et non une sortie produite par l'ISO1540.
Fond de panier débranché, le côté 2 et le MCP23017 doivent donc recevoir un
5 V externe référencé à GND2. Pour un essai de table uniquement, sans aucune
liaison au 740A, VCC1/VCC2 et GND1/GND2 peuvent provisoirement partager le 5 V
et la masse du Mega ; l'essai ne valide alors évidemment pas l'isolation.

```powershell
pio run -e i2c_probe
pio run -e i2c_probe --target upload
pio device monitor --baud 115200
```

La sonde affiche l'adresse détectée et lit `IODIRA`, `IODIRB`, `IOCON`,
`OLATA` et `OLATB`. Si les deux registres `IODIR` valent `0xFF`, elle écrit un
motif dans `OLATA`, le relit puis restaure sa valeur. Toutes les broches restent
alors en entrée : ce test valide les communications dans les deux sens sans
commander le futur bus instruments. La lettre `S` relance le test à 100 kHz et
la lettre `F` l'exécute à la fréquence finale de 400 kHz. La lettre `M` permet
un essai exploratoire à 1 MHz ; cette vitesse n'est pas utilisée par le
firmware normal. La lettre `B` cherche par dichotomie la limite fiable parmi
les fréquences réellement générables par le TWI du Mega entre 400 kHz et
1 MHz. Chaque palier subit 50 cycles et le meilleur palier 1 000 cycles ; la
sonde revient toujours à 400 kHz à la fin.

Le premier essai isolé du 2026-07-21 fonctionne à 100 kHz avec un module
générique MCP23017 équipé de tirages SDA/SCL de 4,7 kohm. En parallèle avec les
10 kohm du clone de la carte Adafruit 4903, le tirage effectif côté MCP23017 est
d'environ 3,2 kohm. Le même montage a passé 20 tests consécutifs à 400 kHz sans
absence de réponse ni erreur de lecture/écriture. La CMJU-2317 équipée de
10 kohm, soit environ 5 kohm effectifs, produisait des niveaux SDA
intermédiaires incorrects. La différence peut provenir des tirages, du routage,
du découplage ou d'un défaut propre à la CMJU ; elle n'est pas encore isolée.

L'essai exploratoire à 1 MHz n'est pas exploitable : l'adresse réelle `0x20`
n'est plus reconnue, de faux acquittements apparaissent à `0x21`, `0x23`,
`0x25` et `0x27`, et les lectures de registres échouent. Un retour immédiat à
400 kHz rétablit le test complet. La capacité nominale de l'ISO1540 à 1 MHz ne
garantit donc pas cette vitesse pour l'ensemble Mega, modules, tirages et
câblage de banc ; le firmware reste configuré à 400 kHz.

Une recherche dichotomique sur les paliers TWI réellement générables par le
Mega a ensuite validé 888 888 Hz pendant 1 000 cycles complets. Chaque cycle
contrôle que seule l'adresse `0x20` acquitte, lit les directions et effectue
une écriture, relecture et restauration d'`OLATA`. Le palier suivant est
1 MHz et échoue. La limite observée se situe donc entre ces deux paliers, sans
que 888 888 Hz constitue une marge de conception suffisante pour remplacer le
choix conservateur de 400 kHz.

Après un démarrage à froid normal, la sortie attendue à l'adresse par défaut
contient notamment :

```text
Reponse a 0x20 (adresse firmware)
  registres: IODIRA=0xFF IODIRB=0xFF IOCON=0x00 OLATA=0x00 OLATB=0x00
  lecture/ecriture OLATA, broches en entree: OK
```

Si aucune adresse ne répond, mesurer au repos SDA et SCL des deux côtés de
l'ISO1540 : les quatre points doivent être au niveau haut. Vérifier ensuite
`RESET`, les alimentations et les tirages avant d'incriminer l'adresse.

### Test des sorties et de Chargt

1. ne raccorder que Mega, ISO1540, MCP23017 et analyseur logique ;
2. compiler et charger l'environnement PlatformIO `instrument_bus_bench`, qui
   définit `ADRET_INSTRUMENT_BUS_BENCH=1` ;
3. vérifier qu'un reset Mega ne produit aucun front descendant sur GPIOB4
   avant le motif, puis observer les six écritures finies du motif ;
   `IB?` doit alors indiquer `READY=1`, `WRITES=6` et `FAILED=0` ;
4. mesurer établissement données/adresse, largeur basse de `Chargt`, durée
   totale et comportement au reset ;
5. recharger le firmware normal en gardant le fond de panier déconnecté,
   forcer SDA ou SCL bas pendant une commande fonctionnelle, puis libérer la
   ligne et répéter la commande ; vérifier avec `IB?` qu'une seule récupération
   a été tentée et que GPIOB4 est revenu haut avant les nouvelles impulsions ;
6. connecter ensuite une carte instrument à la fois.

Le motif teste successivement bus inchangé, donnée seule, adresse seule, puis
donnée et adresse modifiées. Il est absent de l'environnement normal et
produit un avertissement de compilation dans l'environnement de banc. Ce
dernier ne doit jamais être chargé avec le fond de panier instruments
connecté. Après les mesures, recharger impérativement l'environnement normal
`megaatmega2560`.

Le banc déconnecté du 2026-07-21, échantillonné à 4 MHz, a confirmé les six
transactions et leurs états de données/adresse, une impulsion basse `Chargt`
de 22,5 us par transaction, puis le retour au niveau haut inactif. Ce résultat
valide le chemin de sortie Mega--ISO1540--MCP23017 sans charge instrument ; il
ne valide pas encore l'acceptation du strobe par les cartes d'origine.

```powershell
pio run -e instrument_bus_bench
pio run -e instrument_bus_bench --target upload
```

Si 22,5 µs est trop long, les solutions seront évaluées dans cet ordre :

1. strobe séparé du MCP23017 et isolé par une voie rapide dédiée ;
2. backend entièrement parallèle isolé ;
3. modification du matériel I2C seulement si elle conserve l'isolation et un
   état de démarrage sûr.

Les TLP281 commandés restent donc une solution de repli prévue, pas une remise
en cause de l'API logicielle.
