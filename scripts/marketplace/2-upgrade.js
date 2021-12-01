require('@nomiclabs/hardhat-ethers');
require('@openzeppelin/hardhat-upgrades');

const hre = require("hardhat");
const PROXY_ADDRESS = "0x31E34eD544De1A049905D9b3e0Dd3cAD1137F3eA";
const CONTRACT_NAME_V1 = "Vesting";
const CONTRACT_NAME_V2 = "Vesting";

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deployer:", deployer.address);
    console.log("Balance:", (await deployer.getBalance()).toString());
    const factoryV1 = await hre.ethers.getContractFactory(CONTRACT_NAME_V1);
    const contractV1 = factoryV1.attach(PROXY_ADDRESS);
    console.log(`Upgrading ${CONTRACT_NAME_V1} at ${contractV1.address}...`);
    const factoryV2 = await hre.ethers.getContractFactory(CONTRACT_NAME_V2);
    const contractV2 = await hre.upgrades.upgradeProxy(contractV1, factoryV2);
    await contractV2.deployed();
    let logicAddr = await hre.upgrades.erc1967.getImplementationAddress(contractV2.address);
    console.log(`${CONTRACT_NAME_V2} proxy address: ${contractV2.address}`);
    console.log(`${CONTRACT_NAME_V2} logic address: ${logicAddr}`);
}

main().then(() => {
    process.exit(0);
}).catch((error) => {
    console.error(error);
    process.exit(1);
});