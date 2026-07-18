# Bus instruments : modulation d'impulsions

## Conclusion

L'option modulation d'impulsions n'utilise ni l'adresse 7 ni l'adresse 14.
Le logiciel d'origine modifie deux registres déjà employés par d'autres
fonctions :

| Registre | Bit | Fonction en mode impulsions | État actif |
| ---: | ---: | --- | ---: |
| adresse 5 | D5 (`0x20`) | prépare le chemin RF | 1 |
| adresse 6 | D6 (`0x40`) | sortie `Pulse` de la carte Approche | 1 |

L'état interne de la CPU d'origine est mémorisé dans `M8026` D1. Ce bit ne
correspond pas directement à une ligne du bus : la routine de programmation
le transforme en D6 de l'adresse 6 et maintient D5 de l'adresse 5.

Les adresses 7 et 14 doivent donc rester **non émises** tant qu'un nouveau
schéma ou une autre version d'EPROM ne leur attribue pas une fonction.

## Recoupement des sources

### EPROM

Les deux désassemblages ne contiennent aucun accès à `M6007`, `M600E`,
`M8507` ou `M850E`. Les symboles des ports utilisés sautent eux-mêmes les
adresses 7 et 14. Ce résultat exclut leur emploi par cette version du
programme, y compris pour les options absentes de l'appareil observé.

La routine correspondant à `SL 64`, dans `740a1.txt` aux offsets
`03FB..0452`, effectue les opérations suivantes :

1. teste `M800C` D4 et produit `E-64` si l'option n'est pas détectée ;
2. teste `M0048` D6 et produit `E-79` si cet état interne est actif ;
3. positionne D5 du mot mémorisé et écrit l'adresse 5 ;
4. positionne `M8026` D1 ;
5. annule les anciennes valeurs FM/PM puis relance la programmation générale.

La routine `SL 60`, aux offsets `03CB..03F8`, réalise l'opération inverse.
Elle ne supprime D5 de l'adresse 5 que lorsque ce bit n'est pas requis par le
chemin RF courant, efface l'état impulsions, puis relance elle aussi la
programmation générale.

Lors d'un changement de fréquence, la routine aux offsets `097A..0989`
réapplique D5 à l'adresse 5 tant que `M8026` D1 est actif. Dans la routine de
modulation, cet état aboutit à l'ajout de `0x40` au mot de l'adresse 6.

Le test `M800C` D4 est une détection de présence de l'option par l'interface
CPU ; ce n'est pas une lecture du bus instruments.

### Traces

Le comptage mécanique de toutes les lignes décodées du dossier
`Traces_bus_instruments/Out` donne 0 écriture à l'adresse binaire `0111` (7)
et 0 à l'adresse `1110` (14). L'adresse 6 apparaît 14 754 fois et D6 reste à
0 dans les 14 754 mots. C'est attendu puisque l'appareil ayant produit les
captures ne possède pas l'option. Les traces ne peuvent donc pas montrer
l'état actif, mais elles confirment sans exception sa valeur inactive.

### Schémas

La page 17, carte Approche, relie le registre SN8 de l'adresse 6 à la sortie
`Pulse` du connecteur 34. La page 53, commande du modulateur d'impulsions, ne
contient aucun registre raccordé directement au bus instruments : elle reçoit
des commandes discrètes, dont la commande de modulation AM et les bits `A` et
`F`. La page 33b montre ensuite le modulateur d'impulsions dans la chaîne VHF.

Le chemin fonctionnel retenu est donc :

```text
CPU -- adresse 6 D6 --> carte Approche, sortie Pulse
                         --> commande d'impulsions
                         --> modulateur d'impulsions VHF

CPU -- adresse 5 D5 --> sélection/préparation du chemin RF
```

## Activation et désactivation

À partir du plan de fréquence courant et de l'image courante de l'adresse 6 :

```text
activation   : bus[5] = plan_frequence[5] | 0x20
               bus[6] = ancien_bus[6]     | 0x40

désactivation: bus[5] = plan_frequence[5]
               bus[6] = ancien_bus[6]     & 0xBF
```

Il ne faut pas désactiver les impulsions avec un simple
`bus[5] &= 0xDF`. Sous 1,5 MHz, le plan hétérodyne normal vaut déjà `0x23` et
requiert donc D5 même lorsque les impulsions sont inactives. Le mot de
fréquence doit être restauré dans son ensemble.

Ces deux mots sont des images finales. L'EPROM relance une programmation de
fréquence/modulation complète après `SL 64` ou `SL 60`; le futur contrôleur de
bus devra les fusionner dans cette séquence plutôt que supposer qu'une paire
d'écritures isolée reproduit tout le comportement temporel d'origine.

## Compatibilités et codes d'erreur

- `SL 64` sans matériel optionnel : `E-64`, sans écriture d'activation ;
- AM, y compris avec une source AM active : compatible avec les impulsions ;
- demande FM ou PM alors que les impulsions sont actives : `E-74` dans
  l'EPROM et dans la documentation utilisateur ;
- `SL 60` : accepté même si l'option est absente ;
- l'EPROM peut produire `E-79` à l'activation lorsque `M0048` D6 est actif.

La signification de `E-79` n'apparaît pas dans la table d'erreurs du manuel
disponible. Son test exact est établi, mais son libellé reste donc non résolu.
Il ne faut pas lui inventer une signification dans le protocole de la nouvelle
CPU. L'API firmware emploie à la place un résultat interne explicite
`IncompatibleModulation`.

## Intégration firmware

`InstrumentPulse` expose un encodeur sans allocation qui :

- refuse l'activation si l'option est déclarée absente ;
- refuse l'activation lorsque la famille courante n'est pas AM ;
- accepte toujours la désactivation ;
- calcule les images finales des adresses 5 et 6 sans toucher aux autres bits.

Sur l'appareil actuel, le parseur série continue volontairement de retourner
`E-64` pour `SL 64`. L'encodeur réserve le comportement nécessaire pour une
future configuration équipée, sans prétendre que le matériel est présent.

## Niveau de confiance et validation restante

| Élément | Confiance | Validation restante |
| --- | --- | --- |
| adresse 6 D6 = `Pulse`, actif haut | élevée | mesure impossible sans option |
| adresse 5 D5 associé à l'activation | élevée | mesure impossible sans option |
| aucune utilisation EPROM des adresses 7/14 | élevée pour cette version | comparer une autre EPROM si disponible |
| détection option par `M800C` D4 | élevée | relever le câblage CPU si nécessaire |
| condition exacte de `E-79` | moyenne | identifier la sémantique de `M0048` D6 |
