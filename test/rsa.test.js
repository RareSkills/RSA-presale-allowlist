const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");

const verifySignatureSelector = "0xf80af984";

const TEST_PUBLIC_KEY_1024 =
  "0xb21748b28a4d0a072b1c7dcf43a5d885614cdb6468415534ce78725c6713fa3e5cac9e22e0a08096dd96ffc85e7998145f3e1c812c0e26416dfb670838337d73519a86f31dc6cbce3cfa46adf6971b5d28793474d92de1e28b2b54593207f800b66831a049f8f1c6ad51789448d30ffc6b01df5eb2b0301832ad70f6429cd409";

const TEST_SIG_1024 =
  "0x939f58d488df3fca13f99077a6df35675ae392ce346968f735d71b5bd7d7c03ba48a0318d33d73af7a9f79dfa6b47bbe91fe3ecd1edaeaae9eb684677c0037a922b880a580349b728abc0297048fc08e229393024e0b1a89aa11a1a3f993d6bfec4af960e4ad7af62bbd451773bd3675550219e69fccca4ed6ac81ef8a7b04d5";

const MOD_LENGTH_1024 = 128

const TEST_PUBLIC_KEY_2000 =
  "0x697f16c4d76314d187b6225beb1a28ea64eb6ddf1f625f2f7a798bfe94e6b48f6ad2a44853f0deaac0380d693bf39c8d94f080a48ef62c975fb882e894f2b9dec6fee5cbe0a6b41ff942fbd90b6a64b26f764ea30c1f5ae3f9ba2195116f9cbe9b511c68b5ede83915104aba3485f3e13f4c2208e1ad01d18e2e578f959c88e9d5508b4bebd6c33696bd3207a40d7f961fa67f1dae521c1b764d7e1f619ad40fe4eb1aab871b9b2e844eb6050bf549892ad6f9bf755c864ed0e1fec72646ef9a7219319878b56d4aba8ca3a915d7b3ad6c911ea6e0b0f413fba9a42bd6e9beb518a5391cbc4f5e7c88b27c67f0545bffa0de715f96aac516c883";

const TEST_SIG_2000 =
  "0x5d84598e424e7c5ad3cc0a31f7c0593ddea5b6aea54151911f6199de1cafc68608535b188868048d7b43eff815747654b6fec96fe85d936e48d5814f0b3ab2a1f06ea27fcc548b28ff649aa3042b967c853267ce4708242a6d8449f165bf4d841b57cc0d61c28ce4692c1ab8701960652fa565c49207b786bbe3edca9c53caa3515c85f2f4e16eeeec99840c1e59466ae3e9cc8fc2ba245d4ee735bdcf84251e10295c704ce18946015d217597ef8a90654f6e78ad7ee72bc129584bc58cb364d8664abfaa0c5195c0cba074935a2de38611aa0a5210bc2ccfa01dc7513cbece815bfed036db5cb97ee41ca661d5cf74786a56e4ab7f7dfbf52f";

const MOD_LENGTH_2000 = 250

const INVALID_SIG =
  "0x0daed3720f1e753c42a2b471bc492a395fae088713a016341d362d8aecf11364c5f39e14ea923de8fa18d312d2d0a0582b0a54a836600db0c75ca95005cbf6b9612116f59b1defeeccfa9f5868f06cbd1a7ac020fcea218a45aa8067361c68eb91b33d132bcab887e7006f62abb4458afe0878e2a1a1dfcdeba5b6107856f479";

async function variableSigGasEstimate(
  user1,
  contractAddress,
  signature,
  metamorphicContractAddress
) {
  // Construct raw calldata arguments for verifySignature
  const abi = ethers.utils.defaultAbiCoder;
  const calldata = abi.encode(["bytes"], [signature]);
  const data = `${verifySignatureSelector}${calldata.slice(2)}`;

  // Construct unsigned transaction to add metamorphic contract accessList
  const tx = {
    from: user1.address,
    to: contractAddress,
    data: data,
    value: 0,
    type: 1,
    accessList: [
      {
        address: metamorphicContractAddress,
        storageKeys: [],
      },
    ],
  };

  const gasEstimate = await user1.sendTransaction(tx);
  console.log("\tEstimated Gas:" + gasEstimate.gasLimit.toString());
}

describe("RSA presale allowlist", function () {
  async function deployFixture() {
    const [owner, user1, user2] = await ethers.getSigners();

    const RsaFactory = await ethers.getContractFactory("Rsa");
    const rsa1024 = await RsaFactory.deploy(
      "0x2323232323232323232323232323232323232323232323232323232323232323",
      MOD_LENGTH_1024
    );

    const rsa2000 = await RsaFactory.deploy(
      "0x2323232323232323232323232323232323232323232323232323232323232323",
      MOD_LENGTH_2000
    );

    await rsa1024.connect(owner).deployPublicKey(TEST_PUBLIC_KEY_1024);
    await rsa2000.connect(owner).deployPublicKey(TEST_PUBLIC_KEY_2000);

    const metamorphicContractAddress1024 =
      await rsa1024.metamorphicContractAddress();
    const metamorphicContractAddress2000 =
      await rsa2000.metamorphicContractAddress();

    return {
      rsa1024,
      rsa2000,
      owner,
      user1,
      user2,
      metamorphicContractAddress1024,
      metamorphicContractAddress2000,
    };
  }

  describe("Verify signature - With  Gas Estimate", function () {
    it("Should ensure verifySignature returns true (1024 bit)", async function () {
      const { rsa1024, user1, metamorphicContractAddress1024 } =
        await loadFixture(deployFixture);

      await variableSigGasEstimate(
        user1,
        rsa1024.address,
        TEST_SIG_1024,
        metamorphicContractAddress1024
      );

      const verified = await rsa1024
        .connect(user1)
        .verifySignature(TEST_SIG_1024);

      expect(verified).to.equal(true);
    });
    it("Should ensure verifySignature returns true (2000 bit)", async function () {
      const { rsa2000, user1, metamorphicContractAddress2000 } =
        await loadFixture(deployFixture);

      await variableSigGasEstimate(
        user1,
        rsa2000.address,
        TEST_SIG_2000,
        metamorphicContractAddress2000
      );

      const verified = await rsa2000
        .connect(user1)
        .verifySignature(TEST_SIG_2000);

      expect(verified).to.equal(true);
    });
    it("Should ensure user2 cannot use invalid signature", async function () {
      const { rsa1024, user2 } = await loadFixture(deployFixture);

      expect(
        await rsa1024.connect(user2).verifySignature(TEST_SIG_1024)
      ).to.equal(false);
    });
    it("Should ensure invalid signature causes revert", async function () {
      const { rsa1024, user2 } = await loadFixture(deployFixture);

      await expect(rsa1024.connect(user2).verifySignature(INVALID_SIG)).to.be
        .rejected;
    });
  });
});
