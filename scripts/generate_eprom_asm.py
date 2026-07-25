#!/usr/bin/env python3
"""Generate the annotated 6802 sources for the two original ADRET 740A ROMs.

The historical f9dasm listings were made with ORG $0000.  They are useful for
instruction spelling but not authoritative for code/data boundaries.  This
script relocates them to their physical addresses, follows control flow from
the 6802 vectors, fixes the two known split-instruction entry points, emits
unreached bytes as data, and checks that every emitted byte still matches the
EPROM dump.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
EPROM_DIR = ROOT / "docs" / "eeprom_740A"


@dataclass(frozen=True)
class Record:
    address: int
    mnemonic: str
    operand: str
    data: bytes


LISTING_RE = re.compile(
    r"^(?:(\w+)\s+)?\s*([A-Z][A-Z0-9]*)\s*(.*?)\s*;"
    r"([0-9A-F]{4}):\s*((?:[0-9A-F]{2} ?)+)"
)
MEMORY_RE = re.compile(r"\bM([0-9A-F]{4})\b")
CODE_RE = re.compile(r"\bZ([0-9A-F]{4})\b")
BYTE_COMMENT_RE = re.compile(
    r";\s*@\s*([0-9A-F]{4}):\s*((?:[0-9A-F]{2} ?)+)\s*$"
)


ROM_SPECS = (
    ("740a2.txt", "740A-2.BIN", "740A-2.asm", 0xC000, 0xDFFF),
    ("740a1.txt", "740A-1.BIN", "740A-1.asm", 0xE000, 0xFFFF),
)

CONDITIONAL_BRANCHES = {
    "BCC", "BCS", "BEQ", "BGE", "BGT", "BHI", "BLE", "BLS",
    "BLT", "BMI", "BNE", "BPL", "BVC", "BVS",
}
STOP_MNEMONICS = {"RTS", "RTI", "SWI", "WAI"}


KNOWN_CODE_NAMES = {
    0xC2CF: "sub_restore_stack_and_copy",
    0xC33F: "reset_entry",
    0xCC7E: "update_instrument_address_6_control_bits",
    0xCC9F: "irq_swi_front_panel_handler",
    0xE1DE: "nmi_power_fail_handler",
    0xE75F: "program_frequency_plan",
    0xEBF8: "program_modulation",
    0xED74: "program_rf_level",
    0xEF6D: "write_fine_attenuation_address_8",
    0xF08F: "resume_front_panel_dispatch",
}

KNOWN_DATA_NAMES = {
    0xC000: "table_exponential_0p1_db",
    0xC1F6: "attenuator_relay_table_bcd",
    0xFFF8: "hardware_vectors",
}

INSTRUMENT_NAMES = {
    0: "SYNTH_20000_UNITS",
    1: "SYNTH_20000_HUNDREDS_TENS",
    2: "SYNTH_20000_THOUSANDS",
    3: "SYNTH_80_DIVIDER",
    4: "APPROACH_DIVIDER_N",
    5: "RF_PATH_AND_PULSE",
    6: "ATTENUATOR_AND_PULSE",
    7: "UNASSIGNED",
    8: "FINE_ATTENUATION",
    9: "MODULATION_BCD_LOW",
    10: "MODULATION_BCD_HIGH_MODE",
    11: "FM_CORRECTION_N",
    12: "RF_RANGE_MODULATION_SOURCE",
    13: "INCREMENT_DIVIDER",
    14: "UNASSIGNED",
    15: "RANGE_EXTENSION",
}

SPECIAL_MEMORY_NAMES = {
    0x2000: "GPIB_REG_0",
    0x2001: "GPIB_REG_1",
    0x2002: "GPIB_REG_2",
    0x2003: "GPIB_REG_3",
    0x4000: "PIA_PORT_A_OR_DDRA",
    0x4001: "PIA_CONTROL_A",
    0x4002: "PIA_PORT_B_OR_DDRB",
    0x4003: "PIA_CONTROL_B",
    0x4004: "PIA_PORT_A_OR_DDRA_MIRROR",
    0x4005: "PIA_CONTROL_A_MIRROR",
    0x4006: "PIA_PORT_B_OR_DDRB_MIRROR",
    0x4007: "PIA_CONTROL_B_MIRROR",
    0x800C: "RAM_OPTION_PRESENCE_FLAGS",
    0x8026: "RAM_MODE_FLAGS_PULSE_D1",
}

for _address in range(16):
    SPECIAL_MEMORY_NAMES[0x6000 + _address] = (
        f"INST_{_address:02d}_{INSTRUMENT_NAMES[_address]}"
    )


MANUAL_HEADERS = {
    0xC2CF: (
        "DÉDUIT — restauration temporaire de pile et copie avec somme de contrôle.",
        "Entrées : X et B sont préparés par l'appelant C42C; la RAM directe $005E..$0061 décrit la copie.",
        "Sorties : A reflète la somme/état calculé; la destination pointée est mise à jour.",
        "Registres/flags : pile S remplacée provisoirement, A/B/X et indicateurs modifiés.",
        "RAM/E/S : pile sauvegardée en RAM $8000; aucune écriture directe sur le bus instruments.",
        "Algorithme : bascule sur une pile de travail, dépile les octets, les copie et accumule leur somme.",
    ),
    0xC33F: (
        "CONFIRMÉ — point d'entrée RESET du 6802.",
        "Entrées : aucune; interruptions masquées dès la première instruction.",
        "Sorties : PIA, interface distante, images RAM et état initial du bus instruments initialisés.",
        "Registres/flags : A, B, X, S et CCR modifiés; l'exécution rejoint ensuite la boucle principale.",
        "RAM/E/S : PIA $4000, GPIB $2000, bus instruments $6000..$600F et RAM $8000/$8500.",
        "Algorithme : impose d'abord un état RF sûr (adresse 6 à zéro), initialise les périphériques, les sentinelles et les images de configuration.",
    ),
    0xCC7E: (
        "CONFIRMÉ — finalisation et émission du mot de l'adresse instrument 6.",
        "Entrées : images de niveau/modulation en RAM $8505, $8506, $850A et $854A.",
        "Sorties : image $8506 et registre instrument 6 mis à jour.",
        "Registres/flags : A et B modifiés; X inchangé.",
        "RAM/E/S : écrit $6006; préserve D6 Pulse, recalcule D7 (+5 dB/AM) et conserve D5..D0.",
        "Algorithme : teste le chemin RF et les états niveau/AM avant d'ajouter éventuellement D7.",
    ),
    0xCC9F: (
        "CONFIRMÉ — gestionnaire commun IRQ et SWI, principalement panneau avant.",
        "Entrées : événement signalé par le PIA 6821; contexte processeur empilé par le 6802.",
        "Sorties : événement clavier/roue décodé, mémoires d'affichage et états de commande mis à jour.",
        "Registres/flags : contexte interrompu manipulé puis restauré par RTI dans les branches terminales.",
        "RAM/E/S : lit les ports/contrôles PIA $4000..$4007 et touche les images RAM $8000/$8C00.",
        "Algorithme : attend la fin d'un état transitoire du port A, distingue les causes CA/CB puis distribue clavier, roue et temporisations.",
    ),
    0xE1DE: (
        "CONFIRMÉ — gestionnaire NMI de perte de présence alimentation.",
        "Entrées : front de chute PA câblé directement sur NMI; contexte empilé matériellement.",
        "Sorties : état utile préparé/sauvegardé avant disparition de l'alimentation.",
        "Registres/flags : A, B, X et pile modifiés; la routine suit une voie dédiée de sauvegarde.",
        "RAM/E/S : exploite les signatures RAM ($8041 vaut normalement $AA/$55) et la zone non volatile associée.",
        "Algorithme : vérifie l'intégrité de l'état, prépare les pointeurs et recopie les groupes de paramètres à conserver.",
    ),
    0xE75F: (
        "CONFIRMÉ — calcul et programmation du plan de fréquence.",
        "Entrées : fréquence demandée sous forme BCD dans la zone de travail $8500/$851x.",
        "Sorties : séquence des adresses instruments 12, 15, 5, 11, 4, 13 puis 0..3.",
        "Registres/flags : A, B, X, S et CCR modifiés; pile de travail utilisée pour les chiffres BCD.",
        "RAM/E/S : images $8500..$8565 et registres $6000..$600F.",
        "Algorithme : choisit gamme directe/divisée/hétérodyne, calcule N=28..67, le reste de 8 MHz et les diviseurs 20000/80.",
    ),
    0xEBF8: (
        "CONFIRMÉ — composition et programmation AM/FM/PM.",
        "Entrées : valeur BCD, mode et source dans $005E..$0060 et images $8013/$8014/$8026.",
        "Sorties : écrit les adresses 9, 10, 12, 13, 11 et 6; l'AM peut écrire 6 une première fois.",
        "Registres/flags : A, B et X modifiés; interruptions masquées pendant la transaction.",
        "RAM/E/S : images $8500..$8542/$8529 et bus instruments $6006/$6009..$600D.",
        "Algorithme : code quatre chiffres BCD, fusionne gamme/source avec la gamme RF et applique l'interaction AM/+5 dB/Pulse.",
    ),
    0xED74: (
        "CONFIRMÉ — calcul et programmation du niveau RF.",
        "Entrées : niveau demandé en BCD dans $005E..$0060; $FF est la sentinelle RF OFF.",
        "Sorties : séquence adresse 6, adresse 8, adresse 6 et images de niveau actualisées.",
        "Registres/flags : A, B et X modifiés; calculs décimaux via DAA.",
        "RAM/E/S : table BCD $C1F6, travail $8543..$8561, registres instruments $6006/$6008.",
        "Algorithme : décompose le niveau en pas mécaniques de 5 dB et atténuation fine, applique la table de relais puis recalcule D7.",
    ),
    0xEF6D: (
        "CONFIRMÉ — étape d'émission de l'atténuation fine au sein du réglage de niveau.",
        "Entrées : A contient le code de l'adresse 8 après permutation des poids 4/8 dB et correction BCD.",
        "Sorties : registre instrument 8 chargé; la routine enchaîne sur la finalisation de l'adresse 6.",
        "Registres/flags : A conservé par l'écriture, B sert à la courte temporisation qui suit.",
        "RAM/E/S : écrit $6008 puis appelle $CC7E pour D7 (+5 dB/AM) et D6 (Pulse).",
        "Algorithme : émet le DAC fin, attend l'établissement matériel et réémet l'image finale de l'atténuateur.",
    ),
    0xF08F: (
        "DÉDUIT — reprise correctement alignée du distributeur panneau avant.",
        "Entrées : A contient le code lu; $8047 sélectionne une voie de traitement.",
        "Sorties : branche vers le gestionnaire correspondant au caractère/événement.",
        "Registres/flags : A/B/X et CCR modifiés selon la branche.",
        "RAM/E/S : RAM directe $006D et tables de pointeurs voisines de $F077.",
        "Algorithme : filtre espace, LF, CR et '?', puis indexe une table de vecteurs.",
    ),
}


def parse_listings() -> dict[int, Record]:
    records: dict[int, Record] = {}
    for listing_name, _, _, base, _ in ROM_SPECS:
        for line in (EPROM_DIR / listing_name).read_text(encoding="latin-1").splitlines():
            match = LISTING_RE.match(line)
            if not match:
                continue
            _, mnemonic, operand, offset, hex_bytes = match.groups()
            address = base + int(offset, 16)
            records[address] = Record(
                address, mnemonic, operand.strip(), bytes.fromhex(hex_bytes)
            )

    # f9dasm started at zero and consequently swallowed these genuine entry
    # points as operand bytes of fictitious preceding instructions.
    records[0xC2CF] = Record(0xC2CF, "SEI", "", bytes([0x0F]))
    records[0xF08F] = Record(0xF08F, "LDAB", "M8047", bytes([0xF6, 0x80, 0x47]))
    # The final opcode byte of 740A-2 takes its two-byte operand from the start
    # of 740A-1.  f9dasm processed both files separately and invented $0101.
    records[0xDFFF] = Record(0xDFFF, "STX", "M800A", bytes([0xFF, 0x80, 0x0A]))
    return records


def target_of(record: Record) -> int | None:
    data = record.data
    if record.mnemonic in CONDITIONAL_BRANCHES | {"BRA", "BSR"}:
        displacement = data[-1] - 0x100 if data[-1] & 0x80 else data[-1]
        return (record.address + len(data) + displacement) & 0xFFFF
    if record.mnemonic in {"JMP", "JSR"} and data[0] in {0x7E, 0xBD}:
        return (data[-2] << 8) | data[-1]
    return None


def discover_code(records: dict[int, Record]) -> tuple[set[int], set[int], set[int]]:
    routine_entries = set(KNOWN_CODE_NAMES)
    queue = list(routine_entries)
    code: set[int] = set()
    labels = set(routine_entries)

    while queue:
        address = queue.pop()
        while address in records and address not in code:
            record = records[address]
            if record.mnemonic in {"FCB", "FDB", "FCC", "ORG", "END", "EQU"}:
                break
            code.add(address)
            next_address = address + len(record.data)
            target = target_of(record)
            if target is not None:
                labels.add(target)
                queue.append(target)
                if record.mnemonic in {"JSR", "BSR"}:
                    routine_entries.add(target)
            if record.mnemonic == "BRA" or record.mnemonic == "JMP":
                break
            if record.mnemonic in STOP_MNEMONICS:
                break
            address = next_address

    return code, labels, routine_entries


def memory_symbol(address: int, code: set[int], routine_entries: set[int]) -> str:
    if address in SPECIAL_MEMORY_NAMES:
        return SPECIAL_MEMORY_NAMES[address]
    if address in KNOWN_DATA_NAMES:
        return KNOWN_DATA_NAMES[address]
    if address in KNOWN_CODE_NAMES or address in code:
        return code_label(address, routine_entries)
    if address < 0x100:
        return f"DP_{address:04X}"
    if 0x8000 <= address <= 0xAFFF:
        return f"RAM_{address:04X}"
    if 0xC000 <= address <= 0xFFFF:
        return f"ROM_DATA_{address:04X}"
    return f"MEM_{address:04X}"


def code_label(address: int, routine_entries: set[int]) -> str:
    if address in KNOWN_CODE_NAMES:
        return KNOWN_CODE_NAMES[address]
    prefix = "sub" if address in routine_entries else "loc"
    return f"{prefix}_{address:04X}"


def rewrite_operand(record: Record, code: set[int], routine_entries: set[int]) -> str:
    target = target_of(record)
    if target is not None:
        return code_label(target, routine_entries)

    operand = record.operand

    def replace_memory(match: re.Match[str]) -> str:
        return memory_symbol(int(match.group(1), 16), code, routine_entries)

    def replace_code(match: re.Match[str]) -> str:
        raw = int(match.group(1), 16)
        if raw < 0x4000:
            base = 0xE000 if record.address >= 0xE000 else 0xC000
            raw = (base + raw) & 0xFFFF
        return code_label(raw, routine_entries)

    operand = MEMORY_RE.sub(replace_memory, operand)
    operand = CODE_RE.sub(replace_code, operand)
    return operand


def inline_comment(record: Record, operand: str) -> str:
    mnemonic = record.mnemonic
    if "INST_" in operand:
        match = re.search(r"INST_(\d\d)_([A-Z0-9_]+)", operand)
        if match:
            address = int(match.group(1))
            action = "émet" if mnemonic.startswith("ST") else "relit l'image de"
            return f"{action} l'adresse instrument {address} ({match.group(2).lower().replace('_', ' ')})"
    if "PIA_" in operand:
        return "accès au PIA 6821 du panneau avant"
    if "GPIB_" in operand:
        return "accès à l'interface distante IEEE-488"
    if mnemonic == "DAA":
        return "ajuste A après une opération arithmétique BCD"
    if mnemonic == "SEI":
        return "masque les IRQ pendant la section critique"
    if mnemonic == "CLI":
        return "autorise à nouveau les IRQ"
    if mnemonic in {"JSR", "BSR"}:
        return f"appelle {operand}"
    if mnemonic == "JMP":
        return f"transfert sans retour vers {operand}"
    if mnemonic in CONDITIONAL_BRANCHES:
        return f"branche vers {operand} si la condition {mnemonic[1:]} est vraie"
    if mnemonic == "BRA":
        return f"branche toujours vers {operand}"
    if mnemonic in {"ANDA", "ANDB", "ORAA", "ORAB", "BITA", "BITB"} and "#$" in operand:
        return "masque/teste un champ de bits; voir le commentaire de routine"
    return ""


def byte_comment(address: int, data: bytes) -> str:
    return f"; @ {address:04X}: {' '.join(f'{byte:02X}' for byte in data)}"


def emit_header(output_name: str, binary_name: str, start: int, end: int, digest: str) -> list[str]:
    return [
        "; ============================================================================",
        f"; ADRET 740A — source commentée de {binary_name}",
        "; Processeur : Motorola 6802 — syntaxe assembleur Motorola classique",
        f"; Implantation physique : ${start:04X}..${end:04X} (8192 octets)",
        f"; SHA-256 de référence : {digest}",
        ";",
        "; Niveaux de preuve employés :",
        ";   CONFIRMÉ  : établi par le binaire et les schémas/captures/documentation.",
        ";   DÉDUIT    : conséquence forte du flot de contrôle et des données connues.",
        ";   HYPOTHÈSE : interprétation plausible restant à confirmer au banc.",
        ";   INCONNU   : rôle non attribué; le nom reste volontairement neutre.",
        ";",
        "; Cartographie utile confirmée ou directement visible sur le schéma CPU :",
        ";   $0000..$00FF  page directe et variables de travail du 6802",
        ";   $2000..$2003  interface distante/GPIB (registres utilisés au RESET)",
        ";   $4000..$4007  PIA 6821 du panneau avant et miroirs de décodage",
        ";   $6000..$600F  seize registres du bus instruments (adresse = poids faible)",
        ";   $8000..$Axxx  RAM et miroirs matériels; images de configuration en $85xx",
        ";   $C000..$DFFF  EPROM 740A-2; $E000..$FFFF EPROM 740A-1",
        ";",
        "; Chaque ligne porte ses octets d'origine sous la forme '; @ AAAA: XX ...'.",
        "; Ils constituent aussi la preuve mécanique de couverture et de fidélité.",
        "; ============================================================================",
        "",
        f"        ORG     ${start:04X}",
        "",
    ]


def collect_used_memory(records: dict[int, Record], code_subset: set[int]) -> set[int]:
    result: set[int] = set()
    for address in code_subset:
        for match in MEMORY_RE.finditer(records[address].operand):
            result.add(int(match.group(1), 16))
    return result


def emit_equates(
    used: set[int],
    external_code: set[int],
    code: set[int],
    routine_entries: set[int],
    base: int,
    end: int,
) -> list[str]:
    lines = [
        "; ---------------------------------------------------------------------------",
        "; Symboles mémoire et périphériques effectivement employés dans cette EPROM",
        "; ---------------------------------------------------------------------------",
    ]
    by_symbol = sorted(
        (memory_symbol(address, code, routine_entries), address) for address in used
    )
    for symbol, address in by_symbol:
        # Symbols materialized as labels in this file must not also be EQU.
        if base <= address <= end and (
            address in code or address in KNOWN_DATA_NAMES
        ):
            continue
        lines.append(f"{symbol:<40} EQU     ${address:04X}")
    for address in sorted(external_code):
        symbol = code_label(address, routine_entries)
        if base <= address <= end and address in code:
            continue
        lines.append(f"{symbol:<40} EQU     ${address:04X}")
    lines.append("")
    return lines


def callers_and_callees(records: dict[int, Record], code: set[int]) -> tuple[dict[int, set[int]], dict[int, set[int]]]:
    callers: dict[int, set[int]] = {}
    callees: dict[int, set[int]] = {}
    for address in code:
        record = records[address]
        if record.mnemonic not in {"JSR", "BSR"}:
            continue
        target = target_of(record)
        if target is None:
            continue
        callers.setdefault(target, set()).add(address)
        callees.setdefault(address, set()).add(target)
    return callers, callees


def generic_routine_header(address: int, callers: dict[int, set[int]]) -> tuple[str, ...]:
    caller_text = ", ".join(f"${item:04X}" for item in sorted(callers.get(address, ()))) or "entrée indirecte ou appelant non identifié"
    return (
        f"INCONNU — sous-routine interne à ${address:04X}; rôle métier non démontré.",
        "Entrées : contrat non établi; A, B ou X peuvent porter des paramètres.",
        "Sorties : contrat non établi; examiner les branches de retour et les appelants.",
        "Registres/flags : seules les instructions ci-dessous font foi; aucune convention ABI supposée.",
        "RAM/E/S : les symboles explicites du corps indiquent les zones réellement touchées.",
        f"Appelants observés : {caller_text}. Algorithme conservé sans interprétation fonctionnelle forcée.",
    )


def emit_routine_header(address: int, callers: dict[int, set[int]]) -> list[str]:
    details = MANUAL_HEADERS.get(address, generic_routine_header(address, callers))
    lines = [
        "",
        "; ---------------------------------------------------------------------------",
        f"; ROUTINE ${address:04X} — {code_label(address, {address})}",
    ]
    lines.extend(f"; {detail}" for detail in details)
    lines.append("; ---------------------------------------------------------------------------")
    return lines


def data_label(address: int) -> str:
    return KNOWN_DATA_NAMES.get(address, f"ROM_DATA_{address:04X}")


def emit_attenuator_table(binary: bytes, base: int) -> list[str]:
    start = 0xC1F6
    offset = start - base
    lines = [
        "",
        "; ---------------------------------------------------------------------------",
        "; CONFIRMÉ — table des relais de l'atténuateur, indexée par un compteur BCD.",
        "; Un index valide représente le nombre de pas mécaniques de 5 dB :",
        "; $00..$09, $10..$19 puis $20..$27. Les six positions $0A..$0F et",
        "; $1A..$1F sont des trous BCD à zéro, et non du code 6802.",
        "; Les valeurs utiles D5..D0 correspondent à la table documentée dans",
        "; BUS_INSTRUMENTS_NIVEAU_RF.md; D7/D6 sont fusionnés séparément.",
        "; ---------------------------------------------------------------------------",
        f"{data_label(start)}:",
    ]
    for relative in range(0, 40, 8):
        chunk = binary[offset + relative:offset + relative + 8]
        address = start + relative
        index_start = relative
        index_end = relative + len(chunk) - 1
        values = ",".join(f"${byte:02X}" for byte in chunk)
        lines.append(
            f"        FCB     {values:<39} ; indices BCD ${index_start:02X}..${index_end:02X} {byte_comment(address, chunk)}"
        )
    return lines


def emit_exponential_table(binary: bytes, base: int) -> list[str]:
    start = 0xC000
    byte_length = 0x1F6
    offset = start - base
    lines = [
        "; ---------------------------------------------------------------------------",
        "; DÉDUIT — table exponentielle de 251 mots 16 bits big-endian.",
        "; Index : 0..250, très probablement un pas de 0,1 dB sur 0..25,0 dB.",
        "; Valeur : arrondi d'environ 141 * 10^(index/200), de 141 à 2510.",
        "; Cette loi est celle d'un rapport d'amplitude exprimé en décibels.",
        "; Le consommateur exact et l'échelle 141 restent à confirmer; aucune unité",
        "; supplémentaire n'est inventée. Le f9dasm d'origine prenait ces mots pour",
        "; une longue suite d'opcodes 6802 désalignés.",
        "; ---------------------------------------------------------------------------",
        f"{data_label(start)}:",
    ]
    for relative in range(0, byte_length, 8):
        chunk = binary[offset + relative:offset + min(relative + 8, byte_length)]
        values = [
            int.from_bytes(chunk[index:index + 2], "big")
            for index in range(0, len(chunk), 2)
        ]
        operands = ",".join(f"${value:04X}" for value in values)
        first_index = relative // 2
        last_index = first_index + len(values) - 1
        lines.append(
            f"        FDB     {operands:<39} ; index {first_index:03d}..{last_index:03d} "
            f"{byte_comment(start + relative, chunk)}"
        )
    return lines


def emit_vectors() -> list[str]:
    return [
        "",
        "; ---------------------------------------------------------------------------",
        "; CONFIRMÉ — vecteurs matériels du Motorola 6802 (big-endian).",
        "; IRQ et SWI partagent le même gestionnaire; NMI reçoit la perte de PA.",
        "; ---------------------------------------------------------------------------",
        f"{data_label(0xFFF8)}:",
        f"        FDB     {code_label(0xCC9F, {0xCC9F})}                 ; IRQ  {byte_comment(0xFFF8, bytes.fromhex('CC 9F'))}",
        f"        FDB     {code_label(0xCC9F, {0xCC9F})}                 ; SWI  {byte_comment(0xFFFA, bytes.fromhex('CC 9F'))}",
        f"        FDB     {code_label(0xE1DE, {0xE1DE})}                 ; NMI  {byte_comment(0xFFFC, bytes.fromhex('E1 DE'))}",
        f"        FDB     {code_label(0xC33F, {0xC33F})}                 ; RESET {byte_comment(0xFFFE, bytes.fromhex('C3 3F'))}",
    ]


def emit_rom(
    binary: bytes,
    binary_name: str,
    output_name: str,
    base: int,
    end: int,
    digest: str,
    records: dict[int, Record],
    code: set[int],
    labels: set[int],
    routine_entries: set[int],
    callers: dict[int, set[int]],
) -> str:
    lines = emit_header(output_name, binary_name, base, end, digest)
    local_code = {address for address in code if base <= address <= end}
    used_memory = collect_used_memory(records, local_code)
    referenced_code: set[int] = set()
    for instruction_address in local_code:
        target = target_of(records[instruction_address])
        if target is not None:
            referenced_code.add(target)
    if base == 0xE000:
        # Two vector destinations live in the other EPROM.
        referenced_code.update({0xC33F, 0xCC9F})
    lines.extend(
        emit_equates(
            used_memory, referenced_code, code, routine_entries, base, end
        )
    )

    # A label inside a data run must force a new FCB line.
    data_targets = {address for address in KNOWN_DATA_NAMES if base <= address <= end}

    address = base
    while address <= end:
        if address == 0xC000:
            lines.extend(emit_exponential_table(binary, base))
            address += 0x1F6
            continue
        if address == 0xDFFF:
            lines.extend([
                "",
                "; CONFIRMÉ — instruction traversant la frontière des deux EPROM :",
                "; $DFFF fournit l'opcode $FF (STX étendu), puis $E000..$E001",
                "; fournissent l'opérande $800A. L'instruction logique est STX $800A.",
                "        FCB     $FF                                     "
                + byte_comment(0xDFFF, bytes([0xFF])),
            ])
            address += 1
            continue
        if address == 0xE000:
            lines.extend([
                "; Suite de l'instruction STX $800A commencée à $DFFF dans 740A-2.",
                "        FCB     $80,$0A                                 "
                + byte_comment(0xE000, bytes([0x80, 0x0A])),
            ])
            address += 2
            continue
        if address == 0xC1F6:
            lines.extend(emit_attenuator_table(binary, base))
            address += 40
            continue
        if address == 0xFFF8:
            lines.extend(emit_vectors())
            address = 0x10000
            continue

        if address in routine_entries and address in code:
            lines.extend(emit_routine_header(address, callers))

        if address in code:
            record = records[address]
            if address in labels or address in routine_entries:
                lines.append(f"{code_label(address, routine_entries)}:")
            operand = rewrite_operand(record, code, routine_entries)
            instruction = f"        {record.mnemonic:<7} {operand}".rstrip()
            explanation = inline_comment(record, operand)
            suffix = byte_comment(address, record.data)
            if explanation:
                lines.append(f"{instruction:<55} ; {explanation} {suffix}")
            else:
                lines.append(f"{instruction:<55} {suffix}")
            address += len(record.data)
            continue

        # Unreached bytes are data.  Stop before any code, label, special table,
        # vector, or after eight bytes so addresses stay easy to audit.
        chunk_end = min(address + 8, end + 1)
        for candidate in range(address + 1, chunk_end):
            if candidate in code or candidate in data_targets or candidate in {0xC1F6, 0xFFF8}:
                chunk_end = candidate
                break
        chunk = binary[address - base:chunk_end - base]
        if address in data_targets:
            lines.append("")
            confidence = "CONFIRMÉ" if address in KNOWN_DATA_NAMES else "INCONNU"
            lines.append(f"; {confidence} — données ROM référencées à ${address:04X}.")
            lines.append(f"{data_label(address)}:")
        values = ",".join(f"${byte:02X}" for byte in chunk)
        ascii_text = "".join(chr(byte) if 32 <= byte <= 126 else "." for byte in chunk)
        lines.append(
            f"        FCB     {values:<39} ; données '{ascii_text}' {byte_comment(address, chunk)}"
        )
        address = chunk_end

    lines.extend(["", "        END", ""])
    return "\n".join(lines)


def verify_emitted(text: str, binary: bytes, base: int, output_name: str) -> None:
    reconstructed = bytearray(len(binary))
    covered = bytearray(len(binary))
    for line in text.splitlines():
        match = BYTE_COMMENT_RE.search(line)
        if not match:
            continue
        address = int(match.group(1), 16)
        data = bytes.fromhex(match.group(2))
        offset = address - base
        if offset < 0 or offset + len(data) > len(binary):
            raise ValueError(f"{output_name}: byte comment outside ROM at ${address:04X}")
        for index, byte in enumerate(data):
            if covered[offset + index]:
                raise ValueError(f"{output_name}: duplicate byte at ${address + index:04X}")
            reconstructed[offset + index] = byte
            covered[offset + index] = 1
    if not all(covered):
        missing = base + covered.index(0)
        raise ValueError(f"{output_name}: uncovered byte at ${missing:04X}")
    if bytes(reconstructed) != binary:
        mismatch = next(
            index for index, (actual, expected) in enumerate(zip(reconstructed, binary))
            if actual != expected
        )
        raise ValueError(f"{output_name}: mismatch at ${base + mismatch:04X}")


def verify_source_layout(text: str, base: int, output_name: str) -> None:
    """Check source order and that FCB/FDB operands encode their byte comments."""
    symbols: dict[str, int] = {}
    pending_labels: list[str] = []

    # First pass: EQU values and address-bearing labels.
    for line in text.splitlines():
        source = line.split(";", 1)[0]
        equate = re.match(r"^([A-Za-z_][A-Za-z0-9_]*)\s+EQU\s+\$([0-9A-F]{4})", source)
        if equate:
            symbols[equate.group(1)] = int(equate.group(2), 16)
            continue
        label = re.match(r"^([A-Za-z_][A-Za-z0-9_]*):", source)
        if label:
            pending_labels.append(label.group(1))
        byte_match = BYTE_COMMENT_RE.search(line)
        if byte_match and pending_labels:
            address = int(byte_match.group(1), 16)
            for name in pending_labels:
                symbols[name] = address
            pending_labels.clear()

    pc = base
    for line in text.splitlines():
        byte_match = BYTE_COMMENT_RE.search(line)
        if not byte_match:
            continue
        address = int(byte_match.group(1), 16)
        expected = bytes.fromhex(byte_match.group(2))
        if address != pc:
            raise ValueError(
                f"{output_name}: source order jumps from ${pc:04X} to ${address:04X}"
            )

        source = line.split(";", 1)[0].strip()
        directive = re.match(r"^(FCB|FDB)\s+(.+)$", source)
        if directive:
            kind, operand_text = directive.groups()
            encoded = bytearray()
            for operand in (item.strip() for item in operand_text.split(",")):
                if operand.startswith("$"):
                    value = int(operand[1:], 16)
                elif operand in symbols:
                    value = symbols[operand]
                else:
                    raise ValueError(
                        f"{output_name}: unresolved {kind} operand {operand!r}"
                    )
                if kind == "FCB":
                    encoded.append(value & 0xFF)
                else:
                    encoded.extend(((value >> 8) & 0xFF, value & 0xFF))
            if bytes(encoded) != expected:
                raise ValueError(
                    f"{output_name}: {kind} operands disagree at ${address:04X}"
                )
        pc += len(expected)

    if pc != base + 8192:
        raise ValueError(
            f"{output_name}: source ends at ${pc:04X}, expected ${base + 8192:04X}"
        )


def main() -> None:
    import hashlib

    records = parse_listings()
    code, labels, routine_entries = discover_code(records)
    # Address constants can point at executable code without using a JSR/JMP
    # opcode (for example a table base loaded into X).  Materialize labels for
    # those locations too so both generated files remain self-contained.
    for instruction_address in code:
        for match in MEMORY_RE.finditer(records[instruction_address].operand):
            candidate = int(match.group(1), 16)
            if candidate in code:
                labels.add(candidate)
    callers, _ = callers_and_callees(records, code)

    expected_hashes = {
        "740A-1.BIN": "099F43F99A26C1AA3E8C988622865FF8E5EFBA2F6E3A20A678295FD10085B095",
        "740A-2.BIN": "0F178E5DC3220DD51E5F7105D6238C6962E594B3AD1E1CF235A87AA4F26BDA31",
    }

    for _, binary_name, output_name, base, end in ROM_SPECS:
        binary = (EPROM_DIR / binary_name).read_bytes()
        if len(binary) != 8192:
            raise ValueError(f"{binary_name}: expected 8192 bytes, got {len(binary)}")
        digest = hashlib.sha256(binary).hexdigest().upper()
        if digest != expected_hashes[binary_name]:
            raise ValueError(f"{binary_name}: unexpected SHA-256 {digest}")
        text = emit_rom(
            binary, binary_name, output_name, base, end, digest,
            records, code, labels, routine_entries, callers,
        )
        verify_source_layout(text, base, output_name)
        verify_emitted(text, binary, base, output_name)
        (EPROM_DIR / output_name).write_text(text, encoding="utf-8", newline="\n")
        print(
            f"{output_name}: 8192/8192 bytes covered, SHA-256 {digest}, "
            f"{sum(1 for address in code if base <= address <= end)} instructions"
        )


if __name__ == "__main__":
    main()
