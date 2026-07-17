# Interface de commande série de l'Adret 740A

## Objet et statut du document

Ce document spécifie l'interface de télécommande série de la nouvelle carte
CPU de l'Adret 740A basée sur un Arduino Mega 2560. Il constitue la référence
pour une implémentation future ; il ne décrit pas une fonction déjà disponible
dans le firmware.

Le langage de commande reprend celui de l'interface IEEE-488 d'origine décrit
dans [Adret_740A_util_gpib.md](Adret_740A_util_gpib.md). Les mnémoniques de
réglage restent inchangés. Seuls le transport, les acquittements et les
fonctions propres au bus IEEE-488 sont adaptés à une liaison série point à
point.

## Caractéristiques de la liaison

| Propriété | Valeur |
| --- | --- |
| Interface du microcontrôleur | `Serial0` de l'Arduino Mega 2560 |
| Réception par le 740A | D0 / RX0 |
| Émission par le 740A | D1 / TX0 |
| Niveaux électriques | UART TTL 5 V |
| Débit | 115200 bauds |
| Format | 8 bits de données, sans parité, 1 bit d'arrêt (`8N1`) |
| Contrôle de flux | aucun |
| Codage | ASCII 7 bits |
| Duplex | intégral |

Les niveaux ne sont pas compatibles directement avec une interface RS-232.
Un adaptateur de niveaux approprié est obligatoire pour un raccordement
RS-232. Le convertisseur USB-série présent sur certaines cartes Mega peut
également donner accès à `Serial0` ; le protocole reste identique.

En fonctionnement normal, `Serial0` est exclusivement réservé à l'interface
de commande. Celle-ci et les traces compilées avec `ADRET_DEBUG_SERIAL=1` ne
doivent jamais être actives simultanément. Une version du firmware offrant la
télécommande doit donc être construite avec `ADRET_DEBUG_SERIAL=0`.

## Constitution des messages

### Règles lexicales

- Les commandes et les réponses utilisent uniquement des caractères ASCII.
- Les mnémoniques sont insensibles à la casse : `FM`, `fm` et `Fm` sont
  équivalents.
- Le format est libre. Des espaces ASCII peuvent séparer les mnémoniques, les
  signes et les valeurs. Ils ne sont pas obligatoires lorsqu'il n'existe
  aucune ambiguïté, par exemple `FM3`.
- Le séparateur décimal transmis est le point (`.`), quelle que soit la
  configuration régionale du contrôleur.
- La notation scientifique décimale est admise, par exemple `118e6`.
- Le symbole `Ø` employé dans le manuel d'origine est toujours transmis sous
  la forme du chiffre ASCII `0`.
- Plusieurs commandes de réglage peuvent être regroupées dans un même
  message, dans l'ordre où elles doivent être préparées.
- Un message contient au maximum 128 caractères, espaces compris et caractère
  d'exécution exclu.

### Exécution et terminaison

Les caractères suivants demandent l'exécution du message préparé :

| Terminaison reçue | Effet |
| --- | --- |
| `CR` (`0x0D`) | exécute le message |
| `LF` (`0x0A`) | exécute le message |
| `CR LF` | exécute une seule fois le message |
| `?` (`0x3F`) | exécute le message, selon la syntaxe historique |

Un `CR` ou un `LF` reçu immédiatement après `?` appartient à la même
terminaison et ne crée pas de message vide supplémentaire.

Le caractère `!` (`0x21`) termine le message courant sans l'appliquer. Les
réglages sont conservés dans une transaction préparée et la réponse est
`OK`. Un éventuel `CR`, `LF` ou `CR LF` immédiatement placé après `!` est
absorbé et ne déclenche pas l'exécution. La transaction préparée est appliquée
avec les commandes supplémentaires lors de la prochaine terminaison
exécutoire.

Une terminaison reçue sans commande n'a aucun effet et ne produit aucune
réponse, sauf lorsqu'elle exécute une transaction précédemment préparée par
`!`.

### Atomicité et récupération

L'analyse et l'application d'une transaction sont atomiques. Si une commande,
une valeur ou l'état courant est invalide :

1. aucune commande de la transaction n'est appliquée ;
2. la configuration active antérieure reste inchangée ;
3. toute transaction préparée par `!` est abandonnée ;
4. le récepteur ignore les caractères restants jusqu'à la prochaine
   terminaison ;
5. le traitement normal reprend avec le message suivant.

En cas de dépassement des 128 caractères, la trame entière est rejetée avec
`E-91`. Cette règle permet une implémentation à tampon fixe, sans allocation
dynamique.

## Réponses de l'instrument

Chaque message accepté ou exécuté produit exactement une réponse terminale.
Toutes les réponses se terminent par `CR LF` :

| Réponse | Signification |
| --- | --- |
| `OK\r\n` | message accepté et, sauf terminaison `!`, exécuté |
| `ERR E-xx\r\n` | message rejeté avec le code indiqué |
| `STB n\r\n` | résultat de `STB?`, avec `n` compris entre 0 et 255 |

Une commande de lecture telle que `STB?` produit uniquement sa réponse de
données ; elle n'est pas suivie d'un `OK`.

Lorsqu'une erreur demande l'attention du contrôleur, le 740A émet d'abord le
message asynchrone `SRQ n\r\n`, puis la réponse terminale `ERR E-xx\r\n` de la
commande fautive. Le contrôleur doit donc accepter une ligne `SRQ` à tout
moment et ne considérer que `OK`, `ERR` ou `STB` comme fin de sa transaction.

Le firmware n'émet ni bannière ni message de diagnostic au démarrage. Cette
règle évite de confondre des traces libres avec les réponses du protocole.

## Modes local et distant

### Commandes de gestion

Les commandes suivantes remplacent les messages matériels IEEE-488. Elles
sont acceptées dans tous les modes et sont insensibles à la casse.

| Commande | Effet |
| --- | --- |
| `REN 1` | valide la télécommande et passe en mode distant |
| `REN 0` | invalide la télécommande et revient en mode local |
| `GTL` | retour en local demandé par le contrôleur |
| `LLO 1` | verrouille le retour local manuel |
| `LLO 0` | libère le retour local manuel |
| `STB?` | lit l'octet d'état et acquitte la demande `SRQ` |

Les commandes de réglage de l'instrument ne sont acceptées qu'en mode
distant (`REMS` ou `RWLS`). Leur réception en mode local produit `E-00`.

### États

| État | Signification | Voyant `REM` | Bouton `RTL` |
| --- | --- | --- | --- |
| `LOCS` | local sans verrouillage | éteint | sans effet |
| `LWLS` | local avec verrouillage | éteint | sans effet |
| `REMS` | distant sans verrouillage | allumé | retour à `LOCS` |
| `RWLS` | distant avec verrouillage | allumé | ignoré |

À la mise sous tension, l'instrument est en `LOCS`. Les transitions sont les
suivantes :

- `REN 1` transforme `LOCS` en `REMS` et `LWLS` en `RWLS` ;
- `REN 0` ou `GTL` transforme `REMS` en `LOCS` et `RWLS` en `LWLS` ;
- `LLO 1` transforme `LOCS` en `LWLS` et `REMS` en `RWLS` ;
- `LLO 0` transforme `LWLS` en `LOCS` et `RWLS` en `REMS` ;
- le bouton `RTL` transforme uniquement `REMS` en `LOCS`.

En local, le bouton `RTL` n'affiche pas d'adresse : la liaison série est point
à point et ne possède ni adresse primaire ni équivalent de `MLA`. Les notions
IEEE-488 de listener, talker et adressage ne sont donc pas applicables.

## Commandes de réglage

### Tableau récapitulatif

| Fonction | Syntaxe | Unité transmise | Domaine |
| --- | --- | --- | --- |
| Fréquence RF | `F valeur` | Hz | 100 kHz à 560 MHz |
| Niveau RF | `A valeur` | dBm | -129,9 à +13,0 dBm |
| Sortie RF | `RF 0` ou `RF 1` | aucune | 0 = inhibée, 1 = validée |
| Mode AM | `AM mode` | aucune | mode 0 à 3 |
| Taux AM | `% valeur` | % | 0 à 99,9 % |
| Mode FM | `FM mode` | aucune | mode 0 à 3 |
| Déviation FM | `D valeur` | kHz | 0 à 200 kHz |
| Mode PM | `PM mode` | aucune | mode 0 à 3 |
| Déviation PM | `P valeur` | radian | 0 à 19,99 rad |
| Impulsions | `SL 64` / `SL 60` | aucune | validation / suppression |
| Mémorisation | `M nn` | aucune | `nn` de `00` à `39` |
| Rappel | `RM nn` | aucune | `nn` de `00` à `39` |
| Séquence | `SQ dd ff` | aucune | bornes `00` à `39` |
| Suppression séquence | `SQ0` | aucune | sans objet |

### Fréquence RF

`F` est suivi de la fréquence exprimée en hertz. La plage valide est de
100 000 Hz à 560 000 000 Hz inclus. La résolution effective est de 10 Hz ;
une valeur exigeant une résolution supérieure est arrondie vers le bas à la
dizaine de hertz.

```text
F 118e6
F1000000
```

### Niveau et inhibition RF

`A` est suivi du niveau en dBm. La programmation se fait toujours en dBm, de
-129,9 à +13,0 dBm inclus, avec une résolution de 0,1 dB. Une valeur possédant
des décimales supplémentaires est invalide ; elle n'est pas arrondie.

`RF 0` inhibe la sortie RF et `RF 1` la valide. Il s'agit de l'équivalent ASCII
du `RF Ø` imprimé dans le manuel.

```text
A -45.2
F 118e6 A -117 RF 1
```

### Modulation d'amplitude

`AM` sélectionne la source et l'état de la modulation :

| Commande | Sélection |
| --- | --- |
| `AM 0` | modulation inhibée, fonctionnement CW |
| `AM 1` | source externe |
| `AM 2` | source interne 1 kHz |
| `AM 3` | source interne 400 Hz |

`%` est suivi du taux de modulation, compris entre 0 et 99,9 %, avec une
résolution de 0,1 %.

```text
AM 2 % 50.5
```

### Modulation de fréquence

`FM` utilise les mêmes numéros de mode que `AM` : 0 pour CW, 1 pour la source
externe, 2 pour la source interne 1 kHz et 3 pour la source interne 400 Hz.

`D` est suivi de la déviation exprimée en kHz. Elle est comprise entre 0 et
200 kHz. La résolution est de 0,01 kHz (10 Hz) en dessous de 20 kHz, puis de
0,1 kHz (100 Hz) de 20 à 200 kHz. Une valeur située entre deux pas valides est
arrondie vers le bas au pas disponible.

```text
FM3 D75
```

### Modulation de phase

`PM` utilise les mêmes numéros de mode que `AM` et `FM`. `P` est suivi de la
déviation exprimée en radians, comprise entre 0 et 19,99 rad, avec une
résolution de 0,01 rad.

```text
PM 1 P 3.14
```

### Modulation d'impulsion

`SL 64` valide la modulation d'impulsion optionnelle. Si le matériel
correspondant n'est pas installé, la commande est rejetée avec `E-64`.
`SL 60` supprime ce mode et reste accepté même si l'option est absente.

### Mémoires

`M nn` enregistre dans la position `nn` la configuration préparée par le
message ; en l'absence de nouveau réglage dans ce message, la configuration
active est enregistrée. `RM nn` rappelle la configuration de la position
`nn`. Le rappel est appliqué au signal lors de l'exécution du message, ou lors
de l'exécution ultérieure si le message se termine par `!`.

La nouvelle carte CPU utilise 40 positions numérotées de `00` à `39`. Cette
plage diffère du texte GPIB d'origine, qui indique `01` à `40`. Il s'agit d'un
choix volontaire aligné sur le stockage EEPROM et le contrôleur actuels. Les
numéros doivent toujours comporter deux chiffres ; `M 1` n'est pas valide.

Le rappel d'une mémoire vide est rejeté. Il allume le voyant d'erreur et
produit `ERR E-00`, le numéro concerné restant visible sur l'afficheur comme
sur l'instrument d'origine.

### Séquences

`SQ dd ff` définit une séquence inclusive de la mémoire de début `dd` à la
mémoire de fin `ff`. Chaque borne comporte exactement deux chiffres et doit
appartenir à `00..39`. La borne de début ne doit pas dépasser la borne de fin.
`SQ0` supprime la séquence.

La définition de la séquence n'exécute pas automatiquement une mémoire. Son
parcours ultérieur par les commandes locales, la pédale ou le cadenceur AUX
reste conforme au fonctionnement du panneau avant. Une définition invalide
produit `E-89`.

```text
SQ 05 23
SQ0
```

## Traitement des erreurs et état

### Octet d'état

`STB?` remplace la reconnaissance série IEEE-488. La valeur décimale retournée
et celle du message `SRQ` utilisent le format historique :

| Bit | Poids | Signification |
| --- | ---: | --- |
| 7 | 128 | toujours 0 |
| 6 | 64 | demande d'interruption `SRQ` active |
| 5 | 32 | erreur de paramètre ou de manipulation |
| 4 | 16 | mode distant (`REMS` ou `RWLS`) |
| 3..0 | 8..1 | chiffre de famille du dernier code d'erreur |

La famille est le chiffre des dizaines du code : `E-21` donne 2, `E-64`
donne 6 et `E-91` donne 9. `E-00` donne 0.

La lecture `STB?` acquitte et efface le bit 6. Le bit 5 et la famille restent
mémorisés jusqu'à l'exécution réussie d'un nouveau message de réglage. Une
commande de gestion réussie ne les efface pas. Le voyant et l'affichage
d'erreur du panneau avant conservent leur temporisation propre, indépendante
de ces bits mémorisés.

### Codes d'erreur

| Code | Signification série |
| --- | --- |
| `E-00` | syntaxe invalide, commande inconnue, commande interdite dans le mode courant ou mémoire vide |
| `E-21` | fréquence RF trop grande |
| `E-22` | fréquence RF trop basse |
| `E-41` | amplitude RF trop grande |
| `E-42` | amplitude RF trop petite |
| `E-47` | incrément exprimé en volts, réservé au fonctionnement local |
| `E-61` | taux de modulation AM trop grand |
| `E-62` | taux de modulation AM inférieur à zéro |
| `E-64` | option modulation d'impulsion absente |
| `E-71` | excursion FM ou PM trop grande |
| `E-72` | excursion FM ou PM inférieure à zéro |
| `E-74` | FM ou PM demandée en modulation d'impulsion |
| `E-77` | unité incohérente en FM ou PM |
| `E-89` | définition ou borne de séquence invalide |
| `E-91` | dépassement du tampon ou message de plus de 128 caractères |

Les codes historiques non produits par les commandes série restent réservés
afin de ne pas créer de signification incompatible.

## Exemples de sessions

Dans les exemples suivants, `<CR>` et `<LF>` représentent les octets de
contrôle correspondants ; ces libellés ne sont pas transmis littéralement.

### Passage en distant et configuration immédiate

```text
Contrôleur -> 740A : REN 1<CR><LF>
740A -> contrôleur : OK<CR><LF>
Contrôleur -> 740A : F 118e6 A -117 RF 1<CR><LF>
740A -> contrôleur : OK<CR><LF>
```

La fréquence, le niveau et la validation RF sont appliqués ensemble.

### Préparation différée

```text
Contrôleur -> 740A : F 118e6 A -117!<CR><LF>
740A -> contrôleur : OK<CR><LF>
Contrôleur -> 740A : AM 2 % 50.5<CR><LF>
740A -> contrôleur : OK<CR><LF>
```

La première ligne ne modifie pas le signal. La seconde exécute atomiquement
la fréquence, le niveau et la modulation préparés.

### Modulations

```text
Contrôleur -> 740A : FM3 D75?<CR><LF>
740A -> contrôleur : OK<CR><LF>
Contrôleur -> 740A : PM 1 P 3.14<CR>
740A -> contrôleur : OK<CR><LF>
```

Le `CR LF` placé après `?` n'entraîne pas de seconde réponse.

### Mémoires et séquence

```text
Contrôleur -> 740A : F 10e6 M 05<CR><LF>
740A -> contrôleur : OK<CR><LF>
Contrôleur -> 740A : RM 05<CR><LF>
740A -> contrôleur : OK<CR><LF>
Contrôleur -> 740A : SQ 05 23<CR><LF>
740A -> contrôleur : OK<CR><LF>
```

### Lecture d'état

```text
Contrôleur -> 740A : STB?<CR><LF>
740A -> contrôleur : STB 16<CR><LF>
```

La valeur 16 indique le mode distant sans erreur ni demande d'interruption.

### Erreur et reprise

```text
Contrôleur -> 740A : F 600e6<CR><LF>
740A -> contrôleur : SRQ 114<CR><LF>
740A -> contrôleur : ERR E-21<CR><LF>
Contrôleur -> 740A : STB?<CR><LF>
740A -> contrôleur : STB 114<CR><LF>
Contrôleur -> 740A : STB?<CR><LF>
740A -> contrôleur : STB 50<CR><LF>
```

`114 = 64 + 32 + 16 + 2` : demande d'interruption, erreur, mode distant et
famille 2. La première lecture retourne l'état avant acquittement puis efface
le bit 6 ; la seconde retourne donc 50.

### Verrouillage et retour local

```text
Contrôleur -> 740A : LLO 1<CR><LF>
740A -> contrôleur : OK<CR><LF>
Contrôleur -> 740A : GTL<CR><LF>
740A -> contrôleur : OK<CR><LF>
```

Après `GTL`, l'instrument se trouve en `LWLS` : il est local, le voyant `REM`
est éteint et le verrouillage reste mémorisé. `LLO 0` le ramène en `LOCS`.

## Éléments IEEE-488 non repris physiquement

La liaison série n'implémente pas les fonctions électriques ou protocolaires
`AH1`, `SH1`, `T2`, `L1`, `DC1`, `DT1`, les lignes `REN` et `SRQ`, le signal
Group Execute Trigger, le serial polling matériel ni l'adressage `MLA`.
Leurs effets utiles sont couverts respectivement par les terminateurs ASCII,
les commandes `REN`, `GTL`, `LLO`, `STB?` et le message asynchrone `SRQ`.
