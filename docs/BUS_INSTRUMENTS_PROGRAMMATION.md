# Composition et émission d'une configuration complète

## État du raccordement

Le contrôleur d'exploitation produit maintenant les mots du bus instruments
à chaque configuration exécutée, mouvement de molette immédiatement actif ou
basculement de `INHIB RF`. Si le MCP23017 n'est pas présent au démarrage, le
contrôleur conserve son fonctionnement panneau/série. Chaque nouvelle
configuration tente alors une unique récupération avant d'abandonner
l'émission.

L'environnement `instrument_bus_bench` reste indépendant : il ne produit que
son motif fini de six écritures et n'envoie pas la configuration fonctionnelle.

## Image des registres

Le contrôleur conserve une image de seize octets. Elle est mise à jour après
chaque écriture I2C réussie, et non seulement à la fin de la séquence. Après
une erreur en cours d'émission, l'image représente donc les mots effectivement
acceptés avant le défaut. La configuration complète suivante peut repartir de
cet état sans supposer que la transaction précédente était atomique.

Lorsqu'une émission partie d'un bus sain échoue, le contrôleur appelle une fois
`recover()` puis rejoue immédiatement la transaction entière. Une configuration
qui commence avec un bus indisponible consomme cette tentative avant sa première
émission et ne relance donc pas une seconde fois en cas de nouvel échec. Les
compteurs et le dernier défaut sont consultables avec la requête série `IB?`.

L'image initiale vaut zéro, sauf l'adresse 15 initialisée à `0x1F`. Ses cinq
bits bas sont préservés par l'EPROM originale et cette valeur reproduit les
captures de démarrage.

## Séquence composée

Une configuration complète est construite sans allocation :

```text
fréquence : 12, 15, 5, 11|D7, 4, 13, 0, 1, 2, 3
niveau    : 6, 8, 6
modulation: [6 si AM], 9, 10, 12, 13, 11, 6
RF OFF    : [6 final]
```

La taille maximale est donc 21 écritures pour AM avec inhibition RF. Les
champs partagés des adresses 5, 6, 12, 13 et 15 sont calculés avant l'émission
afin que chaque module voie un état cohérent.

Sur un 740A sans doubleur, 560 MHz exactement reste sur le chemin direct O1.
Si le doubleur optionnel est explicitement activé dans la configuration du
compositeur, son plan commence lui aussi à 560 MHz. Le contrôleur actuel
déclare les options doubleur et impulsions absentes.

## Inhibition RF

La routine EPROM de niveau teste une valeur sentinelle `0xFF`; dans ce cas,
elle conserve D7/D6 de l'adresse 6 et met D5..D0 à zéro :

```text
bus[6] = bus[6] & 0xC0
```

Les cinq captures de démarrage contiennent cette écriture `adresse 6 = 0x00`
avant le réglage normal. `INHIB RF` est donc bien une configuration spéciale
de l'atténuateur, et non une ligne de sortie supplémentaire de la nouvelle
CPU. Lors du retour RF actif, le contrôleur réémet la configuration complète,
ce qui restaure les relais et l'atténuation fine.

## Calibration

Le compositeur accepte une correction signée en dixièmes de dB. Le contrôleur
sélectionne maintenant l'index original selon la fréquence et le palier
mécanique, puis additionne la table Flash et l'overlay EEPROM transactionnel.
La table Flash livrée par défaut reste nulle. Voir
[`CALIBRATION_AMPLITUDE.md`](CALIBRATION_AMPLITUDE.md).

## Validation sans matériel

`test/run_host_tests.ps1` compile les encodeurs avec un substitut hôte minimal
de `PROGMEM` et contrôle :

- la séquence AM complète à 240 MHz ;
- `RF OFF` et son dernier mot d'adresse 6 ;
- les champs FM externe et PM externe ;
- les limites 100 kHz et 560 MHz du modèle sans doubleur.

Le vecteur de référence à 240 MHz, -35,1 dBm, AM 60 % à 1 kHz commence par :

```text
12:61 15:1F 05:05 11:B9 04:AA 13:2A
00:00 01:00 02:00 03:9E 06:2D 08:A9 06:2D
```

La suite modulation est :

```text
06:2D 09:00 10:F6 12:61 13:2A 11:39 06:2D
```

## Limites conservées

- le code exact de 200 kHz FM reste inconnu ; 199,9 kHz est la plus grande
  valeur effectivement encodée et testée par le modèle. Le contrôleur et la
  liaison série refusent donc provisoirement 200 kHz avec `E-71` ;
- les diviseurs impairs de la carte « 20000 » restent refusés faute de trace ;
- les corrections de calibration sont nulles ;
- les options doubleur et impulsions sont encodables mais désactivées dans le
  contrôleur de cet appareil.
