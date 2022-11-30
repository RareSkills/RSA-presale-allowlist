const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");

const verifySignatureSelector = "0xf80af984";

const TEST_PUBLIC_KEY =
  "0xece30999723db3a74f0361d350ce4859758fec59db2470e9b04049f1a79ee8f1ec0d0d731becf4d39c9c74aefdaa62a3ce2639d05cfe5d6f0685f8d33636d65293b4ebe839d60e81d83ff7c298340223648007331001cec1756c3a01ee2639388906dc1fb30625f465d95b70a38f4e29b3c4f17f6dd48dab9d4806287bc6ac31ff16e7674b2b7c9c10e31f42aed1a3ba969caa7c8d453871e02c1349c67d149d114b20d5278dbd51caa97492eb9eefa601ba9ea4a487c8dda216125142b69489ab410ffce76fc67a848bdb4f4173aeffcec2aaa9a30bea4a2ca642900370d11167";
const TEST_SIG =
  "0xcf01f74767b1e4be9f175488ee7340b505b37554aba5f87d788e6aec551b94c264cb75d6aadccc0aee9cd4d8d2d4ada300d4628ad410222f58a0af59a48d53a0352b35b5831cdbeca634a0168c30f1bc5ce82fc0fa10dea09156ed533f7e470ca4fe6509783823278ad6eff2348b3f4e3e89a9b27765b59493ed71732d011520ac79da4740f3bd047e0c83153b71126fb6f1174afaeb073394714d69b67c3b921e752d54125c34519c6f88ef96a4ea57030be48b7b2e27789cdcc8e57b5423981a4b0571e93833236601a01216a68f231f03fe0ef3c994e32aee892af42a3f50da";
const INVALID_SIG =
  "0x232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323";

describe("RSA presale allowlist", function () {
  async function deployFixture() {
    const [owner, user1, user2] = await ethers.getSigners();

    const Rsa900Factory = await ethers.getContractFactory("Rsa900");
    const rsa = await Rsa900Factory.deploy(
      "0x2323232323232323232323232323232323232323232323232323232323232323",
      225
    );

    await rsa.connect(owner).deployPublicKey(TEST_PUBLIC_KEY);

    const metamorphicContractAddress = await rsa.metamorphicContractAddress();

    return { rsa, owner, user1, user2, metamorphicContractAddress };
  }

  describe("Verify 900 bit signature", function () {
    it("Should ensure verifySignature returns true", async function () {
      const { rsa, user1, metamorphicContractAddress } = await loadFixture(
        deployFixture
      );

      // Construct raw calldata arguments for verifySignature
      const abi = ethers.utils.defaultAbiCoder;
      const calldata = abi.encode(["bytes"], [TEST_SIG]);
      const data = `${verifySignatureSelector}${calldata.slice(2)}`;

      // Construct unsigned transaction to add metamorphic contract accessList
      const tx = {
        from: user1.address,
        to: rsa.address,
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

      const verified = await rsa.connect(user1).verifySignature(TEST_SIG);

      expect(verified).to.equal(true);
    });
    it("Should ensure user2 cannot use invalid signature", async function () {
      const { rsa, user2 } = await loadFixture(deployFixture);

      expect(await rsa.connect(user2).verifySignature(TEST_SIG)).to.equal(
        false
      );
    });
    it("Should ensure invalid signature causes revert", async function () {
      const { rsa, user2 } = await loadFixture(deployFixture);

      await expect(rsa.connect(user2).verifySignature(INVALID_SIG)).to.be
        .rejected;
    });
  });
});
