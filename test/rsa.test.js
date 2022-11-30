const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");

const verifySignatureSelector = "0xf80af984";

const TEST_PUBLIC_KEY_900 =
  "0xece30999723db3a74f0361d350ce4859758fec59db2470e9b04049f1a79ee8f1ec0d0d731becf4d39c9c74aefdaa62a3ce2639d05cfe5d6f0685f8d33636d65293b4ebe839d60e81d83ff7c298340223648007331001cec1756c3a01ee2639388906dc1fb30625f465d95b70a38f4e29b3c4f17f6dd48dab9d4806287bc6ac31ff16e7674b2b7c9c10e31f42aed1a3ba969caa7c8d453871e02c1349c67d149d114b20d5278dbd51caa97492eb9eefa601ba9ea4a487c8dda216125142b69489ab410ffce76fc67a848bdb4f4173aeffcec2aaa9a30bea4a2ca642900370d11167";

const TEST_SIG_900 =
  "0xcf01f74767b1e4be9f175488ee7340b505b37554aba5f87d788e6aec551b94c264cb75d6aadccc0aee9cd4d8d2d4ada300d4628ad410222f58a0af59a48d53a0352b35b5831cdbeca634a0168c30f1bc5ce82fc0fa10dea09156ed533f7e470ca4fe6509783823278ad6eff2348b3f4e3e89a9b27765b59493ed71732d011520ac79da4740f3bd047e0c83153b71126fb6f1174afaeb073394714d69b67c3b921e752d54125c34519c6f88ef96a4ea57030be48b7b2e27789cdcc8e57b5423981a4b0571e93833236601a01216a68f231f03fe0ef3c994e32aee892af42a3f50da";

const TEST_PUBLIC_KEY_864 =
  "0xcee2673703bceb4756e42038bdb63772a90dbbf61df1fcb7bc72f8a51433db07e562a0d92b5165c7e7eceb94f0af2c33429875cf3dc27c0d780d23fbbfe2c4b746b8b9b9765a2f7ebc3270620f747dbe3b24ddf82d10b0fee4a583b8272c11a48ecffd11c503645990e604485fcecd2003f49427984193985aa657d533d3e0104d8e2c0ec2c7fc93f39d7cc32671856c41a3b9f528305a72a184b80d66fb85e7699da0c45d74c5101ffb0cbe6d59a133d77bd696a154cc27ad1f227c528ca2fadb4e3b0a5145c9443d4282dbb9d8c2840fc93e2bcda838db";

const TEST_SIG_864 =
  "0x8c5e15e4fb5f4881c1aa4523a02cbf96cd480d9c65103e5b4b26a7adf3750b8a3eda24fd241ca05afdb8daf221c1467b906464fd8fcd2c27dccf7ebb762fac85fca831cb6b8a7c62f9fc5f79e104be937fb5bb7de7c1d7f244bec888364c0cddbe65bb29f4cfecd0fa9ab83142ef0baf0891c107fbac28cca10ca00bb1e34f6c18f29840a7373b404eb7d6fcec71ab093024362fd229dcafd75f26333e8a8f3827bd2db87d6fd2284ceb20bfebfb91e5e01e9377b2836dbba09b1e07cb4eafd9769f38e25d46181debc3b910fdc21cb31d24f3fe070ededf";

const INVALID_SIG =
  "0x232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323";

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
    const rsa900 = await RsaFactory.deploy(
      "0x2323232323232323232323232323232323232323232323232323232323232323",
      225
    );

    const rsa864 = await RsaFactory.deploy(
      "0x2323232323232323232323232323232323232323232323232323232323232323",
      216
    );

    await rsa900.connect(owner).deployPublicKey(TEST_PUBLIC_KEY_900);
    await rsa864.connect(owner).deployPublicKey(TEST_PUBLIC_KEY_864);

    const metamorphicContractAddress900 =
      await rsa900.metamorphicContractAddress();
    const metamorphicContractAddress864 =
      await rsa864.metamorphicContractAddress();

    return {
      rsa900,
      rsa864,
      owner,
      user1,
      user2,
      metamorphicContractAddress900,
      metamorphicContractAddress864,
    };
  }

  describe("Verify signature - With  Gas Estimate", function () {
    it("Should ensure verifySignature returns true (900 bit)", async function () {
      const { rsa900, user1, metamorphicContractAddress900 } =
        await loadFixture(deployFixture);

      await variableSigGasEstimate(
        user1,
        rsa900.address,
        TEST_SIG_900,
        metamorphicContractAddress900
      );

      const verified = await rsa900
        .connect(user1)
        .verifySignature(TEST_SIG_900);

      expect(verified).to.equal(true);
    });
    it("Should ensure verifySignature returns true (864 bit)", async function () {
      const { rsa864, user1, metamorphicContractAddress864 } =
        await loadFixture(deployFixture);

      await variableSigGasEstimate(
        user1,
        rsa864.address,
        TEST_SIG_864,
        metamorphicContractAddress864
      );

      const verified = await rsa864
        .connect(user1)
        .verifySignature(TEST_SIG_864);

      expect(verified).to.equal(true);
    });
    it("Should ensure user2 cannot use invalid signature", async function () {
      const { rsa900, user2 } = await loadFixture(deployFixture);

      expect(
        await rsa900.connect(user2).verifySignature(TEST_SIG_900)
      ).to.equal(false);
    });
    it("Should ensure invalid signature causes revert", async function () {
      const { rsa900, user2 } = await loadFixture(deployFixture);

      await expect(rsa900.connect(user2).verifySignature(INVALID_SIG)).to.be
        .rejected;
    });
  });
});
