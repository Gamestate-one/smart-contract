/* SPDX-License-Identifier: UNLICENSED */

pragma solidity ^0.8.0;

import "./QuantumAccelerator.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Marketplace is
    UUPSUpgradeable,
    ERC721HolderUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    struct Information {
        address payable seller;
        address buyer;
        address nftContract;
        uint256 tokenId;
        address currency;
        uint256 price;
    }

    CountersUpgradeable.Counter private _itemId;
    mapping(address => bool) private _operators;
    QuantumAccelerator public quantumAccelerator;
    address[] public listOperators;
    address[] public listCurrencyWhitelist;
    address[] public listNFTContractWhitelist;
    mapping(address => bool) private _currencyWhitelist;
    mapping(address => bool) private _NFTContractWhitelist;
    mapping(uint256 => Information) private _informationOf;
    uint256[] private _listNFTOnSell;
    mapping(address => bool) private _walletCanSell;
    mapping(address => bool) private _walletCanBuyNFTMint;
    bool public isEveryoneCanSell;
    bool public isEveryoneCanBuyNFTMint;
    mapping(address => uint256[]) private _listNFTOnSellOf;
    address public receiveFeeWallet;
    mapping(address => uint256) private _priceMintNFT;
    uint256 public maxNFTCanMint;
    uint256 public supplyNFTMinted;
    uint256 private _fee;
    uint256 private _percent;

    event Operator(address operator, bool isOperator);
    event NewNFT(
        uint256 itemId,
        address nftContract,
        uint256 tokenId,
        address currency,
        uint256 price
    );
    event GetNFTBack(uint256 tokenId);
    event UpdatePrice(uint256 tokenId, uint256 newPrice);
    event NFTSold(
        uint256 itemId,
        address buyer,
        address nftContract,
        uint256 tokenId,
        address currency,
        uint256 price
    );
    event WalletCanSell(address wallet, bool isSeller);
    event EveryoneCanSell(bool canSell);
    event WalletCanBuyNFTMint(address wallet, bool isBuyer);
    event EveryoneCanBuyNFTMint(bool canBuy);
    event NFT721Contract(address NFT721Addr);
    event PaymentCurrency(address currency, bool accepted);
    event NFTContractWhitelist(address nftContract, bool accepted);
    event PriceMintNFT(address currency, uint256 price);
    event BuyNFTMint(address buyer, address currency, uint256 price);
    event ReceiveFeeWallet(address wallet);
    event MaxNFTCanMint(uint256 maxSupply);
    event FeePercent(uint256 fee, uint256 percent);

    function initialize() public initializer {
        __UUPSUpgradeable_init();
        __ERC721Holder_init();
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        _fee = 0;
        _percent = 1;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    modifier onlyOperator() {
        require(_operators[_msgSender()]);
        _;
    }

    modifier onlyOwnerToken(uint256 itemId) {
        Information memory info = _informationOf[itemId];
        require(
            address(this) ==
                ERC721Upgradeable(info.nftContract).ownerOf(info.tokenId),
            "token-not-sell"
        );
        require(msg.sender == info.seller, "not-owner-token");
        _;
    }

    modifier isTokenOnMarketplace(uint256 itemId) {
        Information memory info = _informationOf[itemId];
        require(info.seller != address(0), "token-not-exists");
        require(info.buyer == address(0), "token-bought");
        _;
    }

    function getNFTInfo(uint256 itemId)
        public
        view
        returns (
            address seller,
            address buyer,
            address nftContract,
            uint256 tokenId,
            address currency,
            uint256 price
        )
    {
        Information memory info = _informationOf[itemId];
        return (
            info.seller,
            info.buyer,
            info.nftContract,
            info.tokenId,
            info.currency,
            info.price
        );
    }

    function getNFTsOnSellOf(address seller)
        public
        view
        returns (uint256[] memory)
    {
        return _listNFTOnSellOf[seller];
    }

    function getNFTsOnSell() public view returns (uint256[] memory) {
        return _listNFTOnSell;
    }

    function getPriceMintNFT(address currency) public view returns (uint256) {
        return _priceMintNFT[currency];
    }

    function getListCurrecyWhitelist() public view returns (address[] memory) {
        return listCurrencyWhitelist;
    }

    function getListNFTContractWhitelist()
        public
        view
        returns (address[] memory)
    {
        return listNFTContractWhitelist;
    }

    function getFeePercent()
        public
        view
        returns (uint256 fee, uint256 percent)
    {
        fee = _fee;
        percent = _percent;
    }

    function checkCurrency(address currency) public view returns (bool) {
        return (_currencyWhitelist[currency]);
    }

    function checkNFTContract(address nftContract) public view returns (bool) {
        return (_NFTContractWhitelist[nftContract]);
    }

    function setOperator(address operator, bool isOperator) public onlyOwner {
        _operators[operator] = isOperator;

        (bool isOperatorBefore, uint256 indexInArr) = checkExistsInArray(
            listOperators,
            operator
        );

        if (isOperator && !isOperatorBefore) {
            listOperators.push(operator);
        }
        if (!isOperator && isOperatorBefore) {
            removeOutOfArray(listOperators, indexInArr);
        }
        emit Operator(operator, isOperator);
    }

    function setQuantumAcceleratorAddress(address nft721Address)
        public
        onlyOperator
    {
        require(nft721Address != address(0) && nft721Address != address(this));
        quantumAccelerator = QuantumAccelerator(nft721Address);
        emit NFT721Contract(nft721Address);
    }

    function setPaymentCurrency(address currency, bool accepted)
        public
        onlyOperator
    {
        _currencyWhitelist[currency] = accepted;

        (bool isAcceptedBefore, uint256 indexInArr) = checkExistsInArray(
            listCurrencyWhitelist,
            currency
        );

        if (accepted && !isAcceptedBefore) {
            listCurrencyWhitelist.push(currency);
        }
        if (!accepted && isAcceptedBefore) {
            removeOutOfArray(listCurrencyWhitelist, indexInArr);
        }

        emit PaymentCurrency(currency, accepted);
    }

    function setNFTContractWhitelist(address nftContract, bool accepted)
        public
        onlyOperator
    {
        _NFTContractWhitelist[nftContract] = accepted;

        (bool isAcceptedBefore, uint256 indexInArr) = checkExistsInArray(
            listNFTContractWhitelist,
            nftContract
        );

        if (accepted && !isAcceptedBefore) {
            listNFTContractWhitelist.push(nftContract);
        }
        if (!accepted && isAcceptedBefore) {
            removeOutOfArray(listNFTContractWhitelist, indexInArr);
        }

        emit NFTContractWhitelist(nftContract, accepted);
    }

    function setWalletCanSell(address wallet, bool isSeller)
        public
        onlyOperator
    {
        _walletCanSell[wallet] = isSeller;
        emit WalletCanSell(wallet, isSeller);
    }

    function setEveryoneCanSell(bool canSell) public onlyOperator {
        isEveryoneCanSell = canSell;
        emit EveryoneCanSell(isEveryoneCanSell);
    }

    // The owner of an NFT pushes their NFT to our platform for sale
    function sellNFT(
        address nftContract,
        uint256 tokenId,
        address currency,
        uint256 price
    ) public whenNotPaused {
        if (!isEveryoneCanSell) {
            require(_walletCanSell[msg.sender], "can-not-sell");
        }
        require(
            _NFTContractWhitelist[nftContract],
            "nft-contract-not-whitelist"
        );
        require(
            msg.sender == ERC721Upgradeable(nftContract).ownerOf(tokenId),
            "not-owner-token"
        );
        require(
            ERC721Upgradeable(nftContract).getApproved(tokenId) ==
                address(this),
            "not-approval"
        );
        require(_currencyWhitelist[currency], "currency-invalid");
        require(price > 0, "price-invalid");

        uint256 itemId = _itemId.current();
        _informationOf[itemId] = Information(
            payable(msg.sender),
            address(0),
            nftContract,
            tokenId,
            currency,
            price
        );

        ERC721Upgradeable(nftContract).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId
        );

        _listNFTOnSellOf[msg.sender].push(itemId);
        _listNFTOnSell.push(itemId);

        _itemId.increment();
        emit NewNFT(itemId, nftContract, tokenId, currency, price);
    }

    // The owner of an NFT takes his NFT back
    function getNFTBack(uint256 itemId)
        public
        whenNotPaused
        onlyOwnerToken(itemId)
        isTokenOnMarketplace(itemId)
    {
        Information storage info = _informationOf[itemId];

        ERC721Upgradeable(info.nftContract).safeTransferFrom(
            address(this),
            info.seller,
            info.tokenId
        );

        info.buyer = info.seller;

        //remove itemId out of list on sell of seller
        uint256 indexTokenInArr = getIndexInArray(
            _listNFTOnSellOf[msg.sender],
            itemId
        );
        _listNFTOnSellOf[msg.sender] = removeArrayByIndex(
            _listNFTOnSellOf[msg.sender],
            indexTokenInArr
        );

        //remove itemId out of list on sell of marketplace
        uint256 indexItemIdInArr = getIndexInArray(_listNFTOnSell, itemId);
        _listNFTOnSell = removeArrayByIndex(_listNFTOnSell, indexItemIdInArr);

        emit GetNFTBack(itemId);
    }

    // The owner wants to update the price of his NFT
    function updatePrice(uint256 itemId, uint256 newPrice)
        public
        whenNotPaused
        onlyOwnerToken(itemId)
        isTokenOnMarketplace(itemId)
    {
        Information storage info = _informationOf[itemId];
        require(newPrice > 0, "price-invalid");
        info.price = newPrice;
        emit UpdatePrice(itemId, newPrice);
    }

    // A person wants to purchase an NFT from our platform
    function purchaseNFT(uint256 itemId)
        public
        payable
        whenNotPaused
        isTokenOnMarketplace(itemId)
    {
        Information storage info = _informationOf[itemId];
        require(
            msg.sender != address(this) && msg.sender != info.seller,
            "caller-invalid"
        );
        require(info.price > 0, "price-token-invalid");
        address payable seller = info.seller;

        uint256 realPrice = info.price;
        uint256 feePrice = realPrice.mul(_fee).div(_percent);
        uint256 sellerReceive = realPrice.sub(feePrice);

        if (info.currency == address(0)) {
            // Native currency(ETH/BNB/MATIC) payment
            require(msg.value == info.price, "value-invalid");
            (bool successTransFee, ) = receiveFeeWallet.call{value: feePrice}(
                ""
            );
            require(successTransFee, "fail-transfer");
            (bool success, ) = seller.call{value: sellerReceive}("");
            require(success, "fail-trans");
        } else {
            // ERC20 handle
            IERC20Upgradeable currencyContract = IERC20Upgradeable(
                info.currency
            );
            require(currencyContract.balanceOf(msg.sender) >= info.price);
            require(
                currencyContract.allowance(msg.sender, address(this)) >=
                    info.price
            );
            currencyContract.safeTransferFrom(
                msg.sender,
                receiveFeeWallet,
                feePrice
            );
            currencyContract.safeTransferFrom(
                msg.sender,
                seller,
                sellerReceive
            );
        }

        ERC721Upgradeable(info.nftContract).safeTransferFrom(
            address(this),
            msg.sender,
            info.tokenId
        );

        info.buyer = msg.sender;

        //remove itemId out of list on sell of seller
        uint256 indexTokenInArr = getIndexInArray(
            _listNFTOnSellOf[seller],
            itemId
        );
        _listNFTOnSellOf[seller] = removeArrayByIndex(
            _listNFTOnSellOf[seller],
            indexTokenInArr
        );

        //remove itemId out of list on sell of marketplace
        uint256 indexItemIdInArr = getIndexInArray(_listNFTOnSell, itemId);
        _listNFTOnSell = removeArrayByIndex(_listNFTOnSell, indexItemIdInArr);

        emit NFTSold(
            itemId,
            info.buyer,
            info.nftContract,
            info.tokenId,
            info.currency,
            info.price
        );
    }

    function buyNFTMint(address currency) public whenNotPaused {
        if (!isEveryoneCanBuyNFTMint) {
            require(_walletCanBuyNFTMint[msg.sender], "not-whitelist-to-buy");
        }
        require(maxNFTCanMint != 0, "max-supply-have-not-set");
        require(supplyNFTMinted < maxNFTCanMint, "out-of-times-to-buy");
        require(
            receiveFeeWallet != address(0),
            "have-not-setup-recevei-fee-wallet"
        );
        require(_priceMintNFT[currency] > 0, "have-not-setup-price");
        require(
            IERC20Upgradeable(currency).balanceOf(msg.sender) >=
                _priceMintNFT[currency]
        );
        require(
            IERC20Upgradeable(currency).allowance(msg.sender, address(this)) >=
                _priceMintNFT[currency]
        );

        IERC20Upgradeable(currency).safeTransferFrom(
            msg.sender,
            receiveFeeWallet,
            _priceMintNFT[currency]
        );

        quantumAccelerator.safeMint(msg.sender);

        supplyNFTMinted++;

        _walletCanBuyNFTMint[msg.sender] = false;

        emit BuyNFTMint(msg.sender, currency, _priceMintNFT[currency]);
    }

    function setMaxNFTCanMint(uint256 maxSupply) public onlyOperator {
        require(maxSupply > 0, "max-supply-invalid");
        maxNFTCanMint = maxSupply;
        emit MaxNFTCanMint(maxNFTCanMint);
    }

    function setPriceMintNFT(address currency, uint256 price)
        public
        onlyOperator
    {
        require(_currencyWhitelist[currency], "not-whitelist");
        _priceMintNFT[currency] = price;
        emit PriceMintNFT(currency, price);
    }

    function setReceiveFeeWallet(address wallet) public onlyOwner {
        require(wallet != address(0), "wallet-invalid");
        receiveFeeWallet = wallet;
        emit ReceiveFeeWallet(receiveFeeWallet);
    }

    function setWalletCanBuyNFTMint(address wallet, bool isBuyer)
        public
        onlyOperator
    {
        _walletCanBuyNFTMint[wallet] = isBuyer;
        emit WalletCanBuyNFTMint(wallet, isBuyer);
    }

    function setEveryoneCanBuyNFTMint(bool canBuy) public onlyOperator {
        isEveryoneCanBuyNFTMint = canBuy;
        emit EveryoneCanBuyNFTMint(isEveryoneCanBuyNFTMint);
    }

    /**
    @dev set fee for each transaction on marketplace
    feePercent = fee/percent
    example: - 4% is fee = 4, percent = 100
             - 0.04 if fee = 4, percent = 10000
             - not set fee is fee = 0, percent = 1
    */
    function setFeePercent(uint256 fee, uint256 percent) public onlyOperator {
        _fee = fee;
        if (fee == 0) {
            require(percent == 1, "if-not-set-fee-require-percent-is-1");
        }
        _percent = percent;
        emit FeePercent(fee, percent);
    }

    function getIndexInArray(uint256[] memory listNFT, uint256 tokenId)
        internal
        pure
        returns (uint256 index)
    {
        for (uint256 i = 0; i < listNFT.length; i++) {
            if (tokenId == listNFT[i]) {
                index = i;
                return i;
            }
        }
    }

    function removeArrayByIndex(uint256[] storage listWallet, uint256 index)
        internal
        returns (uint256[] storage)
    {
        require(index <= listWallet.length);

        for (uint256 i = index; i < listWallet.length - 1; i++) {
            listWallet[i] = listWallet[i + 1];
        }
        listWallet.pop();
        return listWallet;
    }

    function checkExistsInArray(address[] memory arr, address _address)
        internal
        pure
        returns (bool isExist, uint256 index)
    {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == _address) {
                isExist = true;
                index = i;
            }
        }
    }

    function removeOutOfArray(address[] storage arr, uint256 index) internal {
        arr[index] = arr[arr.length - 1];
        arr.pop();
    }
}
