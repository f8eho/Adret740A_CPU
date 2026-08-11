# Bus instruments : cartes « 20000 » et « 80 »

## Résultat

Les adresses 0 à 2 programment la carte « 20000 » et l'adresse 3 programme
la carte « 80 ». Le modèle ci-dessous reproduit les quatre octets de toutes
les configurations RF présentes dans les six captures de balayage.

L'analyse part de la fréquence `A` du document
[`ADRET7401_Principe.md`](ADRET7401_Principe.md). La carte « 80 » produit un
multiple de 500 kHz et la carte « 20000 » ajoute une fréquence de 1 à
1,5 MHz par pas de 25 Hz :

```text
A = Q x 500 000 + M x 25
Q = 178 .. 257
M = 40 000 .. 59 999
```

La décomposition utilisée par la CPU est :

```text
Q = entier((A - 1 000 000) / 500 000)
M = (A - Q x 500 000) / 25
```

La plage théorique correspondante est `90 000 000` à `129 999 975 Hz` au
point A.

## Carte « 20000 » : adresses 0, 1 et 2

Les captures disponibles ne contiennent que des valeurs `M` paires. Le code
de la CPU d'origine permet toutefois de démontrer le codage des valeurs
impaires. On définit :

```text
C = plancher(M / 2) - 20 000
```

`C` est compris entre 0000 et 9999. Ses quatre chiffres décimaux sont répartis
de façon inhabituelle sur le bus :

| Adresse | D7..D4 | D3..D0 |
| --- | --- | --- |
| 0 | unités de `C` en BCD | `0000` si M pair, `1000` si M impair |
| 1 | centaines de `C` en BCD | dizaines de `C` en BCD |
| 2 | `0000` | milliers de `C` en BCD |

Les formules d'encodage sont donc :

```text
bus[0] = ((C % 10) << 4) | (M impair ? 0x08 : 0x00)
bus[1] = ((C / 100 % 10) << 4) | (C / 10 % 10)
bus[2] = C / 1000 % 10
```

Le schéma de la carte confirme trois registres d'entrée, le décodeur d'adresse
SN24 et les compteurs/comparateurs du diviseur 40 000 à 59 999. Dans la
routine originale `$E75F`, l'octet de poids faible calculé est lu en `$EACC` :
si son demi-octet bas BCD vaut `.5`, la CPU ajoute 3 avant d'écrire l'adresse
0. Le marqueur envoyé est donc `0x8`. Ce chemin, absent des captures, est
validé par le code EPROM et des vecteurs hôte aux deux bornes impaires.

## Carte « 80 » : adresse 3

On code d'abord l'offset du diviseur sous forme de deux chiffres BCD :

```text
R = Q - 178                 // 00 à 79
BCD(R) = dizaines << 4 | unités
bus[3] = BCD(R) XOR 0xFE
```

Autrement dit, D7 à D1 sont inversés par rapport au BCD de `R`, tandis que D0
ne l'est pas. Exemples :

| Q | R en BCD | Adresse 3 |
| ---: | ---: | ---: |
| 178 | `0x00` | `0xFE` |
| 179 | `0x01` | `0xFF` |
| 180 | `0x02` | `0xFC` |
| 238 | `0x60` | `0x9E` |
| 257 | `0x79` | `0x87` |

Les 80 valeurs de `Q`, de 178 à 257, apparaissent dans les captures. La table
complète de cette carte est donc couverte, et pas seulement extrapolée à
partir de quelques points.

## Raccordement avec une fréquence de sortie

Dans la gamme capturée, 184 à 279,9 MHz, l'oscillateur RF fonctionne à deux
fois la fréquence affichée. Pour une fréquence de sortie `F` :

```text
F_synthèse = 2 x F
N = entier((F_synthèse - 18 MHz) / 8 MHz)
Delta = F_synthèse - 18 MHz - N x 8 MHz
A = 5 x (18 MHz + Delta)
```

Exemples tirés de la première transaction de chaque balayage :

| Sortie | N | Delta | A | Q | M | Adresses 0..3 |
| ---: | ---: | ---: | ---: | ---: | ---: | --- |
| 240,000010 MHz | 57 | 6 000 020 Hz | 120 000 100 Hz | 238 | 40 004 | `20 00 00 9E` |
| 240,000100 MHz | 57 | 6 000 200 Hz | 120 001 000 Hz | 238 | 40 040 | `00 02 00 9E` |
| 240,001000 MHz | 57 | 6 002 000 Hz | 120 010 000 Hz | 238 | 40 400 | `00 20 00 9E` |
| 240,010100 MHz | 57 | 6 020 200 Hz | 120 101 000 Hz | 238 | 44 040 | `00 02 02 9E` |
| 240,100100 MHz | 57 | 6 200 200 Hz | 121 001 000 Hz | 240 | 40 040 | `00 02 00 9C` |
| 241,000100 MHz | 58 | 200 Hz | 90 001 000 Hz | 178 | 40 040 | `00 02 00 FE` |

Le dernier exemple montre le report de `Delta` à `N` : le point A revient en
bas de sa plage et la carte « 80 » revient à `Q = 178`.

## Validation sur les traces

Les fichiers suivants ont été découpés en transactions de 13 écritures. Dans
chaque transaction, les adresses 0, 1, 2 et 3 occupent les positions 7 à 10 et
l'ordre est constant.

| Pas de la molette | Configurations | Octets 0..3 vérifiés |
| ---: | ---: | ---: |
| 10 Hz | 2 000 | 8 000 |
| 100 Hz | 2 018 | 8 072 |
| 1 kHz | 1 000 | 4 000 |
| 10 kHz | 1 000 | 4 000 |
| 100 kHz | 100 | 400 |
| 1 MHz | 10 | 40 |
| **Total** | **6 128** | **24 512** |

Résultat : `24 512 / 24 512` octets reproduits.

Le fichier à pas de 100 Hz contient 2 017 rotations en avant, jusqu'à
240,2017 MHz, puis une dernière rotation en arrière à 240,2016 MHz. Cette
dernière transaction explique pourquoi le nombre de configurations dépasse de
deux le suffixe « 240,2016 MHz » du nom de fichier ; elle a été validée avec
son sens réel et non avec un index artificiellement toujours croissant.

Les valeurs observées couvrent :

- les 80 diviseurs `Q = 178 .. 257` de la carte « 80 » ;
- `M = 40 000 .. 59 960` dans ces balayages ;
- 2 300 valeurs distinctes de `M`, toutes paires ;
- tous les chiffres BCD utiles aux quatre positions de `C`.

## Intégration firmware

`InstrumentSmallSteps` fournit une première fonction sans accès matériel :

```cpp
bool makeSmallStepProgram(uint32_t pointAFrequencyHz,
                          SmallStepProgram* program);
```

Elle calcule `Q`, `M` et les quatre octets. Elle contrôle la plage du point A
et le pas de 25 Hz. Quatre vecteurs issus des captures et deux vecteurs impairs
issus de l'algorithme EPROM sont vérifiés à la compilation par `static_assert`.

Cette fonction ne décide pas encore de la gamme RF et n'écrit pas le bus. Le
futur calcul de gamme devra produire `A`, puis le pilote MCP23017 enverra les
octets aux adresses 0 à 3 dans l'ordre observé au sein de la séquence complète.
