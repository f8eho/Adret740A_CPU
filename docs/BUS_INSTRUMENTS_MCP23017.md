# Pilote physique ISO1540 + MCP23017

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

1. configuration `IOCON.SEQOP=1`, en conservant `BANK=0` ;
2. préchargement de `OLATA=0x00` ;
3. préchargement de `OLATB=0x10`, donc `Chargt=1` ;
4. passage de GPIOA en sortie ;
5. passage de GPIOB4..0 en sortie, GPIOB7..5 restant en entrée.

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

`SEQOP=1` empêche l'auto-incrément du pointeur de registre : les deux derniers
octets atteignent donc tous les deux `OLATB`. Ils produisent un unique front
descendant, puis libèrent immédiatement `Chargt`.

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
