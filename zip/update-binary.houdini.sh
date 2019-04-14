#!/sbin/sh
mount_if_necessary "/data" || :

if [ -d /data/data/com.android.vending ]; then
    ui_print "Note: Clear storage of Google Play Store if ARM apps still show up as incompatible."
fi
