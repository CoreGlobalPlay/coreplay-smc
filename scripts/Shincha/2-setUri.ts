import { ethers } from "hardhat";
import { Shincha, ShinchaFactory } from "../../typechain-types";
import { keccak256, toUtf8Bytes } from "ethers";

async function main() {
  const shinchaContract: Shincha = await ethers.getContract("Shincha");

  const uri = "https://assets.berahive.io/metadata/";
  console.log("Set Base Token URI to ", uri);
  await shinchaContract.setBaseURI(uri);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
