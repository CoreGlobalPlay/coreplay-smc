import { ethers } from "hardhat";
import { parseEther } from "ethers";
import { CoinFlip } from "../../typechain";

async function main() {
  for (const gameName of ["CoinFlip", "Crash", "Mines", "Plinko"]) {
    const gameContract: CoinFlip = await ethers.getContract(gameName);

    /// SetBet
    await gameContract.setMinBet(parseEther("0.00025"));
    console.log("setMinBet: 0.00025");
    await gameContract.setMaxBet(parseEther("0.2"));
    console.log("setMaxBet: 0.2");
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
