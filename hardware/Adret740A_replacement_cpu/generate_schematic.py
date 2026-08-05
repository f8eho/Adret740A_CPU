#!/usr/bin/env python3
"""Generate the KiCad 10 schematic for the Adret 740A replacement CPU.

The generated schematic deliberately models the assembled breakout modules,
not the IC packages or a future PCB.  UUIDs are deterministic so regenerating
the project does not create noisy diffs.
"""

from __future__ import annotations

import json
import uuid
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path


PROJECT = "Adret740A_replacement_cpu"
ROOT = Path(__file__).resolve().parent
UUID_NAMESPACE = uuid.UUID("e9a8bfc7-b87f-45d6-8ad9-d0dd6caf740a")


def uid(key: str) -> str:
    return str(uuid.uuid5(UUID_NAMESPACE, key))


def quote(value: str) -> str:
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def effects(size: float = 1.0, hide: bool = False, justify: str | None = None) -> str:
    lines = ["(effects", f"  (font (size {size:g} {size:g}))"]
    if justify:
        lines.append(f"  (justify {justify})")
    if hide:
        lines.append("  (hide yes)")
    lines.append(")")
    return "\n".join(lines)


@dataclass(frozen=True)
class Pin:
    number: str
    name: str
    side: str
    y: float
    net: str | None = None


@dataclass(frozen=True)
class SymbolSpec:
    name: str
    reference: str
    value: str
    pins: tuple[Pin, ...]
    half_width: float = 12.7
    description: str = ""

    @property
    def half_height(self) -> float:
        return max(7.62, max((abs(pin.y) for pin in self.pins), default=0.0) + 2.54)


@dataclass(frozen=True)
class PinPoint:
    reference: str
    number: str
    side: str
    x: float
    y: float
    net: str


def paired_pins(names: list[tuple[str, str, str | None]]) -> tuple[Pin, ...]:
    """Lay out physical pin numbers bottom-to-top, odd right/even left."""
    pair_count = (len(names) + 1) // 2
    pins: list[Pin] = []
    for index, (number, name, net) in enumerate(names, start=1):
        row = (index - 1) // 2
        # Pin 1 is the bottom-right contact in the confirmed connector view;
        # odd pins remain on the right and even pins on the left while rising.
        y = -(pair_count - 1) * 1.27 + row * 2.54
        side = "R" if index % 2 else "L"
        pins.append(Pin(number, name, side, y, net))
    return tuple(pins)


def row_pins(rows: list[tuple[str, str, str, str | None]]) -> tuple[Pin, ...]:
    """Lay out an arbitrary symbol with explicit pin side."""
    left = [row for row in rows if row[2] == "L"]
    right = [row for row in rows if row[2] == "R"]
    result: list[Pin] = []
    for side, group in (("L", left), ("R", right)):
        offset = (len(group) - 1) * 1.27
        for index, (number, name, _, net) in enumerate(group):
            result.append(Pin(number, name, side, offset - index * 2.54, net))
    return tuple(result)


def panel_pin_y(number: int) -> float:
    """J1-1 is bottom-right and J1-26 is top-left in the documented view."""
    return (number - 13.5) * 2.54


def b1_pin_y(number: int) -> float:
    """Place B1-31 at the top so D0..CHARGT form a contiguous bus bundle."""
    return (number - 16) * 2.54


PANEL_NAMES: list[tuple[str, str, str | None]] = [
    ("1", "MODE / PB3", "FP_MODE"),
    ("2", "C / PB2", "FP_C"),
    ("3", "B / PB1", "FP_B"),
    ("4", "A / PB0", "FP_A"),
    ("5", "INHIB", "INHIB_POWER"),
    ("6", "NC", None),
    ("7", "NC", None),
    ("8", "+5V", "+5V_CPU"),
    ("9", "NC", None),
    ("10", "WP / CA2", "FP_CA2"),
    ("11", "NC", None),
    ("12", "INT CLAV / CA1", "FP_CA1"),
    ("13", "NC", None),
    ("14", "NC", None),
    ("15", "NC", None),
    ("16", "GND", "GND_CPU"),
    ("17", "NC", None),
    ("18", "NC", None),
]
PANEL_NAMES.extend((str(19 + bit), f"PA{bit} / D{bit}", f"FP_D{bit}") for bit in range(8))
PANEL_PINS = tuple(
    Pin(number, name, "R", panel_pin_y(int(number)), net)
    for number, name, net in PANEL_NAMES
)

B1_NAMES: list[tuple[str, str, str | None]] = [
    ("1", "+5V DIG-P (original)", None),
    ("2", "+5V CPU", "+5V_CPU"),
    ("3", "+5V CPU", "+5V_CPU"),
    ("4", "0V CPU", "GND_CPU"),
    ("5", "0V CPU", "GND_CPU"),
    ("6", "INHIB (actif bas)", "INHIB_POWER"),
    ("7", "PA presence alim", "POWER_SENSE"),
    ("8", "PEDALE 1 (original)", None),
    ("9", "PEDALE 2 (original)", None),
    ("10", "NC original", None),
    ("11", "NC original", None),
    ("12", "NC original", None),
    ("13", "+5V instruments", "+5V_INST"),
    ("14", "0V instruments", "GND_INST"),
    ("15", "10MHz original", None),
    ("16", "0V instruments", "GND_INST"),
    ("17", "10MHz retour original", None),
    ("18", "0V instruments", "GND_INST"),
]
B1_NAMES.extend((str(19 + bit), f"D{bit}", f"IB_D{bit}") for bit in range(8))
B1_NAMES.extend((str(27 + bit), f"A{bit}", f"IB_A{bit}") for bit in range(4))
B1_NAMES.append(("31", "CHARGT actif bas", "CHARGT"))
B1_PINS = tuple(
    Pin(number, name, "L", b1_pin_y(int(number)), net)
    for number, name, net in B1_NAMES
)

ARDUINO_PINS = (
    Pin("28", "D28 / PA6", "L", panel_pin_y(26), "FP_D7"),
    Pin("29", "D29 / PA7", "L", panel_pin_y(25), "FP_D6"),
    Pin("26", "D26 / PA4", "L", panel_pin_y(24), "FP_D5"),
    Pin("27", "D27 / PA5", "L", panel_pin_y(23), "FP_D4"),
    Pin("24", "D24 / PA2", "L", panel_pin_y(22), "FP_D3"),
    Pin("25", "D25 / PA3", "L", panel_pin_y(21), "FP_D2"),
    Pin("22", "D22 / PA0", "L", panel_pin_y(20), "FP_D1"),
    Pin("23", "D23 / PA1", "L", panel_pin_y(19), "FP_D0"),
    Pin("2", "D2 / PE4 / INT4", "L", panel_pin_y(12), "FP_CA1"),
    Pin("10", "D10 / PB4", "L", panel_pin_y(10), "FP_CA2"),
    Pin("53", "D53 / PB0", "L", panel_pin_y(4), "FP_A"),
    Pin("52", "D52 / PB1", "L", panel_pin_y(3), "FP_B"),
    Pin("51", "D51 / PB2", "L", panel_pin_y(2), "FP_C"),
    Pin("50", "D50 / PB3", "L", panel_pin_y(1), "FP_MODE"),
    Pin("5V", "+5V", "R", 15.24, "+5V_CPU"),
    Pin("GND", "GND", "R", 12.70, "GND_CPU"),
    Pin("21", "D21 / SCL", "R", 10.16, "I2C_SCL_CPU"),
    Pin("20", "D20 / SDA", "R", 7.62, "I2C_SDA_CPU"),
    Pin("3", "D3 / PE5 / INT5", "R", -10.16, "POWER_SENSE"),
)

ISO_PINS = (
    Pin("CPU_VCC", "VCC cote CPU", "L", 15.24, "+5V_CPU"),
    Pin("CPU_GND", "GND cote CPU", "L", 12.70, "GND_CPU"),
    Pin("CPU_SCL", "SCL cote CPU", "L", 10.16, "I2C_SCL_CPU"),
    Pin("CPU_SDA", "SDA cote CPU", "L", 7.62, "I2C_SDA_CPU"),
    Pin("INST_VCC", "VCC cote instruments", "R", 15.24, "+5V_INST"),
    Pin("INST_GND", "GND cote instruments", "R", 12.70, "GND_INST"),
    Pin("INST_SCL", "SCL cote instruments", "R", 10.16, "I2C_SCL_INST"),
    Pin("INST_SDA", "SDA cote instruments", "R", 7.62, "I2C_SDA_INST"),
)

MCP_PINS = (
    # Header vertical visible at the left of the green breakout board.
    Pin("I2C_VCC", "VCC header I2C", "L", 15.24, "+5V_INST"),
    Pin("I2C_GND", "GND header I2C", "L", 12.70, "GND_INST"),
    Pin("I2C_SCL", "SCL", "L", 10.16, "I2C_SCL_INST"),
    Pin("I2C_SDA", "SDA", "L", 7.62, "I2C_SDA_INST"),
    Pin("RST", "RST actif bas", "L", 5.08, "MCP_RESET"),
    Pin("ITA", "ITA", "L", 2.54, None),
    Pin("ITB", "ITB", "L", 0.00, None),
    # Duplicated supply pins on the PA and PB headers.
    Pin("PB_VCC", "VCC header PB", "L", -12.70, "+5V_INST"),
    Pin("PB_GND", "GND header PB", "L", -15.24, "GND_INST"),
    Pin("PA_VCC", "VCC header PA", "L", -17.78, "+5V_INST"),
    Pin("PA_GND", "GND header PA", "L", -20.32, "GND_INST"),
)
MCP_PINS += tuple(
    Pin(f"PA{bit}", f"PA{bit}", "R", b1_pin_y(19 + bit), f"IB_D{bit}")
    for bit in range(8)
)
MCP_PINS += tuple(
    Pin(f"PB{bit}", f"PB{bit}", "R", b1_pin_y(27 + bit), f"IB_A{bit}")
    for bit in range(4)
)
MCP_PINS += (Pin("PB4", "PB4 / CHARGT", "R", b1_pin_y(31), "CHARGT"),)
MCP_PINS += tuple(
    Pin(f"PB{bit}", f"PB{bit} reserve", "R", -12.70 - (bit - 5) * 2.54, None)
    for bit in range(5, 8)
)

SPECS = {
    "Front_Panel_2x13": SymbolSpec(
        "Front_Panel_2x13", "J", "PANNEAU AVANT 2x13", PANEL_PINS, 13.97,
        "Connecteur nappe 26 contacts du panneau avant Adret 740A",
    ),
    "Arduino_Mega2560_Used": SymbolSpec(
        "Arduino_Mega2560_Used", "A", "Arduino Mega 2560", ARDUINO_PINS, 19.05,
        "Module Arduino Mega 2560; seules les broches utilisees sont representees",
    ),
    "ISO1540_Breakout": SymbolSpec(
        "ISO1540_Breakout", "A", "Mini-plaquette ISO1540", ISO_PINS, 15.24,
        "Module isolateur I2C ISO1540, deux domaines 5 V",
    ),
    "MCP23017_Breakout": SymbolSpec(
        "MCP23017_Breakout", "A", "Mini-plaquette MCP23017 (0x20)", MCP_PINS, 20.32,
        "Mini-plaquette MCP23017 avec headers VCC/GND/PB7..PB0 et VCC/GND/PA0..PA7",
    ),
    "B1_Instrument_31": SymbolSpec(
        "B1_Instrument_31", "J", "B1 BUS INSTRUMENTS", B1_PINS, 17.78,
        "Connecteur 31 contacts du fond de panier instruments Adret 740A",
    ),
    "Resistor": SymbolSpec(
        "Resistor", "R", "R", (Pin("1", "1", "L", 0.0), Pin("2", "2", "R", 0.0)), 3.81,
        "Resistance externe montee sur la plaque de prototypage",
    ),
}


def indent(block: str, spaces: int) -> str:
    prefix = " " * spaces
    return "\n".join(prefix + line if line else line for line in block.splitlines())


def property_block(name: str, value: str, x: float, y: float, hidden: bool = False) -> str:
    return "\n".join([
        f"(property {quote(name)} {quote(value)}",
        f"  (at {x:g} {y:g} 0)",
        indent(effects(1.0, hide=hidden), 2),
        ")",
    ])


def symbol_definition(spec: SymbolSpec, embedded: bool) -> str:
    lib_name = f"Adret740A:{spec.name}" if embedded else spec.name
    child_name = f"{spec.name}_1_1"
    lines = [
        f"(symbol {quote(lib_name)}",
        "  (pin_names (offset 1.016))",
        "  (exclude_from_sim no)",
        "  (in_bom yes)",
        "  (on_board no)",
        indent(property_block("Reference", spec.reference, 0, -spec.half_height - 3.81), 2),
        indent(property_block("Value", spec.value, 0, spec.half_height + 3.81), 2),
        indent(property_block("Footprint", "", 0, 0, True), 2),
        indent(property_block("Datasheet", "", 0, 0, True), 2),
        indent(property_block("Description", spec.description, 0, 0, True), 2),
        f"  (symbol {quote(child_name)}",
        "    (rectangle",
        f"      (start {-spec.half_width:g} {-spec.half_height:g})",
        f"      (end {spec.half_width:g} {spec.half_height:g})",
        "      (stroke (width 0.254) (type default))",
        "      (fill (type background))",
        "    )",
    ]
    pin_x = spec.half_width + 2.54
    for pin in spec.pins:
        x = -pin_x if pin.side == "L" else pin_x
        angle = 0 if pin.side == "L" else 180
        lines.extend([
            "    (pin passive line",
            f"      (at {x:g} {pin.y:g} {angle})",
            "      (length 2.54)",
            f"      (name {quote(pin.name)} {effects(0.9)})",
            f"      (number {quote(pin.number)} {effects(0.9)})",
            "    )",
        ])
    lines.extend(["  )", "  (embedded_fonts no)", ")"])
    return "\n".join(lines)


def symbol_library() -> str:
    blocks = [symbol_definition(spec, embedded=False) for spec in SPECS.values()]
    return "\n".join([
        "(kicad_symbol_lib",
        "  (version 20250114)",
        "  (generator \"kicad_symbol_editor\")",
        "  (generator_version \"10.0\")",
        *(indent(block, 2) for block in blocks),
        ")",
        "",
    ])


def wire(x1: float, y1: float, x2: float, y2: float, key: str) -> str:
    return "\n".join([
        "(wire",
        f"  (pts (xy {x1:g} {y1:g}) (xy {x2:g} {y2:g}))",
        "  (stroke (width 0) (type solid))",
        f"  (uuid {quote(uid('wire:' + key))})",
        ")",
    ])


def label(name: str, x: float, y: float, side: str, key: str, size: float = 0.9) -> str:
    angle = 0 if side == "L" else 180
    justify = "left bottom" if side == "L" else "right bottom"
    return "\n".join([
        f"(label {quote(name)}",
        f"  (at {x:g} {y:g} {angle})",
        indent(effects(size, justify=justify), 2),
        f"  (uuid {quote(uid('label:' + key))})",
        ")",
    ])


def no_connect(x: float, y: float, key: str) -> str:
    return "\n".join([
        "(no_connect",
        f"  (at {x:g} {y:g})",
        f"  (uuid {quote(uid('nc:' + key))})",
        ")",
    ])


def junction(x: float, y: float, key: str) -> str:
    return "\n".join([
        "(junction",
        f"  (at {x:g} {y:g})",
        "  (diameter 0)",
        "  (color 0 0 0 0)",
        f"  (uuid {quote(uid('junction:' + key))})",
        ")",
    ])


def text_note(text: str, x: float, y: float, key: str, size: float = 1.27, angle: int = 0) -> str:
    return "\n".join([
        f"(text {quote(text)}",
        "  (exclude_from_sim no)",
        f"  (at {x:g} {y:g} {angle})",
        indent(effects(size, justify="left bottom"), 2),
        f"  (uuid {quote(uid('text:' + key))})",
        ")",
    ])


def symbol_instance(
    spec: SymbolSpec, reference: str, value: str, x: float, y: float
) -> tuple[str, list[PinPoint], list[str]]:
    inst_key = f"instance:{reference}"
    pin_entries = []
    points: list[PinPoint] = []
    no_connects: list[str] = []
    pin_x = spec.half_width + 2.54
    for pin in spec.pins:
        pin_entries.append("\n".join([
            f"(pin {quote(pin.number)}",
            f"  (uuid {quote(uid(inst_key + ':pin:' + pin.number))})",
            ")",
        ]))
        endpoint_x = x + (-pin_x if pin.side == "L" else pin_x)
        # KiCad symbol-local positive Y points upward while sheet positive Y
        # points downward.  Mirror the local ordinate around the instance.
        endpoint_y = y - pin.y
        if pin.net is None:
            no_connects.append(no_connect(endpoint_x, endpoint_y, f"{reference}:{pin.number}"))
        else:
            points.append(PinPoint(reference, pin.number, pin.side, endpoint_x, endpoint_y, pin.net))

    lines = [
        "(symbol",
        f"  (lib_id {quote('Adret740A:' + spec.name)})",
        f"  (at {x:g} {y:g} 0)",
        "  (unit 1)",
        "  (exclude_from_sim no)",
        "  (in_bom yes)",
        "  (on_board no)",
        "  (dnp no)",
        f"  (uuid {quote(uid(inst_key))})",
        indent(property_block("Reference", reference, x, y - spec.half_height - 3.81), 2),
        indent(property_block("Value", value, x, y + spec.half_height + 3.81), 2),
        indent(property_block("Footprint", "", x, y, True), 2),
        indent(property_block("Datasheet", "", x, y, True), 2),
        indent(property_block("Description", spec.description, x, y, True), 2),
        *(indent(entry, 2) for entry in pin_entries),
        "  (instances",
        f"    (project {quote(PROJECT)}",
        f"      (path {quote('/' + uid('root'))}",
        f"        (reference {quote(reference)})",
        "        (unit 1)",
        "      )",
        "    )",
        "  )",
        ")",
    ]
    return "\n".join(lines), points, no_connects


def resistor_instance(
    reference: str, value: str, x: float, y: float, left_net: str, right_net: str
) -> tuple[str, list[PinPoint], list[str]]:
    spec = SPECS["Resistor"]
    custom = SymbolSpec(spec.name, spec.reference, value, (
        Pin("1", "1", "L", 0.0, left_net),
        Pin("2", "2", "R", 0.0, right_net),
    ), spec.half_width, spec.description)
    return symbol_instance(custom, reference, value, x, y)


def route_pair(net: str, points: list[PinPoint], key: str) -> list[str]:
    """Draw an explicit orthogonal connection between two module pins."""
    if len(points) != 2:
        raise ValueError(f"{net}: route_pair requires two points, got {len(points)}")
    first, second = sorted(points, key=lambda point: point.x)
    result: list[str] = []
    if abs(first.y - second.y) < 0.001:
        result.append(wire(first.x, first.y, second.x, second.y, f"{key}:direct"))
        label_x = first.x + 2.54
        result.append(label(net, label_x, first.y, "L", f"{key}:label", 0.75))
        return result

    middle_x = round(((first.x + second.x) / 2) / 1.27) * 1.27
    result.extend([
        wire(first.x, first.y, middle_x, first.y, f"{key}:a"),
        wire(middle_x, first.y, middle_x, second.y, f"{key}:b"),
        wire(middle_x, second.y, second.x, second.y, f"{key}:c"),
        label(net, first.x + 2.54, first.y, "L", f"{key}:label", 0.75),
    ])
    return result


def route_label_stub(net: str, point: PinPoint, key: str) -> list[str]:
    """Use a labelled stub for a subsidiary connection to an explicit main net."""
    outer_x = point.x + (-5.08 if point.side == "L" else 5.08)
    return [
        wire(point.x, point.y, outer_x, point.y, f"{key}:stub"),
        label(net, outer_x, point.y, point.side, f"{key}:label", 0.8),
    ]


def route_over_top(
    net: str,
    points: list[PinPoint],
    top_y: float,
    escape: float,
    key: str,
) -> list[str]:
    """Route a long direct signal above all modules without crossing a bus."""
    if len(points) != 2:
        raise ValueError(f"{net}: expected two points, got {len(points)}")
    left, right = sorted(points, key=lambda point: point.x)
    left_x = left.x + escape
    right_x = right.x - escape
    return [
        wire(left.x, left.y, left_x, left.y, f"{key}:left-escape"),
        wire(left_x, left.y, left_x, top_y, f"{key}:left-rise"),
        wire(left_x, top_y, right_x, top_y, f"{key}:top"),
        wire(right_x, top_y, right_x, right.y, f"{key}:right-drop"),
        wire(right_x, right.y, right.x, right.y, f"{key}:right-escape"),
        label(net, left_x + 2.54, top_y, "L", f"{key}:label", 0.8),
    ]


def schematic() -> str:
    placements = [
        (SPECS["Front_Panel_2x13"], "J1", "PANNEAU AVANT 2x13", 33.02, 90.17),
        (SPECS["Arduino_Mega2560_Used"], "A1", "Arduino Mega 2560", 118.11, 90.17),
        (SPECS["ISO1540_Breakout"], "A2", "Mini-plaquette ISO1540", 200.66, 90.17),
        (SPECS["MCP23017_Breakout"], "A3", "Mini-plaquette MCP23017 (0x20)", 274.32, 90.17),
        (SPECS["B1_Instrument_31"], "J2", "B1 BUS INSTRUMENTS", 375.92, 90.17),
    ]
    instances: list[str] = []
    connections: list[str] = []
    net_points: dict[str, list[PinPoint]] = defaultdict(list)
    for spec, reference, value, x, y in placements:
        instance, points, no_connects = symbol_instance(spec, reference, value, x, y)
        instances.append(instance)
        connections.extend(no_connects)
        for point in points:
            net_points[point.net].append(point)
    for reference, value, x, y, left_net, right_net in (
        ("R1", "4.7k CHARGT pull-up", 271.78, 190.50, "+5V_INST", "CHARGT"),
        ("R2", "10k RESET pull-up", 337.82, 190.50, "+5V_INST", "MCP_RESET"),
    ):
        instance, points, no_connects = resistor_instance(reference, value, x, y, left_net, right_net)
        instances.append(instance)
        connections.extend(no_connects)
        for point in points:
            net_points[point.net].append(point)

    # Visible point-to-point bundles.  Pin placement deliberately aligns each
    # corresponding signal, so every conductor can be followed across the A3
    # sheet without relying on net labels alone.
    direct_nets = [
        "FP_MODE", "FP_C", "FP_B", "FP_A", "FP_CA1", "FP_CA2",
        "I2C_SCL_CPU", "I2C_SDA_CPU", "I2C_SCL_INST", "I2C_SDA_INST",
    ]
    direct_nets.extend(f"FP_D{bit}" for bit in range(8))
    direct_nets.extend(f"IB_D{bit}" for bit in range(8))
    direct_nets.extend(f"IB_A{bit}" for bit in range(4))
    for net in direct_nets:
        connections.extend(route_pair(net, net_points[net], f"route:{net}"))

    # CHARGT is explicit between PB4 and B1-31.  R1 joins it through a named
    # branch so the thirteen-wire instrument bundle remains visually parallel.
    chargt_main = [point for point in net_points["CHARGT"] if point.reference != "R1"]
    chargt_pullup = next(point for point in net_points["CHARGT"] if point.reference == "R1")
    connections.extend(route_pair("CHARGT", chargt_main, "route:CHARGT"))
    connections.extend(route_label_stub("CHARGT", chargt_pullup, "route:CHARGT:R1"))

    # These long, direct conductors make the exceptional chassis wiring
    # explicit: INHIB bypasses the Mega; PA is sensed by D3/INT5.  Separate
    # escape lanes avoid both visible data bundles.
    connections.extend(route_over_top(
        "INHIB_POWER", net_points["INHIB_POWER"], 41.91, 7.62,
        "route:INHIB_POWER",
    ))
    connections.extend(route_over_top(
        "POWER_SENSE", net_points["POWER_SENSE"], 45.72, 10.16,
        "route:POWER_SENSE",
    ))

    # Supplies use labelled stubs.  Long common rails would cross the dense,
    # visible data bundles and KiCad would then interpret every crossing as an
    # electrical junction.  Data, address, I2C and chassis signals remain
    # fully point-to-point and visually traceable.
    for net in (
        "+5V_CPU", "GND_CPU", "+5V_INST", "GND_INST", "MCP_RESET",
    ):
        for index, point in enumerate(net_points[net]):
            connections.extend(route_label_stub(net, point, f"route:{net}:{index}"))

    notes = [
        text_note("DOMAINE CPU : +5V_CPU / GND_CPU", 18, 28, "cpu-domain", 1.5),
        text_note("PANNEAU AVANT", 18, 36, "panel-heading", 1.5),
        text_note("ARDUINO MEGA 2560", 96, 36, "mega-heading", 1.5),
        text_note("BARRIERE D'ISOLATION GALVANIQUE", 180, 28, "barrier-heading", 1.5),
        text_note("GND_CPU et GND_INST NE DOIVENT JAMAIS ETRE RELIES", 180, 34, "barrier-warning", 1.1),
        text_note("DOMAINE INSTRUMENTS : +5V_INST / GND_INST", 232, 28, "inst-domain", 1.5),
        text_note("MINI-PLAQUETTE MCP23017", 250, 36, "mcp-heading", 1.5),
        text_note("CONNECTEUR B1 - 31 CONTACTS", 346, 36, "b1-heading", 1.5),
        text_note("ISO1540 : deux headers VCC/GND/SCL/SDA, tirages 10k integres", 176, 118, "iso-pullups", 0.9),
        text_note("MCP23017 : headers I2C, PB et PA ; tirages SDA/SCL 4.7k integres", 242, 125, "mcp-pullups", 0.9),
        text_note("Cavaliers A2=A1=A0=0 (GND) -> adresse I2C 0x20", 242, 132, "mcp-address", 0.9),
        text_note("CHARGT actif bas : repos haut garanti par R1", 248, 207, "chargt-note", 0.9),
        text_note("INHIB : fil continu J1-5 vers B1-6, sans passage par la Mega", 18, 207, "inhib-note", 1.0),
        text_note("PA : B1-7 vers Mega D3/INT5, entree haute impedance", 18, 214, "pa-note", 1.0),
        text_note("Bus panneau : permutations validees (22/23, 24/25, 26/27, 28/29)", 18, 221, "panel-map-note", 0.9),
        text_note("Les broches Arduino non utilisees sont omises du symbole.", 18, 228, "mega-omitted", 0.9),
        text_note("Prototype sur plaque a pastilles - aucun routage PCB associe", 18, 238, "prototype-note", 1.1),
    ]

    lib_blocks = [symbol_definition(spec, embedded=True) for spec in SPECS.values()]
    return "\n".join([
        "(kicad_sch",
        "  (version 20250114)",
        "  (generator \"eeschema\")",
        "  (generator_version \"10.0\")",
        f"  (uuid {quote(uid('root'))})",
        "  (paper \"A3\")",
        "  (title_block",
        "    (title \"CPU de remplacement Adret 740A\")",
        "    (date \"2026-08-03\")",
        "    (rev \"1.0\")",
        "    (company \"Projet Adret 740A\")",
        "    (comment 1 \"Schema de cablage du prototype Arduino Mega / ISO1540 / MCP23017\")",
        "    (comment 2 \"Les domaines CPU et instruments restent galvaniquement isoles\")",
        "  )",
        "  (lib_symbols",
        *(indent(block, 4) for block in lib_blocks),
        "  )",
        *(indent(note, 2) for note in notes),
        *(indent(conn, 2) for conn in connections),
        *(indent(instance, 2) for instance in instances),
        "  (sheet_instances",
        "    (path \"/\" (page \"1\"))",
        "  )",
        "  (embedded_fonts no)",
        ")",
        "",
    ])


def project_file() -> str:
    project = {
        "board": {},
        "boards": [],
        "cvpcb": {"equivalence_files": []},
        "erc": {"erc_exclusions": [], "meta": {"version": 0}, "pin_map": [], "rule_severities": {}},
        "libraries": {"pinned_footprint_libs": [], "pinned_symbol_libs": ["Adret740A"]},
        "meta": {"filename": f"{PROJECT}.kicad_pro", "version": 1},
        "net_settings": {"classes": [], "meta": {"version": 3}, "net_colors": None, "netclass_assignments": None, "netclass_patterns": []},
        "pcbnew": {},
        "schematic": {"connection_grid_size": 50.0, "drawing": {}, "legacy_lib_dir": "", "legacy_lib_list": []},
        "sheets": [[uid("root"), "Root"]],
        "text_variables": {},
    }
    return json.dumps(project, indent=2, ensure_ascii=False) + "\n"


def main() -> None:
    outputs = {
        "Adret740A.kicad_sym": symbol_library(),
        f"{PROJECT}.kicad_sch": schematic(),
        f"{PROJECT}.kicad_pro": project_file(),
        "sym-lib-table": """(sym_lib_table
  (version 7)
  (lib (name \"Adret740A\")(type \"KiCad\")(uri \"${KIPRJMOD}/Adret740A.kicad_sym\")(options \"\")(descr \"Modules du prototype Adret 740A\"))
)
""",
    }
    for filename, content in outputs.items():
        (ROOT / filename).write_text(content, encoding="utf-8", newline="\n")
        print(f"generated {filename}")


if __name__ == "__main__":
    main()
