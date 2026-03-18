{ config, lib, pkgs, ... }:

{
  networking.hostName = "sentinel-node";

  services.sentinel = {
    enable = true;
    interface = "eth0";
    port = 9090;
  };

  system.stateVersion = "26.05";
}
