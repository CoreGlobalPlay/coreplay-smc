# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a Hardhat Ignition module that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat ignition deploy ./ignition/modules/Lock.ts
```

### Deployed Contracts

Deployed contract abis and addresses are exported in the `deployments` directory. To create a summary export of all contracts deployed to a network run

```bash
NETWORK=localhost
yarn hardhat export --network $NETWORK --export ./deployments/$NETWORK.json
jq -M '{name, chainId, addresses: .contracts | map_values(.address)}' ./deployments/${NETWORK}.json > ./deployments/${NETWORK}_addresses.json
```
