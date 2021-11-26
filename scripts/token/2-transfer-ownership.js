require("@nomiclabs/hardhat-ethers");
require("@openzeppelin/hardhat-upgrades");
const hre = require("hardhat");
const CONTRACT_NAME = "GamestateToken";
const GNOSIS_SAFE = process.env.GNOSIS_SAFE;
const { PROXY_ADDRESS } = require("./config");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Preparing to transfer...");
    const factory = await hre.ethers.getContractFactory(CONTRACT_NAME);
    const contract = factory.attach(PROXY_ADDRESS);
    await contract.transferOwnership(GNOSIS_SAFE, { from: deployer.address });
    console.log("Ownership has been transfered to", GNOSIS_SAFE);
}

main().then(() => {
    process.exit(0);
}).catch(error => {
    console.error(error);
    process.exit(1);
});