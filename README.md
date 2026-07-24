# ADRET740A_CPU

Projet PlatformIO pour remplacer la carte CPU d'un generateur RF Adret 740A
avec un Arduino Mega / ATmega2560.

## Etat actuel

Le panneau avant est maintenant raccordé à une Arduino Mega et les fonctions
principales ont été validées au banc :

- le bus panneau avant sur PORTA;
- le decodage d'adresse panneau avant via `PB2..PB0`;
- l'activation CA2 active bas du 74LS138;
- l'interruption CA1 commune clavier/roue;
- une couche d'etat haut niveau pour les voyants, les flags SN4/SN17,
  les buffers d'affichage, le clavier et la roue codeuse;
- la logique fonctionnelle du panneau, les mémoires et les séquences ;
- un protocole de télécommande ASCII sur Serial0.

Le firmware courant pilote le panneau avant et accepte à 115200 bauds les
commandes historiques du bus GPIB transposées sur Serial0.

## Regles de base

- Pas de `String`, `malloc`, `free`, `new` ou `delete` dans le code projet.
- Les tables volumineuses restent en Flash via `PROGMEM`.
- Les bus 8 bits sont manipules par registres AVR, pas par `digitalWrite`.
- Les modules sont des objets statiques globaux.
- Les broches Serial0 Arduino D0/D1 sont réservées à la télécommande externe.

## Fichiers principaux

- `docs/retroanalyse_panneau_avant.md` rassemble le fonctionnement électrique,
  les protocoles, les résultats du banc et les points restant à valider.
- `include/Adret/HardwareConfig.h` centralise le cablage AVR.
- `include/Adret/FrontPanelMap.h` nomme les selections issues du tableur ODS.
- `include/Adret/FrontPanel.h` expose l'API logique du panneau avant.
- `src/FrontPanel.cpp` maintient l'etat des voyants, afficheurs et entrees.
- `src/FrontPanelBus.cpp` pilote PORTA pour le bus panneau avant.
- `src/FrontPanelIrq.cpp` installe l'interruption externe CA1 commune clavier/roue.
- `src/OperatingController.cpp` contient les valeurs, limites, pas et actions
  fonctionnelles du panneau.
- `src/SettingsStore.cpp` conserve la configuration dans deux slots EEPROM
  versionnés avec CRC.
- `src/PowerFailMonitor.cpp` traite l'interruption PA active sur D3 / INT5.
- `src/CalibrationEprom.cpp` reserve le dump 2716 en Flash.
- `src/main.cpp` orchestre le panneau, la télécommande et la persistance.

## Couche panneau avant

`adret::frontPanel` est l'interface haut niveau a utiliser par la logique
metier. Elle conserve une copie RAM des latches SN2/SN3/SN4/SN17, puis les
ecrit via `FrontPanelBus`.

- Les voyants se pilotent par entite avec `turnOn`, `turnOff`,
  `setIndicator` et `isOn`.
- Les groupes pilotes par decodeurs 74LS138/74LS139 restent exclusifs: allumer
  `RF` remplace donc `FM`, `PM`, `AM` ou `AMP`, sans modifier les autres
  familles de voyants.
- `setFrequencyHz` formate dix digits : huit sont envoyés à SN10/Y7 et les deux
  derniers à SN11/Y6.
- `setModulationValue` et `setAmplitudeValue` maintiennent trois digits
  numériques chacun dans SN11. Les premiers caractères restent sur SN4.
- `refreshDisplays` envoie aux ICM7218A une commande Code B puis huit digits.
  Le bit de point décimal est actif bas.
- `pollInputs` consomme les interruptions CA1, empile les touches dans une FIFO
  statique de 8 evenements et cumule les pas de roue codeuse jusqu'a
  `consumeEncoderDelta`.

## Logique fonctionnelle courante

- RF, AMPL, FM, PM et AM sélectionnent la valeur réglée par la roue codeuse.
- VALID MAN affecte la sélection affichée à la roue ; MUL10 et DIV10 changent
  le pas de la dernière cible validée et font clignoter le digit correspondant.
- CW, 400 Hz, 1 kHz, EXT et RF OFF mettent à jour les voyants et l'état de
  sortie préparé ou actif.
- En mode distant, le panneau est inhibé sauf la touche `Adr RTL` lorsque le
  retour local n'est pas verrouillé.
- Une EEPROM à deux slots et CRC restaure les réglages, tout en forçant RF OFF
  au démarrage. L'entrée PA sur D3 / INT5 déclenche la sauvegarde sur son front
  descendant ; elle est configurée sans pull-up interne.

## Compilation

Depuis VS Code, utiliser PlatformIO: `Project Tasks > megaatmega2560 > Build`.

Depuis un terminal ou Codex, si `pio` n'est pas dans le PATH :

```powershell
& "$env:USERPROFILE\.platformio\penv\Scripts\pio.exe" run
```

Les tests hôte du parseur et du cadrage série se lancent avec :

```powershell
& ".\scripts\test_serial_protocol.ps1"
```

## Résultats et points restant à valider

- Le bus utilise PORTA / Mega 22..29 avec les paires croisées 22/23, 24/25,
  26/27 et 28/29 sur le faisceau validé.
- Le controle panneau avant `PB3..PB0` est cable par defaut sur PORTB bits 0..3.
- `PB2..PB0` portent l'adresse decodee; `PB3` sert au mode ICM7218A.
- La ligne CA2 active G2 du 74LS138; elle est cablee par defaut sur PORTB bit 4
  et active bas.
- La ligne CA1 clavier/roue est cablee par defaut sur Mega D2, soit PE4 / INT4
  sur ATmega2560.
- La lecture SN5 maintient CA2/Y5 actif 10 µs. Quatre acquittements sont
  envoyés au démarrage avant l'armement d'INT4.
- SN11 est sélectionné par Y6/`110`; SN10 par Y7/`111`.
- Les voyants, chiffres Code B et touches ont été observés au banc.
- La stabilité CA1 au démarrage, le sens de la roue et le placement individuel
  des points décimaux restent à valider.

Ces points sont volontairement isoles dans `HardwareConfig.h` pour eviter de
modifier la logique metier apres validation du connecteur CPU.
