import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { networkConfig } from "../scripts/deploymentConfigs";
import { ethers } from "hardhat";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const network = hre.network.name;
  const config = networkConfig[network];
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  // NFT
  const shincha = await deploy("Shincha", {
    from: deployer,
    args: [config.ShinchanName, config.ShinchanSymbol],
    log: true,
    autoMine: true,
    skipIfAlreadyDeployed: true,
  });

  // Factory
  await deploy("ShinchaFactory", {
    proxy: {
      proxyContract: "UUPS",
      execute: {
        init: {
          methodName: "initialize",
          args: [shincha.address],
        },
      },
      upgradeFunction: {
        methodName: "upgradeToAndCall",
        upgradeArgs: ["{implementation}", "{data}"],
      },
    },
    contract: "ShinchaFactory",
    from: deployer,
    log: true,
    autoMine: true,
    skipIfAlreadyDeployed: false,
  });
};

func.tags = ["deploy"];
export default func;
