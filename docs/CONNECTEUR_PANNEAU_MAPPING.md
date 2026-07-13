# Mapping du connecteur du panneau avant

Ce document décrit le câblage prévu entre les **signaux logiques du connecteur
CPU du panneau avant ADRET 740A** et les broches de l'**Arduino Mega 2560**.
Ce mapping reprend le faisceau validé au banc avec la matrice clavier, les
voyants et les trois groupes d'affichage.

> Attention : les noms `PAx` et `PBx` du bus ADRET désignent les sorties du PIA
> d'origine. Les noms `PAx`, `PBx` et `PEx` dans la colonne ATmega désignent les
> ports internes du microcontrôleur. Leur ressemblance ne garantit pas à elle
> seule le câblage ; la correspondance explicite ci-dessous fait foi.

## Tableau de câblage

| Signal connecteur ADRET | Rôle | Sens côté Arduino | Port ATmega2560 | Nom logique Arduino | **N° imprimé sur le PCB** | Registre firmware |
| --- | --- | --- | --- | --- | --- | --- |
| `PA0` / donnée `D0` | Bit 0 du bus de données | Entrée/sortie | `PA1` | `D23` | **23** | `PORTA`, bit 1 |
| `PA1` / donnée `D1` | Bit 1 du bus de données | Entrée/sortie | `PA0` | `D22` | **22** | `PORTA`, bit 0 |
| `PA2` / donnée `D2` | Bit 2 du bus de données | Entrée/sortie | `PA3` | `D25` | **25** | `PORTA`, bit 3 |
| `PA3` / donnée `D3` | Bit 3 du bus de données | Entrée/sortie | `PA2` | `D24` | **24** | `PORTA`, bit 2 |
| `PA4` / donnée `D4` | Bit 4 du bus de données | Entrée/sortie | `PA5` | `D27` | **27** | `PORTA`, bit 5 |
| `PA5` / donnée `D5` | Bit 5 du bus de données | Entrée/sortie | `PA4` | `D26` | **26** | `PORTA`, bit 4 |
| `PA6` / donnée `D6` | Bit 6 du bus de données | Entrée/sortie | `PA7` | `D29` | **29** | `PORTA`, bit 7 |
| `PA7` / donnée `D7` | Bit 7 du bus de données | Entrée/sortie | `PA6` | `D28` | **28** | `PORTA`, bit 6 |
| `PB0` | Adresse de sélection, bit 0 | Sortie | `PB0` | `D53` | **53** | `PORTB`, bit 0 |
| `PB1` | Adresse de sélection, bit 1 | Sortie | `PB1` | `D52` | **52** | `PORTB`, bit 1 |
| `PB2` | Adresse de sélection, bit 2 | Sortie | `PB2` | `D51` | **51** | `PORTB`, bit 2 |
| `PB3` | Mode des afficheurs ICM7218A | Sortie | `PB3` | `D50` | **50** | `PORTB`, bit 3 |
| `CA2` | Validation du décodeur d'adresse 74LS138 | Sortie | `PB4` | `D10` | **10** | `PORTB`, bit 4 |
| `CA1` | Interruption clavier et roue codeuse | Entrée | `PE4` / `INT4` | `D2` | **2** | `PINE`, bit 4 |
| `INHIB` | Marche/arrêt général de l'alimentation ADRET | Sortie | **À attribuer** | **À attribuer** | **À attribuer** | Non implémenté |

La colonne **N° imprimé sur le PCB** est celle à utiliser directement pendant
le câblage. Le relevé validé avec toutes les touches de la matrice impose les
permutations `22/23`, `24/25`, `26/27` et `28/29`. `CA1` va au contact marqué
**2** et `CA2` au contact marqué **10**.

Le bus de données reste groupé sur la totalité de `PORTA`, car le firmware le
lit et l'écrit en une seule opération par `PINA`, `PORTA` et `DDRA`. Les
permutations du tableau font partie du câblage validé et ne doivent pas être
compensées dans le logiciel.

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
`INT4` sur l'ATmega2560. Le firmware la configure sur front descendant et
active la résistance de pull-up interne de `PE4`. Celle-ci complète la
résistance de rappel de 4,7 kΩ présente sur le panneau.

## Commande générale d'alimentation `INHIB`

`INHIB` est une **ligne dédiée du connecteur entre le panneau avant et la carte
CPU**. Elle commande la mise en marche et l'arrêt général de l'ADRET 740A après
son raccordement au secteur :

| Niveau sur `INHIB` | État de l'alimentation générale |
| --- | --- |
| Masse / `0 V` | Alimentation en fonction, appareil en marche |
| Niveau haut / `5 V` | Alimentation arrêtée, appareil à l'arrêt |

La commande est donc **active à l'état bas**. Le bouton marche/arrêt du panneau
avant agit sur cette fonction. Sur la carte CPU d'origine, l'interface GPIB
pouvait également commander `INHIB`. Cette commande GPIB ne sera pas reprise
sur la nouvelle carte CPU.

La broche Arduino destinée à `INHIB` n'est pas encore définie dans
`HardwareConfig.h`. Elle est donc volontairement marquée **À attribuer** dans
le tableau, afin de ne pas créer un câblage erroné. Une fois choisie, cette
sortie devra être initialisée dans un état maîtrisé dès le démarrage.

Pour un comportement sûr en cas de reset, de débranchement ou pendant le
bootloader, prévoir matériellement un état par défaut à `5 V` (alimentation
arrêtée), par exemple avec une résistance de rappel adaptée. Il faut également
vérifier sur le schéma si la ligne peut être pilotée directement en logique
5 V ou si une sortie à collecteur ouvert/drain ouvert est nécessaire, notamment
à cause du bouton du panneau câblé sur la même commande.

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

1. configurer `PORTA` en sortie et placer l'octet de données ;
2. placer l'adresse sur `PB2..PB0` et, si nécessaire, le mode sur `PB3` ;
3. attendre la stabilisation des niveaux TTL ;
4. faire passer `CA2` de `1` à `0`, puis de `0` à `1`.

Pour lire le clavier ou la roue codeuse après une interruption `CA1` :

1. configurer `PORTA` en entrée ;
2. placer `PB2..PB0 = 101` pour sélectionner `SN5` ;
3. activer `CA2` à l'état bas ;
4. maintenir `CA2` actif pendant 10 µs pour laisser SN5 et le chemin
   d'acquittement C10/SN16 se stabiliser ;
5. lire les huit bits dans `PINA` ;
6. relâcher `CA2`, puis remettre le bus dans son état de repos.

Au démarrage, CA1 peut déjà être bloqué à l'état bas avant que l'interruption
sur front descendant soit armée. Le firmware effectue donc quatre lectures
d'acquittement SN5 espacées de 20 µs, puis initialise `INT4`. Chaque lecture
maintient CA2/Y5 actif pendant 10 µs. Cette séquence permet de libérer un
événement clavier ou molette resté mémorisé pendant le reset de la Mega.

## Points à vérifier avant raccordement définitif

- La numérotation physique des contacts du connecteur n'est pas indiquée ici :
  elle doit être relevée sur le schéma ou sur le faisceau avant sertissage.
- Vérifier la continuité de chaque signal et la présence d'une masse commune.
- Attribuer une broche Arduino dédiée à `INHIB`, puis reporter son numéro
  sérigraphié dans le tableau et dans `HardwareConfig.h`.
- Confirmer le circuit électrique de `INHIB` avant de le piloter : commande
  directe ou collecteur ouvert, résistance de rappel et interaction avec le
  bouton marche/arrêt du panneau.
- Surveiller la stabilité de `CA1` lors de démarrages à froid répétés.
- Ne pas utiliser Arduino `D0` et `D1`, réservées à `Serial0`.
- Tous les signaux sont supposés compatibles TTL 5 V ; ne pas raccorder une
  alimentation du panneau sans avoir vérifié sa tension et sa masse.

Le câblage logiciel correspondant est centralisé dans
`include/Adret/HardwareConfig.h`.
