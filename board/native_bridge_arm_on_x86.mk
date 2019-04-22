# Enable support for ARM on x86 native bridge
BUILD_ARM_FOR_X86 := true

ifeq ($(filter x86 x86_64,$(TARGET_ARCH)),)
    $(error TARGET_ARCH needs to be set to x86 or x86_64)
endif

# If native bridge is bundled with the system, indicate support for ARM ABIs
ifeq ($(WITH_NATIVE_BRIDGE), true)
    NATIVE_BRIDGE_ABI_LIST_32_BIT := armeabi-v7a armeabi
else
    # TARGET_CPU_ABI2 must be set to make soong build additional ARM code
    # However, if no native bridge is bundled, the system does not support
    # ARM binaries by default, yet it indicates support through
    # ro.product.cpu.abi2 in build.prop.

    # Attempt to reset ro.product.cpu.abi2 using
    # https://github.com/LineageOS/android_build/commit/94282042cac8dc66e9935c8d7455bd323b0b6716
    PRODUCT_BUILD_PROP_OVERRIDES += TARGET_CPU_ABI2=
endif

# Add ARM to supported ABIs
ifeq ($(TARGET_ARCH),x86_64)
    TARGET_2ND_CPU_ABI2 := armeabi-v7a
    TARGET_CPU_ABI_LIST_32_BIT := $(TARGET_2ND_CPU_ABI) $(NATIVE_BRIDGE_ABI_LIST_32_BIT)
else
    TARGET_CPU_ABI2 := armeabi-v7a
    TARGET_CPU_ABI_LIST_32_BIT := $(TARGET_CPU_ABI) $(NATIVE_BRIDGE_ABI_LIST_32_BIT)
endif
