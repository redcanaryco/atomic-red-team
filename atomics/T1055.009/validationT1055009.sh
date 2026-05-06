#!/bin/bash

BIN_DIR="bin"

executables=(
    "$BIN_DIR/inplace_instruction_overwrite"
    "$BIN_DIR/instruction_overwrite_jump"
    "$BIN_DIR/got_injection"
    "$BIN_DIR/rop_mprotect_return_address_overwrite"
    "$BIN_DIR/return_address_overwrite"
    "$BIN_DIR/return_address_overwrite_fullROPchain"
)

rm /tmp/pwned
for exe in "${executables[@]}"; do
    echo "[*] Running: $exe"
    "$exe"
    sleep 3
    if rm /tmp/pwned 2>/dev/null; then
        echo "[+] $exe: OK (pwned file removed)"
    else
        echo "[!] FAILED: $exe did not create /tmp/pwned"
        exit 1
    fi
done

echo ""
echo "[✓] All tests passed"