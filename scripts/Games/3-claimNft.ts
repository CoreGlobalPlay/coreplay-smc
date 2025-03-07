import { ethers, network, getNamedAccounts, upgrades } from "hardhat";
import { keccak256 } from "ethers";
import MerkleTree from "merkletreejs";
import { readFileToArray } from "../helpers/utils";
import { ShinchaFactory } from "../../typechain";
import { Address } from "hardhat-deploy/types";

async function main() {
  const shinchaFactoryContract: ShinchaFactory = await ethers.getContract(
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

  const { deployer } = await getNamedAccounts();
  const proof = merkleTree.getHexProof(keccak256(deployer as `0x${string}`));

  console.log("Claim Nft from Shincha Factory");
  // await shinchaFactoryContract.claim(proof);

  // console.log(await shinchaFactoryContract.claimedCount());

  const implementationAddress = await upgrades.erc1967.getImplementationAddress(
    shinchaFactoryContract.target as Address
  );
  console.log("Implementation contract address:", implementationAddress);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
