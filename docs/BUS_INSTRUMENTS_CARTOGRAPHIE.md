# Bus instruments : cartographie consolidée

## Carte des adresses

Cette table consolide les schémas, les deux EPROM et toutes les captures
décodées. Le nombre d'écritures est le comptage mécanique de l'ensemble du
dossier `Traces_bus_instruments/Out`.

| Adr. | Écritures | Carte ou fonction | Contenu principal |
| ---: | ---: | --- | --- |
| 0 | 6 397 | « 20000 », registre 1 | unités de `C` en D7..D4 |
| 1 | 6 136 | « 20000 », registre 2 | centaines/dizaines de `C` en BCD |
| 2 | 6 133 | « 20000 », registre 3 | milliers de `C` en D3..D0 |
| 3 | 6 133 | « 80 » | `BCD(Q-178) XOR 0xFE` |
| 4 | 6 133 | Approche | code du diviseur `N`; D7 poursuite doubleur |
| 5 | 6 133 | Approche/VHF | sélection du chemin RF; D5 partagé avec Pulse |
| 6 | 14 754 | Approche/atténuateur | relais 5 dB, `Pulse`, commande `+5 dB` |
| 7 | 0 | non attribuée | aucune référence dans les EPROM |
| 8 | 6 986 | carte analogique | atténuation fine 0,1/1 dB corrigée |
| 9 | 1 156 | carte analogique | deux chiffres faibles de modulation en BCD |
| 10 | 1 145 | carte analogique | deux chiffres forts, mode et source |
| 11 | 7 278 | correction FM | `N` binaire; transitoirement `N|0x80` |
| 12 | 7 278 | FM/PM, source et gamme RF | champs partagés fréquence/modulation |
| 13 | 7 278 | diviseur d'incréments | code `N`; D7 complément de l'adresse 12 D0 |
| 14 | 0 | non attribuée | aucune référence dans les EPROM |
| 15 | 6 133 | compatibilité/extension | D7..D5 dérivés de l'adresse 12 |

Les adresses 7 et 14 ne doivent pas être employées comme commandes de test
sur un appareil assemblé. L'adresse 15 reste émise dans la séquence de
fréquence parce que l'EPROM l'écrit systématiquement, même si aucun récepteur
n'est identifié sur le châssis standard étudié.

## Champs partagés

Les adresses suivantes ne peuvent pas être calculées par un seul module :

- adresse 5 : chemin RF, doubleur et activation des impulsions ;
- adresse 6 : atténuateur, plage `+5 dB`, interaction AM et impulsions ;
- adresse 12 : gamme RF, gamme FM/PM et source de modulation ;
- adresse 13 : diviseur de fréquence et état de l'adresse 12 D0 ;
- adresse 15 : ancienne valeur basse et champs dérivés de l'adresse 12.

Le contrôleur devra donc conserver une image des seize registres et fusionner
les masques, plutôt que demander à chaque encodeur de produire un octet
complet indépendamment des autres.

## Plages démontrées

| Fonction | Domaine pris en charge | Réserve |
| --- | --- | --- |
| fréquence standard | 100 kHz à 560 MHz inclus, résolution de commande 10 Hz | 560 MHz reste direct O1 sans doubleur |
| doubleur optionnel | 560 MHz à moins de 1 120 MHz, résolution de commande 10 Hz | logique validée hors matériel |
| point A/adresses 0..3 | 90 à 129,999975 MHz, pas de 25 Hz | diviseurs impairs codés par adresse 0 D3 |
| diviseur `N` | 28 à 67 | plage complète |
| niveau | -129,9 à +13,0 dBm | calibration encore nulle |
| AM | 0 à 99,9 %, pas de 0,1 % | restrictions de niveau à appliquer |
| FM | 0 à 199,9 kHz encodés | code exact de 200 kHz non résolu |
| PM | 0 à 19,99 rad, pas de 0,01 rad | déduite de l'EPROM, sans capture |
| impulsions | inactif/actif avec AM | option absente, pas de mesure active |

## Séquences connues

Une reprogrammation RF observée suit :

```text
12, 15, 5, 11, 4, 13, 0, 1, 2, 3, 6, 8, 6
```

Le niveau seul suit `6, 8, 6`. La modulation suit `9, 10, 12, 13, 11, 6`,
avec une écriture préalable supplémentaire à l'adresse 6 pour l'AM. Ces
séquences seront composées au niveau contrôleur ; le pilote physique ne reçoit
que des couples `(adresse, valeur)`.
