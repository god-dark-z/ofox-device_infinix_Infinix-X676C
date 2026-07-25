# OrangeFox device tree for the Infinix NOTE 12 2023 (X676C)

Self-contained fox_12.1 tree (no more device/transsion/mt6789-common dependency).
Based on the transsion mt6789-common fox tree and the X6837 twrp_12.1 tree - same
MT6789 (Helio G99) platform.

## Building

> **Important:** the leaf folder MUST be named `X676C` (the build system
> locates `BoardConfig.mk` via `device/*/X676C/`). All paths inside the tree
> resolve dynamically.

```bash
# Sync OrangeFox 12.1 sources (orangefox_sync script), then:
git clone https://github.com/dark-z-666/twrp-device_infinix_Infinix-X676C -b fox_12.1 device/infinix/X676C

# Fetch proprietary decryption blobs (also runs from vendorsetup.sh):
bash device/infinix/X676C/prepare-blobs.sh

export ALLOW_MISSING_DEPENDENCIES=true
export FOX_BUILD_DEVICE=X676C
source build/envsetup.sh
lunch twrp_X676C-eng
mka adbd vendorbootimage
```

> **There is no recovery partition on this device** (virtual-A/B GKI device,
> recovery lives inside `vendor_boot`). Build `vendorbootimage` - a
> `recoveryimage` target would do nothing.

Flash `out/target/product/X676C/vendor_boot.img`:

```bash
fastboot flash vendor_boot out/target/product/X676C/vendor_boot.img
fastboot reboot recovery
```

The TWRP-only variant of this tree lives on the `twrp_12.1` branch.
