import { Wallet } from "ethers";
import { createObjectCsvWriter } from "csv-writer";

const csvWriter = createObjectCsvWriter({
  path: `scripts/MM/account.csv`,
  header: [
    { id: "address", title: "address" },
    { id: "privateKey", title: "privateKey" },
  ],
});

const records = [];

for (let i = 0; i < 100; i++) {
  const wallet = Wallet.createRandom();
  records.push({
    address: wallet.address,
    privateKey: wallet.privateKey,
  });
}

csvWriter.writeRecords(records).then(() => {
  console.log("...Done");
});
