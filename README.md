# RSA-presale-allowlist
This is a [RareSkills.io](https://RareSkills.io) project to allowlist addresses far more efficiently than ECDSA or Merkle Trees.
For a detailed breakdown see Jeffrey Scholz's medium post [here](https://medium.com/donkeverse/hardcore-gas-savings-in-nft-minting-part-2-signatures-vs-merkle-trees-917c43c59b07)

It is a common practice in the cryptocurrency space to have sales for tokens to addresses than have been allowlisted(whitelisted) off-chain. Therefore, there must be a verification mechanism on-chain to validate these users to enable them to receive these tokens.

#### Three common methods for doing so are (including gas costs of optimizer set to 1,000 runs):
- storing the address in a mapping (Gas: 23,424) 
- ECDSA Signature Verification (Gas: 29,293) 
- using Merkle proofs (Gas: 30,517, 128 addresses) 

The issues with the mapping, and merkle approach is a cap on scalability. Our aim was to beat
the current best known approach the ECSDA Signature Verification.

#### Our approach:
- RSA 896 bit Metamorphic (Gas: 26,850)
- RSA 960 bit Metamorphic (Gas: 26,925)
- RSA 1024 bit Metamorphic (Gas: 27,033)
- RSA 2048 bit Metamorphic (Gas: 29,271) 

<hr>

The metamorphic approach is one where we have a contract factory. From this contract an administrator has the ability to deploy a secondary contract at a fixed address that contains the public key(modulus). They also have the ability to self-destruct this contract and redploy to this fixed address with a new public key(rendering the previous signature invalid).

## General
To get started checkout the unit tests in the test folder, which will have the correct format for inputs to the contracts/functions.

Head over to the RSA folder under the offchain_scripts folder. From here you must run the file called mainRSA.py and pass in command line arguments to interact with it (see off-chain scripts section for instructions).

The execution flow that one is expected to take is to generate an RSA key pair using the python script. Then you must either singularly pass in addresses you want to generate signatures for or utilize the bulk approach we have provided. This involves generating a csv file which will have the first value as the Ethereum address whitelisted. When you generate bulk signatures the csv you have provided as input will be cloned and the signature will be appended onto the last column of the csv (as the last value). 

Whitelisted users would then be distributed the signatures and they will input their signature into the verifySignatures function.

## Off-Chain Scripts

### Prerequistes 

```
pip install pycryptodome
```

### Command Line Arguments Guide
    - python mainRSA.py --genKeyPair [Modulus key size (bits)]
        - generates a new key pair of specified bits with a fixed exponent of 3
        - stores key values in RSA/crypto
    - python mainRSA.py --genKeyPair [ Modulus key size (bits)] --genExponent
        - generates a new key pair of specified bits with a random exponent less than 30,000
        - note that the gas costs will increase if the exponent is above 3
        - stores key values in RSA/crypto
    - python mainRSA.py --viewKeyPair
        - view the keys that were generated to the RSA/crypto
    - python mainRSA.py --genSingularSignature [address]
        - generates a single signature in the cli output 
    - python mainRSA.py --bulkGenSignatures [readingFile] [outputFile] [headerPresent]
        - readingFile is the csv file being passed in (must have ethereum address as first value)
        - outputFile is the cloned csv file with appended signatures
        - headPresent must have either True or False passed to it and indicates whether the csv file has a header row
 
## RSA (metamorphic modulus)
This section includes an advanced explanation into the metamorphic contract factory process. A metamorphic contract is one that has the ability to be self destructed and deployed to the same address. How this is acheived is that we use the CREATE2 opcode which internally uses hash(0xFF, sender, salt, bytecode) to deterministically calculate the deployment address. However, the bytecode which we supply to create the contract will have an init code (code which is run during the constructor phase) that will call back on to the msg.sender (contract factory) via a STATICCALL. The contract factory has a callback function which returns the raw bytecode of what is to be the runtime code of this instance of the metamorphic contract. It is the end of this runtime code where we append the public key(modulus). When the metamorphic contract receives this bytecode within it's constructor phase it pushes the returned data into memory. From where the metamorphic contract will return it from it's own memory, ending its constructor/init phase. (which finalizes the process of pushing this to the blockchain as the run time code).

It's important to note this is not the standard process for deploying a metamorphic contract. We have modified the bytecode which is used to instantiate the metamorphic contract by having the contract factory send back the actual runtime code to use. The standard implementation involves deploying an 'implementation contract' which has the runtime code we would like the metamorphic contract to have. We store this address in the contract factory and return it to the metamorphic contract during the callback phase. From where the metamorphic contract will instead do an extcodecopy of the entire runtime code of the implementation contract. See the original implementation [here](https://github.com/0age/metamorphic)

Our approach cuts out the need of having to deploy the implementation contract entirely, giving us significant gas savings.

#### Modified metamorphic init code(See contract constructor):
```
 
    PUSH4 0x0000000e                  -> push selector
    PUSH1 0x00                        -> store from beginning of memory
    MSTORE                            -> store using previous 2 arguments MSTORE(0x00, selector)
    PUSH2 [uint16(0x77 + _modLength)] -> byte size of return data to copy  
    PUSH1 0x00                        -> where in memory to copy the return data
    PUSH1 0x04                        -> size of calldata argument
    PUSH1 0x1c                        -> where in memory to start copying the calldata arguments
    CALLER                            -> msg.sender (initiating contract)
    GAS                               -> forward all current gas
    STATICCALL                        -> (GAS, msg.sender, memory offset, memory to copy size, memory offset to copy to,byte size of return data to copy)
    PUSH2 [uint16(0x37 + _modLength)] -> size of return data
    PUSH1 0x40                        -> where to start copying the return data from (skip bytes ptr,length)
    RETURN                            -> will be this contracts new bytecode

```

#### Metamorphic runtime code:
```
    bytecode:
        33[msg.sender]14601f5760006000f35b73[CONTRACT FACTORY]fffe[DYANMIC MODULUS APPENDED AT THE END]

    CALLER                      -> Push msg.sender to stack  
    PUSH20 [CONTRACT FACTORY]   -> Push contract factory address 
    EQ                          -> If msg.sender == contract factory address, return 1
    PUSH1 0x1f                  -> Push JUMPDEST location
    JUMPI                       -> If EQ is true go to JUMPDEST
    /* note: make the return an invalid op code instead */
    PUSH1 0x00                  -> Byte size for return
    PUSH1 0x00                  -> Offset in memory to copy from
    RETURN                      -> Returns no data, ends execution
    JUMPDEST                    -> Came here from JUMP
    PUSH20 [CONTRACT FACTORY]   -> Address to send funds to
    SELFDESTRUCT                -> Delete contract code from the blockchain and send funds to previously pushed address and end execution
    INVALID                     -> End execution if this line is reached there was an error

```

## Tests
Run tests: `npx hardhat test`

![image](https://user-images.githubusercontent.com/106453938/205217581-16c8312c-668c-437c-88ae-2172df153f1c.png)

## Working with the repo:

Clone repo: `git clone <https/ssh string>`

Install packages: `npm i`
