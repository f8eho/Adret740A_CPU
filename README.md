# ADRET740A_CPU

Projet PlatformIO pour remplacer la carte CPU d'un generateur RF Adret 740A
avec un Arduino Mega / ATmega2560.

## Etat actuel

L'environnement hardware de test n'est pas encore pret. Le projet compile pour
Arduino Mega / ATmega2560 et fournit pour l'instant une base bas niveau pour :

- le bus panneau avant sur PORTA;
- le decodage d'adresse panneau avant via `PB2..PB0`;
- l'activation CA2 active bas du 74LS138;
- l'interruption CA1 commune clavier/roue;
- une premiere sequence de debug par balayage des voyants SN2/SN3.

La prochaine etape hardware sera de valider les broches, puis de tester les
LEDs avant de passer aux afficheurs ICM7218A.

## Regles de base

- Pas de `String`, `malloc`, `free`, `new` ou `delete` dans le code projet.
- Les tables volumineuses restent en Flash via `PROGMEM`.
- Les bus 8 bits sont manipules par registres AVR, pas par `digitalWrite`.
- Les modules sont des objets statiques globaux.
- Les broches Serial0 Arduino D0/D1 restent libres pour un dialogue externe.

## Fichiers principaux

- `include/Adret/HardwareConfig.h` centralise le cablage AVR.
- `include/Adret/FrontPanelMap.h` nomme les selections issues du tableur ODS.
- `src/FrontPanelBus.cpp` pilote PORTA pour le bus panneau avant.
- `src/FrontPanelIrq.cpp` installe l'interruption externe CA1 commune clavier/roue.
- `src/CalibrationEprom.cpp` reserve le dump 2716 en Flash.
- `src/main.cpp` contient le mode de debug courant, d'abord le balayage LED.

## Sequence de debug

Le mode courant est choisi par `kDebugPhase` dans `src/main.cpp`.

- `Leds` : balaye les sorties SN2/SN3 pour verifier les voyants.
- `Displays` : reserve pour les premiers essais ICM7218A.
- `Inputs` : consomme les interruptions CA1 puis lit SN5.

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

Ces points sont volontairement isoles dans `HardwareConfig.h` pour eviter de
modifier la logique metier apres validation du connecteur CPU.
