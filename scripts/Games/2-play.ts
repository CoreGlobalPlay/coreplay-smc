import { ethers } from "hardhat";
import { CoinFlip } from "../../typechain";

async function main() {
  const coinFlipContract = await ethers.getContract<CoinFlip>("CoinFlip");

  const betAmount = ethers.parseEther("1");
  const receipt = await (
    await coinFlipContract.flip(false, {
      value: betAmount,
    })
  ).wait();
  console.log({ receipt });
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
