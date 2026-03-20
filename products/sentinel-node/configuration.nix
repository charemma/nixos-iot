{ config, lib, pkgs, ... }:

{
  networking.hostName = "sentinel-node";

  # -- sentinel service --------------------------------------------------

  services.sentinel = {
    enable = true;
    port = 9090;
  };

  # -- network hardening --------------------------------------------------

  # default-deny firewall, only allow SSH and metrics
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22    # SSH (management)
      9090  # Prometheus metrics
    ];
  };

  # -- kernel hardening ----------------------------------------------------

  boot.kernel.sysctl = {
    # no routing -- this device observes, it does not forward
    "net.ipv4.ip_forward" = 0;
    "net.ipv6.conf.all.forwarding" = 0;

    # restrict kernel attack surface
    "kernel.kptr_restrict" = 2;             # hide kernel pointers from unprivileged
    "kernel.dmesg_restrict" = 1;            # restrict dmesg to root
    "kernel.perf_event_paranoid" = 3;       # disable perf for unprivileged
    "kernel.unprivileged_bpf_disabled" = 1; # no BPF for unprivileged users
    "net.core.bpf_jit_harden" = 2;         # harden BPF JIT compiler
  };

  # disable unnecessary kernel modules
  boot.blacklistedKernelModules = [
    "bluetooth"
    "btusb"
    "firewire-core"
    "thunderbolt"
  ];

  # -- system hardening ----------------------------------------------------

  # no interactive login -- management via SSH only
  services.getty.autologinUser = null;

  # -- audit logging -------------------------------------------------------

  security.auditd.enable = true;
  security.audit = {
    enable = true;
    rules = [
      "-a always,exit -F arch=b64 -S execve" # log all process execution
    ];
  };

  system.stateVersion = "26.05";
}
