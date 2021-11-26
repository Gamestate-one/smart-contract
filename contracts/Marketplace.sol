/* SPDX-License-Identifier: UNLICENSED */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract NFTSale is
    UUPSUpgradeable,
    ERC721HolderUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    using SafeMathUpgradeable for uint256;

    struct Information {
        address payable seller;
        address currency;
        uint256 price;
    }

    ERC721Upgradeable public erc721Contract;
    mapping(uint256 => Information) private _informationOf;
    mapping(address => bool) private _currencyWhitelist;
    mapping(address => uint256) private _maxValueOfCurrency;
    bool public isEveryoneCanSell;
    mapping(address => bool) private _walletCanSell;
    address payable public receiveFeeWallet;
    uint256 public feePercent;

    event NewProduct(uint256 tokenId, address currency, uint256 price);
    event GetProductBack(uint256 tokenId);
    event UpdatePrice(uint256 tokenId, uint256 newPrice);
    event ProductSold(uint256 tokenId, address buyer, uint256 price);
    event WalletCanSell(address wallet, bool isSeller);
    event EveryoneCanSell(bool canSell);
    event CryptiaNFT721Contract(address cryptiaNFT721Addr);
    event PaymentCurrency(address currency, bool accepted, uint256 maxValue);
    event ReceiveFeeWallet(address receiveFeeWallet);
    event FeePercent(uint256 feePercent);

    function initialize() public initializer {
        __UUPSUpgradeable_init();
        __ERC721Holder_init();
        __Ownable_init();
        __Pausable_init();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    modifier onlyOwnerToken(uint256 tokenId) {
        require(
            address(this) == erc721Contract.ownerOf(tokenId),
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

    function checkCurrency(address currency)
        public
        view
        returns (bool, uint256)
    {
        return (_currencyWhitelist[currency], _maxValueOfCurrency[currency]);
    }

    function setCryptiaNFT721Addr(address cryptiaNFT721Addr) public onlyOwner {
        require(
            cryptiaNFT721Addr != address(0) &&
                cryptiaNFT721Addr != address(this)
        );
        erc721Contract = ERC721Upgradeable(cryptiaNFT721Addr);
        emit CryptiaNFT721Contract(cryptiaNFT721Addr);
    }

    function setPaymentCurrency(
        address currency,
        bool accepted,
        uint256 maxValue
    ) public onlyOwner {
        if (accepted == true) {
            require(maxValue > 0, "max-value-invalid");
            _maxValueOfCurrency[currency] = maxValue;
        }
        _currencyWhitelist[currency] = accepted;
        // erc721Contract._safeMint(address(this), 1);
        emit PaymentCurrency(currency, accepted, maxValue);
    }

    function setReceiveFeeWallet(address _receiveFeeWallet) public onlyOwner {
        receiveFeeWallet = payable(_receiveFeeWallet);
        emit ReceiveFeeWallet(receiveFeeWallet);
    }

    function setFeePercent(uint256 _feePercent) public onlyOwner {
        feePercent = _feePercent;
        emit FeePercent(feePercent);
    }

    function setWalletCanSell(address wallet, bool isSeller) public onlyOwner {
        _walletCanSell[wallet] = isSeller;
        emit WalletCanSell(wallet, isSeller);
    }

    function setEveryoneCanSell(bool canSell) public onlyOwner {
        isEveryoneCanSell = canSell;
        emit EveryoneCanSell(isEveryoneCanSell);
    }

    // The owner of an NFT pushes his NFT to our platform for sale
    function sellNFT(
        uint256 tokenId,
        address currency,
        uint256 price
    ) public whenNotPaused {
        if (!isEveryoneCanSell) {
            require(_walletCanSell[msg.sender], "can-not-sell");
        }
        require(
            msg.sender == erc721Contract.ownerOf(tokenId),
            "not-owner-token"
        );
        require(
            erc721Contract.getApproved(tokenId) == address(this),
            "not-approval"
        );
        require(_currencyWhitelist[currency], "currency-invalid");
        require(
            _informationOf[tokenId].price == 0 &&
                price > 0 &&
                price <= _maxValueOfCurrency[currency],
            "price-invalid"
        );
        _informationOf[tokenId] = Information(
            payable(msg.sender),
            currency,
            price
        );
        erc721Contract.safeTransferFrom(msg.sender, address(this), tokenId);
        emit NewProduct(tokenId, currency, price);
    }

    // The owner of an NFT takes his NFT back
    function getNFTBack(uint256 tokenId)
        public
        whenNotPaused
        onlyOwnerToken(tokenId)
    {
        require(_informationOf[tokenId].price > 0);
        delete _informationOf[tokenId];
        erc721Contract.safeTransferFrom(address(this), msg.sender, tokenId);
        emit GetProductBack(tokenId);
    }

    // The owner wants to update the price of his NFT
    function updatePrice(uint256 tokenId, uint256 newPrice)
        public
        whenNotPaused
        onlyOwnerToken(tokenId)
    {
        require(
            _informationOf[tokenId].price > 0 &&
                newPrice > 0 &&
                newPrice <=
                _maxValueOfCurrency[_informationOf[tokenId].currency],
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
            address(this) == erc721Contract.ownerOf(tokenId),
            "token-not-sell"
        );
        require(_informationOf[tokenId].price > 0);
        address payable seller = _informationOf[tokenId].seller;
        require(msg.sender != seller);
        if (_informationOf[tokenId].currency == address(0)) {
            // Native BNB payment
            require(msg.value >= _informationOf[tokenId].price);
            erc721Contract.safeTransferFrom(address(this), msg.sender, tokenId);
            uint256 realPrice = msg.value;
            uint256 feePrice = realPrice.mul(feePercent).div(100);
            uint256 sellerReceive = realPrice.sub(feePrice);

            seller.transfer(sellerReceive);
            receiveFeeWallet.transfer(feePrice);
        } else {
            // BEP20 payment
            ERC20Upgradeable currencyContract = ERC20Upgradeable(
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

            uint256 realPrice = _informationOf[tokenId].price;
            uint256 feePrice = realPrice.mul(feePercent).div(100);
            uint256 sellerReceive = realPrice.sub(feePrice);

            currencyContract.transferFrom(msg.sender, seller, sellerReceive);

            currencyContract.transferFrom(
                msg.sender,
                receiveFeeWallet,
                feePrice
            );

            erc721Contract.safeTransferFrom(address(this), msg.sender, tokenId);
        }

        emit ProductSold(tokenId, msg.sender, _informationOf[tokenId].price);
        delete _informationOf[tokenId];
    }
}
