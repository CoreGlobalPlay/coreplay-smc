import { ethers } from "hardhat";
import { CoinFlip, Crash, Mines, Plinko } from "../../typechain";

async function main() {
  const playPlinko = async () => {
    const plinkoContract = await ethers.getContract<Plinko>("Plinko");

    const betAmount = ethers.parseEther("0.00025975");
    const receipt = await (
      await plinkoContract.plinko(false, 1, {
        value: betAmount,
      })
    ).wait();
  }
  
  const playCoinflip = async () => {
    const coinFlipContract = await ethers.getContract<CoinFlip>("CoinFlip");

    const betAmount = ethers.parseEther("0.00025975");
    const tx = await coinFlipContract.flip(false, {
        value: betAmount,
      });
    const receipt = await tx.wait();
    console.log({ receipt });
  }

  const playCrash = async () => {
    const crashContract = await ethers.getContract<Crash>("Crash");

    const betAmount = ethers.parseEther("0.00025975");
    const receipt = await (
      await crashContract.crash(200, {
        value: betAmount,
      })
    ).wait();
    console.log({ receipt });
  }

  const playMines = async () => {
    const minesContract = await ethers.getContract<Mines>("Mines");

    const betAmount = ethers.parseEther("0.00025975");
    const receipt = await (
      await minesContract.checkMine(10, 1, {
        value: betAmount,
      })
    ).wait();
    console.log({ receipt });
  }

  await playCoinflip();
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
