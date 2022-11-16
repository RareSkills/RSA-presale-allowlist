const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");

describe("RSA presale allowlist", function () {
  async function deployFixture() {
    const [owner, user1] = await ethers.getSigners();

    const TestTokenFactory = await ethers.getContractFactory("TestToken");
    const testToken = await TestTokenFactory.deploy();

    return { testToken, owner, user1 };
  }

    describe("Deployment", function () {
        it("TestToken returns name as expected", async function () {
            const { testToken, owner } = await loadFixture(deployFixture);
            const tokenName = await testToken.name();

            expect(tokenName).to.equal("TestToken");
        });
    });
});
