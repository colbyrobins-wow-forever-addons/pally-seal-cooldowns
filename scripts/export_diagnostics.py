"""Export saved addon diagnostics without executing the SavedVariables Lua file."""

import argparse
import logging
import re
from pathlib import Path

LOGGER = logging.getLogger(__name__)
LOG_BLOCK = re.compile(
    r'^\s*\["debugLog"\]\s*=\s*\{\s*\n(.*?)^\s*\}',
    re.MULTILINE | re.DOTALL,
)
LOG_ENTRY = re.compile(r'\s*(?:\[\d+\]\s*=\s*)?"((?:[^"\\]|\\.)*)"\s*,?\s*')
ESCAPES = {"n": "\n", "r": "\r", "t": "\t", '"': '"', "\\": "\\",
           "a": "\a", "b": "\b", "f": "\f", "v": "\v", "'": "'"}


def decode_lua_string(value: str) -> str:
    """Decode the quoted-string escapes used by WoW's saved data writer."""
    result = bytearray()
    index = 0
    while index < len(value):
        character = value[index]
        if character != "\\":
            result.extend(character.encode("utf-8"))
            index += 1
            continue
        index += 1
        if index >= len(value):
            raise ValueError("Incomplete escape in a diagnostic entry.")
        character = value[index]
        if character.isascii() and character.isdigit():
            end = index
            while end < min(index + 3, len(value)) and value[end].isascii() and value[end].isdigit():
                end += 1
            number = int(value[index:end])
            if number > 255:
                raise ValueError("Invalid byte escape in a diagnostic entry.")
            result.append(number)
            index = end
        elif character in ESCAPES:
            result.extend(ESCAPES[character].encode("utf-8"))
            index += 1
        else:
            raise ValueError("Unsupported escape in a diagnostic entry.")
    return result.decode("utf-8")


def extract_diagnostics(source: str) -> list[str]:
    """Extract only the debugLog strings; reject missing or malformed captures."""
    match = LOG_BLOCK.search(source)
    if match is None:
        raise ValueError("No saved capture found. Use /psc debug on, reproduce, then /reload.")
    entries = []
    for line in match.group(1).splitlines():
        if not line.strip():
            continue
        entry = LOG_ENTRY.fullmatch(line)
        if entry is None:
            raise ValueError("Unexpected diagnostic data format; the Lua file was not executed.")
        entries.append(decode_lua_string(entry.group(1)))
    if not entries:
        raise ValueError("Capture is empty. Enable diagnostics, reproduce the issue, then /reload.")
    if len(entries) > 100:
        raise ValueError("Capture exceeds the addon's 100-entry limit.")
    return entries


def export_diagnostics(source: Path, output: Path) -> int:
    """Write a UTF-8 report containing only captured diagnostic entries."""
    if source.resolve() == output.resolve():
        raise ValueError("Output must differ from the SavedVariables source file.")
    entries = extract_diagnostics(source.read_text(encoding="utf-8-sig"))
    report = "Pally Seal Cooldowns diagnostic capture\n\n" + "\n".join(entries) + "\n"
    output.write_text(report, encoding="utf-8")
    LOGGER.info("Exported %d diagnostic entries to %s", len(entries), output)
    return len(entries)


def main() -> int:
    """Parse file paths and report actionable export failures."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, help="SavedVariables/PallySealCooldowns.lua")
    parser.add_argument("output", type=Path, help="Destination text file (replaced on success)")
    args = parser.parse_args()
    logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
    try:
        export_diagnostics(args.source, args.output)
    except (OSError, ValueError) as error:
        LOGGER.error("Export failed: %s", error)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
