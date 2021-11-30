const hre = require("hardhat");
const CONTRACT_NAME = "GamestateToken";    // Change contract name here

const OwnerWallet = "0x8124c6Af26f52631C9425679e422f84a2E176322";

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deployer:", deployer.address);
    console.log("Balance:", (await deployer.getBalance()).toString());
    const factory = await hre.ethers.getContractFactory(CONTRACT_NAME);
    console.log("Deploying " + CONTRACT_NAME + "...");

    // Provide constructor parameters here
    const token = {
        name: "Gamestate",
        symbol: "STATE",
        totalSupply: web3.utils.toWei("10000000000", "ether"),
        ownerAddress: "0x8124c6Af26f52631C9425679e422f84a2E176322"
    }

    const contract = await factory.deploy(
        token.name,
        token.symbol,
        token.totalSupply,
        token.ownerAddress
    );
    await contract.deployed();
    console.log(`${CONTRACT_NAME} deployed address: ${contract.address}`);

    console.log("Balance after deploy:", (await deployer.getBalance()).toString());
}

main().then(() => {
    process.exit(0);
}).catch(err => {
    console.error(err);
    process.exit(1);
});