# Schéma de la CPU de remplacement

Ce projet KiCad 10 documente le câblage du prototype Arduino Mega 2560,
ISO1540 et MCP23017 monté sur plaque à pastilles. Il ne contient volontairement
ni PCB ni empreintes.

Le même câblage et les mêmes numéros de broches s'appliquent à une Arduino
Mega 1280 ; les validations matérielles consignées ici ont toutefois été
effectuées avec le prototype Mega 2560.

Les faisceaux panneau–Mega, Mega–ISO1540–MCP23017 et MCP23017–B1 sont dessinés
fil à fil. Les symboles ISO1540 et MCP23017 reprennent les headers des
mini-plaquettes photographiées ; seules les alimentations multidrop utilisent
des étiquettes de net afin de préserver la lisibilité et l'isolation des deux
domaines.

## Fichiers

- `Adret740A_replacement_cpu.kicad_pro` et `.kicad_sch` : projet et schéma A3 ;
- `Adret740A.kicad_sym` et `sym-lib-table` : symboles locaux des modules ;
- `Adret740A_replacement_cpu.pdf` : rendu imprimable en noir et blanc ;
- `Adret740A_replacement_cpu.xml` : netlist KiCad XML auditée ;
- `erc.rpt` : dernier rapport ERC ;
- `generate_schematic.py` : génération déterministe des sources KiCad ;
- `validate_netlist.py` : contrôle des 38 nets matériels imposés.

## Régénération et vérification

Depuis la racine du dépôt :

```powershell
python hardware\Adret740A_replacement_cpu\generate_schematic.py

$env:KICAD_CONFIG_HOME = "$env:TEMP\adret-kicad-config"
$env:KICAD_DOCUMENTS_HOME = "$env:TEMP\adret-kicad-docs"
$sch = "hardware\Adret740A_replacement_cpu\Adret740A_replacement_cpu.kicad_sch"

& "C:\Program Files\KiCad\10.0\bin\kicad-cli.exe" sch erc `
    --severity-all --exit-code-violations `
    --output hardware\Adret740A_replacement_cpu\erc.rpt $sch

& "C:\Program Files\KiCad\10.0\bin\kicad-cli.exe" sch export pdf `
    --black-and-white `
    --output hardware\Adret740A_replacement_cpu\Adret740A_replacement_cpu.pdf $sch

& "C:\Program Files\KiCad\10.0\bin\kicad-cli.exe" sch export netlist `
    --format kicadxml `
    --output hardware\Adret740A_replacement_cpu\Adret740A_replacement_cpu.xml $sch

python hardware\Adret740A_replacement_cpu\validate_netlist.py
```

Le contrôle vérifie notamment la séparation de `GND_CPU` et `GND_INST`, la
liaison directe J1-5 vers B1-6, B1-7 vers Mega D3, le nouveau mapping inversé
du bus du panneau et les treize sorties MCP23017 vers B1.
