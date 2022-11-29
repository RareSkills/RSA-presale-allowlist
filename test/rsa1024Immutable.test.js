const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect, use } = require('chai');

use(require('chai-as-promised'));

const TEST_PUBLIC_KEY_ARRAY = [
  "0xaa1313030fe6d08341a6466c68cf0681efd99902801d84b60727ed4c221382d5",
  "0xe7f810a3c2cc0d6fe34c490f10bf1a8224f92f9cd26795cf18afdd42daffcb73",
  "0x00415f19b894fe806b9ed5934df67af9de8e7d0489447ec96831975169dc868c",
  "0x7607529549bfcdee7cff9077ccd1401480629789345ea061298a78a18860eccf",
  "0x7b5b3f1c00ada9c423032a16b8449721052a11c2daffd98ddfac452be2f0b50e",
  "0x24a21048789819ec7787ed15f90b7caea643ca8877baacd538e483c198f9f75e",
  "0x38905363eb45473aee076e33c4a7aca2894115c8fe39d0d6f54a1a86ca1a5f29",
  "0x0e4fbb6bcd8b10f90f56dc30d40339a0d6092160362d432c08459276837d70f9",
];

const TEST_SIG =
  "0x15b35c9b7dceb39db3ac7baf52bd6ca5b60fa7708c7375fc09d539bd8b41207d42c0ffba36e28c071f0281fbab26114882c78088e97c1a736daffb376c7c96bb3a8f0677418930537fddd65ecb5e5fbf2957df49edfe3ed377fdce0664928fe228cf2de00757d26f4f9d463327844bf59032b2997a24fbae701b128fd31dd45f238bce7d8b4064a3d0d16a74fd9a1cd4c8062ce74edc13ecd666330f1fa009e2def7888acc9ff566490fdc40638883f544452a96af6e5f3e85bc87fce4469683826b8598281dbbc1f760cbc70018c2b6d4628715b081f3d3c02138aff3214cd38db5d9aaaba06e375611f9477d1f118847059e230e7cea1fbd8af652354aa5a0";

const INVALID_SIG = 
  "0x232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323";

describe("RSA presale allowlist", function () {
  async function deployFixture() {
    const [owner, user1, user2] = await ethers.getSigners();

    const Rsa1024ImmutableFactory = await ethers.getContractFactory(
      "Rsa1024Immutable"
    );
    const rsaImmutable = await Rsa1024ImmutableFactory.deploy(
      TEST_PUBLIC_KEY_ARRAY
    );

    return { rsaImmutable, owner, user1, user2 };
  }

  describe("Verify 1024 bit signature w/ immutable vars", function () {
    it("Should ensure verifySignature returns true", async function () {
      const { rsaImmutable, user1 } = await loadFixture(deployFixture);

      const gasEstimate = await rsaImmutable
        .connect(user1)
        .estimateGas.verifySignature(TEST_SIG);
      console.log(`\ngas estimate: ${gasEstimate}`);

      const verified = await rsaImmutable
        .connect(user1)
        .verifySignature(TEST_SIG);

      expect(verified).to.equal(true);
    });
    it("Should ensure user2 cannot use invalid signature", async function () {
      const { rsaImmutable, user2 } = await loadFixture(deployFixture);

      expect(await rsaImmutable.connect(user2).verifySignature(TEST_SIG)).to.equal(false);
    });
    it("Should ensure invalid signature causes revert", async function () {
      const { rsaImmutable, user2 } = await loadFixture(deployFixture);

      await expect(rsaImmutable.connect(user2).verifySignature(INVALID_SIG)).to.be.rejected;
    });
  });
});
