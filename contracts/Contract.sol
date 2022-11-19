// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import './KeyStore.sol';

contract Contract {
    function _readFromAddress(address _address, uint256 _memSlot) public view returns(bytes32) {
        assembly {
            // Fetch size of external code
            let size := extcodesize(_address)

            // allowcate @ free mem pointer
            let outputCode := mload(0x40)

            // update freee mem pointer
            //mstore(0x40, add(outputCode, and(add(add(size, 0x20), 0x1f), not(0x1f))))

            // Store size of external code
            mstore(outputCode, size)

            // Fetch/store external code
            extcodecopy(_address, add(outputCode, 0x20), 0, size)

            // Note: Only returns 32bytes. Increment 1st arg to read through memory.
            // return(offset, size) \\120
            return(add(outputCode, mul(0x20, _memSlot)), 0x20)
        }
    }

    /**
     * Note:
     *
     * How do we append data to the end of the creation code and have it show up in runtime
     * code?
     *
     * Why does calling 'deployAsBytecode' and then '_readFromAddress' work differently than
     * calling 'deployAndReadSlot'? The former returns null (0x00..) while the later performs
     * as expected.
     */

    function deployAsBytecode(string calldata _publicKey) external returns (address) {
        bytes memory creationByteCode = type(KeyStore).creationCode;
        
        // Append passed in value
        bytes memory byteCode =  abi.encodePacked(creationByteCode, _publicKey);

        // Deploy bytecode to new address
        address _address;
        assembly {
            _address := create2(
                callvalue(),
                add(byteCode, 0x20),
                mload(byteCode),
                111
            )
        }

        return _address;
    }

    function deployAndReadSlot(string calldata _publicKey, uint256 _memSlot) 
        external 
        returns (bytes32) {
            bytes memory creationByteCode = type(KeyStore).creationCode;
            bytes memory byteCode =  abi.encodePacked(creationByteCode, _publicKey);

            address _address;
            assembly {
                _address := create2(
                    callvalue(),
                    add(byteCode, 0x20),
                    mload(byteCode),
                    111
                )
            }
            return _readFromAddress(_address, _memSlot);
    }

}
