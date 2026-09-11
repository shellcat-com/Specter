#!/usr/bin/env python3
"""Validate the study catalog and exercise cleanup in disposable POSIX PTYs."""
import fcntl
import json
import os
from pathlib import Path
import pty
import re
import select
import signal
import struct
import subprocess
import sys
import termios
import time

ROOT = Path(__file__).resolve().parents[2]
ARTIFACTS = ROOT / ".artifacts/mascot-lab"
COMMAND = [sys.executable, str(ROOT / "scripts/preview-mascots.py")]


def check_pty(mode):
    master, slave = pty.openpty()
    height, width = (18, 27) if mode == "normal" else (48, 108)
    fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", height, width, 0, 0))
    process = subprocess.Popen(
        COMMAND + ["--all", "--state", "working", "--seconds", "1"],
        stdout=slave, stderr=slave, env={**os.environ, "TERM": "xterm-256color"})
    os.close(slave)
    output = bytearray()
    start, sent = time.monotonic(), False
    try:
        while time.monotonic() - start < 5:
            if select.select([master], [], [], 0.03)[0]:
                try:
                    chunk = os.read(master, 65536)
                except OSError:
                    break
                if not chunk:
                    break
                output.extend(chunk)
            if mode != "normal" and not sent and time.monotonic() - start > 0.3:
                process.send_signal(signal.SIGTERM if mode == "sigterm" else signal.SIGINT)
                sent = True
        process.wait(timeout=2)
        assert process.returncode == 0, (mode, process.returncode)
        assert output.startswith(b"\x1b[?1049h\x1b[?25l")
        assert output.endswith(b"\x1b[0m\x1b[?25h\x1b[?1049l")
        assert output.count(b"\x1b[H") >= 2
        for frame in output.decode().split("\x1b[H")[1:]:
            lines = re.sub(r"\x1b\[[0-9;?]*[A-Za-z]", "", frame).replace("\r", "").splitlines()
            assert len(lines) <= height and all(len(line) <= width for line in lines)
        (ARTIFACTS / (mode + ".ansi")).write_bytes(output)
    finally:
        if process.poll() is None:
            process.kill()
            process.wait()
        os.close(master)
    return mode + ": real PTY, multiple frames, cursor/colors/screen restored, exit 0."


def main():
    ARTIFACTS.mkdir(parents=True, exist_ok=True)
    raw = (ROOT / "design/mascots/catalog.json").read_text().strip()
    catalog = json.loads(raw)
    assert len(catalog["mascots"]) == 12
    assert len({m["id"] for m in catalog["mascots"]}) == 12
    for mascot in catalog["mascots"]:
        assert set(mascot["states"]) == {"idle", "working", "celebrate"}
        for frames in mascot["states"].values():
            assert len(frames) == 12 and len({tuple(f) for f in frames}) > 1
            for frame in frames:
                assert len(frame) == 24
                assert all(len(row) == 24 and set(row) <= set(".BAo") for row in frame)
    assert raw in (ROOT / "design/mascots/gallery.html").read_text()
    output = subprocess.run(COMMAND + ["--all"], capture_output=True, check=True).stdout
    assert b"\x1b" not in output
    for duration in ("nan", "inf", "-1", "301"):
        assert subprocess.run(COMMAND + ["--seconds", duration], capture_output=True).returncode == 2
    records = ["12 unique mascots; 432 bounded frames; motion in every state; gallery catalog matches.",
               "Redirected output contains no ANSI; invalid durations rejected."]
    records.extend(check_pty(mode) for mode in ("normal", "sigterm", "sigint"))
    (ARTIFACTS / "validation.txt").write_text("\n".join(records) + "\n")
    print("\n".join(records))


if __name__ == "__main__":
    main()
