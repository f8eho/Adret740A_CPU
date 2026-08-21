# ADRET740A_CPU

[English version](README.md)

![Prototype ADRET 740A fonctionnant avec la CPU Arduino Mega](docs/Photos/Proto%20en%20fonctionnement%201.jpg)

`ADRET740A_CPU` remplace la carte processeur d'un générateur RF Adret 740A par
une Arduino Mega 1280 ou 2560. Le projet conserve le panneau avant et les cartes
RF analogiques d'origine ; il remplace leur commande, mémorise les réglages et
ajoute une télécommande ASCII sur liaison série.

Le prototype sur plaque à pastilles est monté dans un 740A et pilote déjà le
générateur. Le dépôt contient le firmware, le schéma KiCad complet du câblage,
les outils de calibration et les résultats détaillés de la rétroanalyse.

## Qu'est-ce que l'Adret 740A ?

L'Adret 740A est un générateur de signaux RF synthétisé destiné au laboratoire
et à la maintenance radio. La version de base couvre 100 kHz à 560 MHz avec une
résolution de commande de 10 Hz. Une option doubleur étend la couverture à
1,12 GHz. L'appareil règle également le niveau de sortie et produit des
modulations AM, FM, PM et impulsionnelles.

Sa partie RF reste intéressante aujourd'hui : elle est construite autour de
cartes analogiques spécialisées et d'une synthèse originale. En revanche, son
pilotage dépend d'une carte CPU à microprocesseur 6802, de deux EPROM et d'une
mémoire sauvegardée par batterie. Cette carte dialogue séparément avec le
panneau avant et avec un bus interne de seize registres commandant les cartes
instruments.

Cet appareil des années 1980 possède une architecture modulaire qui se prête
bien au remplacement de sa CPU par un microcontrôleur plus moderne. La carte
processeur centralise les commandes au moyen de bus clairement séparés, tandis
que la synthèse et les fonctions RF restent réalisées par des cartes
spécialisées relativement autonomes. Il est ainsi possible de remplacer la
logique de contrôle sans redessiner toute la chaîne analogique.

## Pourquoi remplacer la carte CPU ?

Dans mon appareil, l'électrolyte de la batterie de sauvegarde a coulé et a
détruit la carte CPU. Vu l'âge de ces générateurs, la même panne peut avoir
touché ou menacer d'autres exemplaires, même lorsque la partie RF est encore
réparable et performante.

L'objectif n'est donc pas de reconstruire l'ensemble du 740A. Il est de donner
une seconde vie à ses cartes RF, à son alimentation et à son panneau avant avec
des composants disponibles, un firmware lisible et un câblage documenté. La
rétroanalyse des EPROM et des captures du bus permet de reproduire les commandes
de fréquence, de niveau et de modulation sans modifier les cartes instruments.

L'installation de la nouvelle CPU ne demande aucune modification du châssis,
du câblage, du panneau avant ou des cartes instruments de l'Adret. Elle utilise
les connexions existantes à la place de la carte CPU d'origine. L'opération est
donc réversible : la nouvelle carte peut être retirée et une CPU d'origine
fonctionnelle peut être remontée.

## Pourquoi une Arduino Mega ?

La Mega 1280/2560 est un compromis pratique pour ce remplacement :

- son ATmega fonctionne en logique 5 V, compatible avec une grande partie des
  circuits TTL/CMOS du 740A sans ajouter des convertisseurs sur chaque signal ;
- elle fournit un port AVR 8 bits complet pour le panneau avant, suffisamment
  d'E/S, un contrôleur I2C matériel et un UART matériel indépendant ;
- les broches sont accessibles et la carte reste facile à trouver et à
  remplacer ;
- le framework Arduino simplifie les fonctions non critiques, tandis que les
  bus sensibles au temps utilisent directement les registres AVR ;
- PlatformIO rend les deux cibles, les options de compilation et les builds de
  diagnostic reproductibles.

La Mega n'est pas choisie pour transformer le 740A en projet Arduino
élémentaire : elle fournit surtout une plateforme AVR 5 V accessible, avec
assez de ressources pour émuler proprement la carte d'origine.

Un portage vers une autre plateforme reste possible, par exemple un ESP32, un
STM32 ou un Raspberry Pi Pico. Ces microcontrôleurs fonctionnant généralement
en logique 3,3 V, leurs GPIO ne peuvent toutefois pas être raccordées
directement au bus 5 V du panneau avant. Il faudrait ajouter de ce côté une
interface isolée et un expandeur d'E/S alimenté en 5 V, en plus de l'interface
du bus instruments, puis adapter le backend matériel et ses temporisations. La
logique fonctionnelle de haut niveau pourrait en grande partie être conservée.

## Architecture

```text
                     domaine CPU 5 V

 panneau avant <--- PORTA/PORTB --- Arduino Mega 1280/2560
                                         |
                                         | I2C 400 kHz
                                         v
                                    côté 1 ISO1540
                               - - isolation galvanique - -
                                    côté 2 ISO1540
                                         |
                                         v
                                     MCP23017
                               8 données + 4 adresses
                                   + strobe Chargt
                                         |
                                         v
                            bus des cartes instruments 5 V
                                domaine instruments isolé

 Serial0 D0/D1 <---------- télécommande ASCII 115200 bauds
```

### Panneau avant

Le bus de données du panneau est relié directement à `PORTA` (broches Mega
22 à 29). `PORTB` sélectionne les latches, afficheurs, voyants, clavier et roue
codeuse. Les accès directs aux registres AVR évitent le surcoût et la gigue de
`digitalWrite()`.

### Plaquette ISO1540 et MCP23017

Le bus instruments n'est pas un simple prolongement du bus panneau. Il
appartient à un autre domaine d'alimentation et de masse. Une liaison directe
avec la Mega supprimerait cette séparation et pourrait créer des courants de
masse ou endommager l'instrument, la carte de développement ou le matériel de
mesure.

L'ISO1540 isole les lignes I2C SDA et SCL. Le MCP23017, alimenté côté
instruments, convertit ensuite l'I2C en bus parallèle compatible avec le 740A :

- `GPA0..7` portent les huit bits de données ;
- `GPB0..3` portent les quatre bits d'adresse ;
- `GPB4` produit le signal actif bas `Chargt`, dont le front descendant
  mémorise la commande dans la carte sélectionnée.

L'ISO1540 n'isole **pas** l'alimentation. Son côté 2 et le MCP23017 utilisent
le `+5V_INST` et le `GND_INST` du domaine instruments, distincts du `+5V_CPU`
et du `GND_CPU` de la Mega. Chaque côté de l'isolateur demande ses propres
résistances de tirage I2C et son découplage.

Le brochage complet et la séquence de démarrage sûre sont documentés dans
[`BUS_INSTRUMENTS_MAPPING_HARDWARE.md`](docs/BUS_INSTRUMENTS_MAPPING_HARDWARE.md)
et
[`BUS_INSTRUMENTS_MCP23017.md`](docs/BUS_INSTRUMENTS_MCP23017.md).

## Compatibilité fonctionnelle et télécommande

Le nouveau firmware est quasiment iso-fonctionnel avec la CPU d'origine : il
conserve l'utilisation du panneau avant, les réglages RF et de modulation, les
mémoires, les séquences et la logique locale/distance. Les validations encore
ouvertes sont indiquées plus bas et dans `PROJECT_STATUS.md`.

Deux fonctions d'origine ne sont pas reprises actuellement :

- la pédale ou le cadenceur raccordé à l'entrée arrière `AUX` ne commande pas
  l'avancement des séquences ; cette fonction pourrait être ajoutée facilement
  si elle est nécessaire ;
- l'option de modulation `Impulsion` n'est pas implémentée dans le firmware
  utilisable, même si une partie de son codage bas niveau a été étudiée.

La principale différence volontaire concerne l'interface distante. Le circuit
IEEE-488/GPIB d'origine n'est pas reproduit ; il est remplacé par le port série
Serial0 à 115200 bauds, accessible par le connecteur USB de l'Arduino Mega. La
syntaxe historique des commandes GPIB est conservée autant que possible : seul
le transport électrique change. Un ordinateur peut ainsi commander le 740A
avec un terminal série ou un programme ouvrant le port USB-série, sans
contrôleur GPIB.

## Performances par rapport à la carte d'origine

L'interface I2C est plus lente que les écritures parallèles de la CPU 6802
d'origine. Ce compromis est mesuré et non supposé :

| Opération | Carte d'origine | ISO1540 + MCP23017 à 400 kHz |
| --- | ---: | ---: |
| impulsion basse `Chargt` typique | 3 à 5 µs | 22,5 µs |
| moyenne mesurée de `Chargt` | 4,151 µs | 22,5 µs |
| un mot, bus inchangé | — | 90 µs théoriques |
| un mot, donnée seule modifiée | — | 157,5 µs théoriques |
| un mot, donnée et adresse modifiées | — | 225 µs théoriques |
| séquence RF de 13 mots, pire cas | — | 2,925 ms théoriques |

L'impulsion est donc environ cinq fois plus longue que l'impulsion originale
moyenne. Elle a été vérifiée à l'analyseur logique, puis acceptée par les cartes
d'origine sur le générateur assemblé. Le firmware réduit aussi la latence en
n'envoyant que les blocs modifiés : une demande identique ne produit aucune
écriture, et `RF OFF` seul ne produit qu'un mot.

La fréquence I2C a été volontairement limitée à 400 kHz afin de conserver une
bonne marge de fiabilité avec les modules, les résistances de tirage et le
câblage actuels. À cette vitesse, le générateur répond déjà très bien et aucune
différence n'est perceptible en utilisation normale par rapport à la carte
d'origine. Le banc a fonctionné à 888 888 Hz pendant 1 000 cycles complets,
alors que 1 MHz n'était pas fiable dans le montage actuel. Une carte réalisée
avec un routage court, une capacité de bus réduite, des tirages et un découplage
soignés pourrait donc employer une fréquence supérieure, mais celle-ci devrait
être revalidée sur toute la chaîne isolée avant de remplacer le réglage
conservateur de 400 kHz.

Ces chiffres concernent le temps nécessaire pour programmer les latches du bus
interne. Ils ne constituent pas une mesure de la précision, du bruit de phase,
de la pureté spectrale ou du niveau RF des circuits analogiques d'origine. Ces
performances dépendent toujours de l'état et de la calibration de chaque 740A.

## État du projet

Le prototype a démarré à froid avec le bus instruments complet raccordé et a
produit un signal RF. Les validations effectuées couvrent notamment :

- le bus, les voyants, les afficheurs et le clavier du panneau avant, ainsi que
  l'acquisition des événements de la roue (son sens définitif reste à valider) ;
- les commandes fonctionnelles de fréquence, niveau, AM, FM et PM ;
- l'inhibition RF et la programmation différentielle des cartes instruments ;
- l'initialisation sans impulsion parasite et la récupération bornée après une
  erreur I2C ;
- la persistance des réglages et mémoires en EEPROM avec version et CRC ; la
  détection de disparition d'alimentation est implémentée, mais sa validation
  sur une vraie coupure reste à effectuer ;
- les commandes historiques du bus GPIB transposées en protocole ASCII sur
  Serial0 à 115200 bauds ;
- les outils d'import de l'ancienne 2816 et de calibration du niveau RF.

La couverture de base va de 100 kHz à 560 MHz. Le même firmware sait déclarer
l'option doubleur par un cavalier et calcule les commandes jusqu'à
1 119 999 990 Hz, mais cette partie reste validée hors matériel tant qu'elle
n'a pas été essayée sur un châssis équipé du doubleur.

Le câblage est identique pour les Mega 1280 et 2560 et les deux cibles
compilent avec succès. Les essais matériels consignés ont toutefois été
réalisés avec la Mega 2560 du prototype.

Il reste également à terminer certaines validations de panneau, la mesure
précise des pas de 10 Hz, la sauvegarde pendant une vraie coupure secteur et la
calibration RF complète. L'état détaillé, y compris les essais réussis et les
points encore ouverts, se trouve dans
[`PROJECT_STATUS.md`](docs/PROJECT_STATUS.md).

## Réaliser une carte de remplacement

La réalisation demande de savoir lire un schéma, câbler proprement une plaque
à pastilles et contrôler des alimentations 5 V. Elle ne demande pas de
redessiner la synthèse RF ni de modifier les cartes analogiques.

Le prototype utilise principalement :

- une Arduino Mega 2560 ou 1280 ;
- une plaquette d'isolation à ISO1540 ;
- une plaquette MCP23017 configurée à l'adresse I2C `0x20` ;
- une plaque à pastilles, les connecteurs adaptés au 740A, les résistances de
  tirage, résistances de sécurité et condensateurs de découplage du schéma ;
- un programmateur USB, un multimètre et, idéalement, un analyseur logique ou
  un oscilloscope isolé pour la mise au point.

Le projet KiCad 10 et son PDF imprimable sont dans
[`hardware/Adret740A_replacement_cpu`](hardware/Adret740A_replacement_cpu/).
Il décrit le prototype fil à fil et son dernier contrôle ERC ne contient ni
erreur ni avertissement. Il ne contient actuellement **pas de circuit imprimé
prêt à fabriquer** ni d'empreintes : la réalisation documentée est celle sur
plaque à pastilles.

La carte se raccorde aux connecteurs existants du 740A. Aucune piste ni aucun
fil de l'appareil ne doit être coupé ou modifié pour l'installer.

Un parcours prudent consiste à :

1. inspecter et remettre en état les alimentations et cartes RF du 740A ;
2. câbler et tester le panneau avant sans le bus instruments ;
3. valider l'ISO1540 et le MCP23017 avec le build `i2c_probe`, sorties encore
   en haute impédance ;
4. observer `Chargt` avec le build `instrument_bus_bench`, fond de panier
   instruments impérativement débranché ;
5. recharger le firmware normal, vérifier l'isolation, puis raccorder le bus
   instruments ;
6. effectuer les contrôles fonctionnels et la calibration décrits dans les
   documents du dépôt.

Les photos du prototype et du câblage sont disponibles dans
[`docs/Photos`](docs/Photos/).

## Précautions importantes

Le 740A est un appareil alimenté par le secteur et contient des circuits RF.
La carte de remplacement ne dispense pas des précautions habituelles de
réparation d'un instrument de laboratoire.

- Ne jamais relier directement `GND_CPU` à `GND_INST` si l'isolation doit être
  conservée.
- Un câble USB, un analyseur logique ou un oscilloscope relié à la terre peut
  ponter les deux domaines à votre insu. Vérifier les références de masse avant
  de brancher une sonde.
- Vérifier les tirages SDA/SCL déjà montés sur les modules. Le prototype
  validé utilise un module MCP23017 avec des tirages de 4,7 kΩ ; un module à
  10 kΩ a présenté des niveaux intermédiaires incorrects derrière l'ISO1540.
- Maintenir `RESET` du MCP23017 au niveau haut et découpler les alimentations au
  plus près des circuits.
- Une résistance externe doit maintenir `Chargt` inactif haut pendant le reset
  et avant que le firmware configure les sorties.
- Ne jamais charger `instrument_bus_bench` avec le fond de panier instruments
  raccordé. Recharger ensuite le firmware normal.

## Technologies et règles du firmware

- C++17, framework Arduino et toolchain AVR via PlatformIO ;
- Arduino Mega / ATmega1280 ou ATmega2560 à 16 MHz et logique 5 V ;
- accès directs à PORTA, PORTB et PORTE pour les bus et interruptions ;
- I2C matériel à 400 kHz, timeout borné et récupération sans boucle infinie ;
- données volumineuses et image de calibration placées en Flash avec
  `PROGMEM` ;
- configuration, mémoires et calibration transactionnelles en EEPROM avec
  CRC ;
- scripts Python pour la calibration et la génération des données ;
- schéma et validation de netlist avec KiCad 10 ;
- télécommande ASCII sur Serial0, broches D0/D1 réservées.

Le code projet reste sans allocation dynamique : pas de `String`, `malloc`,
`free`, `new` ou `delete`. Les modules sont statiques et les files, buffers et
tables ont une taille fixe.

## Compilation avec PlatformIO

La cible par défaut est `megaatmega2560`. Une Mega 1280 utilise les mêmes
connexions mais doit être sélectionnée explicitement.

### VS Code sous Windows, Linux ou macOS

Installer l'extension PlatformIO IDE, ouvrir la racine du dépôt puis utiliser :

- `Project Tasks > megaatmega2560 > Build` pour la cible par défaut ;
- `Project Tasks > megaatmega1280 > Build` pour la Mega 1280 ;
- la tâche `Upload` correspondante pour téléverser.

### Terminal sous Linux

Installer Python 3 puis PlatformIO Core selon la
[documentation officielle PlatformIO](https://docs.platformio.org/en/latest/core/installation/methods/pypi.html) :

```bash
python3 -m pip install -U platformio
```

Depuis la racine du dépôt :

```bash
# Compiler la Mega 2560, cible par défaut
pio run

# Compiler explicitement la Mega 1280
pio run -e megaatmega1280

# Téléverser la cible par défaut
pio run -t upload

# Téléverser la cible Mega 1280
pio run -e megaatmega1280 -t upload

# Ouvrir le terminal Serial0
pio device monitor --baud 115200
```

Selon la distribution, l'exécutable peut s'appeler `platformio` au lieu de
`pio` ; les deux noms lancent PlatformIO Core.

### Terminal PowerShell sous Windows

Si `pio` est dans le `PATH`, les commandes Linux ci-dessus sont identiques sous
PowerShell. Avec l'environnement Python créé par l'extension PlatformIO :

```powershell
& "$env:USERPROFILE\.platformio\penv\Scripts\pio.exe" run
& "$env:USERPROFILE\.platformio\penv\Scripts\pio.exe" run -e megaatmega1280
& "$env:USERPROFILE\.platformio\penv\Scripts\pio.exe" run -t upload
& "$env:USERPROFILE\.platformio\penv\Scripts\pio.exe" device monitor --baud 115200
```

### Peut-on utiliser l'IDE Arduino ?

Le firmware utilise le framework Arduino et les bibliothèques standard
`Wire` et `EEPROM`, mais ce dépôt n'est pas directement un sketch pour l'IDE
Arduino. Il ne contient pas de fichier `.ino` et dépend de l'arborescence
`src`/`include`, de C++17, de macros propres aux environnements et d'une option
d'édition de liens qui conserve la table de calibration en Flash.

Une adaptation manuelle vers une structure de sketch ou de bibliothèque
Arduino est possible, mais elle n'est ni fournie ni validée. PlatformIO est la
méthode de compilation prise en charge et reproductible.

## Builds de diagnostic

Deux environnements sont réservés à la mise au point matérielle :

```bash
# Sonde I2C sûre : le MCP23017 reste en entrée
pio run -e i2c_probe
pio run -e i2c_probe -t upload

# Motif de sortie pour analyseur logique
# DANGER : fond de panier instruments débranché
pio run -e instrument_bus_bench
pio run -e instrument_bus_bench -t upload
```

Après un diagnostic, recharger le firmware normal :

```bash
pio run -e megaatmega2560 -t upload
```

La procédure complète et les résultats mesurés se trouvent dans
[`BUS_INSTRUMENTS_MCP23017.md`](docs/BUS_INSTRUMENTS_MCP23017.md).

## Calibration et tests hôte

L'application à menus regroupe une procédure guidée de calibration de
l'atténuateur, l'import d'une 2816 d'origine et la fusion finale de la table
dans la Flash. Elle guide la mesure et la correction des différents états de
l'atténuateur en fonction de la fréquence.

Si l'EEPROM 2816 de la carte CPU d'origine est encore lisible et que son contenu
est cohérent, ses données de calibration peuvent être reprises comme table de
base au lieu de repartir de zéro. Dans le cas contraire, la procédure manuelle
permet de reconstruire une table adaptée à l'appareil restauré. L'import
conserve le format logique de la grille fréquence/atténuateur d'origine et
vérifie sa compatibilité avec le profil de base ou l'option doubleur.

Sous Windows, double-cliquer sur `scripts\lancer_calibration.cmd` ou lancer :

```powershell
python .\scripts\adret_calibration.py
```

Sous Linux :

```bash
python3 scripts/adret_calibration.py
```

La procédure détaillée est décrite dans
[`CALIBRATION_AMPLITUDE.md`](docs/CALIBRATION_AMPLITUDE.md). Le réalignement
analogique préalable est décrit dans
[`CALIBRATION_GROSSIERE_NIVEAU_RF.md`](docs/CALIBRATION_GROSSIERE_NIVEAU_RF.md).

Les tests hôte du parseur, du cadrage série, de la composition du bus, de la
calibration et de la persistance se lancent sous Windows avec :

```powershell
& ".\test\run_host_tests.ps1"
```

Ils nécessitent PowerShell et un compilateur hôte `g++`.

## Organisation du dépôt

- [`src`](src/) : implémentation C++ et point d'entrée du firmware ;
- [`include/Adret`](include/Adret/) : interfaces, configuration matérielle et
  tables fixes ;
- [`hardware/Adret740A_replacement_cpu`](hardware/Adret740A_replacement_cpu/) :
  schéma KiCad, PDF, netlist et contrôle ERC ;
- [`docs/PROJECT_STATUS.md`](docs/PROJECT_STATUS.md) : état détaillé et essais
  au banc ;
- [`docs/retroanalyse_panneau_avant.md`](docs/retroanalyse_panneau_avant.md) :
  protocole électrique du panneau ;
- [`docs/BUS_INSTRUMENTS_CARTOGRAPHIE.md`](docs/BUS_INSTRUMENTS_CARTOGRAPHIE.md) :
  cartographie consolidée des seize registres ;
- [`docs/ADRET7401_Principe.md`](docs/ADRET7401_Principe.md) : explication de la
  synthèse de fréquence originale ;
- [`scripts`](scripts/) : calibration, import et tests hôte ;
- [`platformio.ini`](platformio.ini) : cibles et options de compilation.

Le câblage AVR est centralisé dans
[`HardwareConfig.h`](include/Adret/HardwareConfig.h). Les broches Serial0 D0/D1
restent réservées à la télécommande externe.

## Licence et crédits

Les créations originales de ce projet — firmware, scripts, tests,
documentation et matériel KiCad — sont distribuées sous
[licence MIT](LICENSE), Copyright (c) 2026 Pascal AMESLAND (F8EHO).

Les scans, extraits, dumps, désassemblages et autres éléments provenant de
tiers ne sont pas couverts par cette licence. Voir
[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) pour le détail.

Assisted-by: OpenAI:ChatGPT-5.6-Sol codex
