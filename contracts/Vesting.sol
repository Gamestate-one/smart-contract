// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./GamestateToken.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Vesting is
    UUPSUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    struct VestingInformation {
        uint256 startTime;
        uint256 endTime;
        uint256 maxSupplyClaim;
        uint256 timeIncreaseSupplyCanClaim;
        uint256 supplyIncrease;
        uint256 totalClaimed;
    }

    GamestateToken public gamestateToken;
    mapping(address => VestingInformation) private vests;

    event NewVestingInformation(
        address wallet,
        uint256 startTime,
        uint256 endTime,
        uint256 maxSupplyClaim,
        uint256 timeIncreaseSupplyCanClaim,
        uint256 supplyIncrease
    );
    event Claim(address wallet, uint256 amount);

    function initialize(address _gamestateToken) public initializer {
        __Pausable_init();
        __UUPSUpgradeable_init();
        __Ownable_init();
        __ReentrancyGuard_init();

        gamestateToken = GamestateToken(_gamestateToken);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function newVestingInformation(
        address _address,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _timeIncreaseSupplyCanClaim,
        uint256 _maxSupplyClaim
    ) public onlyOwner {
        require(
            vests[_address].maxSupplyClaim == vests[_address].totalClaimed,
            "exists"
        );
        require(_startTime < _endTime && _startTime > 0, "time-invalid");
        require(_maxSupplyClaim > 0, "max-supply-claim-invalid");
        require(_timeIncreaseSupplyCanClaim > 0, "time-increase-invalid");

        VestingInformation storage vest = vests[_address];
        vest.startTime = _startTime;
        vest.endTime = _endTime;
        vest.maxSupplyClaim = _maxSupplyClaim;
        vest.timeIncreaseSupplyCanClaim = _timeIncreaseSupplyCanClaim;
        uint256 durationTime = _endTime.sub(_startTime);
        vest.supplyIncrease = _maxSupplyClaim.div(
            durationTime.div(_timeIncreaseSupplyCanClaim)
        );
        vest.totalClaimed = 0;

        emit NewVestingInformation(
            _address,
            vest.startTime,
            vest.endTime,
            vest.maxSupplyClaim,
            vest.timeIncreaseSupplyCanClaim,
            vest.supplyIncrease
        );
    }

    function claim(address _address, int256 _amount) public {
        VestingInformation storage vest = vests[_address];
        uint256 supplyCanClaim = getSupplyCanClaim(_address);
        int256 i = -1;
        if (bytes32(uint256(_amount)) == bytes32(abi.encodePacked(i))) {
            gamestateToken.mint(_address, supplyCanClaim);
            vest.totalClaimed = vest.totalClaimed.add(supplyCanClaim);
            _amount = int256(supplyCanClaim);
        } else {
            require(uint256(_amount) <= supplyCanClaim, "amount-invalid");
            gamestateToken.mint(_address, uint256(_amount));
            vest.totalClaimed = vest.totalClaimed.add(uint256(_amount));
        }
        emit Claim(_address, uint256(_amount));
    }

    function getVestingInformation(address _address)
        public
        view
        returns (
            uint256 startTime,
            uint256 endTime,
            uint256 timeIncreaseSupplyCanClaim,
            uint256 maxSupplyClaim,
            uint256 supplyIncrease,
            uint256 totalClaimed,
            uint256 supplyCanClaim
        )
    {
        VestingInformation memory vest = vests[_address];
        startTime = vest.startTime;
        endTime = vest.endTime;
        timeIncreaseSupplyCanClaim = vest.timeIncreaseSupplyCanClaim;
        maxSupplyClaim = vest.maxSupplyClaim;
        supplyIncrease = vest.supplyIncrease;
        totalClaimed = vest.totalClaimed;
        supplyCanClaim = getSupplyCanClaim(_address);
    }

    function getSupplyCanClaim(address _address)
        internal
        view
        returns (uint256 supplyCanClaim)
    {
        if (block.timestamp < vests[_address].startTime) {
            supplyCanClaim = 0;
        } else if (block.timestamp < vests[_address].endTime) {
            if (
                vests[_address].totalClaimed == vests[_address].maxSupplyClaim
            ) {
                return 0;
            }
            supplyCanClaim = block
                .timestamp
                .sub(vests[_address].startTime)
                .div(vests[_address].timeIncreaseSupplyCanClaim)
                .add(1)
                .mul(vests[_address].supplyIncrease)
                .sub(vests[_address].totalClaimed);
            if (
                block.timestamp.add(
                    vests[_address].timeIncreaseSupplyCanClaim
                ) > vests[_address].endTime
            ) {
                supplyCanClaim = vests[_address].maxSupplyClaim.sub(
                    vests[_address].totalClaimed
                );
            }
        } else {
            supplyCanClaim = vests[_address].maxSupplyClaim.sub(
                vests[_address].totalClaimed
            );
        }
    }
}
