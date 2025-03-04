import { ethers } from "hardhat";

async function main() {
  const contractAddress = (await ethers.getContract("Shincha")).target;
  console.log({ contractAddress });
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
