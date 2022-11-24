// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

contract RsaVerifDemo {
    // fires when a metamorphic contract is deployed by cloning another contract.
    event Metamorphosed(address metamorphicContract, address newImplementation);

    // Controller of selfdestruct/deploy of public key contract
    address public immutable owner;
    
    // for RSA calculations
    bytes32 public immutable exponent;

    // metamorphic variables
    address public immutable metamorphicContractAddress;
    bytes32 private immutable salt;
    bytes private constant _metamorphicContractInitializationCode = (
      hex"5860208158601c335a63aaf10f428752fa158151803b80938091923cf3"
    );
    
    // address of current implementation contract
    address private implementation;


    constructor(bytes32 _salt, bytes32 _exponent) {
        owner = msg.sender;
        salt = _salt;

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

        exponent = _exponent;
    }

    function verifySignature(bytes calldata sig) external view returns (bool) {
        // <length_of_BASE> <length_of_EXPONENT> <length_of_MODULUS> <BASE> <EXPONENT> <MODULUS>
        // size of modulus will be same size as signature
        // exponent length will be less than 256 bits

        // load exponent from bytecode into memory
        bytes32 _exponent = exponent;
        // load metamorphic contract address from bytecode into memory
        address _metamorphicContractAddress = metamorphicContractAddress;

        assembly {
            
            let pointer := mload(0x40)
            
            // length_of_BASE
            mstore(pointer, sig.length)
            // length_of_EXPONENT (should always be 256 bits and less) aka max 32 bytes
            mstore(add(pointer, 0x20), 0x20)
            // length_of_MODULUS ( will always be same length as signature)
            mstore(add(pointer, 0x40), sig.length)

            // update ptr
            mstore(0x40, 0xe0)
            pointer := 0xe0

            // BASE: The signature
            calldatacopy(pointer, sig.offset, sig.length)

            // EXPONENT hardcoded to 3
            mstore(add(pointer, sig.length), _exponent)


            // MODULUS (same as signature length)
            // copy from the metamorphic contract code
            // 0x37 -> offset of where the signature in the bytecode begins
            let lookAhead := add(pointer, add(sig.length, 0x20))
            extcodecopy(_metamorphicContractAddress, lookAhead, 0x37, sig.length)
            pointer := add(lookAhead, sig.length)

            // call 0x05 precompile (modular exponentation)
            // <length_of_BASE> <length_of_EXPONENT> <length_of_MODULUS> <BASE> <EXPONENT> <MODULUS>
            // 0x80 -> (pointer update) is the range of calldata arguments
            if iszero(staticcall(gas(), 0x05, 0x80, pointer, 0, 0)) {
                revert(0, 0)
            }

            // overwrite previous memory data and store return data
            // will return the decodedSignature aka corresponding message/address
            returndatacopy(0x80, 0x00, returndatasize())

            // if msg.sender == decoded signature
            // load the exact slot of where the decoded signature is copied to
            if eq(caller(), mload(add(0x60, sig.length))) {
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

        bytes memory initCode = hex"610137600e6000396101376000f3";
        
        bytes memory contractCode = abi.encodePacked(initCode, hex"3373", address(this), 
            hex"14601f5760006000f35b73", address(this), hex"fffe", publicKey);

        // move the initialization code from storage to memory.
        bytes memory metaMorphicInitCode = _metamorphicContractInitializationCode;

        // get salt immutable from bytecode into memory
        bytes32 _salt = salt;

        // declare a variable for the address of the implementation contract.
        address implementationContract;
        
        // where metamorphic contract was deployed and projected correct address
        address deployedMetamorphicContract;
        
        assembly {
            implementationContract := create(0, add(contractCode, 0x20), mload(contractCode))
        }

        require(
            implementationContract != address(0),
            "Could not deploy implementation."
        );

        // store the implementation to be retrieved by the metamorphic contract.
        implementation = implementationContract;

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

    function getImplementation() external view returns (address) {
        return implementation;
    }

}