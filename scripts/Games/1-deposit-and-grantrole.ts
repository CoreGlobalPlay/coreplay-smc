import { ethers } from "hardhat";
import { keccak256, toUtf8Bytes } from "ethers";
import { Leaderboard } from "../../typechain";

const GAME_ROLE = keccak256(toUtf8Bytes("GAME_ROLE"));

async function main() {
  const [deployer] = await ethers.getSigners();

  const leaderboardContract: Leaderboard = await ethers.getContract(
    "Leaderboard"
  );

  const depositAmount = ethers.parseEther("10");
  for (const gameName of ["CoinFlip", "Crash", "Mines", "Plinko"]) {
    const gameContract = await ethers.getContract(gameName);

    /// Deposit
    const tx = await deployer.sendTransaction({
      to: gameContract.target,
      value: depositAmount,
    });
    await tx.wait();
    console.log("Deposit Success to contract: ", gameName);

    /// GrantRole
    await leaderboardContract.grantRole(GAME_ROLE, gameContract.target);
    console.log("Granted GAME_ROLE to contract: ", gameName);
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
