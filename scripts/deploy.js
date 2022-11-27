// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
/* byte code paths */
const abi = require("../abis/RsaCodeCopyDemoABI.json"); 
const bytecode = require("../contracts/RsaCodeCopyDemo.json");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const Contract = await hre.ethers.getContractFactory(abi, bytecode);
  //const Contract = await ethers.getContractFactory("RsaCopyCodeDemo");
  const contract = await Contract.deploy(
    "0x2323232323232323232323232323232323232323232323232323232323232323",//salt
    "0x0000000000000000000000000000000000000000000000000000000000000003"//exponent
  );

  console.log("contract address:", contract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });