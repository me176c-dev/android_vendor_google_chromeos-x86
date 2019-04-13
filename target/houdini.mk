# Enable support for Houdini as ARM on x86 native bridge

# This property is built into the boot image
# Adding it from a OTA package would require re-building the boot image...
# To avoid this, it is always set - it does not cause issues
# if libhoudini.so does not exist.
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    ro.dalvik.vm.native.bridge=libhoudini.so

# Bundle Houdini in the system?
ifeq ($(WITH_NATIVE_BRIDGE), true)
    PRODUCT_PROPERTY_OVERRIDES += \
        ro.dalvik.vm.isa.arm=x86 \
        ro.enable.native.bridge.exec=1

    HOUDINI_PATH := $(dir $(LOCAL_PATH))proprietary/houdini
    PRODUCT_COPY_FILES += \
        $(call find-copy-subdir-files,*,$(HOUDINI_PATH),$(TARGET_COPY_OUT_SYSTEM))
else
    # Remove ARM from ro.product.cpu.abi2 in build.prop
    # Note: This depends on: https://github.com/LineageOS/android_build/commit/94282042cac8dc66e9935c8d7455bd323b0b6716
    PRODUCT_BUILD_PROP_OVERRIDES += TARGET_CPU_ABI2=
endif
