require("@nomiclabs/hardhat-ethers");
require("@openzeppelin/hardhat-upgrades");
const hre = require("hardhat");
const CONTRACT_NAME = "Vesting";
const GNOSIS_SAFE = process.env.GNOSIS_SAFE;
const { PROXY_ADDRESS, LOGIC_ADDRESS } = require("./config");
const { vestingInfo } = require("./vestingInfo")

async function main() {
    const [operator] = await hre.ethers.getSigners();
    console.log("Preparing to create new vesting information...");
    const factory = await hre.ethers.getContractFactory(CONTRACT_NAME);
    const contract = factory.attach(PROXY_ADDRESS);
    // console.log(contract)
    for (let i = 0; i < vestingInfo.length; i++) {
        const rs = await contract.newVestingInformation(
            vestingInfo[i].wallet,
            vestingInfo[i].startTime,
            vestingInfo[i].endTime,
            vestingInfo[i].timeIncrease,
            web3.utils.toWei(vestingInfo[i].maxSupplyClaim, "ether")
        );
        const data = await rs.wait();
        const wallet = data.events[0].args.wallet;
        console.log("Address: ", wallet, "add success");
    }
}

main().then(() => {
    process.exit(0);
}).catch(error => {
    console.error(error);
    process.exit(1);
});