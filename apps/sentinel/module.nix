self:
{ config, lib, pkgs, ... }:

let
  cfg = config.services.sentinel;
in
{
  options.services.sentinel = {
    enable = lib.mkEnableOption "sentinel network security monitor";

    interface = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Network interface to monitor. Empty string means auto-detect.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 9090;
      description = "Port for the Prometheus metrics endpoint.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.sentinel = {
      description = "Sentinel network security monitor";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        SENTINEL_PORT = toString cfg.port;
      } // lib.optionalAttrs (cfg.interface != "") {
        SENTINEL_INTERFACE = cfg.interface;
      };

      serviceConfig = {
        ExecStart = "${self.packages.${pkgs.system}.default}/bin/sentinel";
        Restart = "on-failure";
        RestartSec = 10;

        # hardening
        DynamicUser = true;
        AmbientCapabilities = [ "CAP_NET_RAW" ];
        CapabilityBoundingSet = [ "CAP_NET_RAW" ];
        ProtectSystem = "strict";
        ProtectHome = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictNamespaces = true;
        RestrictRealtime = true;
        MemoryDenyWriteExecute = true;
      };
    };
  };
}
