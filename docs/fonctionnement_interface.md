# Fonctionnement de l'interface

Ce document décrit la première logique fonctionnelle du panneau avant. Le bus
instrument réel n'est pas encore piloté : les commandes correspondantes sont
émises sur Serial0 sous la forme `INSTR ...`.

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

Au-dessus de 20 kHz FM, le pas effectif minimal devient 100 Hz. Un pas de
10 Hz reste mémorisé et redevient actif lorsque la valeur repasse sous ce
seuil. Toutes les valeurs saturent à leurs limites sans rebouclage.

Les affichages utilisent les formats suivants :

- fréquence : dix digits en hertz ;
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
reproduire. Sauf indication contraire dans le tableau d'état plus bas, elles ne
sont pas encore prises en charge par le contrôleur du firmware.

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

Un appui sur `INC` permet de revoir un incrément déjà défini. Pour l'amplitude,
l'incrément s'exprime exclusivement en dB, même si le niveau actif est affiché
dans une autre unité.

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

Le voyant `SEQ` s'allume lorsque la fonction est active.

### Exploitation, inhibition et suppression

Tant que la séquence est active :

- `↑` sélectionne la position suivante et exécute immédiatement sa
  configuration ;
- `↓` revient au début de la séquence selon le paragraphe détaillé du manuel ;
- une pédale ou un cadenceur raccordé à la prise arrière `AUX` permet également
  de faire défiler les positions avec exécution à chaque pas ;
- un dépassement de borne produit l'erreur `E-89`.

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
| Chiffres, point et unités | Préparent une valeur sans agir sur la sortie | Touches lues et tracées, saisie non implémentée |
| `←`, `CLEAR`, `EXEC` et `X→Y` | Corrigent, annulent, exécutent ou consultent l'état actif | Touches lues et tracées, actions non implémentées |
| `MEM` et `RECALL` | Enregistrent et rappellent 40 configurations | Touches lues et tracées, stockage mémoire non implémenté |
| `SEQ` | Définit et exploite une plage de mémoires | Touche lue et tracée, séquences non implémentées |
| `INC`, `↑` et `↓` | Programment et appliquent un incrément, ou parcourent une séquence | Touches lues et tracées, actions non implémentées |
| `SPL` et `ADR17` | Fonctions spéciales du clavier et d'adressage | Touches lues et tracées, actions non implémentées |

## Diagnostic Serial0

Serial0 reste à 115200 bauds. Le firmware conserve les lignes brutes `KEY` et
`ENC` et ajoute notamment :

```text
TARGET value=FM
STEP target=FM value=100
VALUE target=FM value=12500
VALID target=FM active=1
SOURCE value=1KHZ
RF_OFF value=1
INSTR parameter=FM value=12500
```

Les valeurs entières des traces utilisent les unités internes : Hz, dixièmes
de dBm, centièmes de radian et dixièmes de pour-cent.
