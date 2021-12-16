const hre = require("hardhat");
const assert = require("assert")

const artifactERC20 = "GamestateToken";
const artifactNFT = "QuantumAccelerator";
const artifactMarketplace = "Marketplace";

describe("Buy NFT Quantum Accelerator", () => {
    let accounts = null;
    let erc20Contract = null;
    let nftContract = null;
    let marketplaceContract = null;

    before(async () => {
        accounts = await hre.ethers.getSigners();

        const tokenERC20Factory = await hre.ethers.getContractFactory(artifactERC20);

        const objTokenERC20 = {
            name: "USD Coin",
            symbol: "USDC",
            ownerAddress: accounts[0].address
        }

        const _contractTokenERC20 = await tokenERC20Factory.deploy(
            objTokenERC20.name,
            objTokenERC20.symbol,
            objTokenERC20.ownerAddress
        );
        erc20Contract = await _contractTokenERC20.deployed();

        const NFTFactory = await hre.ethers.getContractFactory(artifactNFT)
        const objNFT = {
            name: "Quantum Accelerator",
            symbol: "QA"
        }
        const _contractNFT = await NFTFactory.deploy(objNFT.name, objNFT.symbol);
        nftContract = await _contractNFT.deployed();

        const MarketplaceFactory = await hre.ethers.getContractFactory(artifactMarketplace)

        const _contractMaketplace = await hre.upgrades.deployProxy(
            MarketplaceFactory,
            [],   // Provide constructor parameters here
            { kind: "uups" }
        );
        marketplaceContract = await _contractMaketplace.deployed();
    });

    describe("Token ERC20", async () => {

        it("set operator", async () => {
            const owner = await erc20Contract.owner();

            const tx = await erc20Contract.setOperator(owner, true);
            const data = await tx.wait();
            assert.equal(owner, data.events[0].args.operator);
        })


        it("mint token", async () => {
            const supply = web3.utils.toWei("5000000000", "ether");
            erc20Contract.mint(accounts[0].address, supply);
            assert.equal(supply, await erc20Contract.balanceOf(accounts[0].address))
        })

        it("approve for marketplace", async () => {
            const tx = await erc20Contract.approve(marketplaceContract.address, web3.utils.toWei("9999999999999999", "ether"));
            const data = await tx.wait();
            assert.equal(marketplaceContract.address, data.events[0].args.spender);
        })
    })

    describe("NFT", async () => {
        it("set operator", async () => {
            const tx = await nftContract.setOperator(marketplaceContract.address, true);
            const data = await tx.wait();
            assert.equal(marketplaceContract.address, data.events[0].args.operator);
        })
    })

    describe("Marketplace", async () => {
        it("set operator", async () => {
            const tx = await marketplaceContract.setOperator(accounts[0].address, true);
            const data = await tx.wait();
            assert.equal(accounts[0].address, data.events[0].args.operator);
        })

        it("set QA contract", async () => {
            const tx = await marketplaceContract.setQuantumAcceleratorAddress(nftContract.address);
            assert.equal(nftContract.address, await marketplaceContract.quantumAccelerator());
        })

        it("set receive fee wallet", async () => {
            const tx = await marketplaceContract.setReceiveFeeWallet(accounts[1].address);
            assert.equal(accounts[1].address, await marketplaceContract.receiveFeeWallet());
        })

        it("set currency", async () => {
            await marketplaceContract.setPaymentCurrency(erc20Contract.address, true);
            assert.ok(await marketplaceContract.checkCurrency(erc20Contract.address))
            await marketplaceContract.setPriceMintNFT(erc20Contract.address, web3.utils.toWei("250", "ether"))
            assert.equal(await marketplaceContract.getPriceMintNFT(erc20Contract.address), web3.utils.toWei("250", "ether"))
            await marketplaceContract.setMaxNFTCanMint(20);
            assert.equal(20, await marketplaceContract.maxNFTCanMint())
        })
        it("buy NFT QA", async () => {
            assert.equal(await nftContract.totalSupply(), 0);
            try {
                let i = 0;
                while (true) {
                    if (i == 20) {
                        console.log("in case out of time buy");
                        assert.ifError(await marketplaceContract.buyNFTMint(erc20Contract.address));
                        return;
                    }
                    await marketplaceContract.buyNFTMint(erc20Contract.address)
                    assert.equal(await nftContract.totalSupply().toString(), await marketplaceContract.supplyNFTMinted().toString())
                    let supplyNFTMinted = await marketplaceContract.supplyNFTMinted()
                    console.log(supplyNFTMinted.toString());
                    i++;
                }
            } catch (err) {

            }

        })
    })

});