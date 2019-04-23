#!/sbin/sh
# addond.houdini.sh
set -e

NEW_PROPERTIES="
# Houdini
ro.product.cpu.abi2=armeabi-v7a
ro.dalvik.vm.isa.arm=x86
ro.enable.native.bridge.exec=1
ro.dalvik.vm.native.bridge=libhoudini.so"

case "$1" in
  post-restore)
    # Add ARM to the list of supported ABIs (if it is not listed already)
    # Extra system properties are always added, it does not matter if they are listed twice
    sed -ri -e '/^ro\.product\.cpu\.abilist(32)?=/ {/armeabi/! s/$/,armeabi-v7a,armeabi/}' \
        -e '/^ro\.dalvik\.vm\.native\.bridge=/d' /system/build.prop
    echo "$NEW_PROPERTIES" >> /system/build.prop
  ;;
esac
