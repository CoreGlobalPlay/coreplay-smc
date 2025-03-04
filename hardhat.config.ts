import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-abi-exporter";
import { task } from "hardhat/config";
import * as dotenv from "dotenv";
import "@openzeppelin/hardhat-upgrades";

dotenv.config();

const {
  TESTNET_PRIVATE_KEY: testnetPrivateKey,
  MAINNET_PRIVATE_KEY: mainnetPrivateKey,
} = process.env;

task("accounts", "Prints the list of accounts", async (_taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

const config: HardhatUserConfig = {
  networks: {
    bscTestnet: {
      url: "https://bsc-testnet-rpc.publicnode.com",
      chainId: 97,
      accounts: [testnetPrivateKey!],
    },
    berachain: {
      url: "https://rpc.berachain.com",
      chainId: 80094,
      accounts: [mainnetPrivateKey!],
    },
  },
  solidity: {
    compilers: [
      {
        version: "0.8.28",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000,
          },
          evmVersion: "cancun",
        },
      },
    ],
  },
  abiExporter: {
    path: "data/abi",
    runOnCompile: true,
    clear: true,
    flat: false,
    only: [],
    spacing: 4,
  },
};

export default config;
