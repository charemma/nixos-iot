# VM image builder for standalone QEMU disk images.
#
# Produces a self-contained qcow2 image that can be booted with QEMU on
# any host (macOS, Linux) using direct kernel boot. Unlike qemu-vm.nix
# this does not generate a Linux-only run script or rely on virtfs to
# share the host's Nix store -- everything is baked into the image.
#
# The build output is a bundle containing disk.qcow2, kernel, initrd,
# and kernel-params. The justfile constructs the QEMU command from these
# artifacts, using the host's native QEMU binary with HVF (macOS) or
# KVM (Linux) acceleration.
{ config, lib, pkgs, modulesPath, ... }:

{
  # virtio drivers for QEMU's virtual hardware
  boot.initrd.availableKernelModules = [
    "virtio_pci" "virtio_blk" "virtio_net" "virtio_rng"
  ];

  # no bootloader -- QEMU loads the kernel directly via -kernel flag
  boot.loader.grub.enable = false;

  # root filesystem on the virtio block device (the qcow2 image)
  fileSystems."/" = {
    device = "/dev/vda";
    fsType = "ext4";
  };

  # bundle: disk image + kernel + initrd + kernel-params in one output
  system.build.vmBundle = let
    diskImage = import (modulesPath + "/../lib/make-disk-image.nix") {
      inherit lib config pkgs;
      diskSize = "auto";
      additionalSpace = "256M";
      format = "qcow2";
      partitionTableType = "none";
      installBootLoader = false;
      copyChannel = false;
    };
    toplevel = config.system.build.toplevel;
  in pkgs.runCommand "vm-bundle" {} ''
    mkdir -p $out
    ln -s ${diskImage}/*.qcow2 $out/disk.qcow2
    ln -s ${toplevel}/kernel $out/kernel
    ln -s ${toplevel}/initrd $out/initrd
    cp ${toplevel}/kernel-params $out/kernel-params
    echo -n "${toplevel}" > $out/toplevel
  '';
}
