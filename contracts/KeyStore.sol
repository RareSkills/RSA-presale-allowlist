// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract KeyStore {
    function destroy(address _address) external {
        selfdestruct(payable(_address));
    }
}
