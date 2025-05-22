import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { Leaderboard } from "../typechain";
import { ethers } from "hardhat";
import { keccak256, toUtf8Bytes } from "ethers";
import { ScriptConfig } from "../scripts/Games/config";

const GAME_ROLE = keccak256(toUtf8Bytes("GAME_ROLE"));


const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  // Leaderboard
  const leaderboard = await deploy("Leaderboard", {
    proxy: {
      proxyContract: "UUPS",
      execute: {
        init: {
          methodName: "initialize",
          args: [],
        },
      },
    },
    contract: "Leaderboard",
    from: deployer,
    log: true,
    autoMine: true,
    skipIfAlreadyDeployed: false,
  });
  const leaderboardContract: Leaderboard = await ethers.getContract("Leaderboard");

  // Games
  for (const gameName of ["CoinFlip", "Crash", "Mines", "Plinko"]) {
    /// Deploy
    const deployed = await deploy(gameName, {
      proxy: {
        proxyContract: "UUPS",
        execute: {
          init: {
            methodName: "initialize",
            args: [leaderboard.address, ScriptConfig.SwAddress, ScriptConfig.swQueue],
          },
          onUpgrade: {
            methodName: "sequenceNumberToGameId",
            args: [0]
          }
        },
      },
      contract: gameName,
      from: deployer,
      log: true,
      autoMine: true,
      skipIfAlreadyDeployed: false,
    });
    
    await leaderboardContract.grantRole(GAME_ROLE, deployed.address);
  }
};

func.tags = ["deploy"];
export default func;
