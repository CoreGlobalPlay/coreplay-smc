import { ethers } from "hardhat";
import { Shincha, ShinchaFactory } from "../../typechain-types";
import { keccak256, toUtf8Bytes } from "ethers";

const MINTER_ROLE = keccak256(toUtf8Bytes("MINTER_ROLE"));

async function main() {
  const shinchaContract: Shincha = await ethers.getContract("Shincha");
  const shinchaFactoryContract: ShinchaFactory = await ethers.getContract(
    "ShinchaFactory"
  );

  console.log("Granting MINTER_ROLE Role to Shincha Factory");
  await shinchaContract.grantRole(MINTER_ROLE, shinchaFactoryContract.target);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
