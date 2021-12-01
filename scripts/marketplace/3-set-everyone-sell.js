require("@nomiclabs/hardhat-ethers");
require("@openzeppelin/hardhat-upgrades");
const hre = require("hardhat");
const CONTRACT_NAME = "NFTSale";
const GNOSIS_SAFE = process.env.GNOSIS_SAFE;
const { PROXY_ADDRESS } = require("./config");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Preparing to set wallet can sell...");
  const factory = await hre.ethers.getContractFactory(CONTRACT_NAME);
  const contract = factory.attach(PROXY_ADDRESS);
  await contract.setEveryoneCanSell(true, { from: deployer.address });
  console.log("Everyone can sell");
}

main().then(() => {
  process.exit(0);
}).catch(error => {
  console.error(error);
  process.exit(1);
});