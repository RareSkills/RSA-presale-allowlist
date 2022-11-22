// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./RsaLib.sol";

contract TestToken is ERC20 {

    address immutable pkAddress;

    constructor(address _pkAddress) ERC20("TestToken", "TST") {
        pkAddress = _pkAddress;
    }

    function mint(address to, uint256 amount) public {
        require(RsaLib.verifySignature(), "Signature could not be verified");
        _mint(to, amount);
    }
}
