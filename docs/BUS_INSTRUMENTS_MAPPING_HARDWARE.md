# Mapping matériel du bus instruments

## Objet et statut

Ce document décrit le câblage du premier prototype entre :

```text
Arduino Mega 2560 -> ISO1540 -> MCP23017 -> connecteur B1 -> bus instruments
```

Il complète [`BUS_INSTRUMENTS_MCP23017.md`](BUS_INSTRUMENTS_MCP23017.md), qui
décrit le protocole, l'initialisation et les temporisations. Le mapping logique
est implémenté dans `include/Adret/HardwareConfig.h` et `src/InstrumentBus.cpp`.

Les numéros B1 proviennent des schémas CPU et châssis. Le brochage MCP23017
ci-dessous s'applique aux boîtiers 28 broches SPDIP, SOIC et SSOP, vus de
dessus. Le QFN utilise d'autres numéros de broches.

## Vue d'ensemble

```text
Domaine CPU / Mega                         Domaine instruments / fond de panier

Mega D20 SDA ---- ISO1540 SDA1 | SDA2 ---- MCP23017 SDA
Mega D21 SCL ---- ISO1540 SCL1 | SCL2 ---- MCP23017 SCL
Mega +5 V  ----- ISO1540 VCC1  | VCC2 ---- +5 V instruments
Mega GND   ----- ISO1540 GND1  | GND2 ---- 0 V instruments
                                isolation

MCP GPA0..7 -------------------------------- B1 D0..D7
MCP GPB0..3 -------------------------------- B1 A0..A3
MCP GPB4 ----------------------------------- B1 Chargt
```

Pour conserver une isolation galvanique, il ne doit exister aucune liaison
directe entre `GND1` et `GND2`. Un analyseur logique, un oscilloscope relié à
la terre ou l'USB du Mega peut court-circuiter involontairement cette
isolation.

## Domaines d'alimentation

| Domaine | Alimentation | Masse de référence | Circuits concernés |
| --- | --- | --- | --- |
| CPU | `+5V_MEGA` | `GND_MEGA` | Mega et côté 1 de l'ISO1540 |
| Instruments | `+5V_INST` | `0V_INST` | côté 2 de l'ISO1540, MCP23017 et bus B1 |

Le schéma CPU nomme `+5VB1` l'alimentation instruments présente sur B1-13. Le
schéma châssis identifie B1-5 comme `0V dig`. Ces deux points sont les candidats
pour `+5V_INST` et `0V_INST`, à confirmer au multimètre sur le châssis avant
raccordement. Le schéma châssis montre également le +5 V sur B1-14 ; ne pas
relier simultanément B1-13 et B1-14 sans avoir confirmé leur continuité et leur
fonction sur l'appareil.

L'ISO1540 isole les signaux, pas l'alimentation. Si `+5VB1` n'est pas utilisé,
une alimentation ou un convertisseur DC/DC isolé doit fournir `+5V_INST`, avec
son retour relié à `0V_INST` pour référencer correctement les sorties du
MCP23017 au fond de panier.

### Vérification indispensable de l'isolation globale

L'isolation ne dépend pas seulement de l'ISO1540. Il faut rechercher toutes les
autres liaisons possibles entre `GND_MEGA` et `0V_INST` : alimentation du Mega,
liaison au panneau avant, Serial0, USB, analyseur logique et oscilloscope. Si le
Mega utilise déjà B1-5 comme masse, les deux domaines sont communs et
l'ISO1540 n'assure plus d'isolation galvanique, même si la communication I2C
reste possible. Dans ce cas, il faut soit accepter explicitement la masse
commune, soit revoir l'alimentation et les autres interfaces pour rétablir deux
domaines réellement isolés.

## Arduino Mega 2560 vers ISO1540

| Fonction | Broche Arduino | Port ATmega2560 | Broche ISO1540 | Domaine |
| --- | ---: | --- | ---: | --- |
| SDA | D20 | PD1 / SDA | 2, `SDA1` | CPU |
| SCL | D21 | PD0 / SCL | 3, `SCL1` | CPU |
| alimentation | `5V` | — | 1, `VCC1` | CPU |
| masse | `GND` | — | 4, `GND1` | CPU |

Les broches Arduino D0 et D1 restent réservées à `Serial0` et ne participent
pas au bus instruments. Le firmware utilise l'I2C matériel à 400 kHz et
l'adresse MCP23017 `0x20`.

## Brochage complet de l'ISO1540

Boîtier SOIC-8, vue de dessus :

| Broche | Nom | Raccordement retenu |
| ---: | --- | --- |
| 1 | `VCC1` | `+5V_MEGA` |
| 2 | `SDA1` | Mega D20 / SDA |
| 3 | `SCL1` | Mega D21 / SCL |
| 4 | `GND1` | `GND_MEGA` |
| 5 | `GND2` | `0V_INST` |
| 6 | `SCL2` | MCP23017 broche 12 / SCL |
| 7 | `SDA2` | MCP23017 broche 13 / SDA |
| 8 | `VCC2` | `+5V_INST` |

Le côté 1 est placé côté Mega, où le nœud I2C doit rester de faible capacité.
Le côté 2 accepte le nœud MCP23017. SDA et SCL exigent chacune une résistance
de tirage vers leur propre alimentation, donc quatre résistances au total :

```text
SDA1 -> RPU1 -> VCC1             SDA2 -> RPU2 -> VCC2
SCL1 -> RPU1 -> VCC1             SCL2 -> RPU2 -> VCC2
```

Une plage provisoire de 2,2 à 4,7 kΩ peut servir au premier montage à 5 V ; la
valeur finale doit être validée avec les capacités réelles et les temps de
montée à 400 kHz. Les résistances de tirage déjà présentes sur un module ou le
Mega doivent être comptées en parallèle.

Placer un condensateur céramique de 100 nF entre VCC1/GND1 et un autre entre
VCC2/GND2, au plus près de l'ISO1540. Texas Instruments recommande une distance
maximale de 2 mm entre ces condensateurs et les broches d'alimentation.

## Raccordements fixes du MCP23017

Boîtiers 28 broches SPDIP, SOIC ou SSOP, vue de dessus :

| Broche | Nom | Raccordement | Remarque |
| ---: | --- | --- | --- |
| 9 | `VDD` | `+5V_INST` | découplage 100 nF vers VSS |
| 10 | `VSS` | `0V_INST` | référence du bus instruments |
| 11 | `NC` | non connectée | ne pas utiliser |
| 12 | `SCL` | ISO1540 broche 6 / SCL2 | I2C 400 kHz |
| 13 | `SDA` | ISO1540 broche 7 / SDA2 | I2C bidirectionnel |
| 14 | `NC` | non connectée | ne pas utiliser |
| 15 | `A0` | `0V_INST` | adresse I2C `0x20` |
| 16 | `A1` | `0V_INST` | adresse I2C `0x20` |
| 17 | `A2` | `0V_INST` | adresse I2C `0x20` |
| 18 | `RESET` | tirage vers `+5V_INST` | actif bas, prévoir un point de test |
| 19 | `INTB` | non connectée | inutilisée par le firmware |
| 20 | `INTA` | non connectée | inutilisée par le firmware |

Les broches A0, A1, A2 et RESET doivent être polarisées extérieurement ; elles
ne doivent pas rester flottantes. Un tirage de 10 kΩ sur RESET convient comme
point de départ. Placer le 100 nF de découplage du MCP23017 au plus près des
broches 9 et 10.

## MCP23017 vers connecteur B1

Le mapping ne comporte aucune inversion logicielle : `GPA0` transporte D0,
`GPA1` transporte D1, etc. Les noms D0 à D7 désignent ici le bus instruments,
pas les broches Arduino D0 à D7.

| Signal instruments | Port MCP23017 | Broche MCP | Connecteur CPU | Direction | État au chargement |
| --- | --- | ---: | ---: | --- | --- |
| D0 | GPA0 | 21 | B1-19 | sortie | donnée bit 0 |
| D1 | GPA1 | 22 | B1-20 | sortie | donnée bit 1 |
| D2 | GPA2 | 23 | B1-21 | sortie | donnée bit 2 |
| D3 | GPA3 | 24 | B1-22 | sortie | donnée bit 3 |
| D4 | GPA4 | 25 | B1-23 | sortie | donnée bit 4 |
| D5 | GPA5 | 26 | B1-24 | sortie | donnée bit 5 |
| D6 | GPA6 | 27 | B1-25 | sortie | donnée bit 6 |
| D7 | GPA7 | 28 | B1-26 | sortie | donnée bit 7 |
| A0 | GPB0 | 1 | B1-27 | sortie | adresse bit 0 |
| A1 | GPB1 | 2 | B1-28 | sortie | adresse bit 1 |
| A2 | GPB2 | 3 | B1-29 | sortie | adresse bit 2 |
| A3 | GPB3 | 4 | B1-30 | sortie | adresse bit 3 |
| `Chargt` | GPB4 | 5 | B1-31 | sortie | inactif haut, front descendant actif |

Les broches restantes sont :

| Broche MCP | Nom | Configuration du firmware | Raccordement |
| ---: | --- | --- | --- |
| 6 | GPB5 | entrée réservée | non connectée |
| 7 | GPB6 | entrée réservée | non connectée |
| 8 | GPB7 | réservée | non connectée |

## Résumé du connecteur B1

Extrait du schéma de la carte CPU :

```text
B1-19 D0    B1-20 D1    B1-21 D2    B1-22 D3
B1-23 D4    B1-24 D5    B1-25 D6    B1-26 D7
B1-27 A0    B1-28 A1    B1-29 A2    B1-30 A3
B1-31 Chargt, actif bas
```

Les contacts pairs et impairs alternent physiquement sur le connecteur. Il ne
faut donc pas câbler la séquence comme une rangée linéaire sans vérifier
l'orientation, le repère de B1-1 et la vue utilisée par le schéma.

## État de démarrage

Au reset, les GPIO du MCP23017 sont initialement en entrée. Le montage doit
maintenir `Chargt` inactif haut pendant cette période. Prévoir un tirage externe
de 4,7 à 10 kΩ entre B1-31/GPB4 et `+5V_INST`, sauf si un tirage équivalent du
fond de panier est déjà confirmé.

Le firmware précharge ensuite :

```text
OLATA = 0x00        D0..D7 = 0
OLATB = 0x10        A3..A0 = 0, Chargt = 1
```

Il passe GPA0..7 et GPB0..4 en sortie seulement après ces préchargements. GPB5
à GPB7 restent réservées. Une écriture place d'abord données et adresse, puis
produit une unique transition haut-bas-haut sur `Chargt`.

## Points de test recommandés

Prévoir au minimum des points accessibles pour :

- SDA1, SCL1, GND1 et VCC1 ;
- SDA2, SCL2, GND2 et VCC2 ;
- RESET du MCP23017 ;
- D0, D7, A0, A3 et `Chargt` ;
- idéalement les treize signaux D0..D7, A0..A3 et `Chargt` sur un connecteur
  d'analyse logique.

Avant de connecter B1, contrôler séparément :

1. les deux alimentations et, si l'isolation galvanique est retenue, l'absence
   de continuité entre GND1 et GND2 ;
2. l'adresse I2C `0x20` ;
3. l'absence de front descendant parasite sur `Chargt` au démarrage et au
   reset ;
4. le motif de banc décrit dans `BUS_INSTRUMENTS_MCP23017.md` ;
5. l'absence de conflit avec l'ancienne carte CPU ou tout autre pilote encore
   raccordé au fond de panier.

## Sources

- schéma ADRET `Page 30a _ CPU_schema.pdf`, connecteur B1 et bloc
  `BUS INSTRUMENT` ;
- schéma ADRET `Page 23a _ chassis_schema.pdf`, répartition du fond de panier ;
- Texas Instruments, [ISO1540/ISO1541, SLLSEB6F](https://www.ti.com/lit/ds/symlink/iso1540.pdf) ;
- Microchip, [MCP23017/MCP23S17, DS20001952D](https://ww1.microchip.com/downloads/aemDocuments/documents/APID/ProductDocuments/DataSheets/MCP23017-Data-Sheet-DS20001952.pdf).
