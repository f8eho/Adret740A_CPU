# ADRET740A_CPU

Projet PlatformIO pour remplacer la carte CPU d'un generateur RF Adret 740A
avec un Arduino Mega / ATmega2560.

## Etat actuel

L'environnement hardware de test n'est pas encore pret. Le projet compile pour
Arduino Mega / ATmega2560 et fournit pour l'instant une base compilee pour :

- le bus panneau avant sur PORTA;
- le decodage d'adresse panneau avant via `PB2..PB0`;
- l'activation CA2 active bas du 74LS138;
- l'interruption CA1 commune clavier/roue;
- une couche d'etat haut niveau pour les voyants, les flags SN4/SN17,
  les buffers d'affichage, le clavier et la roue codeuse;
- une sequence de debug par balayage des voyants SN2/SN3 via cette couche.

La prochaine etape hardware sera de valider les broches, puis de tester les
LEDs et la couche `FrontPanel` avant de passer aux afficheurs ICM7218A.

## Regles de base

- Pas de `String`, `malloc`, `free`, `new` ou `delete` dans le code projet.
- Les tables volumineuses restent en Flash via `PROGMEM`.
- Les bus 8 bits sont manipules par registres AVR, pas par `digitalWrite`.
- Les modules sont des objets statiques globaux.
- Les broches Serial0 Arduino D0/D1 restent libres pour un dialogue externe.

## Fichiers principaux

- `include/Adret/HardwareConfig.h` centralise le cablage AVR.
- `include/Adret/FrontPanelMap.h` nomme les selections issues du tableur ODS.
- `include/Adret/FrontPanel.h` expose l'API logique du panneau avant.
- `src/FrontPanel.cpp` maintient l'etat des voyants, afficheurs et entrees.
- `src/FrontPanelBus.cpp` pilote PORTA pour le bus panneau avant.
- `src/FrontPanelIrq.cpp` installe l'interruption externe CA1 commune clavier/roue.
- `src/CalibrationEprom.cpp` reserve le dump 2716 en Flash.
- `src/main.cpp` contient le mode de debug courant, d'abord le balayage LED.

## Couche panneau avant

`adret::frontPanel` est l'interface haut niveau a utiliser par la logique
metier. Elle conserve une copie RAM des latches SN2/SN3/SN4/SN17, puis les
ecrit via `FrontPanelBus`.

- Les voyants se pilotent par entite avec `turnOn`, `turnOff`,
  `setIndicator` et `isOn`.
- Les groupes pilotes par decodeurs 74LS138/74LS139 restent exclusifs: allumer
  `RF` remplace donc `FM`, `PM`, `AM` ou `AMP`, sans modifier les autres
  familles de voyants.
- `setFrequencyHz` formate une frequence complete en Hz dans des buffers:
  huit caracteres pour SN10 et deux caracteres pour la partie frequence de
  SN11.
- `setModulationValue` et `setAmplitudeValue` maintiennent des buffers
  numeriques et les unites associees. La sequence exacte d'ecriture ICM7218A
  reste volontairement a valider au banc.
- `pollInputs` consomme les interruptions CA1, empile les touches dans une FIFO
  statique de 8 evenements et cumule les pas de roue codeuse jusqu'a
  `consumeEncoderDelta`.

## Sequence de debug

Le mode courant est choisi par `kDebugPhase` dans `src/main.cpp`.

- `Leds` : balaye les sorties SN2/SN3 via `frontPanel` pour verifier les voyants.
- `Displays` : reserve pour les premiers essais ICM7218A.
- `Inputs` : consomme les interruptions CA1 via `frontPanel`, depile les
  touches et remet le cumul roue a zero.

## Compilation

Depuis VS Code, utiliser PlatformIO: `Project Tasks > megaatmega2560 > Build`.

Depuis un terminal ou Codex, si `pio` n'est pas dans le PATH :

```powershell
& "$env:USERPROFILE\.platformio\penv\Scripts\pio.exe" run
```

## Hypotheses a valider au banc

- Le bus panneau avant 8 bits est sur PORTA / Mega pins 22..29.
- Le controle panneau avant `PB3..PB0` est cable par defaut sur PORTB bits 0..3.
- `PB2..PB0` portent l'adresse decodee; `PB3` sert au mode ICM7218A.
- La ligne CA2 active G2 du 74LS138; elle est cablee par defaut sur PORTB bit 4
  et active bas.
- La ligne CA1 clavier/roue est cablee par defaut sur Mega D2, soit PE4 / INT4
  sur ATmega2560.
- La lecture clavier/roue SN5 est effectuee apres interruption CA1, en activant
  CA2 pendant la selection `PB2..PB0 = 101`.
- Le sens gauche/droite de la roue codeuse depend de D7 et doit encore etre
  confirme au banc.
- La sequence de commande/data des ICM7218A pour SN10/SN11 doit encore etre
  validee avant d'afficher les buffers numeriques sur la facade.

Ces points sont volontairement isoles dans `HardwareConfig.h` pour eviter de
modifier la logique metier apres validation du connecteur CPU.
