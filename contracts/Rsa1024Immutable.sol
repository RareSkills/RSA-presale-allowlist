// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

contract Rsa1024Immutable {
    bytes32 constant EXPONENT =
        0x0000000000000000000000000000000000000000000000000000000000000003;

    /** @notice Each modChunk is 128 sequencial bits of the 1024 bit modulus (n)
     *           used in the RSA signing and decoding process.
     */
    bytes32 immutable modChunk1;
    bytes32 immutable modChunk2;
    bytes32 immutable modChunk3;
    bytes32 immutable modChunk4;
    bytes32 immutable modChunk5;
    bytes32 immutable modChunk6;
    bytes32 immutable modChunk7;
    bytes32 immutable modChunk8;

    //------------------------------------------------------------\\
    constructor(bytes32[] memory modChunkArr) {
        modChunk1 = modChunkArr[0];
        modChunk2 = modChunkArr[1];
        modChunk3 = modChunkArr[2];
        modChunk4 = modChunkArr[3];
        modChunk5 = modChunkArr[4];
        modChunk6 = modChunkArr[5];
        modChunk7 = modChunkArr[6];
        modChunk8 = modChunkArr[7];
    }

    /**
     * @notice 'verifySignature' is the user facing function used to validate signed messages
     *
     * @param 'sig' length must always be equal to the length of the public key(modulus)
     *
     * @dev Exponent is hardcoded at top of contract. It should always be 32 bytes
     *
     * @dev See below layout & link for memory when calling precompiled modular exponentiation contract (0x05)
     *      <length_of_BASE(signature)> <length_of_EXPONENT> <length_of_MODULUS> <BASE(signature)> <EXPONENT> <MODULUS>
     *
     *      https://github.com/ethereum/EIPs/blob/master/EIPS/eip-198.md
     */
    function verifySignature(bytes calldata sig) external view returns (bool) {
        require(sig.length == 256);

        // load modulus from bytecode onto stack
        bytes32 _modulus1 = modChunk1;
        bytes32 _modulus2 = modChunk2;
        bytes32 _modulus3 = modChunk3;
        bytes32 _modulus4 = modChunk4;
        bytes32 _modulus5 = modChunk5;
        bytes32 _modulus6 = modChunk6;
        bytes32 _modulus7 = modChunk7;
        bytes32 _modulus8 = modChunk8;

        assembly {
            let pointer := mload(0x40)
            // Store in memory, length of BASE(signature), EXPONENT, MODULUS
            mstore(pointer, sig.length)
            mstore(add(pointer, 0x20), 0x20)
            mstore(add(pointer, 0x40), sig.length)

            // update ptr
            pointer := add(pointer, 0x60)
            mstore(0x40, pointer)

            // BASE: The signature
            calldatacopy(pointer, sig.offset, sig.length)

            // EXPONENT hardcoded to 3
            mstore(add(pointer, sig.length), EXPONENT)

            // MODULUS (same as signature length)
            // sig.length + exponent length(0x20)
            pointer := add(pointer, 0x120)

            mstore(pointer, _modulus1)
            mstore(add(pointer, 0x20), _modulus2)
            mstore(add(pointer, 0x40), _modulus3)
            mstore(add(pointer, 0x60), _modulus4)
            mstore(add(pointer, 0x80), _modulus5)
            mstore(add(pointer, 0xa0), _modulus6)
            mstore(add(pointer, 0xc0), _modulus7)
            mstore(add(pointer, 0xe0), _modulus8)
            pointer := add(pointer, sig.length)

            /**
             * @dev Call 0x05 precompile (modular exponentation)
             *
             * Args:
             *   gas,
             *   precomipled contract address,
             *   memory pointer of begin of calldata,
             *   size of call data,
             *   pointer for where to copy return,
             *   size of return data
             */
            if iszero(
                staticcall(gas(), 0x05, 0x80, pointer, 0x80, sig.length)
            ) {
                revert(0, 0)
            }

            let decodedSig := mload(add(0x60, sig.length))

            if iszero(
                iszero(
                    and(
                        decodedSig,
                        not(0xffffffffffffffffffffffffffffffffffffffff)
                    )
                )
            ) {
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
