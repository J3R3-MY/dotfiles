#!/usr/bin/env python3
"""Minimal AirPods bridge for the fluid shell (no extra packages).

Speaks Apple's AAP protocol over Bluetooth L2CAP (PSM 0x1001), the same
packets LibrePods/omarchy-pods use, to read per-pod + case battery, noise
control mode, conversational awareness and ear detection, and to set the
noise mode. The AirPods must already be connected as normal audio through
BlueZ; this only opens the extra control channel.

Protocol: prints one JSON object per line on stdout whenever something
changes. Reads commands on stdin:
    anc off|on|transparency|adaptive
    ca on|off
"""
import json
import os
import select
import socket
import subprocess
import sys
import time

AAP_UUID = "74ec2172-0bad-4d01-8f77-997b2be0722a"
PSM = 0x1001

HANDSHAKE = bytes.fromhex("00000400010002000000000000000000")
SET_FEATURES = bytes.fromhex("040004004d00d700000000000000")
REQUEST_NOTIFICATIONS = bytes.fromhex("040004000f00ffffffffff")

BATTERY = bytes.fromhex("040004000400")
EAR = bytes.fromhex("040004000600")
CONTROL = bytes.fromhex("040004000900")   # + identifier + value

NOISE_ID, CA_ID = 0x0D, 0x28
NOISE_MODES = {1: "off", 2: "on", 3: "transparency", 4: "adaptive"}
NOISE_CODES = {v: k for k, v in NOISE_MODES.items()}
COMPONENTS = {0x01: "headset", 0x02: "right", 0x04: "left", 0x08: "case"}
EAR_STATE = {0: "ear", 1: "out", 2: "case"}

state = {}


def emit(**changes):
    state.update(changes)
    print(json.dumps(state), flush=True)


def find_airpods():
    """MAC of a connected device that offers the AAP service, or None."""
    try:
        out = subprocess.run(["bluetoothctl", "devices", "Connected"], capture_output=True, text=True, timeout=5).stdout
    except Exception:
        return None, None
    for line in out.splitlines():
        parts = line.split(" ", 2)
        if len(parts) < 3:
            continue
        mac, name = parts[1], parts[2]
        try:
            info = subprocess.run(["bluetoothctl", "info", mac], capture_output=True, text=True, timeout=5).stdout
        except Exception:
            continue
        if AAP_UUID in info.lower() or "airpods" in name.lower():
            return mac, name
    return None, None


def control(ident, value):
    return CONTROL + bytes([ident, value, 0, 0, 0])


def parse(pkt):
    if pkt.startswith(BATTERY) and len(pkt) >= 7:
        count = pkt[6]
        batt = dict(state.get("battery", {}))
        for i in range(min(count, 3)):
            o = 7 + 5 * i
            if o + 4 >= len(pkt):
                break
            comp, level, status = pkt[o], pkt[o + 2], pkt[o + 3]
            name = COMPONENTS.get(comp)
            if name and status != 0x04:            # 0x04 = disconnected / unknown
                batt[name] = {"level": level, "charging": status == 0x01}
        emit(battery=batt)
    elif pkt.startswith(EAR) and len(pkt) >= 8:
        prev = state.get("ear", ["", ""])
        now = [EAR_STATE.get(pkt[6], "?"), EAR_STATE.get(pkt[7], "?")]
        emit(ear=now)
        # pause when both buds come out, like the AirPods do on a phone
        if "ear" in prev and "ear" not in now:
            subprocess.run(["playerctl", "pause"], capture_output=True)
    elif pkt.startswith(CONTROL) and len(pkt) >= 8:
        ident, value = pkt[6], pkt[7]
        if ident == NOISE_ID:
            emit(anc=NOISE_MODES.get(value, "off"))
        elif ident == CA_ID:
            emit(ca=value == 1)


def session(mac, name):
    s = socket.socket(socket.AF_BLUETOOTH, socket.SOCK_SEQPACKET, socket.BTPROTO_L2CAP)
    s.settimeout(10)
    s.connect((mac, PSM))
    s.settimeout(None)
    for pkt in (HANDSHAKE, SET_FEATURES, REQUEST_NOTIFICATIONS):
        s.send(pkt)
    emit(connected=True, name=name, mac=mac)
    try:
        while True:
            r, _, _ = select.select([s, sys.stdin], [], [], 30)
            if s in r:
                pkt = s.recv(1024)
                if not pkt:
                    break
                parse(pkt)
            if sys.stdin in r:
                line = sys.stdin.readline()
                if not line:
                    sys.exit(0)              # shell went away
                cmd = line.split()
                if len(cmd) == 2 and cmd[0] == "anc" and cmd[1] in NOISE_CODES:
                    s.send(control(NOISE_ID, NOISE_CODES[cmd[1]]))
                elif len(cmd) == 2 and cmd[0] == "ca":
                    s.send(control(CA_ID, 1 if cmd[1] == "on" else 2))
    finally:
        s.close()


def main():
    if not hasattr(socket, "AF_BLUETOOTH"):
        emit(error="python without Bluetooth socket support")
        return
    while True:
        mac, name = find_airpods()
        if mac:
            try:
                session(mac, name)
            except OSError as e:
                emit(error=str(e))
        if state.get("connected"):
            state.clear()
            emit(connected=False)
        # cheap idle poll; also drain stdin so a closed shell ends us
        r, _, _ = select.select([sys.stdin], [], [], 8)
        if r and not sys.stdin.readline():
            return


if __name__ == "__main__":
    emit(connected=False)
    main()
