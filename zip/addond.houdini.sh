#!/sbin/sh
# addond.houdini.sh

case "$1" in
  post-restore)
    # Add ARM to the list of supported ABIs (if it is not listed already)
    # Extra system properties are always added, it does not matter if they are listed twice
    exec sed -ri -e '/^ro\.product\.cpu\.abilist(32)?=/ {/armeabi/! s/$/,armeabi-v7a,armeabi/}' \
        -e '$ a # Houdini\nro.product.cpu.abi2=armeabi-v7a\nro.dalvik.vm.isa.arm=x86\nro.enable.native.bridge.exec=1' \
        /system/build.prop
  ;;
esac
