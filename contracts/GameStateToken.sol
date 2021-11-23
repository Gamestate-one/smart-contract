/* SPDX-License-Identifier: MIT */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GamestateToken is ERC20Capped, ERC20Burnable, Ownable {
    mapping(address => bool) private operators;
    address[] public listOperators;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        address ownerAddress
    ) Ownable() ERC20(_name, _symbol) ERC20Capped(_totalSupply) {
        Ownable.transferOwnership(ownerAddress);
        operators[ownerAddress] = true;
        listOperators.push(ownerAddress);
    }

    event Operator(address operator, bool isOperator);

    modifier onlyOperator() {
        require(operators[msg.sender], "only-operator");
        _;
    }

    function mint(address account, uint256 amount) public onlyOperator {
        _mint(account, amount);
    }

    function _mint(address account, uint256 amount)
        internal
        virtual
        override(ERC20, ERC20Capped)
    {
        ERC20Capped._mint(account, amount);
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
