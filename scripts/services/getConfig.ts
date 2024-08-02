import { types as T, compat } from "../deps.ts";

export const getConfig: T.ExpectedExports.getConfig = compat.getConfig({
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
  "mint-url": {
    type: "string",
    name: "Mint URL",
    description: "The public URL of the mint",
    nullable: false,
  },
  "nws": {
    type: "object",
    name: "NWS Configuration",
    description: "Configuration for the NWS service",
    spec: {
      "enabled": {
        type: "boolean",
        name: "Enabled",
        description: "Whether NWS is enabled",
        nullable: false,
        default: true,
      },
      "private-key": {
        type: "string",
        name: "Nostr Secret Key (Hex)",
        description: "The Nostr secret key for the NWS service",
        nullable: true,
      },
      "relay": {
        type: "string",
        name: "Relay URL",
        description: "The URL of the NWS relay",
        default: "wss://relay.sovereign.app",
        nullable: true,
      },
    }
  },
  "mint-name": {
    type: "string",
    name: "Mint Name",
    description: "The name of the mint",
    nullable: true,
  },
  "mint-description": {
    type: "string",
    name: "Mint Description",
    description: "A description of the mint",
    nullable: true,
  },
  "mint-motd": {
    type: "string",
    name: "Mint MOTD",
    description: "A message of the day for the mint",
    nullable: true,
  },
  "contact-info": {
    type: "object",
    name: "Mint Contact Information",
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
});
