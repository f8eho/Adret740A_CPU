#!/usr/bin/env python3
"""Audit the KiCad XML netlist against the confirmed prototype mapping."""

from __future__ import annotations

import sys
import xml.etree.ElementTree as ET
from pathlib import Path


ROOT = Path(__file__).resolve().parent
NETLIST = ROOT / "Adret740A_replacement_cpu.xml"


def nodes(*items: tuple[str, str]) -> set[tuple[str, str]]:
    return set(items)


EXPECTED: dict[str, set[tuple[str, str]]] = {
    "+5V_CPU": nodes(("A1", "5V"), ("A2", "CPU_VCC"), ("J1", "8"), ("J2", "2"), ("J2", "3")),
    "GND_CPU": nodes(("A1", "GND"), ("A2", "CPU_GND"), ("J1", "16"), ("J2", "4"), ("J2", "5")),
    "+5V_INST": nodes(
        ("A2", "INST_VCC"), ("A3", "I2C_VCC"), ("A3", "PB_VCC"), ("A3", "PA_VCC"),
        ("J2", "13"), ("R1", "1"), ("R2", "1"),
    ),
    "GND_INST": nodes(
        ("A2", "INST_GND"), ("A3", "I2C_GND"), ("A3", "PB_GND"), ("A3", "PA_GND"),
        ("J2", "14"), ("J2", "16"), ("J2", "18"),
    ),
    "INHIB_POWER": nodes(("J1", "5"), ("J2", "6")),
    "POWER_SENSE": nodes(("J2", "7"), ("A1", "3")),
    "FP_CA1": nodes(("J1", "12"), ("A1", "2")),
    "FP_CA2": nodes(("J1", "10"), ("A1", "10")),
    "FP_MODE": nodes(("J1", "1"), ("A1", "53")),
    "FP_C": nodes(("J1", "2"), ("A1", "52")),
    "FP_B": nodes(("J1", "3"), ("A1", "51")),
    "FP_A": nodes(("J1", "4"), ("A1", "50")),
    "I2C_SDA_CPU": nodes(("A1", "20"), ("A2", "CPU_SDA")),
    "I2C_SCL_CPU": nodes(("A1", "21"), ("A2", "CPU_SCL")),
    "I2C_SDA_INST": nodes(("A2", "INST_SDA"), ("A3", "I2C_SDA")),
    "I2C_SCL_INST": nodes(("A2", "INST_SCL"), ("A3", "I2C_SCL")),
    "CHARGT": nodes(("A3", "PB4"), ("J2", "31"), ("R1", "2")),
    "MCP_RESET": nodes(("A3", "RST"), ("R2", "2")),
}

PANEL_DATA_TO_MEGA = ("28", "29", "26", "27", "24", "25", "22", "23")
for bit, mega_pin in enumerate(PANEL_DATA_TO_MEGA):
    EXPECTED[f"FP_D{bit}"] = nodes(("J1", str(19 + bit)), ("A1", mega_pin))
for bit in range(8):
    EXPECTED[f"IB_D{bit}"] = nodes(("A3", f"PA{bit}"), ("J2", str(19 + bit)))
for bit in range(4):
    EXPECTED[f"IB_A{bit}"] = nodes(("A3", f"PB{bit}"), ("J2", str(27 + bit)))


def load_nets(path: Path) -> dict[str, set[tuple[str, str]]]:
    tree = ET.parse(path)
    result: dict[str, set[tuple[str, str]]] = {}
    for net in tree.findall("./nets/net"):
        name = net.attrib["name"].removeprefix("/")
        result[name] = {(node.attrib["ref"], node.attrib["pin"]) for node in net.findall("node")}
    return result


def main() -> int:
    path = Path(sys.argv[1]) if len(sys.argv) > 1 else NETLIST
    actual = load_nets(path)
    failures: list[str] = []
    for name, expected_nodes in EXPECTED.items():
        actual_nodes = actual.get(name)
        if actual_nodes != expected_nodes:
            failures.append(f"{name}: expected {sorted(expected_nodes)}, got {sorted(actual_nodes or set())}")

    cpu_ground = actual.get("GND_CPU", set())
    instrument_ground = actual.get("GND_INST", set())
    if not cpu_ground or not instrument_ground:
        failures.append("Both GND_CPU and GND_INST must exist")
    if cpu_ground & instrument_ground:
        failures.append("GND_CPU and GND_INST share connector nodes")
    if actual.get("GND_CPU") == actual.get("GND_INST"):
        failures.append("GND_CPU and GND_INST were merged")

    if failures:
        print("Netlist audit FAILED:")
        for failure in failures:
            print(f"  - {failure}")
        return 1

    print(f"Netlist audit OK: {len(EXPECTED)} required nets, isolated grounds confirmed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
