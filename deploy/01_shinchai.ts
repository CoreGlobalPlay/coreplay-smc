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
  const shinchaFactoryImpl = await deploy("ShinchaFactoryImpl", {
    contract: "ShinchaFactory",
    from: deployer,
    args: [],
    log: true,
    autoMine: true,
    skipIfAlreadyDeployed: true,
  });
  // Encode the initialize function call for the contract.
  const ShinchaFactory = await ethers.getContractFactory("ShinchaFactory");
  const initialize = ShinchaFactory.interface.encodeFunctionData("initialize", [
    shincha.address,
  ]);
  // Deploy the ERC1967 Proxy, pointing to the implementation
  deploy("ShinchaFactory", {
    contract: "ERC1967Proxy",
    from: deployer,
    args: [shinchaFactoryImpl.address, initialize],
    log: true,
    autoMine: true,
    skipIfAlreadyDeployed: true,
  });
};
export default func;
