// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

contract ExampleMulMod {
    function mulModHardCoded() external view returns (uint256, uint256, uint256, uint256) {
        assembly {
            // Free memory pointer. Technically, we can gas golf this away since
            // the function is external, but let's not worry about that now.
            let pointer := mload(0x40)

            
            mstore(pointer, 0x80) // 0x80 bytes = 128 bytes = 1024 bits
            mstore(add(pointer, 0x20), 0x20)
            mstore(add(pointer, 0x40), 0x80)

            // base = 5
            mstore(add(pointer, 0x60), 0x0000000000000000000000000000000000000000000000000000000000000000)
            mstore(add(pointer, 0x80), 0x0000000000000000000000000000000000000000000000000000000000000000)
            mstore(add(pointer, 0xa0), 0x0000000000000000000000000000000000000000000000000000000000000000)
            mstore(add(pointer, 0xc0), 0x0000000000000000000000000000000000000000000000000000000000000005)

            // modulus = 3
            mstore(add(pointer, 0xe0), 0x0000000000000000000000000000000000000000000000000000000000000003)

            // exponent = 100
            mstore(add(pointer, 0x100), 0x0000000000000000000000000000000000000000000000000000000000000000)
            mstore(add(pointer, 0x120), 0x0000000000000000000000000000000000000000000000000000000000000000)
            mstore(add(pointer, 0x140), 0x0000000000000000000000000000000000000000000000000000000000000000)
            mstore(add(pointer, 0x160), 0x0000000000000000000000000000000000000000000000000000000000000064)
            
            // the last write to 0x160 extends to 0x180
            if iszero(staticcall(gas(), 0x05, pointer, 0x180, 0, 0)) {
                revert(0, 0)
            }

            // this overwrites the memory pointer, but we don't worry about that for now
            returndatacopy(0, 0, returndatasize())
            return (0, returndatasize())
        }
    }

    // needs an onlyOwner!
    /*
    CALLER
    PUSH20 0x0000000000000000000000000000000000000002
    EQ
    PUSH1 0x1f
    JUMPI
    PUSH1 0x00
    PUSH1 0x00
    RETURN
    JUMPDEST
    SELFDESTRUCT
    INVALID

    3373000000000000000000000000000000000000000214602c5760006000f35bfffe
    */

    function deployPublicKey(bytes calldata publicKey) external returns (address foo) {
        require(publicKey.length == 128, "incorrect publicKey length");

        bytes memory initCode = hex"60a2600c60003960a26000f3";
        
        bytes memory contractCode = abi.encodePacked(initCode, hex"3373", address(this), hex"14602c5760006000f35bfffe", publicKey);
        
        assembly {
            foo := create(0, add(contractCode, 0x20), mload(contractCode))
        }
    
    }

    // 60a2600c60003960a26000f333739daf7c849c20be671315e77cb689811bd5edefe614601f5760006000f35bfffe0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000064
    function viewCode(address a) external view returns (bytes memory code) {
        code = a.code;
    }

    // doesn't work, there is a bug in the deployed contract
    function destroyContract(address a) external {
        //a.call("");

    }

    function getPublicKey(address a) view external {
        // this is wasteful, should use extcodecopy() and target the last 128 bytes
        a.code;
    }
}