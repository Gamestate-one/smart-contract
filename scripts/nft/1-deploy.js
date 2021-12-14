const hre = require("hardhat");
const CONTRACT_NAME = "QuantumAccelerator";    // Change contract name here

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deployer:", deployer.address);
    console.log("Balance:", (await deployer.getBalance()).toString());
    const factory = await hre.ethers.getContractFactory(CONTRACT_NAME);
    console.log("Deploying " + CONTRACT_NAME + "...");

    // Provide constructor parameters here
    const nft = {
        name: "NghiaNgu",
        symbol: "NghiaNgu"
    }

    const contract = await factory.deploy(
        nft.name,
        nft.symbol
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