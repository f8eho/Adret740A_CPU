# Calibration grossière du niveau RF

## Objet et limites

Cette procédure permet de remettre en cohérence la boucle analogique de niveau
du 740A avec un équipement d'atelier courant. Elle vise notamment le réglage
des potentiomètres `GAIN` et `CENTRAGE` de la carte de commande de régulation.

Il ne s'agit pas d'une calibration absolue complète. L'oscilloscope permet un
réglage fiable aux niveaux relativement élevés et aux fréquences nettement
inférieures à sa bande passante. La calibration finale selon la fréquence et
les positions de l'atténuateur demandera idéalement un wattmètre RF et une tête
de puissance calibrée 50 ohms.

La correction numérique par fréquence et position d'atténuateur est décrite
séparément dans
[CALIBRATION_AMPLITUDE.md](CALIBRATION_AMPLITUDE.md). Le fonctionnement de la
commande de niveau et de l'atténuateur est détaillé dans
[BUS_INSTRUMENTS_NIVEAU_RF.md](BUS_INSTRUMENTS_NIVEAU_RF.md).

## Organisation de la boucle

La carte de commande de régulation reçoit :

- `PT2 / DET` : tension issue du détecteur RF placé avant l'atténuateur ;
- `PT3 / REF` : consigne analogique produite par la carte analogique ;
- `PT1 / Cde AM` : commande appliquée à la chaîne VHF pour fermer la boucle.

Sur le schéma de la page 52a :

- `CENTRAGE` injecte une composante continue dans le comparateur et déplace
  globalement la loi de niveau ;
- `GAIN` modifie le rapport entre la détection et la référence, donc la pente
  de la loi de niveau.

Les deux réglages se couplent. Ils doivent être réglés avec deux niveaux de
référence, puis repris alternativement jusqu'à convergence. Il ne faut pas les
placer tous les deux au maximum pour rechercher simplement la puissance de
sortie la plus élevée.

Le préamplificateur VHF situé en amont peut sembler sans effet lorsque la boucle
est fermée : la régulation compense alors sa variation de gain. Son réglage ne
doit pas servir à remplacer l'alignement de `GAIN` et `CENTRAGE`.

## Équipement utilisable

Pour un réglage grossier :

- oscilloscope dont la bande passante est largement supérieure à la fréquence
  de mesure ;
- entrée 50 ohms, ou entrée haute impédance associée à une terminaison externe
  50 ohms ;
- câble coaxial court dont la perte est connue ou négligeable ;
- éventuellement analyseur de spectre dont l'erreur d'amplitude a été
  caractérisée.

Pour une calibration plus précise :

- wattmètre RF avec tête thermocouple ou thermistance calibrée ;
- bande utile couvrant au moins 1,12 GHz pour le 740A ;
- dynamique suffisante pour mesurer les niveaux choisis avant de déduire les
  niveaux faibles par cumul des atténuations.

Ne jamais utiliser simultanément l'entrée 50 ohms de l'oscilloscope et une
terminaison externe 50 ohms. Vérifier également le facteur de sonde ou de voie
affiché par l'oscilloscope. Une mesure haute impédance sans terminaison correcte
ne représente pas la puissance disponible sur 50 ohms.

## Conversion dBm vers tension sur 50 ohms

Pour une sinusoïde :

```text
P(W) = 0,001 * 10^(niveau_dBm / 10)
Vrms = sqrt(50 * P)
Vpp  = 2 * sqrt(2) * Vrms
```

Valeurs utiles :

| Niveau | Vrms | Vpp |
|---:|---:|---:|
| +13 dBm | 999 mV | 2,825 V |
| +10 dBm | 707 mV | 2,000 V |
| +5 dBm | 398 mV | 1,125 V |
| 0 dBm | 224 mV | 632 mV |
| -1 dBm | 199 mV | 564 mV |
| -2 dBm | 178 mV | 502 mV |
| -3 dBm | 158 mV | 448 mV |
| -4 dBm | 141 mV | 399 mV |
| -5 dBm | 126 mV | 356 mV |
| -10 dBm | 70,7 mV | 200 mV |
| -20 dBm | 22,4 mV | 63,2 mV |

Ces valeurs supposent une sinusoïde propre et une charge exactement égale à
50 ohms au plan de référence choisi.

## Préparation

1. Photographier et repérer la position initiale des potentiomètres.
2. Laisser chauffer le 740A et l'instrument de mesure.
3. Travailler en CW, sans AM, FM ni modulation d'impulsion.
4. Relier directement la sortie principale à la charge de mesure 50 ohms.
5. Choisir `50 MHz`, qui est le point de calibration spécifié dans la
   documentation du 740A à `0 dBm`.
6. Vérifier qu'aucun relais ne commute entre les deux niveaux retenus.

Les essais effectués sur cet appareil montrent un changement d'état mécanique
entre `-3` et `-4 dBm`. Les points `0` et `-3 dBm` appartiennent au même palier
et conviennent donc pour régler la pente sans mélanger l'erreur d'un relais.

## Réglage de CENTRAGE et GAIN

1. Programmer `50 MHz`, `0 dBm`, RF active.
2. Régler doucement `CENTRAGE` pour obtenir `0 dBm`, soit environ `632 mVpp`
   sur 50 ohms.
3. Programmer `-3 dBm`, sans changer la fréquence.
4. Régler doucement `GAIN` pour obtenir `-3 dBm`, soit environ `448 mVpp`.
5. Revenir à `0 dBm` et reprendre légèrement `CENTRAGE`.
6. Revenir à `-3 dBm` et reprendre légèrement `GAIN`.
7. Répéter les étapes 5 et 6 jusqu'à obtenir simultanément les deux niveaux.

Le sens horaire ou antihoraire n'est pas imposé ici : il dépend du câblage et
de l'orientation physique du potentiomètre. Procéder par petits déplacements
et noter le sens observé.

`PT2` et `PT3` permettent de suivre le comportement de la boucle, mais il ne
faut pas régler systématiquement les potentiomètres pour imposer `PT2 = PT3`.
Le réseau `GAIN/CENTRAGE` introduit précisément le rapport et l'offset requis
entre ces deux tensions. La grandeur de référence finale reste la puissance RF
réellement disponible sur la sortie 50 ohms.

## Contrôles après réglage

### Linéarité dans un même palier

À 50 MHz, relever successivement :

```text
0, -1, -2 et -3 dBm
```

La variation doit être monotone et proche de 1 dB entre chaque point. Avec un
oscilloscope, les rapports de tension attendus par rapport à `0 dBm` sont :

```text
-1 dB : 0,891
-2 dB : 0,794
-3 dB : 0,708
```

### Changement de palier mécanique

Contrôler ensuite la transition `-3 / -4 / -5 dBm`. Un saut de `PT2`, `PT3` ou
de la commande analogique peut être normal lors de la commutation du relais ;
la puissance RF externe doit néanmoins continuer par pas voisins de 1 dB.

Répéter le contrôle sur quelques autres groupes d'atténuation, par exemple
`-5` à `-8 dBm`, puis sur des niveaux plus faibles tant que l'instrument de
mesure conserve une marge suffisante sur son bruit propre.

Si la pente est correcte dans un palier mais qu'une discontinuité apparaît à
un changement de relais, ne pas reprendre `GAIN` et `CENTRAGE`. Il faut alors
examiner la position d'atténuateur concernée ou sa correction numérique.

### Contrôle selon la fréquence

Vérifier ensuite quelques fréquences dans la bande où l'instrument de mesure
est fiable. Les potentiomètres sont un réglage global et ne doivent pas être
repris pour chaque fréquence. Les écarts résiduels dépendant de la fréquence
seront traités ultérieurement par la table de calibration.

Pour le banc actuellement utilisé, la correction externe du Siglent n'est
caractérisée que de 1 à 60 MHz. Hors de cette plage, ses indications absolues
ne doivent pas servir à régler l'Adret tant que l'analyseur n'a pas été
recalibré. Son mode `Auto Cal` doit rester désactivé, puisqu'il a produit une
erreur importante lors des essais.

## Résultat obtenu sur l'appareil étudié

Le défaut initial paraissait être une perte de sortie presque constante de
4 à 6 dB. Les contrôles successifs ont cependant établi que :

- la commande VHF `+5 dB` fonctionne correctement ;
- les quatre étages de l'amplificateur VHF sont actifs et donnent environ
  22 dB de gain total, à comparer aux 24 dB nominaux déduits des quatre étages
  annoncés à 6 dB ;
- les deux chemins RF arrivant au premier étage de puissance donnent des
  niveaux comparables ;
- le bloc atténuateur, le disjoncteur de sortie et leurs connexions présentent
  une perte d'insertion et des écarts relatifs cohérents ;
- l'écart apparent provenait principalement du Siglent SSA3021X modifié en
  SSA3032X, qui indiquait environ 6 dB de moins que le niveau appliqué.

Le générateur Rigol a été relié directement au Siglent, puis contrôlé avec un
oscilloscope correctement chargé par 50 ohms. Une table de correction externe
du Siglent a ensuite été établie par points entre 1 et 60 MHz. Dans cette bande,
les niveaux de l'Adret redeviennent cohérents avec les valeurs programmées.

Les potentiomètres `GAIN` et `CENTRAGE` ont été repris alternativement selon la
méthode à deux points décrite ci-dessus. Le résultat a ensuite été contrôlé sur
plusieurs positions de l'atténuateur et jugé correct. Le relevé de gain de
l'amplificateur est conservé dans
[`tests/Mesures gain ampli adret 740a.ods`](../tests/Mesures%20gain%20ampli%20adret%20740a.ods).

Cette validation lève le diagnostic de panne globale de niveau, mais ne
remplace pas une calibration absolue de l'Adret. Il reste à caractériser le
générateur et l'analyseur sur toute la bande avec une source ou un wattmètre RF
étalonné jusqu'à au moins 3,2 GHz. Les relevés bruts devront être conservés
séparément avant de modifier les tables de correction de l'un ou l'autre
appareil.

## Critères d'arrêt et recherche de panne

Arrêter le réglage si :

- un potentiomètre atteint une butée avant d'obtenir les deux points ;
- le niveau oscille ou devient instable ;
- un même réglage ne permet pas de retrouver `0` et `-3 dBm` après plusieurs
  itérations ;
- l'écart dépend fortement du chemin RF ou d'une seule position de relais.

Ces symptômes peuvent indiquer un défaut de la référence, du détecteur, de la
chaîne de commande, d'une cellule d'atténuation ou de la table de correction.
Un écart constant observé sur toutes les fréquences et toutes les atténuations
doit aussi faire vérifier en priorité l'instrument de mesure.

## Relevé conseillé

Conserver au minimum les informations suivantes :

```text
Date et temps de chauffe :
Fréquence :
Instrument de mesure et configuration 50 ohms :
Câble et correction appliquée :
Position photographiée de CENTRAGE :
Position photographiée de GAIN :

Commande       Mesure RF       PT1       PT2/DET       PT3/REF
  0 dBm
 -1 dBm
 -2 dBm
 -3 dBm
 -4 dBm
 -5 dBm
```

Une fois le résultat satisfaisant, marquer ou photographier les positions des
deux potentiomètres et ne plus les utiliser pour corriger les variations de
fréquence ou les erreurs propres à un palier mécanique.
