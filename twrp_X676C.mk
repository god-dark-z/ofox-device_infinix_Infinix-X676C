#
# Copyright (C) 2022 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Resolve this tree's location dynamically (works from any checkout dir)
LOCAL_DIR := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))

# Inherit from X676C device
$(call inherit-product, $(LOCAL_DIR)/device.mk)

# Inherit some common TWRP stuff.
$(call inherit-product, vendor/twrp/config/common.mk)

# Product Specifics
PRODUCT_NAME := twrp_X676C
PRODUCT_DEVICE := X676C
PRODUCT_BRAND := Infinix
PRODUCT_MODEL := Infinix X676C
PRODUCT_MANUFACTURER := INFINIX

PRODUCT_GMS_CLIENTID_BASE := android-infinix
