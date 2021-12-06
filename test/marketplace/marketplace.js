const hre = require("hardhat");
const assert = require("assert")

const artifactERC20 = "GamestateToken";
const artifactNFT = "QuantumAccelerator";
const artifactMarketplace = "Marketplace";

describe("Marketplace", () => {
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
            erc20Contract.mint(accounts[1].address, supply);
            assert.equal(supply, await erc20Contract.balanceOf(accounts[1].address))
        })

        it("approve for marketplace", async () => {
            const tx = await erc20Contract.connect(accounts[1]).approve(marketplaceContract.address, web3.utils.toWei("9999999999999999", "ether"));
            const data = await tx.wait();
            assert.equal(marketplaceContract.address, data.events[0].args.spender);
        })
    })

    describe("NFT", async () => {
        it("set operator", async () => {
            const tx = await nftContract.setOperator(accounts[0].address, true);
            const data = await tx.wait();
            assert.equal(accounts[0].address, data.events[0].args.operator);
        })

        it("mint NFT and approve for marketplace", async () => {
            const tx = await nftContract.safeMint(accounts[0].address);
            const data = await tx.wait();
            assert.equal(accounts[0].address, data.events[0].args.to);
            let tokenId = data.events[0].args.tokenId;
            await nftContract.approve(marketplaceContract.address, tokenId);
        })
    })

    describe("Marketplace", async () => {
        it("set operator", async () => {
            for (let i = 0; i < 3; i++) {
                const tx = await marketplaceContract.setOperator(accounts[0].address, true);
                const data = await tx.wait();
                assert.equal(accounts[0].address, data.events[0].args.operator);
            }
        })
        it("set everyone can sell", async () => {
            await marketplaceContract.setEveryoneCanSell(true);
        })

        it("set currency", async () => {
            await marketplaceContract.setPaymentCurrency(erc20Contract.address, true);
            assert.ok(await marketplaceContract.checkCurrency(erc20Contract.address))
            await marketplaceContract.setPriceMintNFT(erc20Contract.address, web3.utils.toWei("250", "ether"))
            assert.equal(await marketplaceContract.getPriceMintNFT(erc20Contract.address), web3.utils.toWei("250", "ether"))
            await marketplaceContract.setMaxNFTCanMint(20);
            assert.equal(20, await marketplaceContract.maxNFTCanMint())
        })

        it("set nft contract", async () => {
            await marketplaceContract.setNFTContractWhitelist(nftContract.address, true);
            assert.ok(await marketplaceContract.checkNFTContract(nftContract.address))
        })
        it("sell NFT", async () => {
            let listNFT = await nftContract.getOwnedTokenIds(accounts[0].address);

            const tx = await marketplaceContract.sellNFT(nftContract.address, listNFT[0], erc20Contract.address, web3.utils.toWei("250", "ether"));
            const data = await tx.wait();
            const itemId = await data.events[2].args.itemId;
            let item1 = await marketplaceContract.getNFTInfo(itemId);
            assert(item1.nftContract == nftContract.address
                && item1.tokenId.toString() == listNFT[0]
                && item1.currency == erc20Contract.address
                && item1.price == web3.utils.toWei("250", "ether")
            )
        })

        it("buy nft", async () => {
            await marketplaceContract.connect(accounts[1]).purchaseNFT(0);
            assert.equal(await nftContract.ownerOf(0), accounts[1].address)
        })
    })

});