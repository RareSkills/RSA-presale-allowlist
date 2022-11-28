// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
const deployment = require("./deploymentCodeCopyHelper.js");

async function main() {
  // run deployment code for RsaCodeCopydemo.sol with modified bytecode
  // (modulus added at the end of bytecode)
  const contract = await deployment.helper();
  console.log("contract address:", contract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
