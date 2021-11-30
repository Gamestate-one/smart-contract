// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract GamestateToken is ERC20Burnable, Ownable, Pausable {
    mapping(address => bool) private operators;
    address[] public listOperators;
    bool public isFinishSetupContract;

    constructor(
        string memory _name,
        string memory _symbol,
        address ownerAddress
    ) Ownable() ERC20(_name, _symbol) {
        Ownable.transferOwnership(ownerAddress);
    }

    event Operator(address operator, bool isOperator);

    modifier onlyOperator() {
        require(operators[msg.sender], "only-operator");
        _;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function mint(address account, uint256 amount) public onlyOperator {
        _mint(account, amount);
    }

    function _mint(address account, uint256 amount)
        internal
        virtual
        override(ERC20)
    {
        ERC20._mint(account, amount);
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        whenNotPaused
        returns (bool)
    {
        require(isFinishSetupContract, "contract-not-setup");
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function setOperator(address _operator, bool isOperator) public onlyOwner {
        operators[_operator] = isOperator;

        (bool isOperatorBefore, uint256 indexInArr) = checkExistsInArray(
            listOperators,
            _operator
        );

        if (isOperator && !isOperatorBefore) {
            listOperators.push(_operator);
        }
        if (!isOperator && isOperatorBefore) {
            removeOutOfArray(listOperators, indexInArr);
        }
        emit Operator(_operator, isOperator);
    }

    function finishSetupContract() public onlyOwner {
        isFinishSetupContract = true;
    }

    function getListOperators() public view returns (address[] memory) {
        return listOperators;
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
