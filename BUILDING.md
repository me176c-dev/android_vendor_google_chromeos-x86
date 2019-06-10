## Building ChromeOS Addons
This repository contains build scripts for the following two flashable ZIPs:

  - Widevine (DRM used in some streaming apps)
  - Houdini (used to run ARM apps on x86)

There are no pre-built ZIP packages provided by this project.
However, building the ZIP should always produce the same file.
Therefore its integrity can be verified using the checksums available in the
[release section](https://github.com/me176c-dev/android_vendor_google_chromeos-x86/releases).

### Requirements
- Linux (e.g. Debian, Ubuntu, ...)
- curl or wget, rsync, zip, unzip
  - Debian/Ubuntu: `sudo apt install curl rsync zip unzip` (usually installed by default)

### Building
1. Download the **Source code** as `.tar.gz` from the
   [release section](https://github.com/me176c-dev/android_vendor_google_chromeos-x86/releases)
   and unpack it.

2. Open a terminal and run:
   ```
   $ ./extract-files.sh
   ```

   Then follow the instructions.
   This will download a ChromeOS recovery image and extract the needed files from it.

3. In the terminal, run:
   ```
   $ zip/build.sh
   ```

   This will produce flashable ZIPs from the extracted files.
   They can be found in the `zip/out` directory.

4. Optional: Verify integrity:
   ```
   $ cd zip/out
   $ sha1sum *.zip
   ```

   Compare them with the ones provided in the release notes.
