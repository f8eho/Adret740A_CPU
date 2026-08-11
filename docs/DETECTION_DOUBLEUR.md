# Détection de l'option doubleur par la CPU d'origine

## Conclusion

La carte CPU d'origine ne détecte pas le doubleur en lisant le bus
instruments. Ce bus est unidirectionnel : les optocoupleurs transmettent les
adresses et les données de la CPU vers les cartes de l'instrument, sans voie
de retour vers le 6802.

L'EPROM décide néanmoins si la plage doit s'arrêter à 560 MHz ou être étendue
à 1 120 MHz. Cette décision repose sur un indicateur local de la CPU, conservé
dans le bit D7 de l'octet RAM `$800C`. Il faut donc parler d'une déclaration
ou d'un état de présence côté CPU, et non d'une détection du module à travers
le bus instruments.

## Construction de l'octet de présence `$800C`

La routine `$C2FC` de la seconde EPROM construit l'octet `$800C` :

```text
C2FC  LDAA  $4004       lecture du registre A du PIA 6821
C2FF  EORA  #$3F        D7 et D6 restent inchangés
C307  TAB
C308  ANDB  #$C0        conserve D7 et D6
C30A  STAB  $800C
...
C324  LDAA  $2002       lecture de l'interface IEEE-488
C327  ANDA  #$30        conserve D5 et D4
C329  LDAB  $800C
C32C  ANDB  #$C0
C32E  ABA               fusionne les quatre indicateurs
C32F  STAA  $800C
```

La provenance des quatre bits est donc :

| Bit de `$800C` | Source lue par l'EPROM | Utilisation établie |
| ---: | --- | --- |
| D7 | `$4004`, registre A du PIA 6821 | extension doubleur jusqu'à 1 120 MHz |
| D6 | `$4004`, registre A du PIA 6821 | extension hyperfréquence supérieure |
| D5 | `$2002`, interface IEEE-488 | fonction exacte non établie |
| D4 | `$2002`, interface IEEE-488 | présence de l'option modulation d'impulsions |

`$4004` est un miroir de l'adresse de base du port A du 6821. Selon l'état du
bit 2 de son registre de contrôle `CRA`, cette adresse donne accès au registre
de données `ORA` ou au registre de direction `DDRA`. Le désassemblage établit
donc l'origine logique de D7, mais le mécanisme électrique ou la convention de
configuration qui impose sa valeur reste à confirmer sur la carte CPU
d'origine.

## Choix de la limite de fréquence

La routine `$CC58` contrôle la fréquence demandée et choisit sa table de
limite à partir de `$800C` :

```text
CC6A  LDAB  $800C
CC6D  BMI   ...         D7 = 1 : limite du doubleur
CC72  ASLB
CC73  BMI   ...         D6 = 1 : autre extension supérieure
                        sinon : limite standard de 560 MHz
```

Le comportement correspondant est :

| État | Plage autorisée par la CPU |
| --- | --- |
| `$800C.D7 = 0` et `$800C.D6 = 0` | 100 kHz à 560 MHz |
| `$800C.D7 = 1` | extension par le doubleur jusqu'à 1 120 MHz |
| `$800C.D6 = 1` | extension hyperfréquence distincte, non documentée dans le châssis étudié |

Lorsque D7 est actif, le programme ne se contente pas d'autoriser
l'affichage au-delà de 560 MHz. Il produit aussi les commandes du chemin
doubleur : adresse 5 D4 pour `X2`, adresse 4 D7 pour la poursuite et les bits
de gamme associés aux adresses 12 et 15.

## Pourquoi ce n'est pas une détection par le bus instruments

Les schémas du doubleur et du châssis ne montrent aucune ligne de retour du
module vers la CPU. Les écritures aux adresses instruments `$6000..$600F` ne
sont jamais relues par le logiciel. La présence matérielle réelle du doubleur
ne peut donc pas être vérifiée par ce chemin.

Le bit D7 de `$800C` représente seulement ce que la CPU croit être sa
configuration. Un appareil peut par conséquent accepter une fréquence
supérieure à 560 MHz et envoyer les mots `X2` alors qu'aucun doubleur n'est
installé. Dans ce cas, la fréquence RF obtenue ne peut pas suivre l'affichage.

## Interprétation d'une fausse présence

Si un appareil jusque-là limité à 560 MHz autorise soudainement 1 120 MHz, le
fait directement observable dans le logiciel est le passage de `$800C.D7` à
1. Les causes sont à chercher sur la carte CPU et son interface panneau, par
exemple :

- niveau erroné sur `PA7` lorsque le 6821 lit son port A ;
- mauvais état de `CRA.D2`, provoquant une lecture de `ORA` à la place de
  `DDRA`, ou inversement ;
- défaut du PIA 6821 ;
- bit D7 de la RAM contenant `$800C` défectueux ;
- piste coupée, fuite conductrice ou corrosion autour de l'ancienne batterie ;
- reset ou alimentation incorrects laissant un registre d'interface dans un
  état inattendu.

La RAM de la CPU est sauvegardée par batterie, mais `$800C` est réécrit par la
routine `$C2FC`. Une batterie vide ne suffit donc pas, à elle seule, à déclarer
le doubleur présent. Les dégâts électriques causés par une fuite de batterie
restent en revanche une cause plausible.

## CPU de remplacement : déclaration par cavalier

Le firmware utilise une image unique pour les deux configurations. Arduino
Mega D4, soit `PG5` sur l'ATmega2560, est configurée en entrée avec pull-up et
échantillonnée une seule fois, avant le chargement des réglages :

| Cavalier D4 | Capacité figée jusqu'au prochain redémarrage |
| --- | --- |
| ouvert | doubleur absent, maximum 560 000 000 Hz |
| relié à `GND_CPU` | doubleur installé, maximum 1 119 999 990 Hz |

Il ne faut jamais utiliser `GND_INST`, masse du domaine isolé du bus
instruments. Le cavalier est une déclaration matérielle locale et fiable du
profil choisi, mais il ne prouve pas électriquement que le module RF est
effectivement enfiché. Aucun changement en fonctionnement n'est pris en
compte : il faut redémarrer.

La capacité immuable `InstrumentCapabilities::doublerInstalled` est transmise
au contrôleur, à la liaison série et au stockage de calibration. En profil X2,
le chemin direct reste sélectionné sous 560 MHz, puis le firmware utilise
automatiquement X2/O2 de 560 à moins de 736 MHz et X2/O1 de 736 à moins de
1 120 MHz. La résolution reste 10 Hz sur toute la plage.

Une configuration active restaurée au-dessus de 560 MHz sans cavalier est
ramenée à 560 MHz avec RF OFF. Les mémoires haute fréquence sont conservées en
EEPROM : leur rappel retourne `E-21` sans modifier la sortie et une séquence
s'arrête sur la mémoire incompatible.

Cette logique est validée par tests hôte seulement. La présence du module, les
seuils RF, le niveau et les transitoires devront être contrôlés sur un châssis
réellement équipé.

## Références du projet

- [`eeprom_740A/740A-2.asm`](eeprom_740A/740A-2.asm), routines `$C2FC` et
  `$CC58` ;
- [`BUS_INSTRUMENTS_GRANDS_PAS.md`](BUS_INSTRUMENTS_GRANDS_PAS.md), commandes
  et plages du doubleur ;
- [`BUS_INSTRUMENTS_PROGRAMMATION.md`](BUS_INSTRUMENTS_PROGRAMMATION.md),
  composition des transactions avec ou sans doubleur ;
- [`BUS_INSTRUMENTS_IMPULSIONS.md`](BUS_INSTRUMENTS_IMPULSIONS.md), utilisation
  de `$800C.D4` pour l'autre option détectée par la CPU.
