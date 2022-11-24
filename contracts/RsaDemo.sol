// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

contract RsaDemo {
    /*
    PUSH4 0x0000000e -> push selector
    PUSH1 0x00 -> store from beginning of memory
    MSTORE -> store using previous 2 arguments MSTORE(0x00, selector)
    PUSH2 0x0177 -> byte size of return data to copy
    PUSH1 0x00 -> where in memory to copy the return data
    PUSH1 0x04 -> size of calldata argument
    PUSH1 0x1c -> where in memory to start copying the calldata arguments
    CALLER -> msg.sender (initiating contract)
    GAS -> forward all current gas
    STATICCALL  -> (GAS, msg.sender, memory offset, memory to copy size, memory offset to copy to, byte size of return data to copy)
    PUSH2 0x0137 -> size of return data
    PUSH1 0x40 -> where to start copying the return data from
    RETURN -> will be this contracts new bytecode'
    */


    event Metamorphosed(address metamorphicContract);

    // Controller of selfdestruct/deploy of public key contract
    address public immutable owner;
    
    // for RSA calculations
    bytes32 public immutable exponent;

    address public immutable metamorphicContractAddress;

    bytes32 private immutable salt;

    bytes currentImplementationCode; 

    bytes private constant _metamorphicContractInitializationCode = (
      hex"630000000e60005261017760006004601c335afa6101376040f3"
    );

    /**
     * @dev METAMORPHIC_INIT_HASH is a calculated value based on '_metamorphicContractInitializationCode'
     *      If the code is updated, be sure to recalculate the hash.
     *  
     *      keccak256(abi.encodePacked(_metamorphicContractInitializationCode)
     */
    bytes32 private constant METAMORPHIC_INIT_HASH = 0xc24922855851a254a6fc4fc08e7ae8481ab58d05b2e4f607575d845e559d69ba;
    
    
//------------------------------------------------------------\\
    constructor(bytes32 _salt, bytes32 _exponent) {
        owner = msg.sender;
        salt = _salt;
        exponent = _exponent;

        metamorphicContractAddress = 
        ( 
            address(
                uint160(
                    uint256
                    (
                        keccak256
                        ( 
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
    * @notice verifySignature is the user facing function used to validate signed messages
    *
    * @param sig length must always be equal to the length of the public key(modulus)
    *
    * @dev exponent is padded to 256 bits on generation. See python script.
    *
    * @dev See below layout & link for memory when calling precompiled modular exponentiation contract (0x05)
    *      <length_of_BASE(signature)> <length_of_EXPONENT> <length_of_MODULUS> <BASE(signature)> <EXPONENT> <MODULUS>
    *
    *      https://github.com/ethereum/EIPs/blob/master/EIPS/eip-198.md
    */
    function verifySignature(bytes calldata sig) external view returns (bool) {
        require(sig.length == 256);
        /*
        assembly {
            // costs 365
            if iszero(eq(sig.length, 0x100)) {
                revert(0,0)
            }
        }
        */

        // load exponent and metamorphic contract address onto the stack
        bytes32 _exponent = exponent;
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
            calldatacopy(pointer, sig.offset, sig.length)

            // EXPONENT hardcoded to 3
            mstore(add(pointer, sig.length), _exponent)

            // Calculate where in memory to copy modulus to
            // 0x37 -> offset of where the signature in the metamorphic bytecode begins
            let modPos := add(pointer, add(sig.length, 0x20))
           
//2636
            extcodecopy(_metamorphicContractAddress, modPos, 0x37, sig.length)

            // call 0x05 precompile (modular exponentation)
            // 0x80 -> (pointer update) is the range of calldata arguments
           
            if iszero(staticcall(gas(), 0x05, 0x80, 0x280, 0, 0)) {
                revert(0, 0)
            }

            // overwrite previous memory data and store return data
            // will return the decodedSignature aka corresponding message/address
            returndatacopy(0x80, 0xe0, 0x20)

            let decodedSig := mload(0x80)


//29g
            if iszero(iszero(and(decodedSig, not(0xffffffffffffffffffffffffffffffffffffffff))))
            {
                // validate decodedSignature is indeed an address
                // make sure calldata isn't being gamed
                revert(0, 0)
            }

            // if msg.sender == decoded signature
            // load the exact slot of where the decoded signature is copied to
            /*
            if eq(caller(), decodedSig) {
                // return true
                mstore(0x00, 0x01)
                return(0x00, 0x20)
            }
            */

        }         
        return true;
    }

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    function deployPublicKey(bytes calldata publicKey) external onlyOwner() {
        // n (modulus), as e is hardcoded
        require(publicKey.length == 256, "incorrect publicKey length");

        // don't need initCode as we are not deploying a first contract
        // returning the straight bytecode that should be the meta contract
        //bytes memory initCode = hex"610137600e6000396101376000f3";
        
        bytes memory contractCode = abi.encodePacked( /*initCode,*/ hex"3373", address(this), 
            hex"14601f5760006000f35b73", address(this), hex"fffe", publicKey);

        // put in storage the current implementation code
        // publicKey code with new signature 
        // this saves us from having to deploy a new contract to store this info
        currentImplementationCode = contractCode;

        // move the initialization code from storage to memory.
        bytes memory metaMorphicInitCode = _metamorphicContractInitializationCode;

        // get salt immutable from bytecode into memory
        bytes32 _salt = salt;


        
        // where metamorphic contract was deployed and projected correct address
        address deployedMetamorphicContract;
        
        /*
        assembly {
            implementationContract := create(0, add(contractCode, 0x20), mload(contractCode))
        } 

        require(
            implementationContract != address(0),
            "Could not deploy implementation."
        );
        */
        
        // store the implementation to be retrieved by the metamorphic contract.
        //implementation = implementationContract;

        assembly {
            deployedMetamorphicContract  := create2(0, add(metaMorphicInitCode, 0x20), mload(metaMorphicInitCode), _salt)
        }

        // ensure that the contracts were successfully deployed.
        require(
            deployedMetamorphicContract == metamorphicContractAddress,
            "Failed to deploy the new metamorphic contract."
        );

        emit Metamorphosed(deployedMetamorphicContract);

    }

    function destroyContract() external onlyOwner() {
        (bool success, ) = metamorphicContractAddress.call("");
        require(success);
    }

    function callback19F236F3() external view returns (bytes memory) {
        return currentImplementationCode;
    }
}