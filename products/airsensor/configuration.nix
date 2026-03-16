{ config, lib, pkgs, ... }:

{
  networking.hostName = "airsensor";

  services.airdata = {
    enable = true;
    device = "/dev/ttyUSB0";
    port = 8000;
  };

  system.stateVersion = "26.05";
}
