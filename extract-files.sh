#!/usr/bin/env bash
set -euo pipefail

CHROMEOS_RECOVERY="chromeos_11647.104.1_nocturne_recovery_stable-channel_mp"

CHROMEOS_FILENAME="$CHROMEOS_RECOVERY.bin.zip"
CHROMEOS_URL="https://dl.google.com/dl/edgedl/chromeos/recovery/$CHROMEOS_FILENAME"
CHROMEOS_SHA1="31df452a9e01cbadfc0e6acb3db7d914d9e4c323 $CHROMEOS_FILENAME"

CHROMEOS_FILE="$PWD/$CHROMEOS_FILENAME"
TARGET_DIR="$PWD/proprietary"

read -p "This script requires 'sudo' to mount the partitions in the ChromeOS recovery image. Continue? (Y/n) " choice
[[ -z "$choice" || "${choice,,}" == "y" ]]

echo "Checking ChromeOS image..."
if ! sha1sum -c <<< "$CHROMEOS_SHA1" 2> /dev/null; then
    curl -Lo "$CHROMEOS_FILENAME" "$CHROMEOS_URL"
    sha1sum -c <<< "$CHROMEOS_SHA1"
fi

echo "Deleting old files"
rm -rf "$TARGET_DIR"
mkdir "$TARGET_DIR"

TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

CHROMEOS_EXTRACTED="$CHROMEOS_RECOVERY.bin"
CHROMEOS_ANDROID_VENDOR_IMAGE="opt/google/containers/android/vendor.raw.img"

echo " -> Extracting recovery image"
unzip -q "$CHROMEOS_FILE" "$CHROMEOS_EXTRACTED"

# Setup loop device
echo " -> Mounting images"
loop_dev=$(sudo losetup -r -f --show --partscan "$CHROMEOS_EXTRACTED")

mkdir chromeos
sudo mount -r "${loop_dev}p3" chromeos
mkdir vendor
sudo mount -r "chromeos/$CHROMEOS_ANDROID_VENDOR_IMAGE" vendor

echo " -> Copying files"
cd vendor

# Widevine DRM
mkdir "$TARGET_DIR/widevine"
cp bin/hw/android.hardware.drm@1.1-service.widevine "$TARGET_DIR/widevine"
cp etc/init/android.hardware.drm@1.1-service.widevine.rc "$TARGET_DIR/widevine"
cp lib/libwvhidl.so "$TARGET_DIR/widevine"

# Native bridge (Houdini)
mkdir -p "$TARGET_DIR/houdini/"{bin,etc/init,lib}
cp bin/houdini "$TARGET_DIR/houdini/bin"
cp -r etc/binfmt_misc "$TARGET_DIR/houdini/etc"
cp -r lib/{libhoudini.so,arm} "$TARGET_DIR/houdini/lib"

# Create init script
cat > "$TARGET_DIR/houdini/etc/init/houdini.rc" <<EOF
on property:ro.enable.native.bridge.exec=1
    mount binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc
    copy /system/etc/binfmt_misc/arm_exe /proc/sys/fs/binfmt_misc/register
    copy /system/etc/binfmt_misc/arm_dyn /proc/sys/fs/binfmt_misc/register
EOF

echo " -> Unmounting recovery image"
cd "$TEMP_DIR"
sudo umount vendor
sudo umount chromeos
sudo losetup -d "$loop_dev"

rm -r "$TEMP_DIR"
echo "Done"
