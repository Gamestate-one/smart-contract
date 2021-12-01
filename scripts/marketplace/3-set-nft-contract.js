require("@nomiclabs/hardhat-ethers");
require("@openzeppelin/hardhat-upgrades");
const hre = require("hardhat");
const CONTRACT_NAME = "NFTSale";
const GNOSIS_SAFE = process.env.GNOSIS_SAFE;
const { PROXY_ADDRESS } = require("./config");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Preparing to set NFT contract...");
  const factory = await hre.ethers.getContractFactory(CONTRACT_NAME);
  const contract = factory.attach(PROXY_ADDRESS);
  const CryptiaNFT721Addr = "0x924ED7d1345eB243C3bc3132628a608C32578524";
  await contract.setCryptiaNFT721Addr(CryptiaNFT721Addr, { from: deployer.address });
  console.log("Set cryptia nft contract address success for: ", CryptiaNFT721Addr);
}

main().then(() => {
  process.exit(0);
}).catch(error => {
  console.error(error);
  process.exit(1);
});