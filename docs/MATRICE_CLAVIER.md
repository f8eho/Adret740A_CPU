# Matrice du clavier du panneau avant

Cette table reprend la matrice du schéma `Adret 740A Panneau avant_schema.pdf`.
Elle décrit les codes lus dans le registre d'entrée `SN5`.

| Y \ X | X0 | X1 | X2 | X3 | X4 | X5 | X6 | X7 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Y5 | AMPL | — | — | — | — | — | — | ADR RTL |
| Y4 | RF | SPL | 0 | 5 | MHz | CW | ÷10 | MEM |
| Y3 | FM | X→Y | 1 | 6 | kHz | EXT | VALID MAN | SEQ |
| Y2 | PM | ← | 2 | 7 | Hz | 1kHz | ×10 | RAPPEL |
| Y1 | AM | CLEAR | 3 | 8 | dBm | 400Hz | EXEC | ↑ |
| Y0 | — | POINT | 4 | 9 | 1dBm | RF OFF | INC | ↓ |

## Codage de SN5

- `D0..D2` contiennent le code de colonne `X0..X7`.
- `D3..D5` contiennent le code de ligne `Y0..Y5`.
- Le signal panneau `D6` signale une impulsion de la roue codeuse. Avec le
  nouveau faisceau, il arrive sur `PA0` (`D22`), puis l'inversion logicielle le
  replace dans le bit normalisé 7.
- Le signal panneau `D7` donne le sens de la roue codeuse. Avec le nouveau
  faisceau, il arrive sur `PA1` (`D23`), puis l'inversion logicielle le replace
  dans le bit normalisé 6.
- `CA1` signale au CPU qu'un événement doit être lu dans `SN5`.

Après normalisation de `PINA`, le scan brut est donc décodé par :

```text
X = raw & 0x07
Y = (raw >> 3) & 0x07
```

Les lignes `Y6` et `Y7`, ainsi que les cases marquées `—`, ne correspondent à
aucune touche connue. Le firmware les classe comme `UNKNOWN` puis les ignore.

## Libellés série

Le mode de diagnostic peut envoyer une ligne par touche reconnue. Les codes inconnus sont
ignorés et deux événements identiques reçus à moins de 30 ms d'intervalle sont
filtrés comme rebonds :

```text
KEY raw=0x28 X=0 Y=5 label=AMPL
```

Les libellés sont courts et en ASCII : `AMPL`, `RF`, `FM`, `PM`, `AM`, `SPL`,
`X_TO_Y`, `KHZ`, `EXT`, `VALID`, `RECALL`, `CLEAR`, `RF_OFF`, `INC`, `UP`,
`DOWN`, etc.

## RF OFF, INHIB RF et INHIB

La touche appelée `RF OFF` sur le schéma porte le marquage `INHIB RF` sur la
sérigraphie du panneau. Ces deux noms désignent la même touche de la matrice et
concernent uniquement l'activation de la sortie RF.

Cette touche ne doit pas être confondue avec la ligne dédiée `INHIB` du
connecteur CPU, qui commande la mise en marche et l'arrêt de l'alimentation
générale de l'appareil.
