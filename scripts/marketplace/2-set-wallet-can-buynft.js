require("@nomiclabs/hardhat-ethers");
require("@openzeppelin/hardhat-upgrades");
const hre = require("hardhat");
const CONTRACT_NAME = "Marketplace";
const GNOSIS_SAFE = process.env.GNOSIS_SAFE;
const { PROXY_ADDRESS } = require("./config");
const whitelistWallet = require('./WhitelistWallet.json')

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Preparing to set wallet can buy nft mint...");
  const factory = await hre.ethers.getContractFactory(CONTRACT_NAME);
  const contract = factory.attach(PROXY_ADDRESS);
  // const walletCanSell = "";
  // await contract.setWalletCanBuyNFTMint(walletCanSell, true, { from: deployer.address });
  // console.log("Wallet can buy: ", walletCanSell);
  for (const [key, value] of Object.entries(whitelistWallet)) {
    await contract.setWalletCanBuyNFTMint(key, true, { from: deployer.address });

    console.log("Address: " + key + " can buy");
  }
}

main().then(() => {
  process.exit(0);
}).catch(error => {
  console.error(error);
  process.exit(1);
});