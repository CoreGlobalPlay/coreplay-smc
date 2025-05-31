import { ethers } from "hardhat";
import fs from "fs";
import { parse } from "csv-parse/sync";
import { parseUnits } from "ethers";

const RECEIVER = "0x95485ceC9172e2Dc06690Aa2F986B19f0e364E45";

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

    const gasLimit = 21000n;
    const gasPrice = parseUnits("10", 9);

  for (const record of records) {
    const wallet = new ethers.Wallet(
        record.privateKey,
        ethers.provider
    );

    const balance = await ethers.provider.getBalance(record.address);
    const value = balance - gasLimit*gasPrice;

    if (balance > 0n) {
        await wallet.sendTransaction({to: RECEIVER, value, gasLimit, gasPrice});
        console.log("Transfer from ", record.address, balance);
    } else {
        console.log("Not enough balance")
    }
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
