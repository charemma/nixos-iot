{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    vim
    htop
    curl
    tmux
  ];
}
