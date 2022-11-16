const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");

describe("MulMod", function () {
  async function deployFixture() {
    const [owner, user1] = await ethers.getSigners();

    const MulModFactory = await ethers.getContractFactory("ExampleMulMod");
    const mulMod = await MulModFactory.deploy();

    return { mulMod, owner, user1 };
  }

    describe("Deployment", function () {
        it("===test===", async function () {
            const { mulMod, owner } = await loadFixture(deployFixture);
            expect(true).to.equal(false);
        });
    });
});