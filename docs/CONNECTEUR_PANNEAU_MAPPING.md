# Mapping du connecteur du panneau avant

Ce document décrit le câblage prévu entre les **signaux logiques du connecteur
CPU du panneau avant ADRET 740A** et les broches d'un **Arduino Mega 1280 ou
2560**. Le mapping ci-dessous est la nouvelle disposition destinée à éviter
les croisements lors du soudage du connecteur mâle. Il a été validé au banc le
23 août 2026 sur le faisceau provisoire à fils enfichables ; le brochage est
identique sur Mega 1280.

> Attention : les noms `PAx` et `PBx` du bus ADRET désignent les sorties du PIA
> d'origine. Les noms `PAx`, `PBx` et `PEx` dans la colonne ATmega désignent les
> ports internes du microcontrôleur. Leur ressemblance ne garantit pas à elle
> seule le câblage ; la correspondance explicite ci-dessous fait foi.

## Tableau de câblage

| Signal connecteur ADRET | Contact J1 | Rôle | Sens côté Arduino | Port ATmega1280/2560 | Nom logique Arduino | **N° imprimé sur le PCB** | Registre AVR physique |
| --- | ---: | --- | --- | --- | --- | --- | --- |
| `PA0` / donnée `D0` | 19 | Bit 0 du bus de données | Entrée/sortie | `PA6` | `D28` | **28** | `PORTA`, bit 6 |
| `PA1` / donnée `D1` | 20 | Bit 1 du bus de données | Entrée/sortie | `PA7` | `D29` | **29** | `PORTA`, bit 7 |
| `PA2` / donnée `D2` | 21 | Bit 2 du bus de données | Entrée/sortie | `PA4` | `D26` | **26** | `PORTA`, bit 4 |
| `PA3` / donnée `D3` | 22 | Bit 3 du bus de données | Entrée/sortie | `PA5` | `D27` | **27** | `PORTA`, bit 5 |
| `PA4` / donnée `D4` | 23 | Bit 4 du bus de données | Entrée/sortie | `PA2` | `D24` | **24** | `PORTA`, bit 2 |
| `PA5` / donnée `D5` | 24 | Bit 5 du bus de données | Entrée/sortie | `PA3` | `D25` | **25** | `PORTA`, bit 3 |
| `PA6` / donnée `D6` | 25 | Bit 6 du bus de données | Entrée/sortie | `PA0` | `D22` | **22** | `PORTA`, bit 0 |
| `PA7` / donnée `D7` | 26 | Bit 7 du bus de données | Entrée/sortie | `PA1` | `D23` | **23** | `PORTA`, bit 1 |
| `PB0` / `A` | 4 | Adresse de sélection, bit 0 | Sortie | `PB3` | `D50` | **50** | `PORTB`, bit 3 |
| `PB1` / `B` | 3 | Adresse de sélection, bit 1 | Sortie | `PB2` | `D51` | **51** | `PORTB`, bit 2 |
| `PB2` / `C` | 2 | Adresse de sélection, bit 2 | Sortie | `PB1` | `D52` | **52** | `PORTB`, bit 1 |
| `PB3` / `MODE` | 1 | Mode des afficheurs ICM7218A | Sortie | `PB0` | `D53` | **53** | `PORTB`, bit 0 |
| `CA2` / `WP` | 10 | Validation du décodeur d'adresse 74LS138 | Sortie | `PB4` | `D10` | **10** | `PORTB`, bit 4 |
| `CA1` / `INT CLAV` | 12 | Interruption clavier et roue codeuse | Entrée | `PE4` / `INT4` | `D2` | **2** | `PINE`, bit 4 |
| `INHIB` | 5 | Marche/arrêt général de l'alimentation ADRET | Sans connexion Arduino | — | — | — | Liaison directe vers B1-6 |
| `+5V_CPU` | 8 | Alimentation logique du panneau | Alimentation | — | `5V` | `5V` | — |
| `GND_CPU` | 16 | Masse logique du panneau | Alimentation | — | `GND` | `GND` | — |

J1 est un connecteur 2 x 13. Vu comme sur le schéma CPU d'origine, sa
numérotation commence en bas à droite par `MODE = J1-1`, puis alterne les
contacts impairs à droite et pairs à gauche en remontant. Les contacts J1-6,
J1-7, J1-9, J1-11, J1-13 à J1-15, J1-17 et J1-18 ne sont pas raccordés dans
le prototype.

La colonne **N° imprimé sur le PCB** est celle à utiliser directement côté
Mega. La nouvelle disposition applique au faisceau historique les échanges
`22/29`, `23/28`, `24/27`, `25/26`, ainsi que `50/53` et `51/52`. L'ancien
prototype validé utilisait D0..D7 sur `23, 22, 25, 24, 27, 26, 29, 28` et
MODE/C/B/A sur `50, 51, 52, 53`. Il n'est plus pris en charge par cette version
du firmware. `CA1` va au contact marqué **2** et `CA2` au contact marqué
**10**.

Le bus de données reste groupé sur la totalité de `PORTA`. Le firmware lit et
écrit toujours le port en une seule opération par `PINA`, `PORTA` et `DDRA`,
puis inverse l'ordre des huit bits à la frontière matérielle. Il inverse de la
même façon le quartet adresse/mode dans `PB3..PB0`. Les valeurs normalisées
utilisées par les afficheurs, voyants, clavier et molette restent donc
inchangées.

## Détail des signaux de contrôle

### PB0 à PB2 : adresse du périphérique panneau

`PB2..PB0` sélectionnent une sortie du décodeur du panneau :

| PB2 | PB1 | PB0 | Sélection | Fonction |
| --- | --- | --- | --- | --- |
| 0 | 0 | 0 | `Y0` | Repos / non connecté |
| 0 | 0 | 1 | `Y1` / `SN17` | Points décimaux |
| 0 | 1 | 0 | `Y2` / `SN4` | Premiers caractères et états |
| 0 | 1 | 1 | `Y3` / `SN2` | Banque de voyants |
| 1 | 0 | 0 | `Y4` / `SN3` | Banque de voyants |
| 1 | 0 | 1 | `Y5` / `SN5` | Lecture clavier et roue codeuse |
| 1 | 1 | 0 | `Y6` / `SN11` | Afficheurs modulation/amplitude et fin de fréquence |
| 1 | 1 | 1 | `Y7` / `SN10` | Huit premiers digits de fréquence |

### PB3

`PB3` ne fait pas partie de l'adresse du 74LS138. Cette ligne fournit le bit
de mode nécessaire aux afficheurs ICM7218A lors des sélections `SN10` et
`SN11`.

### CA2

`CA2` valide le 74LS138 lorsque `PB2..PB0` contiennent une adresse stable. Le
firmware considère cette ligne **active à l'état bas** : repos à `1`, sélection
à `0`, puis retour à `1`.

### CA1

`CA1` est une entrée d'interruption commune au clavier et à la roue codeuse.
Elle est raccordée à `D2`, qui correspond à `PE4` et à l'interruption externe
`INT4` sur l'ATmega1280 comme sur l'ATmega2560. Le firmware la configure sur
front descendant et active la résistance de pull-up interne de `PE4`. Celle-ci
complète la résistance de rappel de 4,7 kΩ présente sur le panneau.

### Conservation de D2, D3 et D10

Le regroupement de `CA1`, de la présence alimentation `PA` et de `CA2` dans la
zone D22 à D53 a été étudié puis écarté. D30 à D49 ne disposent ni des
interruptions externes utilisées ici, ni d'interruptions sur changement de
broche. D50 à D53 offrent des PCINT, mais sont déjà entièrement occupées par
`A`, `B`, `C` et `MODE`. Déplacer ces quatre sélections pour libérer des PCINT
rendrait le câblage et les routines d'interruption sensiblement plus complexes.

Le mapping conserve donc `CA1` sur D2/PE4/INT4 et `PA` sur D3/PE5/INT5. `CA2`
reste sur D10/PB4 : bien que D10 soit séparée physiquement des D50 à D53 sur la
Mega, PB4 est contigu à PB3..PB0 dans le registre AVR et permet de préserver
les accès directs et les temporisations actuelles.

## Commande générale d'alimentation `INHIB`

`INHIB` est une **ligne dédiée du connecteur entre le panneau avant et le bus
B1**. Elle commande la mise en marche et l'arrêt général de l'ADRET 740A après
son raccordement au secteur. Dans le prototype, J1-5 est reliée directement à
B1-6 : cette ligne ne passe ni par une broche ni par le firmware de la Mega.

| Niveau sur `INHIB` | État de l'alimentation générale |
| --- | --- |
| Masse / `0 V` | Alimentation en fonction, appareil en marche |
| Niveau haut / `5 V` | Alimentation arrêtée, appareil à l'arrêt |

La commande est donc **active à l'état bas**. Le commutateur marche/attente du
panneau agit directement sur cette fonction. Sur la carte CPU d'origine,
l'interface GPIB pouvait également commander `INHIB`; cette commande n'est pas
reprise par la nouvelle CPU.

## Distinction avec `INHIB RF`

`INHIB RF` est une fonction entièrement différente : elle autorise ou inhibe
la **sortie RF**, sans arrêter l'alimentation générale de l'appareil. Le bouton
`INHIB RF` du panneau fait partie des informations d'entrée qui remontent vers
le CPU pendant la lecture du clavier par `SN5` (`PB2..PB0 = 101`).

Cette même touche porte deux désignations suivant la source consultée :

| Source | Marquage de la touche |
| --- | --- |
| Schéma électrique de la matrice clavier | `RF OFF` |
| Sérigraphie du panneau avant | `INHIB RF` |

Dans ce projet, `RF OFF` et `INHIB RF` désignent donc **la même touche de la
matrice clavier**. Le nom `INHIB RF` reprend le texte visible par l'utilisateur
sur le panneau, tandis que `RF OFF` décrit plus directement son action. Aucun
de ces deux noms ne doit être confondu avec `INHIB`, la commande électrique de
marche/arrêt général.

`INHIB RF` n'est donc ni la ligne dédiée `INHIB`, ni une sortie à commander par
`PA6/D6`. L'ancienne association de `INHIB RF` à une sortie dédiée du bus était
incorrecte. `PA6/D6` reste simplement le bit 6 du bus de données bidirectionnel.

## Séquence électrique attendue

Pour une écriture vers le panneau :

1. configurer `PORTA` en sortie et placer l'octet de données physiquement
   inversé par rapport à l'image normalisée du firmware ;
2. inverser le quartet logique adresse/mode et placer l'image physique sur les
   bits 3..0 de `PORTB` ;
3. attendre la stabilisation des niveaux TTL ;
4. faire passer `CA2` de `1` à `0`, puis de `0` à `1`.

Pour lire le clavier ou la roue codeuse après une interruption `CA1` :

1. configurer `PORTA` en entrée ;
2. placer `PB2..PB0 = 101` pour sélectionner `SN5` ;
3. activer `CA2` à l'état bas ;
4. maintenir `CA2` actif pendant 10 µs pour laisser SN5 et le chemin
   d'acquittement C10/SN16 se stabiliser ;
5. lire les huit bits dans `PINA`, puis inverser l'octet avant son décodage ;
6. relâcher `CA2`, puis remettre le bus dans son état de repos.

Au démarrage, CA1 peut déjà être bloqué à l'état bas avant que l'interruption
sur front descendant soit armée. Le firmware effectue donc quatre lectures
d'acquittement SN5 espacées de 20 µs, puis initialise `INT4`. Chaque lecture
maintient CA2/Y5 actif pendant 10 µs. Cette séquence permet de libérer un
événement clavier ou molette resté mémorisé pendant le reset de la Mega.

## Points à vérifier avant raccordement définitif

- Vérifier l'orientation de J1 et le repère de J1-1 avant sertissage ; J1-1 est
  le contact `MODE` situé en bas à droite dans la vue du schéma CPU.
- Vérifier la continuité de chaque signal et la présence d'une masse commune.
- Vérifier la continuité directe J1-5 vers B1-6 ; ne pas relier `INHIB` à une
  sortie Arduino.
- Surveiller la stabilité de `CA1` lors de démarrages à froid répétés.
- Ne pas utiliser Arduino `D0` et `D1`, réservées à `Serial0`.
- Tous les signaux sont supposés compatibles TTL 5 V ; ne pas raccorder une
  alimentation du panneau sans avoir vérifié sa tension et sa masse.

Le câblage logiciel correspondant est centralisé dans
`include/Adret/HardwareConfig.h`.
