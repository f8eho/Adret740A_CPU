# Modulations AM, FM et PM : adresses 6 et 9 à 13

## Résultat

Les mots de modulation et leur ordre d'émission sont déterminés pour l'AM et
la FM à partir des captures. La PM utilise le même DAC BCD ; son code de gamme
est démontré par l'EPROM et le schéma, mais aucune capture PM n'est disponible.

L'encodeur est implémenté dans `InstrumentModulation.h/.cpp`. Il produit une
liste fixe, sans allocation dynamique :

```text
AM : 6, 9, 10, 12, 13, 11, 6
FM :    9, 10, 12, 13, 11, 6
PM :    9, 10, 12, 13, 11, 6
```

## Sources

- les six captures `Modulation AM...` et `Modulation FM...` ;
- les schémas analogique page 46 et FM page 48 ;
- le schéma du diviseur d'incréments page 44 ;
- les images et désassemblages locaux dans `docs/eeprom_740A/` ;
- la routine EPROM principale `EBF8..ED70` ;
- la routine de commande de niveau `CC7E..CC9E` ;
- le manuel utilisateur pour les plages et les avertissements de dépassement.

## Valeur numérique : adresses 9 et 10

Le DAC reçoit quatre chiffres décimaux, limités à `0000..1999`.
Pour une grandeur entière `V` dans l'unité propre au mode :

```text
adresse9 = BCD(V % 100)
majeur   = V / 100                 // 0 à 19

adresse10 D3..D0 = majeur % 10
adresse10 D4     = 1 si majeur < 10, sinon 0
```

D4 est donc le complément du chiffre des dizaines. Les bits hauts restants
dépendent du mode et de la source :

| Mode/source active | Majeur 0..9 | Majeur 10..19 |
|---|---:|---:|
| CW, quel que soit le mode mémorisé | `1x` | `0x` |
| AM externe | `Dx` | `Cx` |
| AM 1 kHz ou 400 Hz | `Fx` | `Ex` |
| FM/PM externe | `9x` | `8x` |
| FM/PM 1 kHz ou 400 Hz | `Bx` | `Ax` |

`x` est le chiffre des unités du champ majeur. Les deux sources internes ont
le même code à l'adresse 10 ; elles sont distinguées par l'adresse 12.

Les unités de `V` sont :

| Mode | Valeur utilisateur | `V` | Résolution |
|---|---:|---:|---:|
| AM | 0 à 99,9 % | dixièmes de % | 0,1 % |
| PM | 0 à 19,99 rad | centièmes de rad | 0,01 rad |
| FM basse | 0 à moins de 20 kHz | déviation en Hz / 10 | 10 Hz |
| FM haute | 20 à 199,9 kHz | déviation en Hz / 100 | 100 Hz |

Le manuel annonce 200 kHz. Le DAC ne contient que quatre chiffres jusqu'à
`1999` et aucune capture ne montre le code de 200 kHz. L'encodeur refuse donc
provisoirement cette valeur exacte plutôt que d'inventer un repli ou un code
de saturation. Ce point devra être capturé avec l'ancienne CPU ou vérifié au
banc.

## Commandes de mode et de source : adresse 12

La partie fréquence de l'adresse 12 est notée `R` et vaut le champ déjà
déterminé par `FrequencyPlan`, masqué par `0x86`. Les compléments sont :

| Mode | CW | Externe | 1 kHz | 400 Hz |
|---|---:|---:|---:|---:|
| AM | `R|01` | `R|01` | `R|61` | `R|41` |
| FM 0..19,99 kHz | `R|01` | `R|10` | `R|70` | `R|50` |
| FM 20..199,9 kHz | `R|01` | `R|08` | `R|68` | `R|48` |
| PM | `R|01` | `R|18` | `R|78` | `R|58` |

Interprétation des bits hors gamme RF :

- D6/D5 sélectionnent les oscillateurs internes 400 Hz et 1 kHz ;
- D4/D3 sélectionnent la gamme FM basse, la gamme FM haute ou la PM ;
- D0 vaut 1 en AM et en CW, et 0 en FM/PM actives.

La source externe n'ajoute aucun bit de source à l'adresse 12. Elle reste
distinguée du CW par D7/D6 de l'adresse 10 et, en FM/PM, par les bits de gamme.

## Adresses 13 et 11

L'adresse 13 conserve dans D6..D0 le code du diviseur d'incréments déjà calculé
par le plan de fréquence. D7 est le complément de l'adresse 12 D0 :

```text
adresse13 = codeN | ((adresse12 & 1) ? 0x00 : 0x80)
```

La routine EPROM convertit le `N` BCD en binaire avant d'écrire l'adresse 11.
La valeur finale d'une transaction de modulation est donc :

```text
adresse11 = N                  // 28 à 67, D7 à zéro
```

Lors d'une reprogrammation de fréquence, l'ancienne CPU écrit d'abord une
valeur transitoire `N|0x80`, puis la transaction de modulation réécrit `N`.
Cette séquence est visible au démarrage avec `B9`, puis `39`, pour `N=57`.

## Interaction AM avec le niveau : adresse 6 D7

La dernière écriture à l'adresse 6 appelle la même décision que le réglage de
niveau. D7 est actif seulement sur le chemin hétérodyne, adresse 5 D1 à 1, si
au moins une de ces conditions est vraie :

- le niveau utilise la plage haute, à partir de `+7,0 dBm` ;
- une source AM autre que CW est active.

D6 (`Pulse`) et les six bits de relais sont préservés. L'AM effectue aussi une
première écriture de l'adresse 6 avant les mots BCD, ce qui explique l'ordre à
sept écritures des captures.

## Validation des captures

Les six fichiers décodés donnent :

| Capture | Écritures identiques |
|---|---:|
| AM, pas de 0,1 % | 3 500 / 3 500 |
| AM, pas de 1 % | 350 / 350 |
| AM, 1 kHz / 400 Hz / CW | 21 / 21 |
| FM, pas de 10 Hz | 3 000 / 3 000 |
| FM, pas de 100 Hz | 300 / 300 |
| FM, deux gammes jusqu'à 190 kHz | 222 / 222 |
| **Total** | **7 393 / 7 393** |

Les captures ont été faites à 240 MHz : `R=0`, `N=57`, code d'adresse 13
`2A`, adresse 5 `05`. Les champs partagés sont cependant calculés depuis le
`FrequencyPlan`, et non figés à ces valeurs.

## PM : déduction et vecteurs de contrôle

La branche PM de l'EPROM ajoute `0x18` à l'adresse 12. Le schéma commute alors
les voies FM/PM et le filtre actif. Pour 240 MHz, `3,14 rad` donne par exemple :

| Source | A9 | A10 | A12 | A13 | A11 |
|---|---:|---:|---:|---:|---:|
| externe | `14` | `93` | `18` | `AA` | `39` |
| 1 kHz | `14` | `B3` | `78` | `AA` | `39` |
| 400 Hz | `14` | `B3` | `58` | `AA` | `39` |
| CW | `14` | `13` | `01` | `2A` | `39` |

Ces vecteurs sont une transcription directe du programme original, mais ils
restent à confirmer avec une capture PM ou sur l'appareil.

## Limites et avertissements AM

Le manuel ne bloque pas l'AM dans les cas suivants, mais allume le voyant de
dépassement :

- fréquence RF inférieure à 1,5 MHz : spécifications AM dégradées ;
- niveau RF supérieur ou égal à `+7 dBm` avec AM programmée : risque de
  distorsion.

Ces états devront devenir des avertissements du contrôleur et non des erreurs
de l'encodeur de bus.
