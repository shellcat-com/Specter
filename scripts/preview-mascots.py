#!/usr/bin/env python3
"""Explicit, standalone ANSI preview. Never installs shell hooks or reads sessions."""
import argparse
import json
import math
import os
from pathlib import Path
import shutil
import signal
import sys
import time

CATALOG = Path(__file__).resolve().parents[1] / "design/mascots/catalog.json"
ESC = "\x1b["


def rgb(value):
    return ";".join(str(int(value[i:i + 2], 16)) for i in (1, 3, 5))


def render(rows, colors, plain=False):
    if plain:
        return ["".join("  " if c == "." else "oo" if c == "o" else "##" for c in row) for row in rows]
    result = []
    for top, bottom in zip(rows[::2], rows[1::2]):
        line = []
        for upper, lower in zip(top, bottom):
            if upper == lower == ".":
                line.append(ESC + "0m ")
            elif lower == ".":
                line.append(ESC + "0;38;2;" + rgb(colors[upper]) + "m▀")
            elif upper == ".":
                line.append(ESC + "0;38;2;" + rgb(colors[lower]) + "m▄")
            else:
                line.append(ESC + "38;2;" + rgb(colors[upper]) + ";48;2;" + rgb(colors[lower]) + "m▀")
        result.append("".join(line) + ESC + "0m")
    return result


def main():
    data = json.loads(CATALOG.read_text())
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mascot", default="wisp", choices=[m["id"] for m in data["mascots"]])
    parser.add_argument("--state", default="idle", choices=["idle", "working", "celebrate"])
    parser.add_argument("--all", action="store_true", help="Animate all twelve in a responsive grid")
    parser.add_argument("--still", action="store_true", help="Print one frame; no animation or alternate screen")
    parser.add_argument("--plain", action="store_true", help="ASCII output without ANSI colors or cursor control")
    parser.add_argument("--seconds", type=float, default=20, help="Finite duration, 0.1–300 seconds (default 20)")
    args = parser.parse_args()
    if not math.isfinite(args.seconds) or not 0.1 <= args.seconds <= 300:
        parser.error("--seconds must be finite and between 0.1 and 300")
    selected = data["mascots"] if args.all else [next(m for m in data["mascots"] if m["id"] == args.mascot)]
    plain = args.plain or not sys.stdout.isatty() or os.environ.get("TERM") == "dumb"
    still = args.still or plain
    if still:
        for mascot in selected:
            print(mascot["name"] + " / " + args.state)
            print("\n".join(render(mascot["states"][args.state][0], mascot["colors"], plain)))
        return

    def stop(_signum, _frame):
        raise KeyboardInterrupt

    for sig in (signal.SIGTERM, signal.SIGHUP):
        signal.signal(sig, stop)
    # No raw input mode: Ctrl-C remains native terminal behavior.
    try:
        sys.stdout.write(ESC + "?1049h" + ESC + "?25l")
        start = time.monotonic()
        while time.monotonic() - start < args.seconds:
            width, height = shutil.get_terminal_size()
            tick = int((time.monotonic() - start) * data["fps"])
            columns = max(1, min(4, width // 27))
            capacity = columns * max(1, (height - 4) // 14)
            page_count = math.ceil(len(selected) / capacity)
            page = (tick // 32) % page_count
            visible = selected[page * capacity:(page + 1) * capacity]
            lines = ["SPECTER / MASCOT STUDIES", f"{args.state} {page + 1}/{page_count} | Ctrl-C", ""]
            if width < 27 or height < 18:
                lines = ["Resize to 27 x 18 or larger."]
            else:
                for offset in range(0, len(visible), columns):
                    group = visible[offset:offset + columns]
                    lines.append("".join(m["name"].ljust(27) for m in group).rstrip())
                    sprites = [render(m["states"][args.state][tick % 12], m["colors"]) for m in group]
                    for row in range(12):
                        lines.append("   ".join(sprite[row] for sprite in sprites))
                    lines.append("")
            # Clear each line, avoiding full-screen clear and its visible flash.
            output = ESC + "H" + "\r\n".join(ESC + "2K" + line for line in lines) + ESC + "J"
            sys.stdout.write(output)
            sys.stdout.flush()
            time.sleep(1 / data["fps"])
    except KeyboardInterrupt:
        pass
    finally:
        sys.stdout.write(ESC + "0m" + ESC + "?25h" + ESC + "?1049l")
        sys.stdout.flush()


if __name__ == "__main__":
    try:
        main()
    except BrokenPipeError:
        pass
