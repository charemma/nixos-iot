{ config, lib, pkgs, sshKeys, ... }:

{
  raspberry-pi-nix.board = "bcm2712";

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
  };

  networking.hostName = "airsensor";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Athens";
  i18n.defaultLocale = "en_US.UTF-8";

  # User
  users.groups.charemma.gid = 1000;
  users.users.charemma = {
    isNormalUser = true;
    uid = 1000;
    group = "charemma";
    extraGroups = [ "wheel" "networkmanager" ];
    initialHashedPassword = "";
    openssh.authorizedKeys.keyFiles = [ sshKeys ];
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  services.openssh.enable = true;

  services.airdata.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "26.05";
}
