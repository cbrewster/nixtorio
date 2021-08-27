{
  surfvm = { config, modulesPath, lib, name, ... }: {
    imports =
      lib.optional (builtins.pathExists ./do-userdata.nix) ./do-userdata.nix
      ++ [ (modulesPath + "/virtualisation/digital-ocean-config.nix") ];

    nixpkgs.config.allowUnfree = true;

    deployment.targetHost = "165.232.134.105";
    deployment.targetUser = "root";

    networking.hostName = name;
    networking.enableIPv6 = true;
    networking.firewall.allowedTCPPorts = [ 22 80 443 ];

    security.acme.email = "cbrewster@hey.com";
    security.acme.acceptTerms = true;

    services.nginx = {
      enable = true;
      virtualHosts = {
        "factorio.repl.game" = {
          forceSSL = true;
          enableACME = true;

          locations."/" = {
            proxyPass = "http://unix:/${config.services.grafana.socket}";
          };
        };
      };
    };

    services.factorio = {
      enable = true;
      openFirewall = true;
      saveName = "nixtorio";
      game-name = "nixtorio";
      admins = [ "cbrewster" ];
      nonBlockingSaving = true;
    };

    users.groups.grafana.members = [ "nginx" ]; # so nginx can poke grafan's socket

    services.grafana = {
      enable = true;
      socket = "/run/grafana/grafana.sock";
      domain = "factorio.repl.game";
      protocol = "socket";
      rootUrl = "https://factorio.repl.game/";

      auth.anonymous.enable = true;
    };

    services.prometheus = {
      enable = true;
      port = 9090;
      listenAddress = "127.0.0.1";
      retentionTime = "1y";

      scrapeConfigs = [
        {
          job_name = "nodexporter";
          static_configs = [{
            targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
          }];
        }
      ];

      exporters = {
        node = {
          enable = true;
          enabledCollectors = [ "systemd" "textfile" ];
          listenAddress = "127.0.0.1";
          port = 9092;
          user = "root";
          extraFlags = [
            "--collector.textfile.directory=/var/lib/factorio/script-output/graftorio2"
          ];
        };
      };
    };
  };
}
