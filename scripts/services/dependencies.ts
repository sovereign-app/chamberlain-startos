import { types as T, matches } from "../deps.ts";

const { shape, number, boolean, string } = matches;

const matchBitcoindConfig = shape({
  rpc: shape({
    enable: boolean,
    advanced: shape({
      threads: number,
    }),
  }),
  advanced: shape({
    peers: shape({
      listen: boolean,
    }),
    pruning: shape({
      mode: string,
    }),
  }),
});

export const dependencies: T.ExpectedExports.dependencies = {
  bitcoind: {
    // deno-lint-ignore require-await
    async check(effects, configInput) {
      effects.info("check bitcoind");
      const config = matchBitcoindConfig.unsafeCast(configInput);
      if (!matchBitcoindConfig.test(config)) {
        return { error: "Bitcoind config is not the correct shape" };
      }
      if (!config.rpc.enable) {
        return { error: "Must have RPC enabled" };
      }
      if (!config.advanced.peers.listen) {
        return { error: "Must have peer interface enabled" };
      }
      if (config.advanced.pruning.mode !== "disabled") {
        return { error: "Pruning must be disabled (must be an archival node)" };
      }
      if (config.rpc.advanced.threads < 4) {
        return { error: "Must be greater than or equal to 4" };
      }
      return { result: null };
    },

    // deno-lint-ignore require-await
    async autoConfigure(effects, configInput) {
      effects.info("autoconfigure bitcoind");
      const config = matchBitcoindConfig.unsafeCast(configInput);
      config.rpc.enable = true;
      config.advanced.peers.listen = true;
      config.advanced.pruning.mode = "disabled";
      if (config.rpc.advanced.threads < 4) {
        config.rpc.advanced.threads = 4;
      }
      return { result: config };
    },
  },
};
