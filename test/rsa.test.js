const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");

const verifySignatureSelector = "0xf80af984";

const TEST_PUBLIC_KEY_896 =
  "0x5fc93f2abdcd9bfcba4d56aa7551f44d8e579ca6267eb477e91fdfd52c546d3987139f7e69b645822b3e3ef25a38c47e0a1727045e8d23abe22a46012d07086398cf76c22175dc068fac615a6ab0034fd26b42a65b40597fe5eba3cf2fddd281e58ad4ad73d653dd478663371515a3bd";

const TEST_SIG_896 =
  "0x02a8d5366f9df613e11368f575f8c2a4bfe4c4e9a234abdc86e26880875b6136a307057743890c5b81c7646045ddc00231ca12eeacb340b6aea61c46193b952e0b405532f5db3cd791ebe302cc66aee99d5f5b069c6283f6cbef46a3a1e7862407e9b157a42066dfc8f9f8c727855c18";

const MOD_LENGTH_896 = 112

const TEST_PUBLIC_KEY_960 =
  "0x8d058b94bf3c0e6866bbb87b9a04a8dc3136343ef3b81940842c041c5d1f1b6bc8e76f8b37958aaec7483701edbcd9bc3e6f7ad41a56e449326661f375fff9d917634e7202d9b5f4ecb447c9ad6899dadfdaaae19931e883730b60a0a4cf6dc3b383036bc055d8e9ca9d26a39be32e169fbb83ed31bed61f";

const TEST_SIG_960 =
  "0x2dbaa86f8a59fb0bacb971c72ff037252166d3cdb95b8b0cf3e75046e7e977c227bab5ec84e1ac91e46a95472eb9cf06dd3a00bdf31594187621fbf9610ff9eea2cac1825e2c14c09a0a7e3eb3a90944d9d95d96416ab238920b590081a8208fb60b28d152ab1cc89c4fc63ab94f890fcbe63d9ff851ac15";

const MOD_LENGTH_960 = 120

const TEST_PUBLIC_KEY_1024 =
  "0xb21748b28a4d0a072b1c7dcf43a5d885614cdb6468415534ce78725c6713fa3e5cac9e22e0a08096dd96ffc85e7998145f3e1c812c0e26416dfb670838337d73519a86f31dc6cbce3cfa46adf6971b5d28793474d92de1e28b2b54593207f800b66831a049f8f1c6ad51789448d30ffc6b01df5eb2b0301832ad70f6429cd409";

const TEST_SIG_1024 =
  "0x939f58d488df3fca13f99077a6df35675ae392ce346968f735d71b5bd7d7c03ba48a0318d33d73af7a9f79dfa6b47bbe91fe3ecd1edaeaae9eb684677c0037a922b880a580349b728abc0297048fc08e229393024e0b1a89aa11a1a3f993d6bfec4af960e4ad7af62bbd451773bd3675550219e69fccca4ed6ac81ef8a7b04d5";

const MOD_LENGTH_1024 = 128

const TEST_PUBLIC_KEY_2048 =
  "0x9f6eed6bf944152d200e7437e4ff4693f2480e4f532db3d95da8f072db439a206fdc4d92f02cecdf2e34410ebd50087a0edec88163305492ce87396bf37182a0ddd41ba424d3570d75a5c4997518845bea621dc95b22223c8b53378f79d4d85d65fb80cbe532321af9b16457cffcde9397f03d6586d33b5db2e29fc4acd6b94e20cd130c3443629266247f47d9480c3bafc0c5d1e184ca40a9266ec9e54f3246b838bb0acb97f6e7ff8d815ad1a3cf14f38f9084fce117f970be1e17ac9f145eebbe1b701d95b098020aacad2d36817cb176e99b8c8421ac1bbaadc14dbf9bc486f6f3646577b519a63c4b28cf7adfa98d229ae02fe72d2aab53a7dc565425e3";

const TEST_SIG_2048 =
  "0x4be2206543269a33fdbb7cdad920e0d14bf809f90eba4eea4d011fb2b2b2888acdaa9bde3e2842b2a1919121909e36c3122954f8ff63a0f493bb7d6fd25138c35929e7cb041f2bfeacf9e65bce6dada1809d21dee9b0eea5ef34aeac4827070b95d65a2cc6e842dc14bdd4a5beac31844ffbc3c805b1d1a742952fb696cbea54749b8c7e274754117898eb874b90461d5e73cb43db4a8f93d4d9530d9ae40174f159656944ec60b7f39609de6583fff4378b1eccd4705db3e5ca3cbb6a6539d4ffb7df53bd60eb24a50a2323cfa9a6994a004ae9d7e86ce9923c75b75ff5a12605ad5afc07207d8d5c4f71b043150df0f45b199ee49d2155e465b31525bd4bf1";

const MOD_LENGTH_2048 = 256

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
  console.log("\tEstimated Gas: " + gasEstimate.gasLimit.toString());
}

describe("RSA presale allowlist", function () {
  async function deployFixture() {
    const [owner, user1, user2] = await ethers.getSigners();

    const RsaFactory = await ethers.getContractFactory("Rsa");

    const rsa896 = await RsaFactory.deploy(
      "0x2323232323232323232323232323232323232323232323232323232323232323",
      MOD_LENGTH_896
    );

    const rsa960 = await RsaFactory.deploy(
      "0x2323232323232323232323232323232323232323232323232323232323232323",
      MOD_LENGTH_960
    );

    const rsa1024 = await RsaFactory.deploy(
      "0x2323232323232323232323232323232323232323232323232323232323232323",
      MOD_LENGTH_1024
    );

    const rsa2048 = await RsaFactory.deploy(
      "0x2323232323232323232323232323232323232323232323232323232323232323",
      MOD_LENGTH_2048
    );

    // deploy rsa 896
    await rsa896.connect(owner).deployPublicKey(TEST_PUBLIC_KEY_896);
    const metamorphicContractAddress896 =
      await rsa896.metamorphicContractAddress();

    // deploy rsa 960
    await rsa960.connect(owner).deployPublicKey(TEST_PUBLIC_KEY_960);
    const metamorphicContractAddress960 =
      await rsa960.metamorphicContractAddress();

    // deploy rsa 1024
    await rsa1024.connect(owner).deployPublicKey(TEST_PUBLIC_KEY_1024);
    const metamorphicContractAddress1024 =
      await rsa1024.metamorphicContractAddress();

    // deploy rsa 2048
    await rsa2048.connect(owner).deployPublicKey(TEST_PUBLIC_KEY_2048);
    const metamorphicContractAddress2048 =
      await rsa2048.metamorphicContractAddress();

    return {
      rsa896,
      rsa960,
      rsa1024,
      rsa2048,
      owner,
      user1,
      user2,
      metamorphicContractAddress896,
      metamorphicContractAddress960,
      metamorphicContractAddress1024,
      metamorphicContractAddress2048,
    };
  }

  describe("Verify signature - With  Gas Estimate", function () {
    it("Should ensure verifySignature returns true (896 bit)", async function () {
      const { rsa896, user1, metamorphicContractAddress896 } =
        await loadFixture(deployFixture);

      await variableSigGasEstimate(
        user1,
        rsa896.address,
        TEST_SIG_896,
        metamorphicContractAddress896
      );

      const verified = await rsa896
        .connect(user1)
        .verifySignature(TEST_SIG_896)

      expect(verified).to.equal(true);
    });
    it("Should ensure verifySignature returns true (960 bit)", async function () {
      const { rsa960, user1, metamorphicContractAddress960 } =
        await loadFixture(deployFixture);

      await variableSigGasEstimate(
        user1,
        rsa960.address,
        TEST_SIG_960,
        metamorphicContractAddress960
      );

      const verified = await rsa960
        .connect(user1)
        .verifySignature(TEST_SIG_960);

      expect(verified).to.equal(true);
    });
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
    it("Should ensure verifySignature returns true (2048 bit)", async function () {
      const { rsa2048, user1, metamorphicContractAddress2048 } =
        await loadFixture(deployFixture);

      await variableSigGasEstimate(
        user1,
        rsa2048.address,
        TEST_SIG_2048,
        metamorphicContractAddress2048
      );

      const verified = await rsa2048
        .connect(user1)
        .verifySignature(TEST_SIG_2048);

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
