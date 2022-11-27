const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");

/* byte code paths */
const abi = require("../abis/RsaCodeCopyDemoABI.json"); 
const bytecode = require("../contracts/RsaCodeCopyDemo.json");

describe("RSA presale allowlist", function () {
    async function deployFixture() {
        const [owner, user1] = await ethers.getSigners();

        //console.log(user1.address); //0x70997970C51812dc3A010C7d01b50e0d17dc79C8

        // deploy contract with specified abi and bytecode
        const RsaDemoFactory = await hre.ethers.getContractFactory(abi, bytecode);

        const rsa = await RsaDemoFactory.deploy(
            /*
            "0x2323232323232323232323232323232323232323232323232323232323232323",//salt
            "0x0000000000000000000000000000000000000000000000000000000000000003"//exponent
            */
        );

        return { rsa, owner, user1 };
    }

    describe("Deployment", function () {
        it("TestToken returns name as expected", async function () {
            const { rsa, user1 } = await loadFixture(deployFixture);
            const gasEstimate = await rsa.connect(user1).estimateGas.verifySignature(
                "0x28a9c1ab04c2338f0a0e9356f4f8a7e6a25db7f02bfef6308a6be2119d035004e3ab0c1cf16c1d7f89b5a3bca8d13750cdb293c81e08c6f382a488c58733aa0931010584a7f04beea85f6c40543b25c066f3d0f601584f3db0bd2222a46155fce8cad89d4aceb88d873fae5e48aff5ea8a0e71c73d3ef4d3d157745ae631607d4c993631d28af82826f81cfa08fb8fe733373ce1f792bfe3df73ee19ceed321d9f2b78308f8db46154183f030c426ad5edeb21f84c1ddd3b83f68a1f2ee0cef122071224511776a8361c3f6328c49f0cbf12f021d3545f2818f9e20f85c6afd6d06281e4590290fddf777b9ed497f6fb0b3ed188bc000ea384341180dcec7dbc"
            );

            console.log(`gas estimate: ${gasEstimate}`);

            const verified = await rsa.connect(user1).verifySignature(
                "0x28a9c1ab04c2338f0a0e9356f4f8a7e6a25db7f02bfef6308a6be2119d035004e3ab0c1cf16c1d7f89b5a3bca8d13750cdb293c81e08c6f382a488c58733aa0931010584a7f04beea85f6c40543b25c066f3d0f601584f3db0bd2222a46155fce8cad89d4aceb88d873fae5e48aff5ea8a0e71c73d3ef4d3d157745ae631607d4c993631d28af82826f81cfa08fb8fe733373ce1f792bfe3df73ee19ceed321d9f2b78308f8db46154183f030c426ad5edeb21f84c1ddd3b83f68a1f2ee0cef122071224511776a8361c3f6328c49f0cbf12f021d3545f2818f9e20f85c6afd6d06281e4590290fddf777b9ed497f6fb0b3ed188bc000ea384341180dcec7dbc"
            );
            
            expect(verified).to.equal(true);
        });
    });
});
