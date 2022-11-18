// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import './KeyStore.sol';

contract Contract {
    function readFromAddress(address _address) public view returns(bytes32) {

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
            return(add(outputCode, 0x20), 0x20)
        }
    }

    /**
     * Note:
     *
     * At this time, calling readFromAddress returns null (0x00...) how ever, calling it 
     * from inside the contract (modifying the 'deployAsBytecode' func) returns intended
     * data.
     */

    //function deployAsBytecode(bytes calldata _publicKey) external returns (bytes32) {
    function deployAsBytecode(bytes calldata _publicKey) external returns (address) {
        bytes memory creationByteCode = type(KeyStore).creationCode;

        // Append passed in value
        bytes memory byteCode =  abi.encodePacked(creationByteCode, _publicKey);

        // Deploy bytecode to new address (will match above, calculated address)
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

        //return readFromAddress(_address);
    }
}
