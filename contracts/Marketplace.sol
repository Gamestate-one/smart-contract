/* SPDX-License-Identifier: UNLICENSED */

pragma solidity ^0.8.0;

import "./QuantumAccelerator.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
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

    struct Information {
        address payable seller;
        address currency;
        uint256 price;
    }

    QuantumAccelerator public quantumAccelerator;
    address[] public listCurrencyWhitelist;
    mapping(address => bool) private _currencyWhitelist;
    mapping(uint256 => Information) private _informationOf;
    mapping(address => bool) private _walletCanSell;
    bool public isEveryoneCanSell;
    mapping(address => uint256[]) private _listNFTOnSellOf;
    address public receiveFeeWallet;
    mapping(address => uint256) private _priceMintNFT;

    event NewNFT(uint256 tokenId, address currency, uint256 price);
    event GetNFTBack(uint256 tokenId);
    event UpdatePrice(uint256 tokenId, uint256 newPrice);
    event NFTSold(
        uint256 tokenId,
        address buyer,
        address currency,
        uint256 price
    );
    event WalletCanSell(address wallet, bool isSeller);
    event EveryoneCanSell(bool canSell);
    event NFT721Contract(address NFT721Addr);
    event PaymentCurrency(address currency, bool accepted);
    event PriceMintNFT(address currency, uint256 price);
    event BuyNFTMint(address buyer, address currency, uint256 price);
    event ReceiveFeeWallet(address wallet);

    function initialize() public initializer {
        __UUPSUpgradeable_init();
        __ERC721Holder_init();
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    modifier onlyOwnerToken(uint256 tokenId) {
        require(
            address(this) == quantumAccelerator.ownerOf(tokenId),
            "token-not-sell"
        );
        require(
            msg.sender == _informationOf[tokenId].seller,
            "not-owner-token"
        );
        _;
    }

    function getNFTInfo(uint256 tokenId)
        public
        view
        returns (
            address seller,
            address currency,
            uint256 price
        )
    {
        Information memory info = _informationOf[tokenId];
        return (info.seller, info.currency, info.price);
    }

    function getNFTsOnSellOf(address seller)
        public
        view
        returns (uint256[] memory)
    {
        return _listNFTOnSellOf[seller];
    }

    function getPriceMintNFT(address currency) public view returns (uint256) {
        return _priceMintNFT[currency];
    }

    function getListCurrecyWhitelist() public view returns (address[] memory) {
        return listCurrencyWhitelist;
    }

    function checkCurrency(address currency) public view returns (bool) {
        return (_currencyWhitelist[currency]);
    }

    function setNFT721Address(address nft721Address) public onlyOwner {
        require(nft721Address != address(0) && nft721Address != address(this));
        quantumAccelerator = QuantumAccelerator(nft721Address);
        emit NFT721Contract(nft721Address);
    }

    function setPaymentCurrency(address currency, bool accepted)
        public
        onlyOwner
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

    function setWalletCanSell(address wallet, bool isSeller) public onlyOwner {
        _walletCanSell[wallet] = isSeller;
        emit WalletCanSell(wallet, isSeller);
    }

    function setEveryoneCanSell(bool canSell) public onlyOwner {
        isEveryoneCanSell = canSell;
        emit EveryoneCanSell(isEveryoneCanSell);
    }

    // The owner of an NFT pushes their NFT to our platform for sale
    function sellNFT(
        uint256 tokenId,
        address currency,
        uint256 price
    ) public whenNotPaused {
        if (!isEveryoneCanSell) {
            require(_walletCanSell[msg.sender], "can-not-sell");
        }
        require(
            msg.sender == quantumAccelerator.ownerOf(tokenId),
            "not-owner-token"
        );
        require(
            quantumAccelerator.getApproved(tokenId) == address(this),
            "not-approval"
        );
        require(_currencyWhitelist[currency], "currency-invalid");
        require(
            _informationOf[tokenId].price == 0 && price > 0,
            "price-invalid"
        );
        _informationOf[tokenId] = Information(
            payable(msg.sender),
            currency,
            price
        );
        quantumAccelerator.safeTransferFrom(msg.sender, address(this), tokenId);

        _listNFTOnSellOf[msg.sender].push(tokenId);
        emit NewNFT(tokenId, currency, price);
    }

    // The owner of an NFT takes his NFT back
    function getNFTBack(uint256 tokenId)
        public
        whenNotPaused
        onlyOwnerToken(tokenId)
    {
        require(_informationOf[tokenId].price > 0, "token-not-exists");
        delete _informationOf[tokenId];
        quantumAccelerator.safeTransferFrom(address(this), msg.sender, tokenId);

        uint256 indexTokenInArr = getIndexInArray(
            _listNFTOnSellOf[msg.sender],
            tokenId
        );
        _listNFTOnSellOf[msg.sender] = removeArrayByIndex(
            _listNFTOnSellOf[msg.sender],
            indexTokenInArr
        );
        emit GetNFTBack(tokenId);
    }

    // The owner wants to update the price of his NFT
    function updatePrice(uint256 tokenId, uint256 newPrice)
        public
        whenNotPaused
        onlyOwnerToken(tokenId)
    {
        require(
            _informationOf[tokenId].price > 0 && newPrice > 0,
            "price-invalid"
        );
        _informationOf[tokenId] = Information(
            _informationOf[tokenId].seller,
            _informationOf[tokenId].currency,
            newPrice
        );
        emit UpdatePrice(tokenId, newPrice);
    }

    // A person wants to purchase an NFT from our platform
    function purchaseNFT(uint256 tokenId) public payable whenNotPaused {
        require(
            msg.sender != address(this) &&
                msg.sender != _informationOf[tokenId].seller,
            "caller-invalid"
        );
        require(
            address(this) == quantumAccelerator.ownerOf(tokenId),
            "token-not-sell"
        );
        require(_informationOf[tokenId].price > 0, "price-token-invalid");
        address payable seller = _informationOf[tokenId].seller;
        require(msg.sender != seller, "owner-can-not-buy");
        if (_informationOf[tokenId].currency == address(0)) {
            // Native currency(ETH/BNB/MATIC) payment
            require(
                msg.value == _informationOf[tokenId].price,
                "value-invalid"
            );
            (bool success, ) = seller.call{value: msg.value}("");
            require(success, "fail-trans");
        } else {
            // ERC20 handle
            IERC20Upgradeable currencyContract = IERC20Upgradeable(
                _informationOf[tokenId].currency
            );
            require(
                currencyContract.balanceOf(msg.sender) >=
                    _informationOf[tokenId].price
            );
            require(
                currencyContract.allowance(msg.sender, address(this)) >=
                    _informationOf[tokenId].price
            );
            currencyContract.safeTransferFrom(
                msg.sender,
                seller,
                _informationOf[tokenId].price
            );
        }

        quantumAccelerator.safeTransferFrom(address(this), msg.sender, tokenId);

        uint256 indexTokenInArr = getIndexInArray(
            _listNFTOnSellOf[seller],
            tokenId
        );
        _listNFTOnSellOf[seller] = removeArrayByIndex(
            _listNFTOnSellOf[seller],
            indexTokenInArr
        );

        emit NFTSold(
            tokenId,
            msg.sender,
            _informationOf[tokenId].currency,
            _informationOf[tokenId].price
        );
        delete _informationOf[tokenId];
    }

    function buyNFTMint(address currency) public whenNotPaused {
        require(quantumAccelerator.totalSupply() < 1111, "out-of-times-to-buy");
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

        emit BuyNFTMint(msg.sender, currency, _priceMintNFT[currency]);
    }

    function setPriceMintNFT(address currency, uint256 price) public onlyOwner {
        require(_currencyWhitelist[currency], "not-whitelist");
        _priceMintNFT[currency] = price;
        emit PriceMintNFT(currency, price);
    }

    function setReceiveFeeWallet(address wallet) public onlyOwner {
        require(wallet != address(0), "wallet-invalid");
        receiveFeeWallet = wallet;
        emit ReceiveFeeWallet(receiveFeeWallet);
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
