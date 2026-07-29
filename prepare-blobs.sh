#!/bin/bash
#
# Fetch proprietary decryption blobs for TWRP (Infinix NOTE 12 2023 - X676C)
# into recovery/root/. These are binaries that cannot live in this git tree.
#
# Sources:
#   - X676C stock blobs:  god-dark-z/android_vendor_infinix_X676C (main-X676C)
#   - Generic AOSP libs:  Juanstews/twrp_device_Infinix_X6837 (twrp_12.1)
#
# Run from the source tree root or the device dir. Idempotent: skips files
# that already exist.

set -u
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$DIR/recovery/root"
VND="https://raw.githubusercontent.com/god-dark-z/android_vendor_infinix_X676C/main-X676C/proprietary"
REF="https://raw.githubusercontent.com/Juanstews/twrp_device_Infinix_X6837/twrp_12.1/recovery/root"
API="https://api.github.com/repos/god-dark-z/android_vendor_infinix_X676C/contents/proprietary/vendor/app/mcRegistry?ref=main-X676C"

fetch() { # $1=url $2=dest
    if [ -s "$2" ]; then echo "  [skip] $2"; return 0; fi
    mkdir -p "$(dirname "$2")"
    if curl -sfL --retry 3 -o "$2" "$1"; then echo "  [ok]   $2"; else echo "  [FAIL] $1"; MISSING=1; fi
}

MISSING=0
echo "== mcRegistry TAs (X676C stock) =="
for f in $(curl -sfL "$API" | grep -o '"name": *"[^"]*"' | cut -d'"' -f4); do
    fetch "$VND/vendor/app/mcRegistry/$f" "$ROOT/vendor/app/mcRegistry/$f"
done

echo "== TEE / gatekeeper / keymint binaries (X676C stock) =="
# NOTE: gatekeeper.trustonic.so and gatekeeper.default.so are intentionally NOT
# fetched here - they are symlinks in the vendor repo and a raw fetch returns an
# 18/20-byte text stub, which makes the gatekeeper@1.0 HAL abort (SIGABRT crash
# loop) and FBE decryption hang. They are recreated from real targets below.
for f in \
    vendor/bin/mcDriverDaemon \
    "vendor/bin/hw/android.hardware.gatekeeper@1.0-service" \
    vendor/bin/hw/android.hardware.security.keymint-service.trustonic \
    vendor/lib64/libMcClient.so \
    "vendor/lib64/hw/android.hardware.gatekeeper@1.0-impl.so" \
    vendor/lib64/hw/libMcGatekeeper.so \
    vendor/lib64/hw/libSoftGatekeeper.so \
    ; do
    fetch "$VND/$f" "$ROOT/$f"
done


echo "== Extra TEE TAs shipped in the proven mt6789 fox ramdisk =="
COMMON="https://raw.githubusercontent.com/transsion-mt6789/twrp-device_transsion_mt6789-common/fox_12.1/recovery/root"
for f in \
    vendor/app/mcRegistry/030c0000000000000000000000000000.drbin \
    vendor/app/mcRegistry/030c0000000000000000000000000000.tlbin \
    vendor/app/mcRegistry/05060000000000000000000000000000.tabin \
    vendor/app/mcRegistry/05070000000000000000000000000000.drbin \
    vendor/app/mcRegistry/08040000000000000000000000003419.tabin \
    vendor/app/mcRegistry/08050000000000000000000000003419.drbin \
    vendor/app/mcRegistry/08050000000000000000000000003419.tlbin \
    ; do
    fetch "$COMMON/$f" "$ROOT/$f"
done

echo "== Generic AOSP keymaster libs (from X6837 twrp tree) =="
for f in \
    vendor/lib64/libkeymaster4.so \
    vendor/lib64/libkeymaster41.so \
    "vendor/lib64/android.hardware.gatekeeper@1.0.so" \
    ; do
    fetch "$REF/$f" "$ROOT/$f"
done

# --- Materialize the gatekeeper HAL impl modules -------------------------------
# ro.hardware.gatekeeper=trustonic, so the HAL dlopen()s gatekeeper.trustonic.so.
# Ship both impls as REAL copies of their targets (the known-good X6837 tree does
# the same), instead of the vendor repo's symlinks that raw fetch would corrupt.
echo "== Materialize gatekeeper HAL impl modules =="
HWL="$ROOT/vendor/lib64/hw"
if [ -s "$HWL/libMcGatekeeper.so" ]; then
    cp -f "$HWL/libMcGatekeeper.so" "$HWL/gatekeeper.trustonic.so"
    echo "  [ok]   gatekeeper.trustonic.so <- libMcGatekeeper.so"
else
    echo "  [FAIL] libMcGatekeeper.so missing - cannot build gatekeeper.trustonic.so"; MISSING=1
fi
if [ -s "$HWL/libSoftGatekeeper.so" ]; then
    cp -f "$HWL/libSoftGatekeeper.so" "$HWL/gatekeeper.default.so"
    echo "  [ok]   gatekeeper.default.so   <- libSoftGatekeeper.so"
else
    echo "  [FAIL] libSoftGatekeeper.so missing - cannot build gatekeeper.default.so"; MISSING=1
fi

chmod +x "$ROOT"/vendor/bin/mcDriverDaemon "$ROOT"/vendor/bin/hw/* 2>/dev/null

# --- Validate the blobs FBE decryption depends on ------------------------------
# A tiny/text file here means a broken HAL and a decryption hang - fail loudly
# now instead of shipping an undecryptable recovery.
is_elf() { [ -s "$1" ] && [ "$(head -c 4 "$1" 2>/dev/null | od -An -tx1 | tr -d ' \n')" = "7f454c46" ]; }
echo "== Validating critical decryption blobs =="
for b in \
    "$ROOT/vendor/bin/mcDriverDaemon" \
    "$ROOT/vendor/bin/hw/android.hardware.security.keymint-service.trustonic" \
    "$ROOT/vendor/bin/hw/android.hardware.gatekeeper@1.0-service" \
    "$HWL/gatekeeper.trustonic.so" \
    "$HWL/gatekeeper.default.so" \
    "$HWL/libMcGatekeeper.so" \
    "$ROOT/vendor/lib64/libMcClient.so" \
    ; do
    if is_elf "$b"; then
        echo "  [elf]  ${b#$ROOT/}"
    else
        sz=$([ -f "$b" ] && wc -c < "$b" || echo missing)
        echo "  [BAD]  ${b#$ROOT/} is not a valid ELF ($sz bytes)"; MISSING=1
    fi
done

if [ "$MISSING" = "1" ]; then
    echo "!! Some blobs are missing or invalid - decryption WILL fail. Fix the above and re-run."
    exit 1
fi
echo "All blobs ready and validated."
