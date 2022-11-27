// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

contract RsaCopyCodeDemo {

    function verifySignature(bytes calldata sig) external view returns (bool) {
        // <length_of_BASE> <length_of_EXPONENT> <length_of_MODULUS> <BASE> <EXPONENT> <MODULUS>
        // size of modulus will be same size as signature
        // exponent length will be less than 256 bits

        require(sig.length == 256);
        /*
        assembly {
            // costs 365
            if iszero(eq(sig.length, 0x100)) {
                revert(0,0)
            }
        }
        */

        assembly {
            
            let pointer := mload(0x40)
            
            // length_of_BASE
            mstore(pointer, sig.length)
            // length_of_EXPONENT (should always be 256 bits and less) aka max 32 bytes
            mstore(add(pointer, 0x20), 0x20)
            // length_of_MODULUS ( will always be same length as signature)
            mstore(add(pointer, 0x40), sig.length)

            // update ptr
            pointer := add(pointer, 0x60)
            mstore(0x40, pointer)
            
            // BASE: The signature
            calldatacopy(pointer, sig.offset, sig.length)

            // EXPONENT hardcoded to 3
            mstore(add(pointer, sig.length), 0x03)

            // MODULUS (same as signature length)
            pointer := add(pointer, 0x120) // sig.length + exponent length(0x20)
            codecopy(pointer, 0x1a5, sig.length)

            pointer := add(pointer, sig.length)

            // call 0x05 precompile (modular exponentation)
            // <length_of_BASE> <length_of_EXPONENT> <length_of_MODULUS> <BASE> <EXPONENT> <MODULUS>
            // 0x80 -> (pointer update) is the range of calldata arguments
            if iszero(staticcall(gas(), 0x05, 0x80, pointer, 0, 0)) {
                revert(0, 0)
            }

            // overwrite previous memory data and store return data
            // will return the decodedSignature aka corresponding message/address
            returndatacopy(0x80, 0xe0, 0x20)

            let decodedSig := mload(0x80)
            //let decodedSig := mload(add(0x60, sig.length))

            if iszero(iszero(and(decodedSig, not(0xffffffffffffffffffffffffffffffffffffffff))))
            {
                // validate decodedSignature is indeed an address
                // make sure calldata isn't being gamed
                revert(0, 0)
            }

            // if msg.sender == decoded signature
            // load the exact slot of where the decoded signature is copied to
            if eq(caller(), decodedSig) {
                // return true
                mstore(0x00, 0x01)
                return(0x00, 0x20)
            }
        }        
    }    
}