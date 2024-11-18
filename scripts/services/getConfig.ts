import { types as T, compat } from "../deps.ts";

export const getConfig: T.ExpectedExports.getConfig = compat.getConfig({
  "tor-address": {
    "name": "Network Tor Address",
    "description": "The Tor address for the network interface.",
    "type": "pointer",
    "subtype": "package",
    "package-id": "chamberlain",
    "target": "tor-address",
    "interface": "main"
  },
  "bitcoind-rpc-user": {
    type: "pointer",
    name: "RPC Username",
    description: "The username for Bitcoin Core's RPC interface",
    subtype: "package",
    "package-id": "bitcoind",
    target: "config",
    multi: false,
    selector: "$.rpc.username",
  },
  "bitcoind-rpc-password": {
    type: "pointer",
    name: "RPC Password",
    description: "The password for Bitcoin Core's RPC interface",
    subtype: "package",
    "package-id": "bitcoind",
    target: "config",
    multi: false,
    selector: "$.rpc.password",
  },
  "mint": {
    type: "object",
    name: "Mint Configuration",
    description: "Configuration for the mint",
    spec: {
      "url": {
        type: "string",
        name: "Mint URL",
        description: "The public URL of the mint (auto defaults to sovereign.app integration or TOR address)",
        nullable: true,
      },
      "name": {
        type: "string",
        name: "Name",
        description: "The name of the mint",
        nullable: true,
      },
      "description": {
        type: "string",
        name: "Description",
        description: "A description of the mint",
        nullable: true,
      },
      "motd": {
        type: "string",
        name: "MOTD",
        description: "A message of the day for the mint",
        nullable: true,
      },
      "contact-info": {
        type: "object",
        name: "Contact Information",
        description: "Contact information for the mint",
        spec: {
          "email": {
            type: "string",
            name: "Email",
            description: "Email address for the mint",
            nullable: true,
          },
          "twitter": {
            type: "string",
            name: "Twitter",
            description: "Twitter handle for the mint",
            nullable: true,
          },
          "npub": {
            type: "string",
            name: "Npub",
            description: "Nostr public key for the mint",
            nullable: true,
          },
        }
      }
    }
  },
  "sovereign-app": {
    type: "object",
    name: "sovereign.app Configuration",
    description: "sovereign.app integration configuration",
    spec: {
      "enabled": {
        type: "boolean",
        name: "Enabled",
        description: "Whether the sovereign.app integration is enabled",
        nullable: false,
        default: true,
      },
    }
  },
});
