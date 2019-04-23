#!/sbin/sh
# addond.widevine.sh
set -e

case "$1" in
  post-restore)
    # Apply correct label to Widevine binary
    chcon u:object_r:hal_drm_widevine_exec:s0 "$S"/vendor/bin/hw/android.hardware.drm@1.1-service.widevine
  ;;
esac
