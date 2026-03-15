{ config, lib, pkgs, ... }:

{
  networking.hostName = "gateway";

  networking.wireguard.enable = true;

  system.stateVersion = "26.05";
}
