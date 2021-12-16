const hre = require("hardhat");
const CONTRACT_NAME = "Marketplace";    // Change contract name here

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deployer:", deployer.address);
  console.log("Balance:", (await deployer.getBalance()).toString());
  const factory = await hre.ethers.getContractFactory(CONTRACT_NAME);
  console.log(`Deploying ${CONTRACT_NAME}...`);

  const contract = await hre.upgrades.deployProxy(
    factory,
    [],   // Provide constructor parameters here
    { kind: "uups" }
  );
  await contract.deployed();
  let logicAddr = await hre.upgrades.erc1967.getImplementationAddress(contract.address);
  console.log(`${CONTRACT_NAME} proxy address: ${contract.address}`);
  console.log(`${CONTRACT_NAME} logic address: ${logicAddr}`);
}

main().then(() => {
  process.exit(0);
}).catch(err => {
  console.error(err);
  process.exit(1);
});