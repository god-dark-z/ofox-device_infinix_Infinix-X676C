#!/bin/bash
#
# Fetch proprietary decryption blobs for TWRP (Infinix NOTE 12 2023 - X676C)
# into recovery/root/. These are binaries that cannot live in this git tree.
#
# Sources:
#   - X676C stock blobs:  dark-z-666/android_vendor_infinix_X676C (main-X676C)
#   - Generic AOSP libs:  Juanstews/twrp_device_Infinix_X6837 (twrp_12.1)
#
# Run from the source tree root or the device dir. Idempotent: skips files
# that already exist.

set -u
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$DIR/recovery/root"
VND="https://raw.githubusercontent.com/dark-z-666/android_vendor_infinix_X676C/main-X676C/proprietary"
REF="https://raw.githubusercontent.com/Juanstews/twrp_device_Infinix_X6837/twrp_12.1/recovery/root"
API="https://api.github.com/repos/dark-z-666/android_vendor_infinix_X676C/contents/proprietary/vendor/app/mcRegistry?ref=main-X676C"

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
for f in \
    vendor/bin/mcDriverDaemon \
    "vendor/bin/hw/android.hardware.gatekeeper@1.0-service" \
    vendor/bin/hw/android.hardware.security.keymint-service.trustonic \
    vendor/lib64/libMcClient.so \
    "vendor/lib64/hw/android.hardware.gatekeeper@1.0-impl.so" \
    vendor/lib64/hw/gatekeeper.trustonic.so \
    vendor/lib64/hw/libMcGatekeeper.so \
    vendor/lib64/hw/libSoftGatekeeper.so \
    vendor/lib64/hw/gatekeeper.default.so \
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

chmod +x "$ROOT"/vendor/bin/mcDriverDaemon "$ROOT"/vendor/bin/hw/* 2>/dev/null

if [ "$MISSING" = "1" ]; then
    echo "!! Some blobs failed to download - decryption may not work. Re-run this script."
    exit 1
fi
echo "All blobs ready."
