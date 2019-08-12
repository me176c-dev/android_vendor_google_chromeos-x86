#!/usr/bin/env bash
set -euo pipefail

# Use consistent umask for reproducible builds
umask 022

CHROMEOS_VERSION="12105.100.0_nocturne"
CHROMEOS_RECOVERY="chromeos_${CHROMEOS_VERSION}_recovery_stable-channel_mp"

CHROMEOS_FILENAME="$CHROMEOS_RECOVERY.bin.zip"
CHROMEOS_URL="https://dl.google.com/dl/edgedl/chromeos/recovery/$CHROMEOS_FILENAME"
CHROMEOS_SHA1="53ca73c712e90885563245bdf3a363456de637e7 $CHROMEOS_FILENAME"

CHROMEOS_FILE="$PWD/$CHROMEOS_FILENAME"
TARGET_DIR="$PWD/proprietary"

read -rp "This script requires 'sudo' to mount the partitions in the ChromeOS recovery image. Continue? (Y/n) " choice
[[ -z "$choice" || "${choice,,}" == "y" ]]

echo "Checking ChromeOS image..."
if ! sha1sum -c <<< "$CHROMEOS_SHA1" 2> /dev/null; then
    if command -v curl &> /dev/null; then
        curl -fLo "$CHROMEOS_FILENAME" "$CHROMEOS_URL"
    elif command -v wget &> /dev/null; then
        wget -O "$CHROMEOS_FILENAME" "$CHROMEOS_URL"
    else
        echo "This script requires 'curl' or 'wget' to download the ChromeOS recovery image."
        echo "You can install one of them with the package manager provided by your distribution."
        echo "Alternatively, download $CHROMEOS_URL manually and place it in the current directory."
        exit 1
    fi

    sha1sum -c <<< "$CHROMEOS_SHA1"
fi

temp_dir=$(mktemp -d)
cd "$temp_dir"

function cleanup {
    set +e
    cd "$temp_dir"
    mountpoint -q vendor && sudo umount vendor
    mountpoint -q chromeos && sudo umount chromeos
    [[ -n "${loop_dev:-}" ]] && sudo losetup -d "$loop_dev"
    rm -r "$temp_dir"
}
trap cleanup EXIT

CHROMEOS_EXTRACTED="$CHROMEOS_RECOVERY.bin"
CHROMEOS_ANDROID_VENDOR_IMAGE="chromeos/opt/google/containers/android/vendor.raw.img"

echo " -> Extracting recovery image"
unzip -q "$CHROMEOS_FILE" "$CHROMEOS_EXTRACTED"

echo " -> Mounting partitions"
# Setup loop device
loop_dev=$(sudo losetup -r -f --show --partscan "$CHROMEOS_EXTRACTED")

mkdir chromeos
sudo mount -r "${loop_dev}p3" chromeos
mkdir vendor
sudo mount -r "$CHROMEOS_ANDROID_VENDOR_IMAGE" vendor

echo " -> Deleting old files"
rm -rf "$TARGET_DIR"
mkdir "$TARGET_DIR"
echo "$CHROMEOS_VERSION" > "$TARGET_DIR/version"

echo " -> Copying files"
RSYNC="rsync -rt --files-from=-"

# Widevine DRM
$RSYNC . "$TARGET_DIR/widevine" <<EOF
vendor/bin/hw/android.hardware.drm@1.1-service.widevine
vendor/etc/init/android.hardware.drm@1.1-service.widevine.rc
vendor/lib/libwvhidl.so
EOF

# Native bridge (Houdini)

# Create init script
mkdir -p "$TARGET_DIR/houdini/etc/init"
cat > "$TARGET_DIR/houdini/etc/init/houdini.rc" <<EOF
on property:ro.enable.native.bridge.exec=1
    mount binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc
    copy /system/etc/binfmt_misc/arm_exe /proc/sys/fs/binfmt_misc/register
    copy /system/etc/binfmt_misc/arm_dyn /proc/sys/fs/binfmt_misc/register
EOF
touch -hr vendor/etc/init "$TARGET_DIR/houdini/etc/init"{/houdini.rc,}

# Copy files
$RSYNC vendor "$TARGET_DIR/houdini" <<EOF
bin/houdini
etc/binfmt_misc
lib/libhoudini.so
lib/arm
EOF

# It's not quite clear what is the purpose of cpuinfo.pure32...
# The 32-bit version of Houdini cannot emulate aarch64 (afaik),
# so there is little point in pretending to be an ARMv8 processor...
# Continue using the ARMv7 version for now.
mv "$TARGET_DIR/houdini/lib/arm/cpuinfo.pure32" "$TARGET_DIR/houdini/lib/arm/cpuinfo"
touch -hr vendor/lib/arm "$TARGET_DIR/houdini/lib/arm"

# Normalize file modification times
touch -hr "$CHROMEOS_ANDROID_VENDOR_IMAGE" "$TARGET_DIR"{/*,}

echo "Done"
