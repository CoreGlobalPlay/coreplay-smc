import { ethers, network } from "hardhat";
import { ShinchaFactory } from "../../typechain-types";
import MerkleTree from "merkletreejs";
import { keccak256 } from "ethers";
import { readFileToArray } from "../helpers/utils";

async function main() {
  const shinchaFactoryContract = await ethers.getContract<ShinchaFactory>(
    "ShinchaFactory"
  );

  const whitelistAddresses: string[] = await readFileToArray(
    `./scripts/Shincha/whitelist.${network.name}.txt`
  );

  const merkleTree = new MerkleTree(
    whitelistAddresses.map((address) => keccak256(address)),
    keccak256,
    {
      sortPairs: true,
    }
  );

  const root = merkleTree.getHexRoot();
  console.log("Shincha Factory: Set merkle root: ", root);
  await shinchaFactoryContract.setRoot(root);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
