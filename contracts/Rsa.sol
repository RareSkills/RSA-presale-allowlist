// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

contract Rsa {
    event Metamorphosed(address metamorphicContract);

    address public immutable owner;

    address public immutable metamorphicContractAddress;

    bytes32 private immutable salt;

    uint256 private immutable modLength;

    bytes currentImplementationCode;

    bytes32 private constant EXPONENT =
        0x0000000000000000000000000000000000000000000000000000000000000003;

    /**
     * @dev See README.md for bytecode breakdown.
     */
    bytes private constant _metamorphicContractInitializationCode = (
        hex"630000000e60005261017760006004601c335afa6101376040f3"
    );

    /**
     * @dev METAMORPHIC_INIT_HASH is a calculated value based on 
     *      '_metamorphicContractInitializationCode'.
     *
     *      If the metamorphic code is updated, be sure to recalculate the hash.
     *
     *      keccak256(abi.encodePacked(_metamorphicContractInitializationCode)
     */
    bytes32 private constant METAMORPHIC_INIT_HASH =
        0xc24922855851a254a6fc4fc08e7ae8481ab58d05b2e4f607575d845e559d69ba;

//----------------------------------------------------------------------------\\
    constructor(bytes32 _salt, uint256 _modLength) {
        owner = msg.sender;
        salt = _salt;
        modLength = _modLength;

        metamorphicContractAddress = (
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                hex"ff",
                                address(this),
                                _salt,
                                METAMORPHIC_INIT_HASH
                            )
                        )
                    )
                )
            )
        );
    }

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    /**
     * @notice 'verifySignature' is the user facing function used to validate 
     *         signed messages.
     *
     * @param 'sig' is the signed message. It's length must always be equal to 
     *         the length of the public key(modulus).
     *
     * @dev    Exponent is hardcoded at top of contract. It should always be 32 
     *         bytes in length.
     *
     * @dev    See below layout & link for memory when calling precompiled 
     *         modular exponentiation contract (0x05).
     *
     * <length_of_BASE(signature)> <length_of_EXPONENT> <length_of_MODULUS> <BASE(signature)> <EXPONENT> <MODULUS>
     *
     *      https://github.com/ethereum/EIPs/blob/master/EIPS/eip-198.md
     */
    function verifySignature(bytes calldata sig) external view returns (bool) {
        require(sig.length == modLength);

        // Load immutable variable onto the stack
        address _metamorphicContractAddress = metamorphicContractAddress;

        assembly {
            /** 
             * @dev No need to update free memory pointer as all memory written here 
             *      can be overwriten with no consequence.
             *
             * @dev Store in memory, length of BASE(signature), EXPONENT, MODULUS.
             */
            mstore(0x80, sig.length)
            mstore(add(0x80, 0x20), 0x20)
            mstore(add(0x80, 0x40), sig.length)

            /**
             * @dev Calculate where in memory to copy modulus to (modPos). This must 
             *      be dynamically determined as various size of signature may be used.
             */
            let modPos := add(0xe0, add(sig.length, 0x20))

            // Store in memory, BASE(signature), EXPONENT, MODULUS(public key).
            calldatacopy(0xe0, sig.offset, sig.length)
            mstore(add(0xe0, sig.length), EXPONENT)

            /**
             * @dev 0x37 is a precalulated value that is the offset of where the 
             *      signature begins in the metamorphic bytecode.
             */
            extcodecopy(_metamorphicContractAddress, modPos, 0x37, sig.length)

            /**
             * @dev callDataSize must be dynamically calculated. It follows the 
             *      previously mentioned memory layout including the length and
             *      value of the sig, exponent and modulus.
             */
            let callDataSize := add(0x80, mul(sig.length, 2))

            /**
             * @dev Call 0x05 precompile (modular exponentation) w/ the following
             *      args and revert on failure.
             *
             *      Args:
             *      gas,
             *      precomipled contract address,
             *      memory pointer of begin of calldata,
             *      size of call data (callDataSize),
             *      pointer for where to copy return,
             *      size of return data
             */
            if iszero(staticcall(gas(), 0x05, 0x80, callDataSize, 0x80, sig.length)) {
                revert(0, 0)
            }

            /**
             * @dev Parse return value from modular exponentation calculation.
             *      This calculation will load the correct 32bytes of memory 
             *      onto the stack.
             */
            let decodedSig := mload(add(0x60, sig.length))

            /**
             * @dev Use bit mask of decodedSig to ensure it is a valid address.
             *      If the user has passed a valid sig, this will be a 20 byte
             *      address, left padded to 32 bytes, and revert if not valid.
             */
            if iszero(
                iszero(
                    and(
                        decodedSig,
                        not(0xffffffffffffffffffffffffffffffffffffffff)
                    )
                )
            ) {
                revert(0, 0)
            }

            // if msg.sender == decoded signature
            if eq(caller(), decodedSig) {
                // Return true
                mstore(0x00, 0x01)
                return(0x00, 0x20)
            }
            // Else Return false
            mstore(0x00, 0x00)
            return(0x00, 0x20)
        }
    }

    /**
     * @notice 'deployPublicKey' is used in initializing the contract that holds
     *         the RSA modulus (n)
     *
     * @dev See Repo README for guide to generating public key
     *
     * https://github.com/RareSkills/RSA-presale-allowlist
     */
    function deployPublicKey(bytes calldata publicKey) external onlyOwner {
        require(publicKey.length == modLength, "incorrect publicKey length");

        bytes memory contractCode = abi.encodePacked(
            hex"3373",
            address(this),
            hex"14601f5760006000f35b73",
            address(this),
            hex"fffe",
            publicKey
        );

        //Code to be returned from metamorphic init callback. See README for full explanation.
        currentImplementationCode = contractCode;

        // load immutable variable into memory.
        bytes memory metaMorphicInitCode = _metamorphicContractInitializationCode;

        // Load immutable variable onto the stack.
        bytes32 _salt = salt;

        address deployedMetamorphicContract;

        assembly {
            deployedMetamorphicContract := create2(
                0,
                add(metaMorphicInitCode, 0x20),
                mload(metaMorphicInitCode),
                _salt
            )
        }

        // Insure metamorphic deployment to address calculated in constructor.
        require(
            deployedMetamorphicContract == metamorphicContractAddress,
            "Failed to deploy the new metamorphic contract to correct address."
        );

        emit Metamorphosed(deployedMetamorphicContract);
    }

    /**
     * @notice 'destroyContract' must be called before redeployment of public key contract
     *
     * @dev    See Repo README for deeper explaination of this process.
     *
     * https://github.com/RareSkills/RSA-presale-allowlist
     */
    function destroyContract() external onlyOwner {
        (bool success, ) = metamorphicContractAddress.call("");
        require(success);
    }

    /**
     * @notice 'callback19F236F3' is a critical step in the initialization of a 
     *         metamorphic contract
     *
     * @dev    The function selector for this is '0x0000000e'
     */
    function callback19F236F3() external view returns (bytes memory) {
        return currentImplementationCode;
    }
}
