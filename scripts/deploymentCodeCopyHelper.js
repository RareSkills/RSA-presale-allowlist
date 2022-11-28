const { BigNumber } = ethers;
const chalk = require('chalk');
const solc = require('solc');
const path = require('path');
const fs = require('fs');

 async function helper() {
  // load modulus
  let data = fs.readFileSync('./offchain_scripts/RSA/crypto/n.txt', 'utf8');
  data = BigNumber.from(data);
  const modulus = data.toHexString();

  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const thePath = path.resolve(__dirname, '../', 'contracts', 'RsaCodeCopyDemo.sol');
  const source = fs.readFileSync(thePath, 'utf-8');

  let input = {
    language: 'Solidity',
    sources: {
        'RsaCopyCodeDemo.sol' : {
            content: source
        }
    },
    settings: {
        outputSelection: {
            '*': {
                '*': [ "*" ]
            }
        }
    }
  };

  const output = JSON.parse(solc.compile(JSON.stringify(input)));
  const bytecode = output.contracts['RsaCopyCodeDemo.sol'].RsaCopyCodeDemo.evm.bytecode.object;
  const abi = output.contracts['RsaCopyCodeDemo.sol'].RsaCopyCodeDemo.abi;

  // modify init code of bytecode
  // init code is 32 bytes, contract is 556
  // contract should not be modified thus these lengths never change
  let initCode = bytecode.slice(0, 64);
  let contractCode = bytecode.slice(64, 1112);
  console.log("\nCompiled bytecode (RsaCopyCodeDemo.sol) initCode in red, contract code in green:")
  console.log(
    `${chalk.red(initCode.slice(0,38))}`+
    `${chalk.yellow.underline.bold(initCode.slice(38, 42))}`+
    `${chalk.red(initCode.slice(42))}`+
    `${chalk.green(contractCode)}`
  );

  // new init code (modify the codecopy size and return size by adding 0x100 (modulus size))
  // codecopy(destOffset, offset, size) -> size is located at offset 19 (38 in decimal)
  // 0x22c + 0x100 = 0x32c
  // since there is a DUP1 right after the 0x32c is pushed to the stack we only need to make one change
  //  *** changed to 0x30c (should be 0x20c in the init code) *** scrap entire init code and make custom init code
  console.log("\nnew init code in red with size change highlighted in gold:");
  let newInitCode = initCode.replace("022c", "030c"); 
  console.log(
    `${chalk.red(newInitCode.slice(0,38))}`+
    `${chalk.yellow.underline.bold(newInitCode.slice(38, 42))}`+
    `${chalk.red(newInitCode.slice(42))}`
  );

  // new bytecode = modified init code + contract code + modulus
  console.log("\nDeployment bytecode with initCode in red, contract code in green, and modulus blue:")
  let newByteCode = newInitCode + contractCode + modulus.slice(2);
  console.log(
    `${chalk.red(newInitCode.slice(0,38))}`+
    `${chalk.yellow.underline.bold(newInitCode.slice(38, 42))}`+
    `${chalk.red(newInitCode.slice(42))}`+
    `${chalk.green(contractCode)}`+
    `${chalk.blue(modulus.slice(2))}`
  );
  
  const Contract = await hre.ethers.getContractFactory(abi, newByteCode);
  return await Contract.deploy();
}

module.exports = { helper };