#!/usr/bin/env python3
"""Exercise helper cleanup after its application-side owner dies, using synthetic sessions."""
import ctypes, json, os, re, select, signal, subprocess, sys, time
from pathlib import Path
ROOT = Path(__file__).resolve().parent.parent
library = ctypes.CDLL(str(ROOT / '.artifacts/libPTYProbe.dylib'))
start = library.specter_start
start.argtypes = [ctypes.c_char_p] * 4 + [ctypes.c_int] * 2 + [ctypes.POINTER(ctypes.c_int)] * 3

def launch():
    fd, life, pid = ctypes.c_int(-1), ctypes.c_int(-1), ctypes.c_int()
    error = start(str(ROOT / '.build/release/SpecterPTY').encode(), b'/bin/sh', b'/tmp', b'', 24, 80, ctypes.byref(fd), ctypes.byref(life), ctypes.byref(pid))
    if error: raise OSError(error, os.strerror(error))
    os.write(fd.value, b"printf '\\nSHELL=%s\\n' \"$$\"\n")
    output = b''; deadline = time.monotonic() + 5
    while time.monotonic() < deadline:
        if select.select([fd.value], [], [], .1)[0]:
            output += os.read(fd.value, 4096)
            match = re.search(rb'SHELL=(\d+)', output)
            if match: return fd.value, life.value, pid.value, int(match[1])
    raise RuntimeError('Shell did not respond')

if '--child' in sys.argv:
    fd, life, helper, shell = launch()
    print(json.dumps({'helper': helper, 'shell': shell}), flush=True)
    os.kill(os.getpid(), signal.SIGKILL)

child = subprocess.run([sys.executable, __file__, '--child'], stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=10)
ids = json.loads(child.stdout)
deadline = time.monotonic() + 5
remaining = dict(ids)
while remaining and time.monotonic() < deadline:
    for name, pid in list(remaining.items()):
        try: os.kill(pid, 0)
        except ProcessLookupError: del remaining[name]
    time.sleep(.02)
result = {'scenario': 'application-side SIGKILL', 'parent_returncode': child.returncode, 'helper_and_shell_gone': not remaining, 'deadline_seconds': 5}
print(json.dumps(result, indent=2))
if remaining: sys.exit(1)
