// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

contract RsaVerifDemo {
    // fires when a metamorphic contract is deployed by cloning another contract.
    event Metamorphosed(address metamorphicContract, address newImplementation);

    // Controller of selfdestruct/deploy of public key contract
    address public immutable owner;
    
    // for RSA calculations
    bytes32 public immutable exponent;
    bytes32 public immutable modulus1;
    bytes32 public immutable modulus2;
    bytes32 immutable modulus3;
    bytes32 immutable modulus4;
    bytes32 immutable modulus5;
    bytes32 immutable modulus6;
    bytes32 immutable modulus7;
    bytes32 immutable modulus8;

    // metamorphic variables
    address public immutable metamorphicContractAddress;
    bytes32 private immutable salt;
    /*
    bytes private constant _metamorphicContractInitializationCode = (
      hex"5860208158601c335a63aaf10f428752fa158151803b80938091923cf3"
    ); */

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
    bytes private constant _metamorphicContractInitializationCode = (
      hex"630000000e60005261017760006004601c335afa6101376040f3"
    );
    
    bytes currentImplementationCode; 
    
    // address of current implementation contract
    // address private implementation;


    constructor(
        bytes32 _salt, 
        bytes32 _exponent, 
        bytes32  _modulus1,
        bytes32  _modulus2,
        bytes32  _modulus3,
        bytes32  _modulus4,
        bytes32  _modulus5,
        bytes32  _modulus6,
        bytes32  _modulus7,
        bytes32  _modulus8  
        ) {
        owner = msg.sender;
        salt = _salt;
        exponent = _exponent;
        //modulus = _modulus;

        bytes32 _metamorphicContractInitializationCodeHash = keccak256(
            abi.encodePacked(
            _metamorphicContractInitializationCode
            )
        ); 

        // determine the address of the metamorphic contract.
        metamorphicContractAddress = 
        ( 
            address(
                uint160(                      // downcast to match the address type.
                    uint256
                    (                    // convert to uint to truncate upper digits.
                        keccak256
                        (                // compute the CREATE2 hash using 4 inputs.
                            abi.encodePacked(       // pack all inputs to the hash together.
                            hex"ff",              // start with 0xff to distinguish from RLP.
                            address(this),        // this contract will be the caller.
                            _salt,                 // pass in the supplied salt value.
                            _metamorphicContractInitializationCodeHash // the init code hash.
                            )
                        )
                    )
                )
            )
        );


        modulus1 = _modulus1;
        modulus2 = _modulus2;
        modulus3 = _modulus3;
        modulus4 = _modulus4;
        modulus5 = _modulus5;
        modulus6 = _modulus6;
        modulus7 = _modulus7;
        modulus8 = _modulus8;
   
    }

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

        // load exponent from bytecode into memory
        bytes32 _exponent = exponent;

        // load modulus
        bytes32  _modulus1 = modulus1;
        bytes32  _modulus2 = modulus2;
        bytes32  _modulus3 = modulus3;
        bytes32  _modulus4 = modulus4;
        bytes32  _modulus5 = modulus5;
        bytes32  _modulus6 = modulus6;
        bytes32  _modulus7 = modulus7;
        bytes32  _modulus8 = modulus8;

        // load metamorphic contract address from bytecode into memory
        //address _metamorphicContractAddress = metamorphicContractAddress;

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
            mstore(add(pointer, sig.length), _exponent)


            // MODULUS (same as signature length)
            // copy from the metamorphic contract code
            // 0x37 -> offset of where the signature in the bytecode begins
            pointer := add(pointer, 0x120) // sig.length + exponent length(0x20)
            //extcodecopy(_metamorphicContractAddress, lookAhead, 0x37, sig.length)
            mstore(pointer, _modulus1)
            mstore(add(pointer, 0x20), _modulus2)
            mstore(add(pointer, 0x40), _modulus3)
            mstore(add(pointer, 0x60), _modulus4)
            mstore(add(pointer, 0x80), _modulus5)
            mstore(add(pointer, 0xa0), _modulus6)
            mstore(add(pointer, 0xc0), _modulus7)
            mstore(add(pointer, 0xe0), _modulus8)
            pointer := add(pointer, sig.length)

            // call 0x05 precompile (modular exponentation)
            // <length_of_BASE> <length_of_EXPONENT> <length_of_MODULUS> <BASE> <EXPONENT> <MODULUS>
            // 0x80 -> (pointer update) is the range of calldata arguments
            if iszero(staticcall(gas(), 0x05, 0x80, pointer, 0x80, sig.length)) {
                revert(0, 0)
            }

            // overwrite previous memory data and store return data
            // will return the decodedSignature aka corresponding message/address
            //returndatacopy(0x80, 0xe0, 0x20)

            //let decodedSig := mload(0x80)
            let decodedSig := mload(add(0x60, sig.length))

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

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    function deployPublicKey(bytes calldata publicKey) external onlyOwner()  returns (address) {
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

        // declare a variable for the address of the implementation contract.
        address implementationContract;
        
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

        emit Metamorphosed(deployedMetamorphicContract, implementationContract);

    }

    function destroyContract() external onlyOwner() {
        (bool success, ) = metamorphicContractAddress.call("");
        require(success);
    }

    function callback19F236F3() external view returns (bytes memory) {
        return currentImplementationCode;
    }
}