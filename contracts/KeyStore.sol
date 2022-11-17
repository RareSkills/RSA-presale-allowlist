// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract KeyStore {
    address public owner = 0x0000000000000000000000000000000000000001;
    constructor() {}
    
    function destroy() external {
        selfdestruct(payable(owner));
    }
}
