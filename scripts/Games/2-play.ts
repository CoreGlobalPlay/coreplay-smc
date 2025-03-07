import { ethers } from "hardhat";
import { CoinFlip, Plinko } from "../../typechain";

async function main() {
  const coinFlipContract = await ethers.getContract<Plinko>("Plinko");

  const betAmount = ethers.parseEther("0.0025975");
  const receipt = await (
    await coinFlipContract.plinko(false, 1, {
      value: betAmount,
    })
  ).wait();
  console.log({ receipt });
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
