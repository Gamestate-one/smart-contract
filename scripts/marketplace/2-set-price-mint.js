require("@nomiclabs/hardhat-ethers");
require("@openzeppelin/hardhat-upgrades");
const hre = require("hardhat");
const CONTRACT_NAME = "Marketplace";
const GNOSIS_SAFE = process.env.GNOSIS_SAFE;
const { PROXY_ADDRESS } = require("./config");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Preparing to set PriceMintNFT...");
    const factory = await hre.ethers.getContractFactory(CONTRACT_NAME);
    const contract = factory.attach(PROXY_ADDRESS);
    const paymentCurrency = {
        tokenAddress: "0x76B07A77769CB38A973e46d7c29c828Ab91A6744",
        price: web3.utils.toWei("250", "ether")
    }
    await contract.setPriceMintNFT(paymentCurrency.tokenAddress, paymentCurrency.price);
    console.log("Set price mint success for: " + paymentCurrency.tokenAddress + " with  price: " + paymentCurrency.price);
}

main().then(() => {
    process.exit(0);
}).catch(error => {
    console.error(error);
    process.exit(1);
});