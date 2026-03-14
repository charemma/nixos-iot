import * as pulumi from "@pulumi/pulumi";
import * as hcloud from "@pulumi/hcloud";
import * as fs from "fs";

const config = new pulumi.Config();
const location = config.get("location") ?? "nbg1";
const sshPublicKeyPath = config.get("sshPublicKeyPath") ?? "/etc/nix/builder_ed25519.pub";
const sshPublicKey = fs.readFileSync(
  sshPublicKeyPath.replace("~", process.env.HOME!),
  "utf-8",
).trim();

interface BuilderConfig {
  serverType: string;
  arch: string;
  cores: number;
  count: number;
}

const builders: Record<string, BuilderConfig> = config.requireObject("builders");

const cloudConfig = `#cloud-config
users:
  - name: nix
    shell: /bin/bash
    ssh_authorized_keys:
      - ${sshPublicKey}

runcmd:
  - ["bash", "-c", "HOME=/root curl -L https://nixos.org/nix/install | HOME=/root bash -s -- --daemon --yes"]
  - ["bash", "-c", "mkdir -p /etc/nix && printf 'experimental-features = nix-command flakes\\ntrusted-users = root nix\\n' > /etc/nix/nix.conf"]
  - ["systemctl", "restart", "nix-daemon"]
`;

const sshKey = new hcloud.SshKey("nix-builder", {
  name: "nix-builder",
  publicKey: sshPublicKey,
});

const firewall = new hcloud.Firewall("nix-builder", {
  name: "nix-builder",
  rules: [
    {
      direction: "in",
      protocol: "tcp",
      port: "22",
      sourceIps: ["0.0.0.0/0", "::/0"],
    },
  ],
});

const instances: pulumi.Output<{ host: string; arch: string; user: string; cores: number }>[] = [];

for (const [name, cfg] of Object.entries(builders)) {
  for (let i = 0; i < cfg.count; i++) {
    const server = new hcloud.Server(`builder-${name}-${i}`, {
      name: `builder-${name}-${i}`,
      serverType: cfg.serverType,
      image: "ubuntu-24.04",
      location,
      sshKeys: [sshKey.id],
      userData: cloudConfig,
      firewallIds: [firewall.id.apply((id) => Number(id))],
    });

    instances.push(
      server.ipv4Address.apply((ip) => ({
        host: ip,
        arch: cfg.arch,
        user: "nix",
        cores: cfg.cores,
      })),
    );
  }
}

export const output = pulumi.all(instances);
