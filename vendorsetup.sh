#!/bin/bash
#
# OrangeFox build vars - Infinix NOTE 12 2023 (X676C)
#

export OF_DISABLE_OTA_MENU=1
export FOX_AB_DEVICE=1
export FOX_VIRTUAL_AB_DEVICE=1
export OF_DEFAULT_KEYMASTER_VERSION=4.1
export OF_NO_TREBLE_COMPATIBILITY_CHECK=1
export OF_MAINTAINER="Night_Stalker"
export FOX_VARIANT="R11.2-A12"
export OF_FLASHLIGHT_ENABLE=0

export FOX_USE_BASH_SHELL=1
export FOX_USE_NANO_EDITOR=1
export FOX_USE_TAR_BINARY=1
export FOX_USE_SED_BINARY=1
export FOX_USE_XZ_UTILS=1
export FOX_ASH_IS_BASH=1
export OF_ENABLE_LPTOOLS=1
export FOX_DELETE_MAGISK_ADDON=1
export FOX_DELETE_AROMAFM=1
export FOX_ENABLE_APP_MANAGER=1
export OF_SUPPORT_VBMETA_AVB2_PATCHING=1

export FOX_USE_DATA_RECOVERY_FOR_SETTINGS=1
export OF_LOOP_DEVICE_ERRORS_TO_LOG=1
export OF_USE_LZ4_COMPRESSION=true

# Fox UI geometry (1080x2400 panel)
export OF_SCREEN_H=2400
export OF_STATUS_H=95
export OF_STATUS_INDENT_LEFT=48
export OF_STATUS_INDENT_RIGHT=48
export OF_ALLOW_DISABLE_NAVBAR=0
export OF_CLOCK_POS=1

export USE_CCACHE=1
export CCACHE_MAXSIZE="5G"
export LC_ALL="C"
export ALLOW_MISSING_DEPENDENCIES=true

# Lunch selections
add_lunch_combo twrp_X676C-eng
add_lunch_combo twrp_X676C-userdebug

# This tree's own location - no hardcoded paths
FOX_DEVICE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# gflags is needed by the fox_12.1 minimal manifest build
if [ ! -d external/gflags ]; then
    git clone https://android.googlesource.com/platform/external/gflags/ -b android-12.1.0_r4 external/gflags
fi

# Haptics activation path patch for bootable/recovery
if [ -d bootable/recovery ]; then
    ( cd bootable/recovery && \
      git apply "$FOX_DEVICE_DIR/patches/0001-Change-haptics-activation-file-path.patch" > /dev/null 2>&1 && \
      echo "OK: haptics patch applied" || echo "NOTE: haptics patch not applied (maybe already patched)" )
fi

# Fetch proprietary decryption blobs (idempotent)
bash "$FOX_DEVICE_DIR/prepare-blobs.sh" || true
