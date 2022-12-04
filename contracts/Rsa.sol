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
     * @dev See README.md for bytecode breakdown
     */
    bytes32 private immutable _metamorphicContractInitializationCode;

    //------------------------------------------------------------\\
    constructor(bytes32 _salt, uint256 _modLength) {
        owner = msg.sender;
        salt = _salt;
        modLength = _modLength;

        // contract runtime code length (without modulus) = 51 bytes (0x33)
        bytes memory metamorphicInit = ( 
            abi.encodePacked(
                hex"630000000e60005261",
                /** 
                 *   must be 0x40(pointer + bytes length) + contract code length  + modulus length
                 *   fixed 2 bytes as no mod length over 2 bytes in size is expected
                 *   rsa-2048 = 0x0100 2 bytes length
                */ 
                uint16(0x73 + _modLength),  
                hex"60006004601c335afa61",
                /** 
                 *  contract code length + modulus length
                 *  fixed 2 bytes
                */
                uint16(0x33 + _modLength), 
                hex"6040f3"
            )
        );

        // temp stack value used as we can't reference immutable in assembly block
        bytes32 stackMetaInit;

        assembly {
            // use assembly to prune bytes to just get the bytes data
            stackMetaInit := mload(add(metamorphicInit, 0x20))
        }

        // set immutable value
        _metamorphicContractInitializationCode = stackMetaInit;

        // hash of metamorphic bytecode
        bytes32 METAMORPHIC_INIT_HASH = keccak256(abi.encodePacked(stackMetaInit));

        // Calculate metamorphic contract address.
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
     *          signed messages.
     *
     * @param  'sig' length must always be equal to the length of the public 
     *          key(modulus).
     *
     * @dev     Exponent is hardcoded at top of contract. This may be altered
     *          for specific use cases but it must always be 32 bytes.
     *
     * @dev See below layout & link for memory when calling precompiled modular exponentiation contract (0x05)
     *      <length_of_BASE(signature)> <length_of_EXPONENT> <length_of_MODULUS> <BASE(signature)> <EXPONENT> <MODULUS>
     *
     *      https://github.com/ethereum/EIPs/blob/master/EIPS/eip-198.md
     */
    function verifySignature(bytes calldata sig) external view returns (bool) {
        require(sig.length == modLength);

        // Load immutable variable onto the stack
        address _metamorphicContractAddress = metamorphicContractAddress;
        
        // no need to update pointer as all memory written here can be overwriten with no consequence 
        assembly {
            // Store in memory, length of BASE(signature), EXPONENT, MODULUS
            mstore(0x80, sig.length)
            mstore(add(0x80, 0x20), 0x20)
            mstore(add(0x80, 0x40), sig.length)

            // BASE: The signature
            calldatacopy(0xe0, sig.offset, sig.length)

            // EXPONENT hardcoded to 3
            mstore(add(0xe0, sig.length), EXPONENT)

            // Calculate where in memory to copy modulus to
            let modPos := add(0xe0, add(sig.length, 0x20))

            // 0x33 -> offset of where the signature begins in the metamorphic bytecode
            extcodecopy(_metamorphicContractAddress, modPos, 0x33, sig.length)

            /** 
             *  lengths of Signature + Base + Exponent = 0x60...
             *  added with space of storage occupied by exponent, modulus, and signature...
             *  Which is 0x20 + (sig.length * 2) as modulus length will always == signature length  
            */
            let callDataSize := add(0x80, mul(sig.length, 2))

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

            if iszero(staticcall(gas(), 0x05, 0x80, callDataSize, 0x80, sig.length)) {
                revert(0, 0)
            }

            /** 
             *  decoded signature is always stored in the last 32 bytes of return data
             *  sig.length + 0x80 is the end of the return data
             *  0x60 + sig.length will give you the last 32 bytes 
            */
            let decodedSig := mload(add(0x60, sig.length))

            // Check bit mask of return data. Ensure it is a valid address (first 12 bytes are zero)
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
     * @notice 'deployPublicKey' is used in initializing the contract that hold the RSA modulus (n)
     *
     * @dev See Repo README for guide to generating public key
     *
     * https://github.com/RareSkills/RSA-presale-allowlist
     */
    function deployPublicKey(bytes calldata publicKey) external onlyOwner {
        
        require(publicKey.length == modLength, "incorrect publicKey length");

        // contract runtime code length (without modulus) = 51 bytes (0x33)
        bytes memory contractCode = abi.encodePacked(
            hex"3373",
            address(this),
            hex"14601b57fe5b73",
            address(this),
            hex"fffe",
            publicKey
        ); 

        //Code to be returned from metamorphic init callback. See README for full explanation
        currentImplementationCode = contractCode;

        // Load immutable variables onto the stack
        bytes32 metaMorphicInitCode = _metamorphicContractInitializationCode;
        bytes32 _salt = salt;

        // address metamorphic contract will be deployed to
        address deployedMetamorphicContract;

        assembly {
            // store in memory scratch space the init code
            mstore(0x00, metaMorphicInitCode)
            
            /**
             * CREATE2 args:
             *  value: value in wei to send to the new account,
             *  offset: byte offset in the memory in bytes, the initialisation code of the new account,
             *  size: byte size to copy (size of the initialisation code),
             *  salt: 32-byte value used to create the new account at a deterministic address
            */
            deployedMetamorphicContract := create2(
                0,
                0x00,
                0x20, // as init code is stored as bytes32
                _salt
            )
        }

        // Ensure metamorphic deployment to address calculated in constructor.
        require(
            deployedMetamorphicContract == metamorphicContractAddress,
            "Failed to deploy the new metamorphic contract to correct address."
        );

        emit Metamorphosed(deployedMetamorphicContract);
    }

    /**
     * @notice 'destroyContract' must be called before redeployment of public 
     *          key contract.
     *
     * @dev     See Repo README.md process walk-through.
     *
     * https://github.com/RareSkills/RSA-presale-allowlist
     */
    function destroyContract() external onlyOwner {
        (bool success, ) = metamorphicContractAddress.call("");
        require(success);
    }

    /**
     * @notice 'callback19F236F3' is a critical step in the initialization of a 
     *          metamorphic contract.
     *
     * @dev     The function selector for this is '0x0000000e'
     */
    function callback19F236F3() external view returns (bytes memory) {
        return currentImplementationCode;
    }
}