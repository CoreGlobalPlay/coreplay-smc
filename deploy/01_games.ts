import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  // Leaderboard
  const leaderboard = await deploy("Leaderboard", {
    from: deployer,
    args: [],
    log: true,
    autoMine: true,
    skipIfAlreadyDeployed: true,
  });

  // Games
  for (const gameName of ["CoinFlip", "Crash", "Mines", "Plinko"]) {
    /// Deploy
    await deploy(gameName, {
      from: deployer,
      args: [leaderboard.address],
      log: true,
      autoMine: true,
      skipIfAlreadyDeployed: true,
    });
  }
};

func.tags = ["deploy"];
export default func;
