Limites :
 - Fréquence : de 100khz à 560Mhz par pas de 10hz minimum
 - Amplitude : de +13dBm à -129.9 dBm
 - Résolution de l'atténuateur : 10dB, 1dB, 0.1dB
 - Modulation d'amplitude : de 0 à 99.9%
 - Modulation de phase : de 0 à 19.99 rd, par pas de 0.01rd
 - Modulation de fréquence : de 0 à 20khz=par pas de 10hz, de 20khz à 200khz=par pas de 100hz


Au démarrage, la configuration est chargée depuis l'eeprom de l'arduino.
La pin 'PA' (présence alim) est présente sur le bus instrument, elle sert notamment à indiquer à la CPU de sauvegarder les paramètres lors de la coupure de courant.
Appui sur AMPL : 
  - allumer la led AMPL
  - les entrées numériques clavier concernent l'amplitude, validation de la valeur par exec
  - si appui sur VALID, alors la molette incrémente/décrémente l'amplitude

Bouton FREQ : 
  - allumer la led FREQ
  - les entrées numériques clavier concernent la fréquence, validation de la valeur par exec
  - si appui sur VALID, alors la molette incrémente/décrémente l'amplitude
  - chaque modification de la valeur déclenche la transmission des données de changement de la fréquence sur le bus instrument.
  
Boutons : FM AM PM : mutuellements exclusifs.
 - L'appui sur l'un des boutons bascule la led correspondante et invalide les deux autres, les voyants %, Mhz et rd sont allumés selon le mode sélectionné. Si la molette était sélectionnée pour un de ces trois modes, elle le reste, mais l'incrément et les limites changent.

Roue codeuse :
  - Un appui sur x10 allume la led x10, change le digit concerné en le faisant clignoter 3 fois et l'incrément est multiplié par 10 
  - Un appui sur :10 allume la led :10, change le digit concerné en le faisant clignoter 3 fois et l'incrément est divisé par 10 
  - Les valeurs mini/maxi et l'incrément mini/maxi sont selon le mode sélectionné (fréquence, amplitude ou modulation)
  - la touche valid inhib la roue codeuse.

Bouton Inhib RF :
  - Un appui bascule l'état de la led RF_OFF et coupe la RF et envoie les commandes nécessaires sur le bus instrument.

Boutons 400Hz, 1Khz, Ext  : mutuellement exclusifs, l'appui sur l'un désactive les autres, la touche 'CW' inhibe toute modulation indépendamment du réglage de celle-ci.
Bouton 400Hz :
  - Un appui bascule l'état de la led 400Hz et envoie les commandes nécessaires sur le bus instrument (générateur modulation 400hz).
Bouton 1kHz :
  - Un appui bascule l'état de la led 1kHz et envoie les commandes nécessaires sur le bus instrument (générateur modulation 1khz).
Bouton Ext :
  - Un appui bascule l'état de la led Ext et envoie les commandes nécessaires sur le bus instrument (générateur modulation 1khz).
