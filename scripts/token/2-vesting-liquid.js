require("@nomiclabs/hardhat-ethers");
require("@openzeppelin/hardhat-upgrades");
const hre = require("hardhat");
const CONTRACT_NAME = "GamestateToken";
const GNOSIS_SAFE = process.env.GNOSIS_SAFE;
const { PROXY_ADDRESS, LOGIC_ADDRESS } = require("./config");
const liquidWallet = require('./vestingLiquid.json')

async function main() {
    const [operator] = await hre.ethers.getSigners();
    console.log("Preparing to set whitelist wallet...");
    const factory = await hre.ethers.getContractFactory(CONTRACT_NAME);
    const contract = factory.attach(PROXY_ADDRESS);

    for (const [key, value] of Object.entries(liquidWallet)) {
        const tx = await contract.mint(key, web3.utils.toWei(value, "ether"));
        const data = await tx.wait();
        const event = data.events[0].args
        console.log("Address " + event.to + " is minted " + event.value + " STATE");
    }
}

main().then(() => {
    process.exit(0);
}).catch(error => {
    console.error(error);
    process.exit(1);
});
