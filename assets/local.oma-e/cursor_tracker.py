#!/usr/bin/env python3
"""Low-overhead Hyprland cursor position stream over UNIX domain socket.

Polls Hyprland's .socket.sock at ~30 Hz and writes "x y" to stdout only when
the cursor moves, avoiding subprocess forks and keeping CPU usage near zero.
"""

import os
import socket
import sys
import time


def socket_path() -> str:
    runtime = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
    sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", "")
    if not sig:
        hypr_dir = os.path.join(runtime, "hypr")
        if os.path.isdir(hypr_dir):
            entries = sorted(os.listdir(hypr_dir))
            if entries:
                sig = entries[0]
    return os.path.join(runtime, "hypr", sig, ".socket.sock")


def query_cursor(path: str):
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.settimeout(0.25)
        s.connect(path)
        s.sendall(b"cursorpos")
        raw = s.recv(128).decode("utf-8", errors="ignore").strip()
    if "," not in raw:
        return None
    parts = raw.split(",", 1)
    return int(float(parts[0].strip())), int(float(parts[1].strip()))


def main() -> int:
    last = None
    interval = 1.0 / 30.0
    path = socket_path()

    while True:
        try:
            pos = query_cursor(path)
            if pos is not None and pos != last:
                last = pos
                sys.stdout.write(f"{pos[0]} {pos[1]}\n")
                sys.stdout.flush()
        except OSError:
            # Hyprland may be reloading; refresh socket path and back off briefly.
            path = socket_path()
            time.sleep(0.5)
            continue
        except (ValueError, TypeError):
            pass
        time.sleep(interval)


if __name__ == "__main__":
    raise SystemExit(main())
