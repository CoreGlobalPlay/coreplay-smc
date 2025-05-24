import { ethers, network } from "hardhat";
import { CoinFlip } from "../../typechain";
import { CrossbarClient } from "@switchboard-xyz/common";
import { toBeHex } from "ethers";

async function main() {
  const crossbar = CrossbarClient.default();

  const playPlinko = async () => {
  }
  
  const playCoinflip = async () => {
    const coinFlipContract = await ethers.getContract<CoinFlip>("CoinFlip");

    const fromSeq = await coinFlipContract.solvedSeq();
    const toSeq = await coinFlipContract.sequence();
    
    const chainId = network.config.chainId!;
    for (let seq = fromSeq + 1n; seq <= toSeq; seq++) {
      console.log({chainId, x: ethers.zeroPadValue(ethers.toBeHex(seq), 32)})
      const { encoded } = await crossbar.resolveEVMRandomness({
        chainId: chainId,
        randomnessId: ethers.zeroPadValue(ethers.toBeHex(seq), 32),
      });

      const tx = await coinFlipContract.resolve([encoded], seq);
      await tx.wait();
    }
  }

  const playCrash = async () => {
  }

  const playMines = async () => {
  }

  await playCoinflip();
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
