require("@nomiclabs/hardhat-ethers");
require("@openzeppelin/hardhat-upgrades");
const hre = require("hardhat");
const CONTRACT_NAME = "Marketplace";
const GNOSIS_SAFE = process.env.GNOSIS_SAFE;
const { PROXY_ADDRESS } = require("../nft/config");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Preparing to set payment currency...");
    const factory = await hre.ethers.getContractFactory(CONTRACT_NAME);
    const contract = factory.attach(PROXY_ADDRESS);
    const paymentCurrency = {
        tokenAddress: "0x76B07A77769CB38A973e46d7c29c828Ab91A6744"
    }
    await contract.setPaymentCurrency(paymentCurrency.tokenAddress, true, { from: deployer.address });
    console.log("Set payment currency token success for: " + paymentCurrency.tokenAddress);
}

main().then(() => {
    process.exit(0);
}).catch(error => {
    console.error(error);
    process.exit(1);
});