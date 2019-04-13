# Include and enable Widevine DRM in the built system.
WIDEVINE_PATH := $(dir $(LOCAL_PATH))proprietary/widevine

PRODUCT_COPY_FILES += \
    $(WIDEVINE_PATH)/android.hardware.drm@1.1-service.widevine:$(TARGET_COPY_OUT_VENDOR)/bin/hw/android.hardware.drm@1.1-service.widevine:widevine \
    $(WIDEVINE_PATH)/android.hardware.drm@1.1-service.widevine.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/android.hardware.drm@1.1-service.widevine.rc:widevine \
    $(WIDEVINE_PATH)/libwvhidl.so:$(TARGET_COPY_OUT_VENDOR)/lib/libwvhidl.so:widevine
