// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

contract RsaVerifDemo {
    function verifySignature(bytes calldata sig, bytes calldata modulus /* ,bytes calldata exponent*/) external view returns (bool) {
        // <length_of_BASE> <length_of_EXPONENT> <length_of_MODULUS> <BASE> <EXPONENT> <MODULUS>
        // size of modulus will be same size as signature
        // exponent length will be less than 256 bits
        assembly {
            
            let pointer := mload(0x40)
            
            // length_of_BASE
            mstore(pointer, sig.length)
            // length_of_EXPONENT (should always be 256 bits and less) aka max 32 bytes
            mstore(add(pointer, 0x20), 0x20)
            // length_of_MODULUS
            mstore(add(pointer, 0x40), modulus.length)

            // update ptr
            mstore(0x40, 0xe0)
            pointer := 0xe0

            // BASE: The signature
            calldatacopy(pointer, sig.offset, sig.length)

            // EXPONENT hardcoded to 3
            mstore(add(pointer, sig.length), 0x03)
            // if the exponent is passed in as last arg
            //calldatacopy(add(pointer, sig.length), exponent.offset, 0x20)

            // MODULUS (should be read externally passed in manually for now)
            let lookAhead := add(pointer, add(sig.length, 0x20))
            calldatacopy(lookAhead, modulus.offset, modulus.length)

            pointer := add(lookAhead, modulus.length)

            if iszero(staticcall(gas(), 0x05, 0x80, pointer, 0, 0)) {
                revert(0, 0)
            }

            returndatacopy(0x80, 0x00, returndatasize())
            // if msg.sender == decoded signature
            if eq(caller(), mload(0x160)) {
                // return true
                mstore(0x00, 0x01)
                return(0x00, 0x20)
            }

            //returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256)
            //return (0x80, returndatasize())
        }         
    }
}