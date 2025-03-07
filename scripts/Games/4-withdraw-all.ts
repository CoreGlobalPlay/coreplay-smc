import { ethers } from "hardhat";
import { parseEther } from "ethers";
import { CoinFlip } from "../../typechain";

async function main() {
  const [deployer] = await ethers.getSigners();
  for (const gameName of ["CoinFlip", "Crash", "Mines", "Plinko"]) {
    const gameContract: CoinFlip = await ethers.getContract(gameName);

    /// SetBet
    await gameContract.withdrawAll(deployer);
    console.log("Withdrawed from ", gameName);
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
