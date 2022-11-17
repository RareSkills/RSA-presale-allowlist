// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

contract Contract {
    function read(address _address) external view returns(bytes32) {

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
            // return(offset, size)
            return(add(outputCode, 0x20), 0x20)
        }
    }
}
