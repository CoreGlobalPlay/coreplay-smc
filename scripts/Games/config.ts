import hre from "hardhat";

type Config = {
    swQueue: string,
    SwAddress: string,
};

const testnetScriptConfig: Config = {
    swQueue: "0xc9477bfb5ff1012859f336cf98725680e7705ba2abece17188cfb28ca66ca5b0",
    SwAddress: "0x33A5066f65f66161bEb3f827A3e40fce7d7A2e6C"
};

const mainnetScriptConfig: Config = {
    swQueue: "0x86807068432f186a147cf0b13a30067d386204ea9d6c8b04743ac2ef010b0752",
    SwAddress: "0x33A5066f65f66161bEb3f827A3e40fce7d7A2e6C"
};

const hardhatScriptConfig: Config = {
    swQueue: "0x0000000000000000000000000000000000000000000000000000000000000000",
    SwAddress: "0x0000000000000000000000000000000000000000",
};

const configs: Record<string, Config> = {
  hardhat: hardhatScriptConfig,
  "coreTestnet": testnetScriptConfig,
  "coreTestnet2": testnetScriptConfig,
  "coreMainnet": mainnetScriptConfig,
};

export const ScriptConfig: Config = configs[hre.network.name];
