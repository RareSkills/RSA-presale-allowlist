// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TestToken is ERC20, Ownable {

    address immutable pkAddress;

    constructor(address _pkAddress) ERC20("TestToken", "TST") {
        pkAddress = _pkAddress;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
