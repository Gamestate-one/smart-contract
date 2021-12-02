require("@nomiclabs/hardhat-ethers");
require("@openzeppelin/hardhat-upgrades");
const hre = require("hardhat");
const CONTRACT_NAME = "Marketplace";
const GNOSIS_SAFE = process.env.GNOSIS_SAFE;
const { PROXY_ADDRESS } = require("./config");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Preparing to set NFT contract...");
    const factory = await hre.ethers.getContractFactory(CONTRACT_NAME);
    const contract = factory.attach(PROXY_ADDRESS);
    const nftContract = "0x409393a1306cFE8CE00f7dE451e3a67d3db34436";
    await contract.setNFT721Address(nftContract);
    console.log("Set nft contract address success for: ", nftContract);
}

main().then(() => {
    process.exit(0);
}).catch(error => {
    console.error(error);
    process.exit(1);
});