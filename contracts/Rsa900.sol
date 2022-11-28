// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

contract Rsa900 {
    event Metamorphosed(address metamorphicContract);

    bytes32 public constant EXPONENT =
        0x0000000000000000000000000000000000000000000000000000000000000003;

    address public immutable owner;

    address public immutable metamorphicContractAddress;

    bytes32 private immutable salt;

    bytes currentImplementationCode;

    /**
     * @dev See README.md for bytecode breakdown
     */
    bytes private constant _metamorphicContractInitializationCode = (
        hex"630000000e60005261017760006004601c335afa6101376040f3"
    );

    /**
     * @dev METAMORPHIC_INIT_HASH is a calculated value based on '_metamorphicContractInitializationCode'
     *      If the code is updated, be sure to recalculate the hash.
     *
     *      keccak256(abi.encodePacked(_metamorphicContractInitializationCode)
     */
    bytes32 private constant METAMORPHIC_INIT_HASH =
        0xc24922855851a254a6fc4fc08e7ae8481ab58d05b2e4f607575d845e559d69ba;

    //------------------------------------------------------------\\
    constructor(bytes32 _salt) {
        owner = msg.sender;
        salt = _salt;

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
        require(sig.length == 225);

        // Load immutable variable onto the stack
        address _metamorphicContractAddress = metamorphicContractAddress;

        assembly {
            let pointer := mload(0x40)

            // Store in memory, length of BASE(signature), EXPONENT, MODULUS
            mstore(pointer, sig.length)
            mstore(add(pointer, 0x20), 0x20)
            mstore(add(pointer, 0x40), sig.length)

            // update ptr
            mstore(0x40, 0xe0)
            pointer := 0xe0

            // BASE: The signature
            calldatacopy(0xe0, sig.offset, sig.length)

            // EXPONENT hardcoded to 3
            mstore(add(pointer, sig.length), EXPONENT)

            // Calculate where in memory to copy modulus to
            // 0x37 -> offset of where the signature begins in the metamorphic bytecode
            let modPos := add(pointer, add(sig.length, 0x20))

            extcodecopy(_metamorphicContractAddress, modPos, 0x37, sig.length)

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

            if iszero(staticcall(gas(), 0x05, 0x80, 0x242, 0x80, sig.length)) {
                revert(0, 0)
            }

            let decodedSig := mload(0x141)

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

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    /**
     * @notice 'deployPublicKey' is used in initializing the contract that hold the RSA modulus (n)
     *
     * @dev See Repo README for guide to generating public key
     *
     * https://github.com/RareSkills/RSA-presale-allowlist
     */
    function deployPublicKey(bytes calldata publicKey) external onlyOwner {
        require(publicKey.length == 225, "incorrect publicKey length");

        bytes memory contractCode = abi.encodePacked(
            hex"3373",
            address(this),
            hex"14601f5760006000f35b73",
            address(this),
            hex"fffe",
            publicKey
        );

        //Code to be returned from metamorphic init callback. See README for full explanation
        currentImplementationCode = contractCode;

        // Load immutable variables onto the stack
        bytes
            memory metaMorphicInitCode = _metamorphicContractInitializationCode;
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

        // Insure metamorphic deployment to address defines in constructor
        require(
            deployedMetamorphicContract == metamorphicContractAddress,
            "Failed to deploy the new metamorphic contract."
        );

        emit Metamorphosed(deployedMetamorphicContract);
    }

    /**
     * @notice 'destroyContract' must be called before redeployment of public key contract
     *
     * @dev See Repo README for guide to generating public key
     *
     * https://github.com/RareSkills/RSA-presale-allowlist
     */
    function destroyContract() external onlyOwner {
        (bool success, ) = metamorphicContractAddress.call("");
        require(success);
    }

    /**
     * @notice 'callback19F236F3' is a critical step in the initialization of a metamorphic contract
     *
     * @dev The function selector for this is '0x0000000e'
     */
    function callback19F236F3() external view returns (bytes memory) {
        return currentImplementationCode;
    }
}
