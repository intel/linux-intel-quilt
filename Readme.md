### Introduction

This repository contains Intel's Linux LTS and mainline kernel quilt releases.

Kernel quilt release 'patches' folder include a quilt series file and all kernel patches mentioned in the series file.\
kernel patches are grouped by feature, example:

```
    #series file for v6.12.40 linux kernel
    # d90ecb2b1308b Linux 6.12.40
    #sriov
    0001-drm-i915-mtl-Add-C10-table-for-HDMI-Clock-25175.sriov
    0002-drm-i915-mtl-Copy-c10-phy-pll-sw-state-from-master-t.sriov
    0003-drm-i915-guc-Define-MAX_DWORDS-for-CTB-HXG-Message.sriov
    0004-drm-i915-call-taint_for_CI-on-FLR-failure.sriov
    ...
    #security
    0001-mei-bus-add-api-to-query-capabilities-of-ME-clien.security
    ...
```

### How to use quilt release

Step 1: clone and checkout quilt release, lts-v6.12.40-linux-250728T040815Z as example:

```
         $ git clone https://github.com/intel/linux-intel-quilt.git linux-intel-quilt
         $ cd linux-intel-quilt
         $ git checkout lts-v6.12.40-linux-250728T040815Z -b my/v6.12.40
```

Step 2: use 'cat patches/series |head -n2' to get the base kernel version and HEAD, lts-v6.12.40-linux-250728T040815Z as example:

```
         $ cat patches/series |head -n2
         # Series file for v6.12.40 linux kernel
         # d90ecb2b1308b Linux 6.12.40
```

Step 3: clone base kernel from community [stable](https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git) or [mainline](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git). Continue use above tag as example:

```
         $ cd ..
         $ git clone https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git kernel-src
         $ cd kernel-src
         $ git checkout v6.12.40 -b my/v6.12.40
         $ cp -r ../linux-intel-quilt/patches .
```

Step 4: use quilt or git quiltimport to apply kernel patches to your branch.

quilt example:
```
        $ quilt push -a
```

git quiltimport example:
```
        $ git quiltimport
```

Step 5: modify your kernel configuration with 'make menuconfig' or copy from your existing configuration and 'make bindeb-pkg' to build this kernel.


Note: If you don't want apply all the patches, you can also modify the series file to remove patches/features before applying.

### Reference kernel overlay repository

You can also use our kernel overlay release to build the kernel instead of apply quilt series by yourself.\
You can find reference kernel configuration, kernel patch series and build scripts from this [linux kernel overlay release repository](https://github.com/intel/linux-kernel-overlay).

### GPG Signed Releases

i) Check if a release tag is GPG-signed or not

if a tag is not signed, when you run ‘git tag -v <tag>’ command, you get the result as:

$ git tag -v lts-v4.19.272-android_t-230316T041640Z
object 7150c8b4efa2baf0bef3a3da3850d29715c6fcbb
type commit
tag lts-v4.19.272-android_t-230316T041640Z
tagger sys_oak sys_oak@intel.com 1679296599 -0700

release Kernel 4.19 for android T Dessert
error: no signature found

You can see ‘error: no signature found’ if the tag is not signed

If the tag is signed - please follow the below steps to get the public key and verify the tag -

ii) Download public key

Open https://keys.openpgp.org/, input Full Key ID (i.e., EB4D99E5113E284368955757F18D9D84E60D69E7), or,
short Key ID (i.e., F18D9D84E60D69E7, the Last 16 digitals). or, the tagger email address(i.e., sys_oak@intel.com), 
Click ‘Search’, then you can download the pub key file (i.e., EB4D99E5113E284368955757F18D9D84E60D69E7.asc).
The md5sum checksum is 40b0222665a5f6c70ca9d990b4014f43 for the pub key file:
$ md5sum EB4D99E5113E284368955757F18D9D84E60D69E7.asc 
40b0222665a5f6c70ca9d990b4014f43  EB4D99E5113E284368955757F18D9D84E60D69E7.asc

Once your checksum is correct, please do next step.

iii) Configure your Linux Environment and verify the GPG signature of a tag ( one time setup) 

After you get the right pub key, please import it:
$ gpg --import EB4D99E5113E284368955757F18D9D84E60D69E7.asc

Now, when you check the tag GPG signature, you can see ‘Good signature’ with a WARNING:
$ git tag -v lts-v4.19.282-android_t-230509T073627Z
object 180df1199944ebd8928f320a1bd16c8a87dba2ed
type commit
tag lts-v4.19.282-android_t-230509T073627Z
tagger sys_oak sys_oak@intel.com 1683864457 -0700

release Kernel 4.19 for android T Dessert
gpg: Signature made Fri 12 May 2023 12:07:37 AM EDT
gpg:                using RSA key EB4D99E5113E284368955757F18D9D84E60D69E7
gpg: Good signature from "sys_oak (NSWE) sys_oak@intel.com" [unknown]
gpg: WARNING: This key is not certified with a trusted signature!
gpg:          There is no indication that the signature belongs to the owner.
Primary key fingerprint: EB4D 99E5 113E 2843 6895  5757 F18D 9D84 E60D 69E7

To deal with the WARNING, let the pub key be trusted, run ‘gpg --edit-key <key>’ to edit it ( one time setup)
$ gpg --edit-key F18D9D84E60D69E7  
input trust
input 5
input y
input quit

Now, when you check the tag GPG signature again , you can see ‘Good signature’ without warnings: 
$ git tag -v lts-v4.19.282-android_t-230509T073627Z
object 180df1199944ebd8928f320a1bd16c8a87dba2ed
type commit
tag lts-v4.19.282-android_t-230509T073627Z
tagger sys_oak sys_oak@intel.com 1683864457 -0700

release Kernel 4.19 for android T Dessert
gpg: Signature made Fri 12 May 2023 12:07:37 AM EDT
gpg:                using RSA key EB4D99E5113E284368955757F18D9D84E60D69E7
gpg: Good signature from "sys_oak (NSWE) sys_oak@intel.com" [ultimate]
