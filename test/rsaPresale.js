const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

describe("RSA presale allowlist", function () {
    async function deployFixture() {
        const [owner, user1] = await ethers.getSigners();

       /**
        * At this time the token is being deployed w/ the zero address as a 
        * contructor arg. This will later be changes to the address of the metamorphic
        * contract containing the public key value.
        */
        const TestTokenFactory = await ethers.getContractFactory("TestToken");
        const testToken = await TestTokenFactory.deploy(ZERO_ADDRESS);

        const KeyStoreFactory = await ethers.getContractFactory("KeyStore");
        const keyStore = await KeyStoreFactory.deploy();
        
        /**
         * This will need to be renamed. It is currently being used as a 
         * general utility contract for testing ideas.
         */
        const ContractFactory = await ethers.getContractFactory("Contract");
        const contract = await ContractFactory.deploy();

        return { testToken, keyStore, contract, owner, user1 };
    }

    describe("Deployment", function () {
        it("TestToken returns name as expected", async function () {
            const { testToken, owner } = await loadFixture(deployFixture);
            const tokenName = await testToken.name();

            expect(tokenName).to.equal("TestToken");
        });
    });

    describe("Reading from external contract", function () {
        it("===test===", async function () {
            const { testToken, keyStore, contract, owner } = await loadFixture(deployFixture);
            
            const code = await contract.read(keyStore.address);
            console.log(`code: ${code}`);

            expect(true).to.equal(false);
        });
    });
});
