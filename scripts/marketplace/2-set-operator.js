require("@nomiclabs/hardhat-ethers");
require("@openzeppelin/hardhat-upgrades");
const hre = require("hardhat");
const CONTRACT_NAME = "Marketplace";
const GNOSIS_SAFE = process.env.GNOSIS_SAFE;
const { PROXY_ADDRESS } = require("./config");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Preparing to set operator...");
    const factory = await hre.ethers.getContractFactory(CONTRACT_NAME);
    const contract = factory.attach(PROXY_ADDRESS);
    const address = "0x8124c6Af26f52631C9425679e422f84a2E176322";
    await contract.setOperator(address, true);
    console.log("Set operator success for: ", nftContract);
}

main().then(() => {
    process.exit(0);
}).catch(error => {
    console.error(error);
    process.exit(1);
});