# Composition et émission différentielle d'une configuration

## État du raccordement

Le contrôleur d'exploitation compare chaque configuration exécutée à la
dernière configuration effectivement acceptée par le bus. Une demande
identique ne produit aucune écriture. Les changements sont émis par blocs
fonctionnels correspondant aux routines de l'EPROM originale : fréquence,
niveau, modulation et inhibition RF.

La première configuration reste complète. Si le MCP23017 n'est pas présent au
démarrage, le contrôleur conserve son fonctionnement panneau/série. Chaque
nouvelle configuration utile tente alors une unique récupération avant
d'abandonner l'émission.

L'environnement `instrument_bus_bench` reste indépendant : il ne produit que
son motif fini de six écritures et n'envoie pas la configuration fonctionnelle.

## Image des registres

Le contrôleur conserve une image de seize octets. Elle est mise à jour après
chaque écriture I2C réussie, et non seulement à la fin de la séquence. Après
une erreur en cours d'émission, l'image représente donc les mots effectivement
acceptés avant le défaut. La dernière configuration appliquée n'est en revanche
validée qu'après le succès de toute la séquence demandée.

Lorsqu'une émission partie d'un bus sain échoue, le contrôleur appelle une fois
`recover()`, reconstruit une configuration complète depuis l'image partielle,
puis la rejoue immédiatement. Une configuration qui commence avec un bus
indisponible consomme cette tentative avant sa première émission et ne relance
donc pas une seconde fois en cas de nouvel échec. Les compteurs et le dernier
défaut sont consultables avec la requête série `IB?`.

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

## Sélection différentielle

Le masque de blocs est déterminé sans allocation :

- configuration et correction identiques : aucune écriture ;
- modulation seule : bloc modulation de six ou sept mots ;
- niveau ou correction seuls : bloc niveau `6, 8, 6` uniquement ; son dernier
  mot recalcule directement D7 selon le niveau et l'état AM ;
- fréquence, doubleur ou impulsions : configuration fonctionnelle complète ;
- passage à `RF OFF` seul : un mot final à l'adresse 6 ;
- retour RF actif : bloc niveau `6, 8, 6`.

Lorsque la RF reste inhibée mais qu'un autre bloc doit être actualisé, le mot
d'inhibition est toujours réémis en dernier. Les écritures internes d'un bloc
ne sont jamais filtrées mot par mot : le passage transitoire D7 de l'adresse 11
et les répétitions de l'adresse 6 conservent ainsi leur ordre historique.

Sur un 740A sans doubleur, 560 MHz exactement reste sur le chemin direct O1.
Lorsque le cavalier de capacité déclare le doubleur installé, le contrôleur
sélectionne automatiquement le chemin direct sous 560 MHz, X2/O2 de 560 à
moins de 736 MHz, puis X2/O1 de 736 à moins de 1 120 MHz.

## Inhibition RF

La routine EPROM de niveau teste une valeur sentinelle `0xFF`; dans ce cas,
elle conserve D7/D6 de l'adresse 6 et met D5..D0 à zéro :

```text
bus[6] = bus[6] & 0xC0
```

Les cinq captures de démarrage contiennent cette écriture `adresse 6 = 0x00`
avant le réglage normal. `INHIB RF` est donc bien une configuration spéciale
de l'atténuateur, et non une ligne de sortie supplémentaire de la nouvelle
CPU. Lors du retour RF actif, le contrôleur réémet le bloc niveau, ce qui
restaure les relais, l'atténuation fine et les bits de contrôle de l'adresse 6.

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
- les masques et nombres d'écritures des mises à jour identique, modulation,
  niveau, inhibition, réactivation RF et fréquence ;
- la reconstruction complète depuis une image de registres partiellement
  mise à jour après erreur ;
- `RF OFF` et son dernier mot d'adresse 6 ;
- les champs FM externe et PM externe ;
- les limites 100 kHz et 560 MHz du modèle sans doubleur ;
- les seuils X2 560/736 MHz et la limite exclusive de 1 120 MHz ;
- les diviseurs pairs et impairs nécessaires au pas de sortie de 10 Hz.

Le vecteur de référence à 240 MHz, -35,1 dBm, AM 60 % à 1 kHz commence par :

```text
12:61 15:1F 05:05 11:B9 04:AA 13:2A
00:00 01:00 02:00 03:9E 06:2D 08:A9 06:2D
```

La suite modulation est :

```text
06:2D 09:00 10:F6 12:61 13:2A 11:39 06:2D
```

La capture de l'ancienne CPU
`Dec_Mollette -70db à -35db pas de 0,1db.csv` contient 350 réglages et
exactement 350 triplets `6, 8, 6`, sans aucune écriture de modulation, y
compris lors des changements de relais de 5 dB. Ce comportement est repris par
les mises à jour différentielles de niveau.

## Limites conservées

- le code exact de 200 kHz FM reste inconnu ; 199,9 kHz est la plus grande
  valeur effectivement encodée et testée par le modèle. Le contrôleur et la
  liaison série refusent donc provisoirement 200 kHz avec `E-71` ;
- les corrections de calibration sont nulles ;
- le chemin doubleur est validé par vecteurs et désassemblage, mais pas encore
  sur un appareil équipé ;
- l'option impulsions reste déclarée séparément.
