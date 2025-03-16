import { ethers } from "hardhat";
import { parseEther } from "ethers";
import { CoinFlip, Leaderboard } from "../../typechain";

async function main() {
  const leaderBoardContract: Leaderboard = await ethers.getContract(
    "Leaderboard"
  );

  /// SetBet
  await leaderBoardContract.setMinBet(parseEther("0.00025"));
  console.log("setMinBet: 0.00025");
  await leaderBoardContract.setMaxBet(parseEther("0.2"));
  console.log("setMaxBet: 0.2");
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
