import { ethers } from "hardhat";
import { Leaderboard } from "../../typechain";

async function main() {
  const leaderboardContract: Leaderboard = await ethers.getContract(
    "Leaderboard"
  );

  const depositAmount = ethers.parseEther("0.1");
  await leaderboardContract.deposit({
    value: depositAmount,
  });
  console.log("Deposit Success to contract leaderboard");
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
