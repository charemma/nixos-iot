{ config, lib, ... }:

{
  users.groups.iot.gid = 1000;
  users.users.iot = {
    isNormalUser = true;
    uid = 1000;
    group = "iot";
    extraGroups = [ "wheel" "networkmanager" ];
    initialHashedPassword = "";
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };
}
