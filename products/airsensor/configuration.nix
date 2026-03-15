{ config, lib, pkgs, ... }:

{
  networking.hostName = "airsensor";

  services.airdata.enable = true;

  system.stateVersion = "26.05";
}
