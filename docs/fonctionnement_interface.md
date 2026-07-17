# Fonctionnement de l'interface

Ce document décrit la première logique fonctionnelle du panneau avant. Le bus
instrument réel n'est pas encore piloté. En mode diagnostic, les commandes
correspondantes sont représentées sur Serial0 sous la forme `INSTR ...`.

## État initial et persistance

Au démarrage, le firmware charge le dernier enregistrement EEPROM valide. En
l'absence de configuration valide, il utilise :

- fréquence : 100 kHz ;
- amplitude : -129,9 dBm ;
- taux FM, PM et AM : zéro ;
- mode de modulation : AM ;
- source : CW, donc modulation coupée ;
- cible de la molette : fréquence ;
- molette inhibée et voyant `VALID MAN` éteint ;
- sortie RF inhibée et voyant `INHIB RF` allumé.

L'état RF OFF est toujours forcé au démarrage, même si l'EEPROM contenait un
état différent.

Le voyant `REM`, historiquement associé au contrôle GPIB, est éteint par
défaut. Aucun port GPIB matériel ne sera implémenté ; ce voyant reste réservé à
un éventuel futur mode de télécommande sur Serial0.

La configuration utilise deux slots EEPROM versionnés avec CRC. La sauvegarde
n'est déclenchée que par la future entrée `PA` de présence alimentation. Cette
entrée est réservée sur Arduino D3 / PE5 / INT5, mais reste désactivée tant que
sa tension et sa polarité n'ont pas été validées au banc. `saveNow()` permet de
tester directement la persistance.

## Sélection du paramètre et molette

Les touches suivantes choisissent la valeur modifiée par la roue :

| Touche | Cible | Voyant et unité |
| --- | --- | --- |
| RF | fréquence | RF |
| AMPL | amplitude | AMPL et dBm |
| FM | taux FM | FM et kHz |
| PM | taux PM | PM et rd |
| AM | taux AM | AM et % |

FM, PM et AM conservent chacun leur valeur et leur pas. Passer de l'un à
l'autre ne détruit donc aucun réglage.

Une touche RF, AMPL, FM, PM ou AM change la sélection affichée et la future
cible du pavé numérique, mais ne réaffecte pas immédiatement la roue. La roue
continue de modifier sa dernière cible validée. `VALID MAN` affecte la
sélection affichée à la roue ; répéter VALID sur la même sélection ne la
désactive pas. Le voyant VALID est allumé lorsque la sélection affichée est la
cible effectivement pilotée, et éteint lorsqu'une nouvelle sélection reste en
attente de validation.

`MUL10` et `DIV10` déplacent le pas de la cible actuellement validée, même si
une autre sélection est affichée en attente de VALID. Le digit correspondant
au nouveau pas clignote trois fois, sans bloquer la lecture du clavier. Ces
touches n'ont pas de voyant dédié sur le schéma. Chaque cible conserve son
propre indice de pas en RAM et dans la configuration EEPROM.

## Valeurs, limites et pas

| Paramètre | Limites | Pas disponibles |
| --- | --- | --- |
| fréquence | 100 kHz à 560 MHz | 10 Hz à 100 MHz par décades |
| amplitude | -129,9 à +13,0 dBm | 0,1 / 1 / 10 dB |
| AM | 0 à 99,9 % | 0,1 / 1 / 10 % |
| PM | 0 à 19,99 rd | 0,01 / 0,1 / 1 / 10 rd |
| FM | 0 à 200 kHz | 10 Hz à 100 kHz par décades |

La saisie et l'affichage de fréquence possèdent un chiffre de résolution au
hertz. Le générateur ne sait toutefois appliquer que des pas de 10 Hz : lors
de la validation de l'unité, le chiffre des unités est forcé à zéro. Ainsi,
`123456 Hz` est visible pendant la frappe puis prépare `123450 Hz`. La molette
et les incréments utilisent eux aussi un pas minimal de 10 Hz.

Au-dessus de 20 kHz FM, le pas effectif minimal devient 100 Hz. Un pas de
10 Hz reste mémorisé et redevient actif lorsque la valeur repasse sous ce
seuil. Toutes les valeurs saturent à leurs limites sans rebouclage.

Les affichages utilisent les formats suivants :

- fréquence : valeur en hertz sans zéros non significatifs, séparée par groupes
  de trois chiffres (`100.000`, `1.000.000`, `10.000.000`). Le séparateur MHz
  n'est affiché qu'à partir de 1 MHz ;
- amplitude : un chiffre après la virgule ;
- AM : un chiffre après la virgule ;
- PM : deux chiffres après la virgule ;
- FM : centièmes de kHz sous 20 kHz, dixièmes jusqu'à 199,9 kHz, puis 200 kHz.

Le premier caractère spécial de modulation est commandé par SN4. Après les
permutations du faisceau validé, D0 logiciel affiche `1`, D1 affiche `P` et les
deux ensemble prennent l'aspect d'un `A`. Le firmware n'active donc que D0
lorsqu'un `1` de tête est nécessaire. Le `1` spécial d'amplitude possède une
commande d'extinction active haut ; les signes observés sont `+` sur D3 et `-`
sur D4. Les points de tête SN17 sont actifs bas et restent éteints pour ces
formats, les points utiles étant produits directement par les ICM7218A.

## Modulation et RF

Les sources `400 Hz`, `1 kHz` et `EXT` sont mutuellement exclusives. Un nouvel
appui sur la source déjà active la laisse sélectionnée. `CW` coupe toute
modulation sans effacer le mode, le taux ou le pas mémorisé. `EXT` désigne bien
la source externe ; ce n'est pas le générateur interne 1 kHz.

La touche sérigraphiée `INHIB RF`, appelée `RF OFF` sur le schéma, bascule
l'inhibition de la sortie RF et son voyant. Elle reste distincte de la ligne
électrique `INHIB` qui commande l'alimentation générale de l'appareil.

## Comportement cible du clavier d'après le manuel

Les fonctions de cette section décrivent le comportement du 740A d'origine à
reproduire. Le tableau d'état plus bas distingue les fonctions maintenant
prises en charge de celles qui restent différées ou à valider au banc.

### Préparation et exécution d'une configuration

La saisie au clavier prépare une nouvelle configuration sans modifier
immédiatement le signal de sortie. Une valeur complète se saisit dans l'ordre
suivant :

1. sélectionner le paramètre avec `RF`, `AMPL`, `FM`, `PM` ou `AM` ;
2. entrer les chiffres et, si nécessaire, le point décimal ;
3. terminer par une touche d'unité compatible avec le paramètre ;
4. sélectionner éventuellement un autre paramètre et saisir sa valeur ;
5. presser `EXEC` pour appliquer en une fois toute la configuration préparée.

L'ordre des paramètres n'est pas imposé et un paramètre peut être modifié sans
ressaisir les autres. Cette préparation différée évite de faire transiter la
sortie par des configurations intermédiaires. Pendant toute la saisie, les
afficheurs présentent la configuration préparée tandis que l'instrument reste
sur la dernière configuration exécutée.

Le voyant au-dessus de `EXEC` :

- s'allume en continu dès le premier chiffre d'une nouvelle valeur ;
- clignote lorsque l'unité a été saisie et que la valeur est complète ;
- revient à l'allumage continu dès le premier chiffre du paramètre suivant ;
- s'éteint après l'exécution de la configuration préparée.

Après la saisie de l'unité, le pavé numérique n'accepte pas directement une
autre valeur. Il faut d'abord sélectionner le nouveau paramètre, mémoriser la
configuration ou presser `EXEC`. Un chiffre tapé sans nouvelle sélection est
ignoré afin de ne pas écraser le paramètre qui vient d'être complété.

### Unités contextuelles

Certaines touches portent plusieurs unités. Leur interprétation dépend du
paramètre sélectionné :

| Paramètre | Unités de fin de saisie |
| --- | --- |
| `RF` | `MHz`, `kHz` ou `Hz` |
| `AMPL` | `-dBm`, `+dBm`, `V`, `mV` ou `µV` |
| `FM` | `kHz` ou `Hz` |
| `PM` | `rd` |
| `AM` | `%` |

Une unité est obligatoire. Son omission ou une unité incohérente allume le
voyant d'erreur et restaure la valeur antérieure. Le mode spécial `SPL 44`
permet la saisie d'un niveau en dBµV ; `SPL 40` rétablit le fonctionnement
normal. Les autres usages de `SPL`, notamment la modulation d'impulsion, ne
sont pas détaillés ici.

Exemples confirmés par les figures du manuel :

```text
RF 5 4 3 . 2 1 MHz  AMPL 3 3 -dBm  EXEC
RF 9 5 9 2 kHz      AMPL 1 5 2 mV    EXEC
RF 2 2 5 MHz        AMPL 1 0 0 -dBm  AM 3 0 %  EXEC
```

### Correction et consultation de la configuration active

- `←` corrige la valeur appelée en repartant du dernier chiffre entré. Le
  chiffre modifiable clignote.
- `CLEAR` efface les données en cours ainsi que les incréments préparés. Cette
  touche supprime également la définition de séquence.
- Pendant une saisie, `X→Y` affiche pendant environ deux secondes la
  configuration réellement active, puis revient à la préparation en cours.
- Après un rappel mémoire non exécuté, `X→Y` abandonne cet aperçu et réaffiche
  la configuration active.

### Incréments saisis au clavier

Un incrément se prépare comme une valeur ordinaire, puis se termine par `INC`
à la place de l'exécution. `↑` et `↓` appliquent ensuite respectivement le pas
positif et le pas négatif au paramètre concerné ; l'action est immédiatement
exécutoire. Par exemple, un pas de fréquence de 12,5 kHz se programme par :

```text
RF 1 2 . 5 kHz INC
```

La validation de plage absolue est différée après l'unité lorsqu'une valeur
peut encore représenter un incrément. Ainsi `12,5 kHz` n'est pas rejeté comme
fréquence RF inférieure à 100 kHz si la touche suivante est `INC`. Toute autre
touche, sauf `CLEAR`, confirme l'interprétation absolue et produit alors
l'erreur de plage correspondante.

Après la programmation par `valeur unité INC`, l'afficheur revient
automatiquement à la valeur courante du paramètre afin de montrer directement
son évolution avec `↑` et `↓`. Un appui ultérieur sur `INC`, sans nouvelle
saisie, permet de revoir l'incrément déjà défini. Pour l'amplitude, l'incrément
s'exprime exclusivement en dB, même si le niveau actif est affiché dans une
autre unité. Les cinq incréments RF, amplitude, FM, PM et AM sont distincts,
conservés uniquement en RAM et tous supprimés par `CLEAR`.

Les flèches appliquent l'incrément à la configuration active et émettent
immédiatement une transaction instrument complète. Si une autre modification
est en attente d'`EXEC`, la valeur incrémentée est aussi synchronisée dans la
configuration préparée afin qu'une exécution ultérieure ne l'annule pas. Une
séquence active reste prioritaire : dans ce mode, `↑` et `↓` continuent de
parcourir la séquence.

## Mémoires

Le 740A d'origine dispose de 40 positions capables de conserver chacune une
configuration complète. Les numéros de position sont toujours saisis sur deux
chiffres, y compris pour les numéros inférieurs à 10.

### Enregistrement

`MEM` (touche `M` sur la sérigraphie historique), suivi de deux chiffres,
enregistre la configuration préparée dans la position demandée :

```text
MEM 2 4
MEM 0 8
```

Le numéro apparaît fugitivement sur l'afficheur de fréquence, par exemple
`P08`. L'enregistrement ne nécessite pas un `EXEC` préalable : les figures de
création d'une séquence montrent chaque fréquence suivie directement de
`MEM nn`.

### Rappel

`RECALL` (touche `R` sur la sérigraphie historique), suivi de deux chiffres,
rappelle une position, par exemple :

```text
RECALL 1 3
```

Le numéro est affiché pendant environ deux secondes, puis la configuration
mémorisée apparaît et le voyant `EXEC` clignote. Le signal de sortie conserve
la dernière configuration exécutée jusqu'à un appui sur `EXEC`. `X→Y` permet
de quitter un rappel non exécuté et de retrouver l'affichage de la
configuration active.

L'appel d'une position vide allume le voyant d'erreur et affiche `E` avec le
numéro demandé.

## Séquences de mémoires

### Création

Une séquence est une plage continue de positions mémoire. Il faut d'abord
enregistrer les configurations dans l'ordre de leurs numéros, puis définir les
bornes avec `SEQ`, deux chiffres pour le début et deux chiffres pour la fin.
Les quatre chiffres doivent être saisis rapidement : l'attente après l'appui
sur `SEQ` ne peut pas dépasser deux secondes.

L'exemple du manuel enregistre cinq fréquences dans les positions 08 à 12,
puis définit la séquence ainsi :

```text
RF 1 0 MHz       MEM 0 8
RF 1 1 . 2 MHz   MEM 0 9
RF 1 0 . 4 2 MHz MEM 1 0
RF 1 1 . 3 7 MHz MEM 1 1
RF 1 2 MHz       MEM 1 2
SEQ 0 8 1 2
```

Le voyant `SEQ` s'allume dès l'appui sur la touche, pendant la saisie des
bornes, puis reste allumé lorsque la fonction est active. Le premier chiffre
doit être commencé dans les deux secondes suivant l'appui sur `SEQ`. Dès que
ce premier chiffre est reçu, la temporisation ne s'applique plus et
l'utilisateur peut terminer normalement les trois chiffres restants. Le
voyant `MEM` s'allume pendant la saisie des deux chiffres d'une commande `MEM`
ou `RECALL`.

### Exploitation, inhibition et suppression

Tant que la séquence est active :

- `↑` sélectionne la position suivante et exécute immédiatement sa
  configuration ;
- `↓` revient au début de la séquence selon le paragraphe détaillé du manuel ;
- une pédale ou un cadenceur raccordé à la prise arrière `AUX` permet également
  de faire défiler les positions avec exécution à chaque pas ;
- aux bornes, les nouveaux appuis sont ignorés : `↑` reste sur la position de
  fin et `↓` reste sur la position de début, sans réexécuter la configuration.

Le code `E-89` reste utilisé pour une définition de séquence invalide, par
exemple des bornes hors de `00..39` ou une borne de début supérieure à celle
de fin. Il n'est pas émis lorsqu'une touche de défilement atteint une butée.

La légende générale du panneau décrit `↑` et `↓` comme une
incrémentation/décrémentation du paramètre sélectionné. Il s'agit de leur
fonction hors du mode séquence ; dans ce mode, le texte du manuel donne à `↓`
le rôle particulier de retour au début.

Un appui sur `SEQ` affiche les bornes pendant environ deux secondes sous la
forme `08-12`. La sélection de n'importe quel paramètre inhibe le défilement de
la séquence. `CLEAR` efface sa définition.

## État d'implémentation

| Fonction | Comportement documenté | État du firmware |
| --- | --- | --- |
| Sélection RF, AMPL, FM, PM et AM | Choisit le paramètre affiché et sa future saisie | Implémenté pour la sélection et la molette |
| Chiffres, point et unités | Préparent une valeur sans agir sur la sortie | Implémenté pour MHz/kHz/Hz, ±dBm, V/mV/µV, FM, PM et AM |
| `←`, `CLEAR`, `EXEC` et `X→Y` | Corrigent, annulent, exécutent ou consultent l'état actif | Implémenté ; comportement lumineux et temporel à valider au banc |
| `MEM` et `RECALL` | Enregistrent et rappellent 40 configurations | Implémenté pour les positions 00 à 39 avec CRC EEPROM individuel |
| `SEQ` | Définit et exploite une plage de mémoires | Implémenté au clavier ; entrée AUX non implémentée |
| `INC`, `↑` et `↓` | Programment et appliquent un incrément, ou parcourent une séquence | Implémenté ; séquence active prioritaire, validation au banc restante |
| `SPL` et `ADR17` | Fonctions spéciales du clavier et d'adressage | Touches lues et tracées, actions non implémentées |

Le contrôleur conserve séparément la configuration réellement exécutée et la
configuration préparée. Les sources de modulation suivent la préparation ;
`INHIB RF` reste immédiat et synchronise les deux états. La molette agit sur la
préparation lorsqu'elle existe, sans émettre de commande instrument.

Les réglages actifs utilisent deux slots EEPROM v3. Un ancien enregistrement
v2 reste lisible et sera migré lors de la sauvegarde suivante. Les 40 mémoires
de configuration occupent une zone séparée ; la définition de séquence reste
volontairement en RAM et disparaît au redémarrage.

## Diagnostic Serial0

Les diagnostics série sont contrôlés à la compilation par
`ADRET_DEBUG_SERIAL` dans `platformio.ini`. La valeur normale est `0` :
Serial0 n'est pas initialisé et aucune trace de diagnostic n'est incluse dans
le firmware. Passer la directive à `1` rétablit toutes les traces à 115200
bauds, notamment :

```text
TARGET value=FM
STEP target=FM value=100
VALUE target=FM value=12500
VALID target=FM active=1
PENDING source=1KHZ
RF_OFF value=1
INSTR parameter=FM value=12500
```

Les valeurs entières des traces utilisent les unités internes : Hz, dixièmes
de dBm, centièmes de radian et dixièmes de pour-cent.
