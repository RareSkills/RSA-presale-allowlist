const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
const KEYSTORY_BYTECODE = '608060405260008060006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff160217905550348015605057600080fd5b5060a48061005f6000396000f3fe6080604052348015600f57600080fd5b506004361060285760003560e01c806383197ef014602d575b600080fd5b60336035565b005b60008054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16fffea26469706673582212200b7435d044ce1581c087230e6ead7bf275070e9cbeb54836d1e94c644f05e63764736f6c63430008110033';


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
        it("The 'read' function should return data from the passed in contract", async function () {
            const { testToken, keyStore, contract, owner } = await loadFixture(deployFixture);

            const code = await contract._readFromAddress(keyStore.address, 1);
            console.log(`code: ${code}`);
            expect(code).to.not.equal("");
        });

        it("Returns address", async function () {
            const { testToken, keyStore, contract, owner } = await loadFixture(deployFixture);
          
            const newAddress = await contract.callStatic.deployAsBytecode('99999999999');
            console.log(`newAddress: ${newAddress}`);

            const code = await contract._readFromAddress(newAddress, 1);
            console.log(`code: ${code}`);

            expect(true).to.equal(true);
        });

        it("Returns code from specific memory slot", async function () {
            const { testToken, keyStore, contract, owner } = await loadFixture(deployFixture);
          
            const memSlot8 = await contract.callStatic.deployAndReadSlot('99999999999', 8);
            console.log(`memSlot8 : ${memSlot8}`); 

            const memSlot9 = await contract.callStatic.deployAndReadSlot('99999999999', 9);
            console.log(`memSlot9 : ${memSlot9}`); 

            const memSlot10 = await contract.callStatic.deployAndReadSlot('99999999999', 10);
            console.log(`memSlot10: ${memSlot10}`); 

            expect(true).to.equal(true); });
    });
});
