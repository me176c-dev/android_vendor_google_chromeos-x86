#!/usr/bin/env bash
set -euo pipefail

type="${1:-}"
case "$type" in
    widevine) name="Widevine" ;;
    houdini)  name="Houdini" ;;
    "") "$0" widevine && "$0" houdini; exit ;;
    *) echo "Usage: $0 [widevine|houdini]"; exit 1 ;;
esac

cd "$(dirname "$0")"
zip_dir="$PWD"
out_dir="$PWD/out"
main_dir="$(dirname "$PWD")"
version=$(<"$main_dir/proprietary/version")

echo "Building ZIP for $name from ChromeOS $version..."

temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT
cd "$temp_dir"

# Generate addond script (runs when upgrading system to restore modifications)
mkdir -p system/addon.d
ADDOND_ADDON="$zip_dir/addond.$type.sh"
[[ -f "$ADDOND_ADDON" ]] || ADDOND_ADDON=""
cat - "$zip_dir/addond.tail.sh" $ADDOND_ADDON > "system/addon.d/70-$type.sh" <<EOH
#!/sbin/sh
#
# ADDOND_VERSION=1
#
# /system/addon.d/70-$type.sh
# Backup $name (from ChromeOS $version) during upgrades
#

. /tmp/backuptool.functions

list_files() {
cat<<EOF
$(find "$main_dir/proprietary/$type" -type f -printf "%P\n" | sort)
EOF
}
EOH
chmod +x "system/addon.d/70-$type.sh"

# Normalize file modification times for reproducible builds
find system -print0 | xargs -0r touch -hr "$main_dir/proprietary"

# Create tar archive of files to install
tar cf "$type.tar" -C "system" . -C "$main_dir/proprietary/$type" . \
    --owner=0 --group=0 --numeric-owner --sort=name

# Generate update-binary (script that handles installation)
mkdir -p META-INF/com/google/android
UPDATE_BINARY_ADDON="$zip_dir/update-binary.houdini.sh"
[[ -f "$UPDATE_BINARY_ADDON" ]] || UPDATE_BINARY_ADDON=""
cat - "$zip_dir/update-binary.sh" $UPDATE_BINARY_ADDON > META-INF/com/google/android/update-binary <<EOF
#!/sbin/sh
TYPE="$type"
NAME="$name"
VERSION="$version"
EOF
echo "# Dummy file; update-binary is a shell script." > META-INF/com/google/android/updater-script

cp "$main_dir/LICENSE" LICENSE

# Normalize file modification times for reproducible builds
find . -print0 | xargs -0r touch -hr "$main_dir/proprietary"

# Generate ZIP file
mkdir -p "$out_dir"
filename="$type-x86-chromeos-$version.zip"
rm -f "$out_dir/$filename"
zip -rqX "$out_dir/$filename" META-INF LICENSE "$type.tar"
echo "Successfully built: $filename"
