#!/usr/bin/env python3
# Native messaging host for the Personal Agents Drawer extension.
#
# Chromium starts it for each message from the extension. It accepts exactly
# one whitelisted command for a whitelisted agent, relays it to the Hyprland
# side (agents_drawer, loaded from the plugin's hypr/agents-drawer.lua) and exits. Nothing
# from the message is ever passed through unchecked.
import json
import os
import struct
import subprocess
import sys

COMMANDS = {"show", "ensure", "hide", "close"}


def agents():
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "agents.resolved.json")
    try:
        with open(path) as f:
            return {a["id"] for a in json.load(f)}
    except (OSError, ValueError, KeyError, TypeError):
        return set()


APPS = {"home"} | agents()


def read():
    raw = sys.stdin.buffer.read(4)
    if len(raw) < 4:
        return None
    (size,) = struct.unpack("<I", raw)
    if size > 4096:
        return None
    try:
        return json.loads(sys.stdin.buffer.read(size))
    except ValueError:
        return None


def write(obj):
    data = json.dumps(obj).encode()
    sys.stdout.buffer.write(struct.pack("<I", len(data)) + data)
    sys.stdout.buffer.flush()


msg = read()
if not isinstance(msg, dict):
    msg = {}
cmd, app = msg.get("cmd"), msg.get("app", "home")
if cmd not in COMMANDS or app not in APPS:
    write({"ok": False, "error": "rejected"})
    sys.exit(0)

try:
    r = subprocess.run(
        ["hyprctl", "eval", f'agents_drawer.{cmd}("{app}")'],
        capture_output=True,
        timeout=3,
    )
    write({"ok": r.returncode == 0})
except (OSError, subprocess.TimeoutExpired) as e:
    write({"ok": False, "error": type(e).__name__})
