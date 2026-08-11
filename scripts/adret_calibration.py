#!/usr/bin/env python3
"""Application unifiée de calibration d'amplitude pour l'Adret 740A."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import sys
import time


PROJECT_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_SESSION = PROJECT_ROOT / "calibration_amplitude.json"
DEFAULT_TABLE = PROJECT_ROOT / "src" / "CalibrationTable.inc"
DEFAULT_PROFILE = PROJECT_ROOT / "src" / "CalibrationProfile.inc"
DEFAULT_DUMP_DIRECTORY = PROJECT_ROOT / "docs" / "eeprom_740A"

EEPROM_SIZE = 2048
BASE_ROWS = 30
ROWS = 41
STEPS = 28
PHYSICAL_ROWS = 64
ROW_STRIDE = 32
SESSION_VERSION = 1
KEY_VALUE = re.compile(r"([A-Z_]+)=([^ ]+)")


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def tenths_text(value: int) -> str:
    sign = "-" if value < 0 else "+"
    magnitude = abs(value)
    return f"{sign}{magnitude // 10}.{magnitude % 10}"


def parse_tenths(text: str) -> int:
    normalized = text.strip().replace(",", ".")
    match = re.fullmatch(r"([+-]?)(\d+)(?:\.(\d))?", normalized)
    if not match:
        raise ValueError("entrer une valeur avec au plus un chiffre après la virgule")
    value = int(match.group(2)) * 10 + int(match.group(3) or "0")
    return -value if match.group(1) == "-" else value


def representative_frequency(row: int) -> int:
    if row < 9:
        return (row + 1) * 100_000 + 50_000
    if row < 18:
        return (row - 8) * 1_000_000 + 500_000
    if row < 29:
        return 10_000_000 + (row - 18) * 50_000_000 + 25_000_000
    if row == 29:
        return 560_000_000
    if row < 40:
        return 610_000_000 + (row - 30) * 50_000_000 + 25_000_000
    return 1_115_000_000


def representative_amplitude(step: int) -> int:
    if step == 0:
        return 100
    if step == STEPS - 1:
        return -1290
    return 45 - 50 * step


def parse_selection(text: str, maximum: int) -> list[int]:
    if text.strip().lower() == "all":
        return list(range(maximum + 1))
    selected: set[int] = set()
    for part in text.split(","):
        bounds = part.strip().split("-", 1)
        try:
            start = int(bounds[0])
            end = int(bounds[1]) if len(bounds) == 2 else start
        except (IndexError, ValueError) as error:
            raise ValueError(f"sélection invalide : {part!r}") from error
        if start < 0 or end < start or end > maximum:
            raise ValueError(f"plage hors limites 0..{maximum}")
        selected.update(range(start, end + 1))
    if not selected:
        raise ValueError("sélection vide")
    return sorted(selected)


def values(line: str) -> dict[str, str]:
    return dict(KEY_VALUE.findall(line))


class SerialLink:
    def __init__(self, port: str, baudrate: int) -> None:
        try:
            import serial  # type: ignore
        except ImportError as error:
            raise RuntimeError(
                "installer pyserial avec : python -m pip install pyserial"
            ) from error
        self._serial = serial.Serial(port, baudrate=baudrate, timeout=3.0)
        time.sleep(0.2)
        self._serial.reset_input_buffer()

    def close(self) -> None:
        self._serial.close()

    def command(self, command: str, expected_prefix: str | None = None) -> str:
        self._serial.write((command + "\r\n").encode("ascii"))
        self._serial.flush()
        deadline = time.monotonic() + 8.0
        lines: list[str] = []
        while time.monotonic() < deadline:
            raw = self._serial.readline()
            if not raw:
                continue
            line = raw.decode("ascii", errors="replace").strip()
            if not line:
                continue
            lines.append(line)
            if line.startswith("CAL ERROR") or line.startswith("ERR "):
                raise RuntimeError(line)
            if expected_prefix is None or line.startswith(expected_prefix):
                return line
        raise TimeoutError(f"aucune réponse attendue à {command!r}; reçu: {lines}")

    def best_effort(self, command: str, expected_prefix: str) -> str | None:
        try:
            return self.command(command, expected_prefix)
        except Exception:
            return None

    def calibration_dump(self) -> dict[str, int]:
        self._serial.write(b"CAL DUMP\r\n")
        self._serial.flush()
        deadline = time.monotonic() + 15.0
        result: dict[str, int] = {}
        while time.monotonic() < deadline:
            raw = self._serial.readline()
            if not raw:
                continue
            line = raw.decode("ascii", errors="replace").strip()
            if line.startswith("CAL ERROR"):
                raise RuntimeError(line)
            if line == "CAL DUMP END":
                return result
            if line.startswith("CAL DATA "):
                fields = values(line)
                row = int(fields["ROW"])
                step = int(fields["STEP"])
                result[f"{row}:{step}"] = parse_tenths(fields["OVERLAY"])
        raise TimeoutError("fin de CAL DUMP non reçue")

    def options(self) -> dict[str, str]:
        return values(self.command("OPT?", "OPT "))


def save_session(path: Path, session: dict) -> None:
    session["updated_utc"] = utc_now()
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(
        json.dumps(session, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    temporary.replace(path)


def load_or_create_session(path: Path, rows: list[int], steps: list[int]) -> dict:
    if path.exists():
        session = json.loads(path.read_text(encoding="utf-8"))
        if session.get("version") != SESSION_VERSION:
            raise RuntimeError("version de fichier de session incompatible")
        if session.get("status") == "complete":
            raise RuntimeError("cette session est déjà terminée")
        if session.get("status") == "abandoned":
            raise RuntimeError(
                "cette session a été abandonnée définitivement ; choisir un autre fichier"
            )
        return session
    return {
        "version": SESSION_VERSION,
        "created_utc": utc_now(),
        "status": "new",
        "rows": rows,
        "steps": steps,
        "points": {},
    }


def abort_and_restore(link: SerialLink, session: dict, path: Path, status: str) -> None:
    response = link.best_effort("CAL ABORT", "CAL ABORTED")
    session["status"] = status
    session["abort_confirmed"] = response is not None and "RESTORED=1" in response
    save_session(path, session)
    if response:
        print(response)
    else:
        print(
            "ATTENTION : abandon non confirmé par la liaison série. "
            "Appuyer sur Adr RTL ou redémarrer l'appareil pour rejeter la banque de travail."
        )
    link.best_effort("GTL", "OK")


def run_manual_calibration(
    port: str,
    baud: int,
    session_path: Path,
    rows: list[int],
    steps: list[int],
    settle: float,
) -> int:
    try:
        session = load_or_create_session(session_path, rows, steps)
        link = SerialLink(port, baud)
    except (OSError, ValueError, RuntimeError, json.JSONDecodeError) as error:
        print(f"ERREUR : {error}", file=sys.stderr)
        return 1

    active = False
    try:
        link.command("REN1", "OK")
        option_values = link.options()
        doubler_installed = option_values.get("DOUBLER") == "1"
        if any(row >= BASE_ROWS for row in rows) and not doubler_installed:
            raise RuntimeError(
                "les lignes 30..40 nécessitent un appareil déclaré avec doubleur"
            )
        begin = link.command("CAL BEGIN", "CAL OK BEGIN")
        active = True
        begin_values = values(begin)
        base_crc = begin_values.get("BASE_CRC")
        generation = int(begin_values.get("GENERATION", "0"))
        if "base_crc" in session and session["base_crc"] != base_crc:
            raise RuntimeError("la table Flash a changé depuis cette session")
        if "generation" in session and session["generation"] != generation:
            raise RuntimeError("les corrections validées ont changé depuis cette session")
        session["base_crc"] = base_crc
        session["generation"] = generation
        session["profile"] = "x2" if doubler_installed else "base"

        for point in session["points"].values():
            if "overlay_tenths_db" in point:
                command = (
                    f"CAL SET {point['row']} {point['step']} "
                    f"{tenths_text(point['overlay_tenths_db'])}"
                )
                link.command(command, "CAL SET")

        session["status"] = "active"
        save_session(session_path, session)
        grid = [(row, step) for row in session["rows"] for step in session["steps"]]

        for ordinal, (row, step) in enumerate(grid, start=1):
            key = f"{row}:{step}"
            if session["points"].get(key, {}).get("done"):
                continue
            frequency = representative_frequency(row)
            requested = representative_amplitude(step)
            link.command(f"F{frequency} A{tenths_text(requested)} AM0 RF1", "OK")
            time.sleep(max(0.0, settle))
            status = link.command("CAL STATUS?", "CAL STATUS")
            status_values = values(status)
            if int(status_values.get("ROW", "-1")) != row or int(
                status_values.get("STEP", "-1")
            ) != step:
                raise RuntimeError(f"index inattendu retourné par le firmware: {status}")

            print()
            print(f"Point {ordinal}/{len(grid)} — ligne {row}, palier {step}")
            print(f"Fréquence demandée : {frequency / 1_000_000:g} MHz")
            print(f"Niveau demandé     : {tenths_text(requested)} dBm")
            print("Entrer la mesure, S pour ignorer, Q pour quitter.")

            while True:
                answer = input("Mesure en dBm : ").strip()
                upper = answer.upper()
                if upper == "S":
                    session["points"][key] = {
                        "row": row,
                        "step": step,
                        "frequency_hz": frequency,
                        "requested_tenths_dbm": requested,
                        "skipped": True,
                        "done": True,
                    }
                    save_session(session_path, session)
                    break
                if upper == "Q":
                    choice = input(
                        "[P]ause avec reprise possible ou [A]bandon définitif ? "
                    ).strip().upper()
                    status_name = "paused" if choice != "A" else "abandoned"
                    abort_and_restore(link, session, session_path, status_name)
                    active = False
                    return 2
                try:
                    measured = parse_tenths(answer)
                except ValueError as error:
                    print(f"Valeur invalide : {error}")
                    continue
                try:
                    applied = link.command(
                        f"CAL MEAS {tenths_text(measured)}", "CAL APPLIED"
                    )
                except RuntimeError as error:
                    if "CORRECTION_RANGE" in str(error):
                        print(
                            "Mesure refusée : elle produirait une correction hors de la "
                            "plage sûre. Vérifier la saisie et le point de mesure."
                        )
                        continue
                    raise
                applied_values = values(applied)
                residual = parse_tenths(applied_values["RESIDUAL"])
                overlay = parse_tenths(applied_values["OVERLAY"])
                print(applied)
                session["points"][key] = {
                    "row": row,
                    "step": step,
                    "frequency_hz": frequency,
                    "requested_tenths_dbm": requested,
                    "last_measured_tenths_dbm": measured,
                    "last_residual_tenths_db": residual,
                    "overlay_tenths_db": overlay,
                    "done": residual == 0,
                }
                save_session(session_path, session)
                if residual == 0:
                    print("Point vérifié à la résolution de 0,1 dB.")
                    break
                print("Correction appliquée : refaire la mesure, ou Q pour interrompre.")

        session["overlay"] = link.calibration_dump()
        save_session(session_path, session)
        end = link.command("CAL END", "CAL OK END")
        active = False
        session["status"] = "complete"
        session["committed_generation"] = int(values(end)["GENERATION"])
        session["restored"] = "RESTORED=1" in end
        save_session(session_path, session)
        link.command("GTL", "OK")
        print(end)
        print(f"Calibration terminée. Journal : {session_path}")
        return 0
    except KeyboardInterrupt:
        print("\nInterruption demandée.")
        if active:
            abort_and_restore(link, session, session_path, "interrupted")
        return 130
    except Exception as error:
        print(f"ERREUR : {error}", file=sys.stderr)
        if active:
            abort_and_restore(link, session, session_path, "error")
        return 1
    finally:
        link.close()


def decode_2816_byte(raw: int) -> int:
    value = (~raw) & 0xFF
    return value - 0x100 if value >= 0x80 else value


@dataclass(frozen=True)
class DumpAnalysis:
    digest: str
    minimum: int
    maximum: int
    erased_bytes: int
    warnings: list[str]


def analyze_2816(data: bytes, profile: str | None = None) -> DumpAnalysis:
    if len(data) != EEPROM_SIZE:
        raise ValueError(f"taille invalide : {len(data)} octets au lieu de {EEPROM_SIZE}")
    warnings: list[str] = []
    if data == bytes([0xFF]) * EEPROM_SIZE:
        warnings.append("dump entièrement effacé (FF) : toutes les corrections sont nulles")
    if data == bytes(EEPROM_SIZE):
        warnings.append("dump entièrement à 00 : état inhabituel pour une 2816 effacée")

    tail_anomalies = sum(
        data[row * ROW_STRIDE + column] != 0xFF
        for row in range(PHYSICAL_ROWS)
        for column in range(STEPS, ROW_STRIDE)
    )
    if tail_anomalies:
        warnings.append(
            f"{tail_anomalies} octet(s) non-FF dans les quatre colonnes normalement inutilisées"
        )
    x2_non_ff = sum(
        value != 0xFF
        for value in data[BASE_ROWS * ROW_STRIDE : ROWS * ROW_STRIDE]
    )
    if x2_non_ff and profile is None:
        warnings.append(
            f"{x2_non_ff} octet(s) non-FF dans les lignes 30..40 "
            "(profil X2 possible, à confirmer explicitement)"
        )
    unknown_non_ff = sum(value != 0xFF for value in data[ROWS * ROW_STRIDE :])
    if unknown_non_ff:
        warnings.append(
            f"{unknown_non_ff} octet(s) non-FF dans les lignes 41..63 "
            "(extension non prise en charge)"
        )
    active = [
        decode_2816_byte(data[row * ROW_STRIDE + step])
        for row in range(ROWS)
        for step in range(STEPS)
    ]
    unsafe = sum(value < -50 or value > 20 for value in active)
    if unsafe:
        warnings.append(
            f"{unsafe} correction(s) utile(s) hors de la plage sûre -5,0..+2,0 dB"
        )
    decoded = [decode_2816_byte(value) for value in data]
    return DumpAnalysis(
        digest=hashlib.sha256(data).hexdigest().upper(),
        minimum=min(decoded),
        maximum=max(decoded),
        erased_bytes=data.count(0xFF),
        warnings=warnings,
    )


def render_2816_include(source: Path, data: bytes, profile: str) -> str:
    analysis = analyze_2816(data, profile)
    lines = [
        "// Generated from an original Adret 2816 EEPROM dump.",
        f"// Source: {source.name}",
        f"// SHA-256: {analysis.digest}",
        "// Values are decoded signed corrections in 0.1 dB units.",
    ]
    for row in range(PHYSICAL_ROWS):
        decoded = [
            decode_2816_byte(value)
            for value in data[row * ROW_STRIDE : (row + 1) * ROW_STRIDE]
        ]
        comma = "," if row != PHYSICAL_ROWS - 1 else ""
        lines.append(f"// row {row:02d}")
        lines.append(", ".join(f"{value:+d}" for value in decoded) + comma)
    return "\n".join(lines) + "\n"


def profile_include_text(profile: str) -> str:
    value = "Doubler" if profile == "x2" else "Base"
    return f"CalibrationProfile::{value}\n"


def profile_path_for_table(table_path: Path) -> Path:
    return table_path.with_name("CalibrationProfile.inc")


def import_2816(
    dump_path: Path,
    output: Path | None,
    force: bool,
    profile: str | None = None,
) -> int:
    try:
        data = dump_path.read_bytes()
        analysis = analyze_2816(data, profile)
    except (OSError, ValueError) as error:
        print(f"ERREUR : {error}", file=sys.stderr)
        return 1

    print(f"Fichier     : {dump_path}")
    print(f"SHA-256     : {analysis.digest}")
    print(
        f"Corrections : {analysis.minimum / 10:+.1f} à "
        f"{analysis.maximum / 10:+.1f} dB"
    )
    print(f"Octets FF   : {analysis.erased_bytes} / {EEPROM_SIZE}")
    if analysis.warnings:
        for warning in analysis.warnings:
            print(f"ATTENTION   : {warning}")
    else:
        print("Structure   : cohérente avec la matrice 64 × 32 attendue")

    if output is None:
        return 0
    if profile not in {"base", "x2"}:
        print(
            "ERREUR : choisir explicitement le profil --profile base ou --profile x2",
            file=sys.stderr,
        )
        return 1
    first_unknown_row = BASE_ROWS if profile == "base" else ROWS
    unknown_non_ff = sum(
        value != 0xFF for value in data[first_unknown_row * ROW_STRIDE :]
    )
    if unknown_non_ff:
        print(
            f"ERREUR : {unknown_non_ff} octet(s) non-FF dans les lignes "
            f"{first_unknown_row}..63, incompatibles avec le profil {profile}",
            file=sys.stderr,
        )
        return 1
    if output.exists() and not force:
        print(f"ERREUR : {output} existe déjà ; confirmer son remplacement", file=sys.stderr)
        return 1
    try:
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(
            render_2816_include(dump_path, data, profile),
            encoding="utf-8",
            newline="\n",
        )
        profile_path_for_table(output).write_text(
            profile_include_text(profile), encoding="utf-8", newline="\n"
        )
    except OSError as error:
        print(f"ERREUR : {error}", file=sys.stderr)
        return 1
    print(f"Table écrite : {output}")
    print(f"Profil       : {profile.upper()}")
    print("Recompiler puis flasher le firmware pour activer cette table de base.")
    return 0


def crc16(table: list[int]) -> int:
    crc = 0xFFFF
    for value in table:
        crc ^= (value & 0xFF) << 8
        for _ in range(8):
            crc = (
                ((crc << 1) ^ 0x1021) & 0xFFFF
                if crc & 0x8000
                else (crc << 1) & 0xFFFF
            )
    return crc


def read_table(path: Path) -> list[int]:
    tokens: list[int] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        code = line.split("//", 1)[0]
        tokens.extend(int(value) for value in re.findall(r"[+-]?\d+", code))
    if len(tokens) == 1:
        tokens.extend([0] * (EEPROM_SIZE - 1))
    if len(tokens) != EEPROM_SIZE:
        raise ValueError(f"{path}: {len(tokens)} valeurs au lieu de {EEPROM_SIZE}")
    if any(value < -128 or value > 127 for value in tokens):
        raise ValueError(f"{path}: valeur hors plage int8_t")
    return tokens


def read_table_profile(path: Path) -> str:
    profile_path = profile_path_for_table(path)
    if not profile_path.exists():
        return "neutral"
    text = profile_path.read_text(encoding="utf-8")
    if "CalibrationProfile::Doubler" in text:
        return "x2"
    if "CalibrationProfile::Base" in text:
        return "base"
    if "CalibrationProfile::Neutral" in text:
        return "neutral"
    raise ValueError(f"{profile_path}: profil de calibration inconnu")


def render_merged_include(session_path: Path, table: list[int]) -> str:
    lines = [
        "// Generated by adret_calibration.py.",
        f"// Session: {session_path.name}",
        "// Signed corrections in 0.1 dB units.",
    ]
    for row in range(PHYSICAL_ROWS):
        row_values = table[row * ROW_STRIDE : (row + 1) * ROW_STRIDE]
        comma = "," if row != PHYSICAL_ROWS - 1 else ""
        lines.append(f"// row {row:02d}")
        lines.append(", ".join(f"{value:+d}" for value in row_values) + comma)
    return "\n".join(lines) + "\n"


def merge_session(session_path: Path, base_path: Path, output: Path, force: bool) -> int:
    try:
        session = json.loads(session_path.read_text(encoding="utf-8"))
        base = read_table(base_path)
        session_profile = str(session.get("profile", "base")).lower()
        if session_profile not in {"base", "x2"}:
            raise ValueError("profil de session invalide")
        table_profile = read_table_profile(base_path)
        if table_profile not in {"neutral", session_profile}:
            raise ValueError(
                f"profil de table {table_profile} incompatible avec la session "
                f"{session_profile}"
            )
        if session.get("status") != "complete":
            raise ValueError("la session n'est pas validée par CAL END")
        expected_crc = str(session.get("base_crc", "")).upper().lstrip("0") or "0"
        actual_crc = f"{crc16(base):X}"
        if expected_crc != actual_crc:
            raise ValueError(
                f"CRC de base différent : session={expected_crc}, fichier={actual_crc}"
            )
        overlay = session.get("overlay")
        if not isinstance(overlay, dict) or len(overlay) != ROWS * STEPS:
            raise ValueError("dump complet de l'overlay absent du fichier de session")

        merged = list(base)
        for key, delta in overlay.items():
            row_text, step_text = key.split(":", 1)
            row = int(row_text)
            step = int(step_text)
            if row not in range(ROWS) or step not in range(STEPS):
                raise ValueError(f"index overlay invalide : {key}")
            index = row * ROW_STRIDE + step
            merged[index] += int(delta)
            if merged[index] < -128 or merged[index] > 127:
                raise ValueError(f"dépassement int8_t à {key}")
    except (OSError, TypeError, ValueError, json.JSONDecodeError) as error:
        print(f"ERREUR : {error}", file=sys.stderr)
        return 1

    if output.exists() and not force:
        print(f"ERREUR : {output} existe déjà ; confirmer son remplacement", file=sys.stderr)
        return 1
    try:
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(
            render_merged_include(session_path, merged), encoding="utf-8", newline="\n"
        )
        profile_path_for_table(output).write_text(
            profile_include_text(session_profile), encoding="utf-8", newline="\n"
        )
    except OSError as error:
        print(f"ERREUR : {error}", file=sys.stderr)
        return 1
    print(f"Table fusionnée : {output}")
    print(f"CRC base        : {actual_crc}")
    print(f"CRC fusionné    : {crc16(merged):X}")
    print(f"Profil          : {session_profile.upper()}")
    print(
        "Après flashage, le changement de CRC désactivera automatiquement "
        "l'ancien overlay EEPROM."
    )
    return 0


def ask(prompt: str, default: str | None = None) -> str:
    suffix = f" [{default}]" if default is not None else ""
    answer = input(f"{prompt}{suffix} : ").strip()
    return answer if answer else (default or "")


def ask_path(prompt: str, default: Path) -> Path:
    text = ask(prompt, str(default)).strip().strip('"')
    path = Path(text).expanduser()
    return path if path.is_absolute() else PROJECT_ROOT / path


def confirm(prompt: str, default: bool = False) -> bool:
    hint = "O/n" if default else "o/N"
    answer = input(f"{prompt} [{hint}] : ").strip().lower()
    if not answer:
        return default
    return answer in {"o", "oui", "y", "yes"}


def available_serial_ports() -> list[tuple[str, str]]:
    try:
        from serial.tools import list_ports  # type: ignore
    except ImportError:
        return []
    return [(item.device, item.description) for item in list_ports.comports()]


def choose_serial_port() -> str:
    ports = available_serial_ports()
    if ports:
        print("\nPorts série détectés :")
        for index, (device, description) in enumerate(ports, start=1):
            print(f"  {index}. {device} — {description}")
        answer = ask("Numéro du port ou nom saisi manuellement", "1")
        if answer.isdigit() and 1 <= int(answer) <= len(ports):
            return ports[int(answer) - 1][0]
        return answer
    print("Aucun port détecté automatiquement (ou pyserial absent).")
    return ask("Nom du port série", "COM3")


def pause_menu() -> None:
    input("\nAppuyer sur Entrée pour revenir au menu...")


def menu_manual_calibration() -> None:
    print("\n--- Calibration manuelle ---")
    port = choose_serial_port()
    session_path = ask_path("Fichier journal", DEFAULT_SESSION)
    rows_text = ask("Lignes de fréquence (all, 0-8, 18-28...)", "all")
    steps_text = ask("Paliers d'amplitude (all, 0-4, 15...)", "all")
    settle_text = ask("Temps de stabilisation en secondes", "0.5")
    try:
        rows = parse_selection(rows_text, ROWS - 1)
        steps = parse_selection(steps_text, STEPS - 1)
        settle = float(settle_text.replace(",", "."))
        if settle < 0:
            raise ValueError("le temps de stabilisation doit être positif")
    except ValueError as error:
        print(f"ERREUR : {error}")
        pause_menu()
        return
    print(
        f"\n{len(rows) * len(steps)} point(s), port {port}, journal {session_path}."
    )
    print("Le générateur doit être relié au PC et à l'instrument de mesure.")
    if confirm("Démarrer la calibration ?"):
        run_manual_calibration(port, 115200, session_path, rows, steps, settle)
    pause_menu()


def default_dump_path() -> Path:
    candidates = sorted(DEFAULT_DUMP_DIRECTORY.glob("*.BIN"))
    return candidates[0] if candidates else DEFAULT_DUMP_DIRECTORY / "dump_2816.BIN"


def menu_import_2816() -> None:
    print("\n--- Analyse ou import d'une EEPROM 2816 ---")
    dump_path = ask_path("Dump binaire de la 2816", default_dump_path())
    result = import_2816(dump_path, None, False)
    if result == 0 and confirm("Générer la table Flash à partir de ce dump ?"):
        profile = ask("Profil du générateur (base ou x2)", "base").lower()
        if profile not in {"base", "x2"}:
            print("Profil invalide ; import annulé.")
            pause_menu()
            return
        output = ask_path("Table Flash de destination", DEFAULT_TABLE)
        if output.exists() and not confirm(f"Remplacer {output} ?"):
            print("Import annulé ; aucune modification effectuée.")
        else:
            import_2816(dump_path, output, True, profile)
    pause_menu()


def menu_merge_session() -> None:
    print("\n--- Fusion d'une session validée dans la Flash ---")
    session_path = ask_path("Fichier journal terminé", DEFAULT_SESSION)
    base_path = ask_path("Table Flash de base", DEFAULT_TABLE)
    output = ask_path("Table Flash de destination", DEFAULT_TABLE)
    print(
        "La fusion additionne l'overlay validé à la table de base. "
        "Il faudra ensuite recompiler et flasher le firmware."
    )
    if output.exists() and not confirm(f"Remplacer {output} ?"):
        print("Fusion annulée ; aucune modification effectuée.")
    elif confirm("Effectuer la fusion ?"):
        merge_session(session_path, base_path, output, True)
    pause_menu()


def interactive_menu() -> int:
    while True:
        print("\n============================================")
        print("  ADRET 740A — Calibration de l'amplitude")
        print("============================================")
        print("  1. Calibration manuelle guidée")
        print("  2. Analyser ou importer une EEPROM 2816")
        print("  3. Fusionner une session dans la Flash")
        print("  0. Quitter")
        choice = input("\nVotre choix : ").strip()
        if choice == "1":
            menu_manual_calibration()
        elif choice == "2":
            menu_import_2816()
        elif choice == "3":
            menu_merge_session()
        elif choice in {"0", "q", "Q"}:
            print("Au revoir.")
            return 0
        else:
            print("Choix invalide.")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Application unifiée de calibration d'amplitude du 740A"
    )
    subparsers = parser.add_subparsers(dest="command")

    calibrate = subparsers.add_parser("calibrate", help="calibration manuelle")
    calibrate.add_argument("--port", required=True, help="port série, par exemple COM3")
    calibrate.add_argument("--baud", type=int, default=115200)
    calibrate.add_argument("--session", type=Path, default=DEFAULT_SESSION)
    calibrate.add_argument("--rows", default="all")
    calibrate.add_argument("--steps", default="all")
    calibrate.add_argument("--settle", type=float, default=0.5)

    importer = subparsers.add_parser("import", help="analyser/importer une 2816")
    importer.add_argument("dump", type=Path)
    importer.add_argument("--output", type=Path)
    importer.add_argument("--force", action="store_true")
    importer.add_argument("--profile", choices=("base", "x2"))

    merger = subparsers.add_parser("merge", help="fusionner une session")
    merger.add_argument("session", type=Path)
    merger.add_argument("--base", type=Path, default=DEFAULT_TABLE)
    merger.add_argument("--output", type=Path, required=True)
    merger.add_argument("--force", action="store_true")
    return parser


def main(argv: list[str] | None = None) -> int:
    arguments = sys.argv[1:] if argv is None else argv
    if not arguments:
        try:
            return interactive_menu()
        except (EOFError, KeyboardInterrupt):
            print("\nAu revoir.")
            return 0

    parser = build_parser()
    args = parser.parse_args(arguments)
    if args.command == "calibrate":
        try:
            rows = parse_selection(args.rows, ROWS - 1)
            steps = parse_selection(args.steps, STEPS - 1)
        except ValueError as error:
            parser.error(str(error))
        return run_manual_calibration(
            args.port, args.baud, args.session, rows, steps, args.settle
        )
    if args.command == "import":
        return import_2816(args.dump, args.output, args.force, args.profile)
    if args.command == "merge":
        return merge_session(args.session, args.base, args.output, args.force)
    parser.print_help()
    return 2


if __name__ == "__main__":
    sys.exit(main())
