# Plan d'action du bus instruments

## Objectif

Reproduire, avec la nouvelle carte CPU, les écritures du bus instruments de
l'ADRET 740A en fonction de la configuration demandée depuis le panneau avant
ou l'interface distante.

Le résultat attendu n'est pas seulement une table d'adresses. Il faut obtenir :

- la fonction de chaque adresse et de chaque bit ;
- les plages valides et les changements de gamme ;
- les formules transformant fréquence, niveau et modulation en octets ;
- l'ordre des écritures et les temporisations nécessaires ;
- des vecteurs de référence permettant de comparer la nouvelle CPU à
  l'ancienne.

## Sources de référence

- `docs/ADRET7401_Principe.md` pour les équations de synthèse et les gammes ;
- `docs/Adret740a_schemas/` (référence locale non versionnée) pour les
  registres, décodeurs et connexions ;
- `docs/Traces_bus_instruments/Data/` pour les captures brutes ;
- `docs/Traces_bus_instruments/Out/` pour les transactions décodées ;
- les manuels utilisateur pour les plages accessibles et les options.

Les traces brutes priment sur les anciennes interprétations. Le décodeur doit
retenir uniquement le front descendant de `Chargt`.

## Premier rapprochement avec le principe de fonctionnement

Pour une sortie de 240 MHz, le tableau des gammes impose l'oscillateur O1 à
480 MHz suivi du diviseur par deux. Les équations donnent :

```text
F_synthese = 2 x 240 MHz = 480 MHz
N = int((480 - 18) / 8) = 57
Delta = 480 - 18 - 57 x 8 = 6 MHz
A = 5 x (18 + Delta) = 120 MHz
B = A / N + 40 = 42,105263 MHz
```

Un incrément de 10 Hz en sortie correspond alors à :

```text
20 Hz sur l'oscillateur avant le diviseur par deux
100 Hz au point A après multiplication par R = 5
4 pas de 25 Hz sur la carte « 20000 »
```

La première transaction du balayage à 10 Hz modifie bien le registre fin de
la carte « 20000 » suivant ce rapport. Les balayages montrent aussi :

- 100 Hz en sortie : 40 pas de 25 Hz ;
- 1 kHz en sortie : 400 pas de 25 Hz ;
- 10 kHz en sortie : 4 000 pas de 25 Hz ;
- le report vers la carte « 80 » lorsque la plage de 20 000 pas est franchie.

Cette méthode sera appliquée à toutes les gammes RF, pas seulement à la zone
240–250 MHz couverte par les traces actuelles.

## Lots d'analyse

### 1. Protocole électrique et transactions de référence

- confirmer la polarité et le front actif de `Chargt` ;
- mesurer les temps d'établissement des données et de l'adresse ;
- mesurer la largeur et l'espacement des impulsions ;
- produire une table chronologique propre pour chaque capture ;
- conserver les séquences complètes, y compris les écritures apparemment
  constantes.

Critère de fin : chaque ligne de `Out` correspond à un front actif unique.

### 2. Synthèse des petits pas : adresses 0 à 3

- [x] carte « 20000 » : retrouver le compteur 40 000 à 59 999 et la
  répartition des chiffres sur les trois registres ;
- [x] carte « 80 » : retrouver le compteur 178 à 257 ;
- [x] modéliser les retenues entre les deux cartes ;
- [x] vérifier les modèles sur les balayages de 10 Hz, 100 Hz, 1 kHz, 10 kHz,
  100 kHz et 1 MHz.

Critère de fin : génération exacte, octet par octet, des adresses 0 à 3 pour
toutes les fréquences présentes dans les captures.

Résultat : critère atteint sur `24 512 / 24 512` octets. Voir
[`BUS_INSTRUMENTS_20000_80.md`](BUS_INSTRUMENTS_20000_80.md) pour les formules,
les plages couvertes et la réserve concernant les diviseurs impairs, absents
des captures.

### 3. Synthèse des grands pas, approche, VHF et doubleur

- calculer la fréquence interne selon la gamme directe, divisée ou
  hétérodynée ;
- calculer `N`, `Delta`, `A`, `B`, `n` et `m` ;
- attribuer les adresses 4, 5, 6 et 15 aux registres des schémas ;
- identifier les codes de sélection O1/O2, `/2`, mélangeur et filtres ;
- identifier le DAC de poursuite et les commandes de l'option doubleur ;
- établir les seuils exacts des six gammes RF.

Critère de fin : une fonction fréquence -> séquence d'écritures démontrée par
les équations et par les schémas.

Résultat : les chemins du 740A de base et de l'option doubleur, les seuils,
le codage de `N`, les adresses 4, 5, 12, 13 et 15 ainsi que le bit `Pulse` de
l'adresse 6 sont déterminés. La relation des adresses 4, 5 et 13 est vérifiée
sur `6 128 / 6 128` transactions RF. Voir
[`BUS_INSTRUMENTS_GRANDS_PAS.md`](BUS_INSTRUMENTS_GRANDS_PAS.md). L'ordre
complet est connu, mais l'émission matérielle reste à réaliser après le pilote
MCP23017.

### 4. Niveau RF et atténuateur

- [x] séparer les pas mécaniques de l'atténuateur et l'interpolation analogique ;
- [x] décoder les adresses 6 et 8 bit par bit ;
- [x] déterminer les effets des pas de 0,1 dB, 1 dB, 5 dB et des cellules de
  l'atténuateur ;
- [x] vérifier les limites de niveau selon la fréquence et le mode AM.

Critère de fin : reproduction des balayages de -70 à -35 dB et extension du
modèle à la plage complète documentée.

Résultat partiel : l'ordre `6, 8, 6`, la table des 28 états mécaniques, le
codage analogique et les deux formules de niveau sont déterminés. Le balayage
est reproduit sur `1 050 / 1 050` octets et l'encodeur accepte toute la plage
documentée `-129,9..+13,0 dBm`. Une table nulle de 2 Kio est réservée en
`PROGMEM` pour la calibration en deux étapes. Les restrictions de niveau en
AM sont maintenant identifiées comme avertissements de dépassement. Voir
[`BUS_INSTRUMENTS_NIVEAU_RF.md`](BUS_INSTRUMENTS_NIVEAU_RF.md).

### 5. Modulations AM, FM et PM

- [x] adresses 9 et 10 : mots BCD du DAC de modulation ;
- [x] adresse 11 : DAC de correction dépendant du taux `N` ;
- [x] adresse 12 : gamme, mode FM/PM et source de modulation ;
- [x] adresse 13 : diviseur d'incréments et champs `n`/`m` ;
- [x] établir les codages 400 Hz, 1 kHz, externe et CW.

Critère de fin : reproduction exacte des captures AM et FM, puis déduction et
validation du mode PM.

Résultat : les six captures AM/FM sont reproduites sur `7 393 / 7 393`
écritures. La PM est déduite directement de sa branche EPROM et du schéma FM,
mais reste à confirmer faute de capture PM. La valeur exacte de 200 kHz FM
reste également ouverte, le codage BCD démontré s'arrêtant à 199,9 kHz. Voir
[`BUS_INSTRUMENTS_MODULATIONS.md`](BUS_INSTRUMENTS_MODULATIONS.md).

### 6. Modulation d'impulsions et adresses non résolues

- suivre la sortie `Pulse` du registre de la carte approche jusqu'à la carte
  de commande d'impulsions et au modulateur VHF ;
- déterminer le bit utilisé par `SL 64` et sa valeur inactive ;
- vérifier si l'option utilise un champ existant plutôt qu'une adresse propre ;
- conserver l'adresse 15 comme écriture de compatibilité calculée depuis
  l'adresse 12, malgré l'absence de récepteur sur le châssis standard ;
- déterminer si les adresses 7 et 14, absentes des captures disponibles, sont
  inutilisées, réservées ou liées à une option, sans leur attribuer une
  fonction par défaut.

Critère de fin : comportement défini avec ou sans les options doubleur et
impulsions.

Résultat : `Pulse` est l'adresse 6 D6, active à 1, et l'activation des
impulsions force aussi l'adresse 5 D5. Le doubleur utilise l'adresse 5 D4 et
la poursuite adresse 4 D7 ; aucune des deux options ne possède d'adresse
propre. Les EPROM et toutes les traces disponibles n'écrivent jamais les
adresses 7 et 14 : elles restent non attribuées et ne doivent pas être émises.
Les commandes `SL 64`/`SL 60`, la détection d'option et les incompatibilités
sont détaillées dans
[`BUS_INSTRUMENTS_IMPULSIONS.md`](BUS_INSTRUMENTS_IMPULSIONS.md).

## Architecture matérielle proposée

L'association `ISO1540 + MCP23017` est retenue pour le premier prototype sous
les conditions
suivantes :

- côté instruments, alimenter le MCP23017 en 5 V pour garantir les niveaux
  hauts des circuits CMOS 5 V ;
- alimenter ce côté depuis le domaine 5 V isolé de l'instrument, ou depuis un
  convertisseur DC/DC isolé ; l'ISO1540 n'isole pas l'alimentation ;
- placer le côté 1 de l'ISO1540 du côté du nœud I2C de faible capacité et le
  côté 2 du côté MCP23017 ;
- prévoir des résistances de tirage I2C sur les deux domaines et les
  condensateurs de découplage au plus près des circuits ;
- vérifier les résistances de tirage déjà présentes sur le bus instruments et
  le courant total demandé au MCP23017.

Affectation recommandée :

```text
GPIOA0..7 : D0..D7
GPIOB0..3 : A0..A3
GPIOB4    : Chargt
GPIOB5..7 : réserves
```

Les deux ports du MCP23017 ne sont pas mis à jour simultanément : chaque octet
reçu est appliqué immédiatement. Ce n'est pas bloquant si `Chargt` reste
inactif pendant la mise à jour. Le pilote configure `BANK=1` et `SEQOP=1` afin de
produire la descente et la remontée de `Chargt` par deux octets visant le même
registre `OLATB` :

1. écrire les données avec `Chargt` inactif ;
2. écrire l'adresse avec `Chargt` toujours inactif ;
3. écrire `Chargt` actif puis inactif dans une même transaction I2C.

Le pilote conservera une image logicielle des deux ports et n'effectuera
jamais de lecture-modification-écriture du GPIO.

Précautions de démarrage et de panne :

- ajouter une résistance externe maintenant `Chargt` dans son état inactif
  lorsque les broches du MCP23017 sont en haute impédance ;
- charger les registres `OLAT` avant de configurer `IODIR` en sortie ;
- après tout reset CPU ou toute erreur I2C, remettre `Chargt` inactif avant de
  modifier données ou adresse ;
- vérifier au banc qu'une impulsion plus longue que les 4 à 5 us d'origine ne
  provoque aucun effet secondaire ;
- utiliser 400 kHz sur l'I2C. À cette vitesse, `Chargt` reste bas environ
  22,5 us et une séquence complète de 13 écritures demande théoriquement
  environ 3 ms dans le pire cas ;
- retenir provisoirement cette largeur comme acceptable : les cartes chargent
  sur le front descendant, les traces contiennent quelques impulsions plus
  longues et le panneau fonctionne avec un cycle élargi à 10 us. La mesure
  sur charge logique sera faite à réception des composants sans bloquer le
  raccordement logiciel ;
- si la mesure ultérieure montre un problème, conserver l'API `InstrumentBus`
  et remplacer seulement son backend par une interface parallèle isolée avec
  les TLP281.

Le détail de l'implémentation et la procédure de mesure sont dans
[`BUS_INSTRUMENTS_MCP23017.md`](BUS_INSTRUMENTS_MCP23017.md). La synthèse des
seize adresses se trouve dans
[`BUS_INSTRUMENTS_CARTOGRAPHIE.md`](BUS_INSTRUMENTS_CARTOGRAPHIE.md).

## Architecture logicielle cible

Séparer trois niveaux :

1. `InstrumentBus` : émission physique `(adresse, octet)` et temporisations ;
2. encodeurs fonctionnels : fréquence, amplitude et modulation vers les mots
   des cartes ;
3. contrôleur d'exploitation : décide quand appliquer une configuration et
   dans quel ordre appeler les encodeurs.

Les encodeurs doivent être utilisables dans des tests hôte sans Arduino. Les
captures décodées fourniront des vecteurs de référence : pour chaque valeur
utilisateur connue, la séquence calculée devra être identique aux transactions
de l'ancienne CPU.

## Ordre d'implémentation

1. [x] terminer le modèle des adresses 0 à 3 ;
2. [x] résoudre les adresses 4, 5, 6, 13 et 15 à partir des équations RF ;
3. [x] implémenter le pilote MCP23017 indépendamment des encodeurs ;
4. [x] ajouter l'amplitude ;
5. [x] ajouter AM, FM et PM ;
6. [x] ajouter les options doubleur et impulsions ;
7. [x] composer et raccorder une configuration complète au contrôleur ;
8. réaliser les essais sur charges logiques, puis connecter les cartes
   instruments une par une. Le motif de banc, le diagnostic série `IB?` et la
   récupération I2C bornée sont prêts ;
9. documenter les mesures et les fonctions encore non validées dans
   `docs/PROJECT_STATUS.md`.

## Références des composants

- Texas Instruments, `ISO1540/ISO1541`, document SLLSEB6F ;
- Microchip, `MCP23017/MCP23S17`, document DS20001952D.
