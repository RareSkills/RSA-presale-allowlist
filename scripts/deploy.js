async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  /**
   * Fill in strings below with desired values
   * Generate PUBLIC_KEY via the offchain scripts (see README.md)
   */

  // Must be a 32 byte hex value
  const SALT = "";

  // Bytes length of modulus
  const MOD_LENGTH = "";

  // Modulus
  const PUBLIC_KEY = "";

  const RsaFactory = await ethers.getContractFactory('Rsa');
  const rsa = await RsaFactory.deploy(SALT, MOD_LENGTH);

  await rsa.connect(owner).deployPublicKey(PUBLIC_KEY);

  const metamorphicContractAddress =
    await rsa.metamorphicContractAddress();

  console.log("RSA Contract address:", rsa.address);
  console.log("Metamorphic Contract address:", metamorphicContractAddress);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });