// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

contract RsaVerifDemo {
    // fires when a metamorphic contract is deployed by cloning another contract.
    event Metamorphosed(address metamorphicContract, address newImplementation);

    address owner;

    constructor() {
        owner = msg.sender;
    }

    // metamorphic variables
    bytes private _metamorphicContractInitializationCode = (
      hex"5860208158601c335a63aaf10f428752fa158151803b80938091923cf3"
    );
    // store hash of the initialization code for metamorphic contracts as well.
    bytes32 private _metamorphicContractInitializationCodeHash = keccak256(
      abi.encodePacked(
        _metamorphicContractInitializationCode
      )
    );
    
    // maintain a mapping of metamorphic contracts to metamorphic implementations.
    mapping(address => address) public _implementations;

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
            // load the slot of where the decoded signature is copied to
            if eq(caller(), mload(add(0x60, sig.length))) {
                // return true
                mstore(0x00, 0x01)
                return(0x00, 0x20)
            }

            //returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256)
            //return (0x80, returndatasize())
        }         
    }

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    function deployPublicKey(bytes calldata publicKey, bytes32 _salt) external onlyOwner()  returns (address metamorphicContractAddress) {
        // n (modulus), as e is hardcoded
        require(publicKey.length == 256, "incorrect publicKey length");

        bytes memory initCode = hex"610137600e6000396101376000f3";
        
        bytes memory contractCode = abi.encodePacked(initCode, hex"3373", address(this), 
            hex"14601f5760006000f35b73", address(this), hex"fffe", publicKey);

        // move the initialization code from storage to memory.
        bytes memory metaMorphicInitCode = _metamorphicContractInitializationCode;

        // declare a variable for the address of the implementation contract.
        address implementationContract;
        address deployedMetamorphicContract;
        metamorphicContractAddress = _getMetamorphicContractAddress(_salt);
        
        
        assembly {
            implementationContract := create(0, add(contractCode, 0x20), mload(contractCode))
        }

        require(
            implementationContract != address(0),
            "Could not deploy implementation."
        );

        // store the implementation to be retrieved by the metamorphic contract.
        _implementations[metamorphicContractAddress] = implementationContract;

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

    function destroyContract(address _a) external onlyOwner() {
        (bool success, ) = _a.call("");
        require(success);
    }

    function getImplementation() external view returns (address implementation) {
        return _implementations[msg.sender];
    }

    function _getMetamorphicContractAddress(
        bytes32 _salt
    ) internal view returns (address) {
        // determine the address of the metamorphic contract.
        return address(
        uint160(                      // downcast to match the address type.
            uint256(                    // convert to uint to truncate upper digits.
            keccak256(                // compute the CREATE2 hash using 4 inputs.
                abi.encodePacked(       // pack all inputs to the hash together.
                hex"ff",              // start with 0xff to distinguish from RLP.
                address(this),        // this contract will be the caller.
                _salt,                 // pass in the supplied salt value.
                _metamorphicContractInitializationCodeHash // the init code hash.
                )
            )
            )
        )
        );
    }
}