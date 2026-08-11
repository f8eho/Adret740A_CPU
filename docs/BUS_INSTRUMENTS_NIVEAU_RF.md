# Niveau RF : adresses 6 et 8

## Résultat

Le niveau RF est programmé par une séquence de trois écritures :

```text
adresse 6 : sélection des cellules mécaniques, D7/D6 préservés
adresse 8 : atténuation analogique fine corrigée
adresse 6 : état final de D7 (+5 dB) et de D6 (Pulse)
```

L'encodeur correspondant est dans `InstrumentAmplitude.h/.cpp`. Il couvre la
plage documentée de `-129,9` à `+13,0 dBm` et accepte séparément une correction
signée en dixièmes de dB.

## Sources utilisées

- capture `Dec_Mollette -70db à -35db pas de 0,1db.csv` ;
- schéma analogique page 46 pour le réseau de l'adresse 8 ;
- schémas approche et atténuateur, pages 17 et 19 ;
- schéma de commande de régulation page 52 pour les signaux `REF`, `DET`
  et `Cde AM` ;
- routine originale aux adresses physiques `ED74` à `EF6D` ;
- table de relais de l'EPROM programme à l'adresse physique `C1F6` ;
- fiche technique et manuel utilisateur du 740A pour les limites, la
  résolution de 0,1 dB et la course analogique annoncée de 119 pas.

## Vue d'ensemble fonctionnelle

Le réglage de niveau associe deux dispositifs différents :

```text
adresse 8 -> référence analogique REF ---------+
                                                  |
détecteur analogique DET -----------------------+--> commande de niveau VHF
                                                           |
                                                           v
source VHF régulée -> atténuateur RF à relais -> disjoncteur -> sortie
                         adresse 6
```

- la carte analogique produit la consigne `REF`. Son réseau pondéré donne les
  pas fins de 1 et 0,1 dB ;
- la carte détecteur prélève la HF à l'entrée du bloc atténuateur et produit
  `DET` ;
- la carte de commande de régulation compare `REF` et `DET`, puis agit par
  `Cde AM` sur le niveau de la carte VHF ;
- l'atténuateur à relais ajoute ensuite les grands pas RF de 5 dB.

La CPU ne mesure pas `DET`. Le bus instruments est utilisé pour écrire la
consigne et les relais ; il ne ferme pas une seconde boucle numérique autour
du niveau de sortie. La boucle rapide est entièrement analogique.

Le détecteur étant placé avant les cellules d'atténuation, la boucle ne voit
pas directement une perte apparue dans une cellule, le disjoncteur, le
connecteur ou le câblage de sortie. Une telle perte ne peut être compensée que
par une calibration mémorisée ou par une réparation du chemin RF.

## Plage programmable et précision garantie

Le manuel utilisateur distingue deux caractéristiques :

- réglage possible de `+13,0` à `-129,9 dBm` sur 50 ohms ;
- précision d'atténuation garantie seulement de `+13,0` à `-119,9 dBm`.

L'interprétation la plus cohérente est qu'il ne s'agit pas d'une faute de
frappe : les dix derniers dB restent programmables, mais le constructeur ne
donne plus la tolérance de ±1,5 dB. Aux niveaux les plus faibles, les fuites HF,
la diaphonie et l'isolation finie des relais deviennent comparables au signal
utile.

La mention `10 dB, 1 dB et 0,1 dB` du manuel décrit les résolutions de réglage
offertes à l'utilisateur, pas les seuls poids physiques des relais. En
interne :

- un incrément de 0,1 dB modifie normalement la commande analogique d'un pas ;
- un incrément de 1 dB représente dix pas analogiques ;
- un incrément de 10 dB provoque une recomposition complète, généralement
  équivalente à deux pas mécaniques de 5 dB.

## Adresse 8 : atténuation fine

### Course utile de 119 pas

Le synoptique de la carte analogique annonce `119 pas de 0,1 dB`, soit une
course utile voisine de 11,9 dB. Cette course ne signifie pas que les 119 pas
sont parcourus entre deux positions de relais. Comme les relais changent tous
les 5 dB, environ 50 codes fins suffisent pour interpoler entre deux positions.
Le reste fournit le recouvrement nécessaire aux commutations, à la plage haute
et à la calibration.

Avec une correction nulle, le programme utilise :

| Domaine | Pas mécanique | Atténuation fine nominale |
|---|---:|---:|
| niveaux ordinaires | variable par pas de 5 dB | 6,9 à 11,8 dB |
| `+7,0` à `+13,0 dBm` | 0 dB | 6,8 à 0,8 dB |
| ensemble de la plage | 0 à 135 dB | 0,8 à 11,8 dB |

Les valeurs proches de zéro ne doivent donc pas être qualifiées d'inutiles :
elles appartiennent à la marge haute et peuvent aussi être atteintes par une
correction. De même, la capture originale atteint 11,9 dB lorsque la table de
calibration ajoute `+0,1 dB`.

La constante numérique `13,8 dB` utilisée plus bas reproduit exactement le
programme et les commandes de l'ancienne CPU. Elle constitue une référence de
calcul. Elle ne prouve pas, à elle seule, que le code brut zéro produit
physiquement `+13,8 dBm` sur le connecteur de sortie : les pertes fixes et les
réglages analogiques interviennent entre la consigne interne et la mesure
externe.

Le réseau analogique donne les poids suivants :

| Bit du bus | Poids |
|---:|---:|
| D0 | 0,1 dB |
| D1 | 0,2 dB |
| D2 | 0,4 dB |
| D3 | 0,8 dB |
| D4 | 1 dB |
| D5 | 2 dB |
| D6 | 8 dB |
| D7 | 4 dB |

L'inversion des poids 4 et 8 dB explique le saut du quartet haut. Pour une
valeur physique `fine` exprimée en dixièmes de dB :

```text
dizaines = fine / 10
unités    = fine % 10

si dizaines >= 6 : quartet_haut = dizaines + 2
sinon             : quartet_haut = dizaines

adresse8 = (quartet_haut << 4) | unités
```

Le décodage réciproque retranche 2 au quartet haut lorsqu'il vaut au moins 8.

## Adresse 6 : atténuateur et commandes

Les six bits bas sélectionnent les relais. La table compacte, indexée par le
nombre `s` de pas mécaniques de 5 dB, est une transcription de l'EPROM CPU :

| `s` | dB mécaniques | A6 D5..D0 | `s` | dB mécaniques | A6 D5..D0 |
|---:|---:|---:|---:|---:|---:|
| 0 | 0 | `3F` | 14 | 70 | `2C` |
| 1 | 5 | `37` | 15 | 75 | `24` |
| 2 | 10 | `3B` | 16 | 80 | `28` |
| 3 | 15 | `33` | 17 | 85 | `20` |
| 4 | 20 | `3D` | 18 | 90 | `19` |
| 5 | 25 | `35` | 19 | 95 | `11` |
| 6 | 30 | `39` | 20 | 100 | `0D` |
| 7 | 35 | `31` | 21 | 105 | `05` |
| 8 | 40 | `2D` | 22 | 110 | `09` |
| 9 | 45 | `25` | 23 | 115 | `01` |
| 10 | 50 | `29` | 24 | 120 | `18` |
| 11 | 55 | `21` | 25 | 125 | `10` |
| 12 | 60 | `38` | 26 | 130 | `0C` |
| 13 | 65 | `30` | 27 | 135 | `04` |

Les bits de commande sont :

- D6 : `Pulse`, actif à 1, indépendant du niveau ;
- D7 : commande `+5 dB` finale, active pour un niveau d'au moins `+7,0 dBm`
  lorsque l'adresse 5 sélectionne le chemin hétérodyne (D1 à 1).

La première écriture à l'adresse 6 préserve D7 et D6 de la valeur courante.
La seconde préserve D6, recalcule D7 et conserve le nouveau code de relais.
Une source AM active force aussi D7 sur le chemin hétérodyne. Cette interaction
est maintenant intégrée dans `makeAmplitudeControlAddress6()` et détaillée
dans `BUS_INSTRUMENTS_MODULATIONS.md`.

## Calcul nominal

Pour un niveau demandé `L` en dixièmes de dBm :

```text
s = max(0, ceil((20 - L) / 50))
fine_nominale = 138 - L - 50 * s
```

À partir de `+7,0 dBm`, `s` reste naturellement nul et le même calcul est
conservé :

```text
s = 0
fine_nominale = 138 - L
```

Une première transcription utilisait `188 - L` dans cette plage. Le banc a
montré qu'elle provoquait un saut d'atténuation de 4,9 dB au passage de
`+6,9` à `+7,0 dBm` (`adresse 8 = 89` puis `D8`). La formule continue donne
désormais `adresse 8 = 89` puis `88`, et la transition RF est continue.

La valeur envoyée à l'adresse 8 est ensuite :

```text
fine_corrigée = fine_nominale + correction
```

Une correction positive ajoute de l'atténuation. Lors de la calibration au
banc, sa convention est donc :

```text
correction = niveau_mesuré - niveau_demandé
```

Par exemple, une sortie mesurée 0,4 dB trop forte produit une correction de
`+4` dixièmes de dB.

## Coopération des deux atténuations

Pour les niveaux ordinaires et avec une correction nulle, la loi peut se lire
simplement en dB :

```text
niveau demandé = 13,8 - atténuation mécanique - atténuation fine
```

La commande fine diminue de 0,1 dB chaque fois que le niveau demandé augmente
de 0,1 dB. Lorsqu'elle arrive au bord de sa fenêtre, la CPU retire 5 dB
d'atténuation mécanique et ajoute simultanément 4,9 dB d'atténuation fine. La
variation résultante reste donc de 0,1 dB.

### Exemple détaillé autour de -70 dBm

| Niveau demandé | `s` | Mécanique | Fine | Adresse 6 basse | Adresse 8 |
|---:|---:|---:|---:|---:|---:|
| -70,0 dBm | 15 | 75 dB | 8,8 dB | `24` | `A8` |
| -69,9 dBm | 15 | 75 dB | 8,7 dB | `24` | `A7` |
| -68,1 dBm | 15 | 75 dB | 6,9 dB | `24` | `89` |
| -68,0 dBm | 14 | 70 dB | 11,8 dB | `2C` | `D8` |

Les deux valeurs encadrant le changement de relais donnent :

```text
-68,1 dBm : 13,8 - 75 -  6,9 = -68,1
-68,0 dBm : 13,8 - 70 - 11,8 = -68,0
```

Entre ces deux commandes :

```text
variation mécanique : -5,0 dB d'atténuation
variation analogique : +4,9 dB d'atténuation
variation totale      : -0,1 dB d'atténuation
```

La sortie augmente ainsi de 0,1 dB sans discontinuité, malgré la commutation
d'un relais de 5 dB.

## Correction accessible par le bus

Il n'existe pas de commande séparée pour modifier le gain ou l'offset du
détecteur, ni de conversion permettant à la CPU de lire `DET`. Les réglages
`GAIN` et `CENTRAGE` de la carte de commande de régulation sont analogiques.

La correction accessible par le bus agit indirectement : la valeur signée de
la table de calibration est ajoutée à l'atténuation fine de l'adresse 8. La
boucle analogique suit alors une consigne `REF` légèrement déplacée. Une
correction positive augmente l'atténuation et une correction négative augmente
le niveau RF.

Cette correction peut compenser statiquement les variations connues de la
chaîne de niveau selon la fréquence et l'état mécanique. Elle ne constitue pas
une mesure en temps réel du signal disponible sur la prise de sortie.

## Validation par la capture

La capture contient 350 transactions, de `-70,0` à `-35,1 dBm`, soit 1 050
écritures. Chaque transaction suit exactement l'ordre `6, 8, 6`.

Les corrections présentes dans cette capture sont constantes à l'intérieur
de chaque état mécanique :

| `s` | Correction observée |
|---:|---:|
| 15 | 0,0 dB |
| 14 | 0,0 dB |
| 13 | 0,0 dB |
| 12 | -2,7 dB |
| 11 | +0,1 dB |
| 10 | +0,1 dB |
| 9 | 0,0 dB |
| 8 | 0,0 dB |

Avec ces valeurs, le modèle reproduit `1 050 / 1 050` adresses et
`1 050 / 1 050` octets. Ces corrections prouvent la lecture de la table par
l'ancienne CPU, mais ne doivent pas être utilisées comme calibration du nouvel
appareil : elles ne couvrent qu'une fréquence et huit états d'atténuation.

## Calibration Flash + overlay EEPROM

La Flash contient une table de 2 048 corrections `int8_t` en `PROGMEM`. Une
unité vaut 0,1 dB. Son initialisation entièrement à zéro donne le comportement
nominal et occupe réellement 2 Kio dans le binaire grâce à un symbole d'ancrage
de l'éditeur de liens.

### Étape 1 : déterminer les corrections

Le mode série `CAL` et l'assistant Python manuel permettent maintenant de :

1. sélectionner automatiquement un point fréquence/niveau ;
2. afficher la bande RF et le pas mécanique ;
3. recevoir le niveau relevé manuellement sur l'instrument de mesure ;
4. ajouter le résidu `mesuré - demandé` à la correction déjà active ;
5. appliquer immédiatement le résultat et demander une mesure de contrôle ;
6. conserver un journal JSON permettant la reprise et la génération C++.

Deux banques EEPROM compactes de 840 corrections permettent une validation
transactionnelle. `CAL ABORT`, `Adr RTL` ou un redémarrage rejettent la banque
de travail et conservent la dernière calibration validée. La configuration RF
présente au début est restaurée lors de `CAL ABORT` et de `CAL END`.

### Étape 2 : figer la calibration

Le journal peut être fusionné dans `src/CalibrationTable.inc`, puis le firmware
est recompilé et chargé. Le CRC de la nouvelle table invalide automatiquement
l'ancien overlay afin d'empêcher une double application. Un dump brut d'une
2816 originale peut également être contrôlé et converti dans ce fichier.

La procédure détaillée et les commandes sont dans
[`CALIBRATION_AMPLITUDE.md`](CALIBRATION_AMPLITUDE.md).

## Limites restantes

- la table Flash livrée par défaut vaut entièrement zéro ;
- la procédure complète de 840 points reste à exécuter et valider au banc ;
- les avertissements AM sous 1,5 MHz et à partir de +7 dBm restent à confirmer
  au banc.
