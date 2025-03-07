import { HardhatUserConfig } from "hardhat/config";
import "hardhat-abi-exporter";
import { task } from "hardhat/config";
import * as dotenv from "dotenv";
import "@openzeppelin/hardhat-upgrades";
import "@nomicfoundation/hardhat-ethers";
import "hardhat-deploy";
import "hardhat-deploy-ethers";
import "@typechain/hardhat";

dotenv.config();

const {
  TESTNET_PRIVATE_KEY: testnetPrivateKey,
  MAINNET_PRIVATE_KEY: mainnetPrivateKey,
} = process.env;

task("accounts", "Prints the list of accounts", async (_taskArgs, hre) => {
  const accounts = await hre.getNamedAccounts();
  console.table(accounts);
});

const config: HardhatUserConfig = {
  networks: {
    coreTestnet: {
      url: "https://rpc.test.btcs.network",
      chainId: 1115,
      accounts: [testnetPrivateKey!],
    },
    coreMainnet: {
      url: "https://rpc.coredao.org",
      chainId: 1116,
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
  // Hardhat deploy
  namedAccounts: {
    deployer: 0,
    acc1: 1,
    acc2: 2,
    acc3: 3,
    proxyAdmin: 4,
  },
  typechain: {
    outDir: "typechain",
    target: "ethers-v6",
  },
};

export default config;
