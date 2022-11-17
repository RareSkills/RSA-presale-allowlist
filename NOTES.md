# Notes:

## Task:

The over arching goal here is to create a more gas efficient allow listing system. To create a proof of concept and test we will need to:
- [x] Spin up a simple project that involves minting
- [x] Label `rsa.py` output more clearly (This will help transpose RSA proving function into solidity)
- [ ] Implement functionality to prove signature (See `Using RSA for minting` below)
- [ ] Implement reading/parsing large values (1024bit) from outside contracts (See `ExampleMulMod.sol` in ./contracts)
- [ ] Utalize the `metamorphic` pattern for mutating this public key (The large value from above)

## There are a few non-trivial moving parts:
- [ ] The public key is stored in the bytecode of another smart contract because reading 1024 bits from storage (the RSA public key size) would make the gas cost go up a lot
- [ ] To invalidate the public key, the contract must be selfdestructed and different bytecode must be deployed to the same address using the metamorphic pattern.
- [ ] To read the public key, you’ll need to do extcodecopy and ignore the executable bytecode at the beginning. You can also use address.code but I somewhat suspect this kind of an operation is actually easier in assembly than solidity
- [ ] The address of the external contract should be immutable, or you’ll get another storage read. The contents are not immutable because the contract is metamorphic
- [ ] Once you get all that working, add access lists to knock off another 100 gas. I can share working code for that, but the idea is here (https://hackmd.io/@fvictorio/gas-costs-after-berlin)


### Using RSA for minting
The smart contract takes the signature  s  and raises it to the power  e  and takes the modulus  m . If 
this result turns out to be exactly  hash(msg.sender)  then the smart contract knows the seller signed 
hash(msg.sender) , and then the smart contract allows  msg.sender  to mint the NFT or collect the airdrop.

That might look like `function mint(bytes calldata sig);`
