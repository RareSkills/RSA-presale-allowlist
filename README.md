
# RSA-presale-allowlist
This is a [RareSkills.io](https://RareSkills.io) project to allowlist addresses far more efficiently than ECDSA or Merkle Trees.

##

```shell 
 
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
  
    ```
## Working with the repo:

Clone repo: `git clone <https/ssh string>`

Install packages: `npm i`

Run tests: `npx hardhat test`

Display RSA script output: `python3 offchain_scripts/rsa.py`

Compile contract to bytecode: `solc --bin contracts/KeyStore.sol`

