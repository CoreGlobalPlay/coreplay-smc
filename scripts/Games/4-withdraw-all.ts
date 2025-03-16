import { ethers } from "hardhat";
import { parseEther } from "ethers";
import { CoinFlip, Leaderboard } from "../../typechain";

async function main() {
  const [deployer] = await ethers.getSigners();
  const leaderboardContract: Leaderboard = await ethers.getContract(
    "Leaderboard"
  );

  /// SetBet
  await leaderboardContract.withdrawAll(deployer);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
