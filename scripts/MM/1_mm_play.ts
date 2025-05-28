import { ethers } from "hardhat";
import { CoinFlip, Crash, Mines, Plinko } from "../../typechain";
import fs from "fs";
import { parse } from "csv-parse/sync";
import { Wallet } from "ethers";

export function sleep(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

const playPlinko = async (wallet: Wallet) => {
  console.log("Play Plinko");
  const plinkoContract = await ethers.getContract<Plinko>("Plinko", wallet);

  const betAmount = ethers.parseEther("0.027875");
  await (
    await plinkoContract.plinko(false, 1, {
      value: betAmount,
      gasLimit: 300000,
    })
  ).wait();
};

const playCoinflip = async (wallet: Wallet) => {
  console.log("Play CoinFlip");
  const coinFlipContract = await ethers.getContract<CoinFlip>(
    "CoinFlip",
    wallet
  );

  const betAmount = ethers.parseEther("0.027875");
  const tx = await coinFlipContract.flip(false, {
    value: betAmount,
    gasLimit: 300000,
  });
  await tx.wait();
};

const playCrash = async (wallet: Wallet) => {
  console.log("Play Crash");
  const crashContract = await ethers.getContract<Crash>("Crash", wallet);

  const betAmount = ethers.parseEther("0.027875");
  await (
    await crashContract.crash(200, {
      value: betAmount,
      gasLimit: 300000,
    })
  ).wait();
};

const playMines = async (wallet: Wallet) => {
  console.log("Play Mines");
  const minesContract = await ethers.getContract<Mines>("Mines", wallet);

  const betAmount = ethers.parseEther("0.027875");
  await (
    await minesContract.checkMine(10, 1, {
      value: betAmount,
      gasLimit: 300000,
    })
  ).wait();
};

async function main() {
  // 1. Load CSV and parse accounts
  const csvPath = `scripts/MM/account.csv`;
  const fileContent = fs.readFileSync(csvPath);
  const records: { address: string; privateKey: string }[] = parse(
    fileContent,
    {
      columns: true,
      skip_empty_lines: true,
    }
  );

  while (true) {
    try {
      // 2. Pick random account
      const randomAccount = records[Math.floor(Math.random() * records.length)];
      const wallet = new ethers.Wallet(
        randomAccount.privateKey,
        ethers.provider
      );

      // 5. Randomly select and play one game
      const games = [playCoinflip, playPlinko, playCrash, playMines];
      const selectedGame = games[Math.floor(Math.random() * games.length)];

      console.log(`Using wallet: ${wallet.address}`);
      await selectedGame(wallet);
      await sleep(10000);
    } catch (error) {
      console.error(error);
    }
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
