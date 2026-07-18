# Bus instruments : grands pas, approche et options

## Résultat principal

Les adresses liées à la sélection de fréquence ne forment pas quatre mots
indépendants. La CPU d'origine calcule une gamme, programme le diviseur
d'approche et fusionne ces informations avec les états de modulation :

| Adresse | Fonction établie dans ce lot |
| ---: | --- |
| 4 | diviseur d'approche `N`, plus D7 de poursuite du doubleur |
| 5 | sélection hétérodyne, `/2`, directe, `X2` et O1/O2 |
| 6 | niveau/atténuateur ; D6 est la commande `Pulse` |
| 12 | bits de gamme fusionnés avec les bits FM/PM |
| 13 | diviseur d'incréments `N`, plus un bit provenant de l'adresse 12 |
| 15 | mot dérivé de l'adresse 12 ; aucun récepteur n'est représenté sur le châssis standard |

Le doubleur et la modulation d'impulsions n'ont donc pas d'adresse dédiée :

- le doubleur utilise l'adresse 5 D4, l'adresse 4 D7 et les bits de gamme des
  adresses 12 et 15 ;
- la modulation d'impulsions utilise l'adresse 6 D6 et force aussi
  l'adresse 5 D5.

Les adresses 7 et 14 n'ont ni écriture dans les captures disponibles, ni
récepteur sur le schéma du châssis. L'adresse 15 est différente : la CPU
l'écrit réellement, même si aucun récepteur correspondant n'apparaît sur ce
châssis. Elle doit donc rester « écriture de compatibilité ou d'extension » et
ne pas être déclarée universellement inutilisée.

## Sources et niveau de preuve

Cette analyse croise :

- le principe de fonctionnement et ses équations ;
- les schémas des cartes approche, diviseur d'incréments, VHF, doubleur,
  impulsions et châssis ;
- les 6 128 configurations des six balayages RF à partir de 240 MHz ;
- les deux EPROM originales présentes dans
  `D:\Documents\Appareils\Mesure\Adret\740A\Eproms`.

Version binaire analysée :

| Fichier | Taille | SHA-256 |
| --- | ---: | --- |
| `740A-1.BIN` | 8192 | `099F43F99A26C1AA3E8C988622865FF8E5EFBA2F6E3A20A678295FD10085B095` |
| `740A-2.BIN` | 8192 | `0F178E5DC3220DD51E5F7105D6238C6962E594B3AD1E1CF235A87AA4F26BDA31` |

Le désassemblage confirme que les accès mémoire `$6000` à `$600F` sont les
adresses 0 à 15 du bus instruments. Le bloc physique `$E75F..$EABF` choisit
les gammes et écrit notamment `$600C`, `$600F`, `$6005`, `$600B`, `$6004` et
`$600D`, dans le même ordre que les traces.

## Calcul de la fréquence synthétisée

Pour la version de base, la fréquence appliquée aux équations des grands pas
est :

| Sortie `F` | Chemin | Fréquence oscillateur `Fs` |
| ---: | --- | ---: |
| 0,1 à moins de 1,5 MHz | hétérodyne basse | `400 MHz + F` |
| 1,5 à moins de 122 MHz | hétérodyne | `400 MHz + F` |
| 122 à moins de 184 MHz | O2 puis `/2` | `2F` |
| 184 à moins de 280 MHz | O1 puis `/2` | `2F` |
| 280 à moins de 368 MHz | O2 directe | `F` |
| 368 à moins de 560 MHz | O1 directe | `F` |

La coupure à 1,5 MHz ne change pas la synthèse : elle ajoute seulement D5 au
mot de l'adresse 5. Elle est explicitement présente dans l'EPROM mais pas dans
le tableau de principe simplifié.

L'option doubleur prolonge la sélection :

| Sortie `F` | Chemin | Fréquence oscillateur `Fs` |
| ---: | --- | ---: |
| 560 à moins de 736 MHz | O2 puis `X2` | `F/2` |
| 736 à moins de 1120 MHz | O1 puis `X2` | `F/2` |

À exactement 1120 MHz, l'EPROM passe au code `0x45`, qui appartient à une
autre extension de fréquence. Cette limite n'est donc pas incluse dans
l'encodeur du doubleur. De même, exactement 560 MHz sélectionne déjà `X2` ;
la fonction dédiée au 740A sans cette option s'arrête au pas précédent.

À partir de `Fs`, les formules du document de principe sont appliquées sans
approximation :

```text
N     = entier((Fs - 18 MHz) / 8 MHz)
Delta = (Fs - 18 MHz) modulo 8 MHz
A     = 5 x (18 MHz + Delta)
B     = A / N + 40 MHz
```

`N` reste compris entre 28 et 67. Le firmware stocke `B` sous forme exacte
avec le numérateur `A + N x 40 MHz` et le dénominateur `N`.

## Adresses 4 et 13 : codage de N

On décompose :

```text
N = 5n + m
n = entier(N / 5)
m = N modulo 5
codeN = (16 - n) << 3 | m
```

Le schéma du diviseur d'incréments confirme D0..D2 pour `m` et D3..D6 pour
`16 - n`. La plage complète donne `codeN = 0x5B` pour `N = 28` et `0x1A`
pour `N = 67`.

- adresse 4 D6..D0 : `codeN` ;
- adresse 13 D6..D0 : le même `codeN` ;
- adresse 13 D7 : inverse de l'adresse 12 D0.

Formule complète de l'adresse 13 :

```text
bus[13] = codeN | ((bus[12] & 1) ? 0x00 : 0x80)
```

Sur le 740A sans doubleur, l'adresse 4 D7 vaut toujours 1 :

```text
bus[4] = 0x80 | codeN
```

Avec le doubleur, D7 devient le bit de poursuite. L'EPROM le calcule à partir
des centaines de MHz et des deux chiffres MHz suivants de la fréquence
affichée. Les transitions sont :

| Centaine affichée | D7 = 1 dans les intervalles relatifs à la centaine |
| ---: | --- |
| 500 MHz | toute la partie utilisée, de 560 à moins de 600 MHz |
| 600 et 1000 MHz | `[00,04[`, `[44,84[` MHz |
| 700 et 1100 MHz | `[24,64[` MHz |
| 800 MHz | `[04,44[`, `[84,100[` MHz |
| 900 MHz | `[00,24[`, `[64,100[` MHz |

Dans les autres intervalles D7 vaut 0. Pour 1100 MHz, seule la partie
1100–1120 MHz du domaine doubleur est concernée, donc D7 y vaut 0.

## Adresse 5 : sélection du chemin RF

Le registre SN7 de la carte approche reçoit l'adresse 5. Les valeurs produites
par l'EPROM sont :

| Sortie | Adresse 5 | Bits fonctionnels |
| ---: | ---: | --- |
| 0,1 à moins de 1,5 MHz | `0x23` | basse fréquence + hétérodyne + O1 |
| 1,5 à moins de 122 MHz | `0x03` | hétérodyne + O1 |
| 122 à moins de 184 MHz | `0x04` | `/2` + O2 |
| 184 à moins de 280 MHz | `0x05` | `/2` + O1 |
| 280 à moins de 368 MHz | `0x08` | directe + O2 |
| 368 à moins de 560 MHz | `0x09` | directe + O1 |
| 560 à moins de 736 MHz | `0x10` | `X2` + O2 |
| 736 à moins de 1120 MHz | `0x11` | `X2` + O1 |

Décomposition démontrée :

| Bit | Fonction |
| ---: | --- |
| D0 | sélection O1 quand il vaut 1, O2 quand il vaut 0 |
| D1 | chemin hétérodyne |
| D2 | chemin `/2` |
| D3 | chemin direct |
| D4 | option `X2` |
| D5 | sous-gamme basse ; peut aussi être forcé par un état interne de la CPU |
| D6 | extension de fréquence supérieure, hors doubleur étudié |
| D7 | non utilisé par les valeurs de fréquence observées dans l'EPROM |

Les codes supérieurs à 1120 MHz présents dans l'EPROM ne sont pas intégrés :
ils utilisent D6 et combinent plusieurs chemins, mais les cartes optionnelles
correspondantes ne sont pas documentées dans le châssis disponible.

## Adresses 12 et 15

La sélection RF ne remplace pas tout le mot de l'adresse 12. Elle modifie le
masque `0x86`, en préservant D6..D3 et D0 :

| Chemin | Bits de gamme, masque `0x86` |
| --- | ---: |
| hétérodyne | `0x84` |
| `/2` | `0x00` |
| direct | `0x04` |
| `X2` | `0x02` |

```text
bus[12] = (ancien_bus12 & 0x79) | bits_de_gamme
```

L'adresse 15 est ensuite calculée depuis le mot complet de l'adresse 12 :

```text
bus[15] = (ancien_bus15 & 0x1F) | ((bus[12] & 0x0E) << 4)
```

Dans les balayages à 240–250 MHz, le chemin `/2` laisse `bus[12] = 0x01` et
le mot préservé donne `bus[15] = 0x1F`, exactement comme dans les traces.

## Adresse 6 et option impulsions

Le registre SN8 de la carte approche reçoit l'adresse 6. Le schéma donne :

| Bit | Sortie |
| ---: | --- |
| D7 | `+5 dB` |
| D6 | `Pulse` |
| D5, D4 | cellules `30` |
| D3, D2 | cellules `20` |
| D1 | cellule `10` |
| D0 | cellule `5` |

L'EPROM préserve D7 et D6 lorsqu'elle recalcule les six bits d'atténuation.
La commande `Pulse` est donc active à 1 et indépendante du niveau :

```text
actif   : bus[6] |= 0x40
inactif : bus[6] &= 0xBF
```

Les balayages RF contiennent `bus[6] = 0x2D`, donc D6 = 0, cohérent avec
l'absence de l'option impulsions dans l'appareil étudié. Le décodage complet
des six bits de niveau reste volontairement dans le lot « atténuateur ».

L'analyse complète de `SL 64` et `SL 60` montre aussi que l'option force D5 de
l'adresse 5. À la désactivation, il faut restaurer le mot du plan de fréquence
au lieu d'effacer D5 sans condition, car le chemin hétérodyne sous 1,5 MHz
utilise déjà `bus[5] = 0x23`. Voir
[`BUS_INSTRUMENTS_IMPULSIONS.md`](BUS_INSTRUMENTS_IMPULSIONS.md).

## Ordre des écritures et validation

Pour chaque changement de fréquence des balayages disponibles, l'ordre est :

```text
12, 15, 5, 11, 4, 13, 0, 1, 2, 3, 6, 8, 6
```

L'adresse 11 contient aussi `N` dans D6..D0 ; D7 dépend d'un état de
modulation et sera traité avec la carte analogique. En utilisant ce `N` comme
référence indépendante, les contrôles suivants sont exacts sur les 6 128
transactions :

- adresse 4 égale à `0x80 | codeN` ;
- adresse 5 égale à `0x05` dans la gamme 240–250 MHz ;
- adresse 13 D6..D0 égale à `codeN`.

Résultat : `6 128 / 6 128` transactions conformes. Les valeurs de doubleur et
de `Pulse` sont prouvées par l'EPROM et les schémas, mais ne peuvent pas être
confirmées électriquement sur cet appareil puisque les options sont absentes.

## Intégration firmware

`InstrumentFrequencyPlan` ajoute deux fonctions sans accès matériel :

```cpp
bool makeBaseFrequencyPlan(uint32_t outputFrequencyHz,
                           FrequencyPlan* plan);
bool makeDoublerFrequencyPlan(uint32_t outputFrequencyHz,
                              FrequencyPlan* plan);
```

Elles produisent `Fs`, `N`, `n`, `m`, `Delta`, `A`, le numérateur de `B`, les
adresses 4 et 5, les bits de gamme de l'adresse 12 et les sept bits de
l'adresse 13. Des fonctions séparées fusionnent ensuite les champs partagés
des adresses 6, 12, 13 et 15 sans écraser le niveau ou la modulation.

Ce module ne déclenche encore aucune écriture sur le MCP23017. Il reste donc
testable indépendamment du matériel et ne change pas le comportement courant
du firmware.
