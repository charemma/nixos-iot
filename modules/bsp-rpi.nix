# Board Support Package for Raspberry Pi 5.
#
# Analogous to a BSP layer in Yocto. The heavy lifting (kernel, device
# trees, firmware, bootloader) is handled by the raspberry-pi-nix flake.
# This module only selects the board variant and defines the root
# filesystem -- but it exists as a separate file so the BSP concern is
# clearly isolated. Supporting a different board means writing a new
# bsp-<board>.nix and swapping it in the flake, without touching any
# other module.
{ config, lib, ... }:

{
  raspberry-pi-nix.board = "bcm2712";

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
  };
}
