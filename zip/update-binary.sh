#!/sbin/sh
OUTFD="/proc/self/fd/$2"
PACKAGE="$3"

set -eu

ui_print() {
    echo "ui_print $*" > "$OUTFD"
    echo "ui_print" > "$OUTFD"
}
set_progress() {
    echo "set_progress $1" > "$OUTFD"
}

mounted=""
mount_if_necessary() {
    [ -d "$1" ] || return 0
    mountpoint=$(grep "$1" /proc/mounts || :)
    if [ -z "$mountpoint" ]; then
        mounted="$mounted $1"
        mount -w "$1"
    else
        case "$mountpoint" in
            *rw*) ;;
            *) mount -o remount,rw "$1" ;;
        esac
    fi
}

unmount() {
    set +e
    for m in $mounted; do
        umount "$m"
    done
}
trap unmount EXIT

ui_print "Installing $NAME from ChromeOS $VERSION..."

abi32=$(getprop ro.product.cpu.abilist32)
case "$abi32" in
    *x86*) ;;
    *)
        ui_print "Incompatible CPU architecture: $abi32 (expected x86)"
        exit 64
        ;;
esac

mount_if_necessary /system
set_progress 0.1

ui_print " -> Extracting files"
unzip -p "$PACKAGE" "$TYPE.tar" | tar -xC /system
set_progress 0.8

ui_print " -> Completing installation"
touch /tmp/backuptool.functions
"$ADDOND_SCRIPT" post-restore
set_progress 0.9

ui_print " -> Done!"
set_progress 1.0
