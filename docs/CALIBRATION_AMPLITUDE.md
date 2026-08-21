# Calibration de l'amplitude RF

## Principe retenu

La correction appliquée par le firmware est la somme de deux tables :

```text
correction effective = table Flash permanente + overlay EEPROM
```

Les valeurs sont signées et exprimées en dixièmes de dB. Une correction
positive ajoute de l'atténuation. Après une mesure :

```text
résidu = niveau mesuré - niveau demandé
nouvel overlay = ancien overlay + résidu
```

Une calibration antérieure n'est donc jamais remplacée par la dernière
mesure : le défaut résiduel est ajouté à la correction qui était effectivement
active pendant la mesure.

Le firmware refuse une correction effective hors de −5,0 à +2,0 dB. Cette
limite conserve la commande fine dans sa plage physique sur tous les bords de
cellules. Un défaut supérieur indique normalement un problème matériel ou une
mesure affectée au mauvais point.

## Grille originale de la 2816

La table permanente conserve le format logique de la 2816 originale :

- 64 lignes de 32 octets, soit 2 048 octets ;
- colonnes 0 à 27 : les 28 états mécaniques de l'atténuateur, par pas de 5 dB ;
- colonnes 28 à 31 : inutilisées ;
- lignes 0 à 8 : bandes de 100 kHz entre 100 kHz et 1 MHz ;
- lignes 9 à 17 : bandes de 1 MHz entre 1 et 10 MHz ;
- lignes 18 à 28 : bandes de 50 MHz entre 10 et 560 MHz ;
- ligne 29 : 560 à 609,999990 MHz en profil X2, mais uniquement le point
  560 MHz en profil BASE ;
- lignes 30 à 39 : bandes successives de 50 MHz entre 610 et 1 110 MHz ;
- ligne 40 : 1 110 à moins de 1 120 MHz ;
- lignes 41 à 63 : inconnues et refusées si elles ne sont pas neutres.

Le firmware reproduit cette indexation sans interpolation. L'overlay EEPROM
est compact : seules les 41 lignes reconnues et les 28 colonnes utilisables
sont conservées, soit 1 148 valeurs.

Chaque banque est liée au profil `BASE` ou `X2`. Les lignes 0 à 28 sont
communes. La ligne 29 et les lignes supérieures ne sont appliquées que si le
profil de la table permanente et celui déclaré par le cavalier concordent ;
sinon elles restent neutres.

## Import d'une EEPROM 2816 existante

Un dump brut doit faire exactement 2 048 octets. L'ancien firmware stockait
les valeurs complémentées :

```text
correction = int8_t(~octet_2816)
```

Ainsi, une EEPROM effacée à `FF` représente une correction nulle. L'application
contrôle la taille, les quatre colonnes inutilisées et les lignes d'extension,
puis peut générer les valeurs signées natives du nouveau firmware. Utiliser
l'option **2. Analyser ou importer une EEPROM 2816** du menu principal.

La même opération reste disponible en ligne de commande :

```powershell
python .\scripts\adret_calibration.py import `
    .\docs\eeprom_740A\740-2816.BIN

python .\scripts\adret_calibration.py import `
    .\docs\eeprom_740A\740-2816.BIN `
    --output .\src\CalibrationTable.inc --profile base --force
```

La première commande analyse sans écrire. La seconde remplace la table Flash
à compiler et écrit aussi `CalibrationProfile.inc`. Toute génération de table
exige `--profile base` ou `--profile x2`. Le profil BASE exige des lignes
30 à 63 effacées ; le profil X2 accepte les lignes 30 à 40 mais exige les
lignes 41 à 63 effacées. Les corrections provenant d'un autre générateur ne
doivent servir qu'à l'étude du format.

## Stockage transactionnel et abandon

Deux banques EEPROM de 1 148 valeurs sont utilisées à partir de l'adresse
1280. Avec leur en-tête de 16 octets, elles se terminent à l'adresse 3607 et
tiennent dans les 4 Kio d'EEPROM des ATmega1280 et ATmega2560. Chaque banque
possède une signature, une version, une génération, un profil, le CRC de la
table Flash, un CRC de données et un état.

Le format courant est la version 2. Une version 1 est migrée automatiquement :
les lignes 0 à 28 sont toujours conservées, la ligne 29 ne l'est qu'en profil
BASE, et les lignes 30 à 40 sont neutralisées. Un changement de cavalier
conserve également les lignes communes 0 à 28 et neutralise 29 à 40. La
migration utilise l'autre banque et, dans l'unique zone de recouvrement avec
l'ancien format, un marqueur récupérable validé par un test de coupure après
chaque écriture EEPROM.

`CAL BEGIN` copie la dernière banque validée dans l'autre banque et marque
cette copie « travail ». Pendant la session, les corrections dynamiques sont
lues dans cette copie. La banque validée précédente reste intacte.

`CAL END` calcule les CRC, écrit l'en-tête validé puis relit et vérifie toute
la banque. Elle ne devient active qu'après cette vérification.

`CAL ABORT` réalise dans cet ordre :

1. abandon de la banque de travail ;
2. retour à la dernière banque validée ;
3. restauration de la fréquence, du niveau, de la modulation, de la source et
   de l'état RF présents au moment de `CAL BEGIN` ;
4. sortie du mode calibration.

La touche `Adr RTL` provoque le même abandon avant de rendre le panneau local.
Un redémarrage ignore toute banque restée en état « travail » et le démarrage
normal force en plus RF OFF. Pendant une session, la sauvegarde sur coupure
d'alimentation est inhibée afin de ne pas mémoriser le point de mesure courant
comme configuration utilisateur.

En cas de perte de la liaison série sans redémarrage, utiliser `Adr RTL` pour
obtenir immédiatement l'abandon et la restauration locale.

Le CRC de la table Flash est enregistré dans chaque banque. Après fusion des
corrections dans le firmware et reflashage, le nouveau CRC rend l'ancien
overlay incompatible et empêche de l'ajouter une seconde fois.

## Application Python à menus

Les trois opérations sont regroupées dans une seule application :

1. calibration manuelle guidée ;
2. analyse ou import d'une EEPROM 2816 ;
3. fusion d'une session validée dans la table Flash.

Sous Windows, lancer par double-clic :

```text
scripts\lancer_calibration.cmd
```

Ou depuis un terminal :

```powershell
python .\scripts\adret_calibration.py
```

L'application propose les fichiers usuels par défaut, détecte les ports série
disponibles et demande confirmation avant tout remplacement de table. Seule la
calibration manuelle nécessite `pyserial` ; aucun instrument VISA ou SCPI n'est
requis :

```powershell
python -m pip install pyserial
```

L'assistant règle automatiquement fréquence et niveau sur le 740A. Pour chaque
point, l'utilisateur lit son wattmètre, analyseur ou récepteur puis saisit le
niveau mesuré en dBm. La correction est appliquée immédiatement et l'assistant
demande une nouvelle mesure jusqu'à obtenir le niveau demandé à 0,1 dB près.

La ligne de commande avancée reste disponible, par exemple pour limiter la
caractérisation :

```powershell
# Caractérisation limitée aux bandes hautes et aux cinq premiers paliers
python .\scripts\adret_calibration.py calibrate `
    --port COM3 --rows 18-28 --steps 0-4
```

Les lignes 30 à 40 ne sont proposées que si `OPT?` annonce `DOUBLER=1`. La
session JSON mémorise alors le profil `x2`; le firmware et l'outil refusent de
la fusionner avec une table permanente BASE.

Les trois anciens noms de scripts sont conservés comme raccourcis compatibles,
mais toute la logique se trouve désormais dans `adret_calibration.py`.

Les saisies spéciales sont :

- `S` : ignorer le point et poursuivre ;
- `Q`, puis `P` : mettre en pause, abandonner la banque de travail et conserver
  le journal pour reprise ;
- `Q`, puis `A` : abandon définitif de la session ;
- `Ctrl+C` : interruption sécurisée avec tentative automatique de
  `CAL ABORT`.

Le fichier JSON est réécrit atomiquement après chaque mesure. Lors d'une
reprise, l'assistant vérifie le CRC Flash et la génération EEPROM, ouvre une
nouvelle copie de travail, puis rejoue les corrections déjà consignées.

## Commandes série directes

Le générateur doit d'abord être placé en mode distant avec `REN1`.

```text
CAL BEGIN
CAL STATUS?
CAL MEAS -40.2
CAL ADJ +0.1
CAL CLEAR
CAL SET 18 5 +0.3
CAL DUMP
CAL END
CAL ABORT
```

`CAL MEAS` reçoit le niveau mesuré, calcule le résidu et l'ajoute à l'overlay.
`CAL ADJ` ajoute directement une correction manuelle. `CAL SET` est destiné à
la reprise automatisée d'un journal. `CAL DUMP` retourne les 1 148 valeurs.

## Fusion finale dans la Flash

À la fin d'une procédure complète, le journal contient le dump de l'overlay
validé. Choisir **3. Fusionner une session dans la Flash** dans l'application.
En ligne de commande, l'équivalent est :

```powershell
python .\scripts\adret_calibration.py merge `
    .\calibration_amplitude.json `
    --base .\src\CalibrationTable.inc `
    --output .\src\CalibrationTable.inc --force
```

L'outil refuse une session non terminée, un CRC de base différent, une table
incomplète ou un dépassement de `int8_t`. Recompiler et flasher ensuite le
firmware. Au redémarrage, l'overlay maintenant intégré est automatiquement
ignoré grâce au changement de CRC Flash.

## Précautions de mesure

- laisser stabiliser thermiquement le générateur et l'instrument de mesure ;
- utiliser une charge et une chaîne 50 ohms stables ;
- travailler en CW, sans modulation ;
- définir le plan de référence au connecteur RF ou corriger la perte du câble ;
- aux très faibles niveaux, utiliser un récepteur ou analyseur à bande étroite
  et surveiller les fuites ainsi que le plancher de bruit ;
- contrôler particulièrement les bords des paliers mécaniques et les
  changements de chemin RF.
