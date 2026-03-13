self:
{ config, lib, pkgs, ... }:

let
  cfg = config.services.airdata;
in
{
  options.services.airdata = {
    enable = lib.mkEnableOption "airdata particulate matter exporter";

    device = lib.mkOption {
      type = lib.types.path;
      default = "/dev/ttyUSB0";
      description = "Path to the SDS011 serial device.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8000;
      description = "Port for the Prometheus metrics endpoint.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.airdata = {
      description = "SDS011 particulate matter Prometheus exporter";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${self.packages.${pkgs.system}.default}/bin/airdata";
        Restart = "on-failure";
        RestartSec = 10;

        # hardening
        DynamicUser = true;
        SupplementaryGroups = [ "dialout" ];
        DeviceAllow = [ "${cfg.device} rw" ];
        ProtectSystem = "strict";
        ProtectHome = true;
        NoNewPrivileges = true;
      };
    };
  };
}
