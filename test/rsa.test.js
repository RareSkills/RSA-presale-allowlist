const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");

describe("RSA presale allowlist", function () {
    async function deployFixture() {
        const [owner, user1] = await ethers.getSigners();

    
        const RsaDemoFactory = await ethers.getContractFactory("RsaDemo");
        const rsa = await RsaDemoFactory.deploy(
            "0x2323232323232323232323232323232323232323232323232323232323232323",//salt
            "0x0000000000000000000000000000000000000000000000000000000000007381"//exponent
        );

        await rsa.connect(owner).deployPublicKey(
            "0xd40f7fe64e0016cf8453a8e58e132e9299486db45c1e7fe610fde645b3a28cd6ed27ea000ebd38584a054ad60c9b1407fde81fc17bf6664b4c789deca6edfea343884e1fbda8a1e0af987f6a95892431f4aa0a8549cc727ffda74dd74fd4f5bfb015ca6caafca163d9978455a8761a4a7005cd5cb654ad42d1aca97766af57e68006451a07237b3d36ddbc507dd120e73c4f291874ab332bd8d026768a60aa8eb3e47424a31b1c67f86a3da2bb59bed3ab471cc6dc3087ebca3cad128cc2ad0801f36aec45970b0a5beb2059d149fbfb2a41df49c74f4ce3d62d54b702c9b2bf9a5c2373d3dcd7973bfaa3d533241da809864512ef3203a7dfc9317326132bcb"
        );

        return { rsa, owner, user1 };
    }

    describe("Deployment", function () {
        it("TestToken returns name as expected", async function () {
            const { rsa, user1 } = await loadFixture(deployFixture);
            const gasEstimate = await rsa.connect(user1).estimateGas.verifySignature(
                "0x65ed20219898fd68244a9d1e562a11169f675d7cedb81408fca7c8e1b75e25c988172a5cc9f37f43a036dce135cba132374e5401015d44a26aca4381b00305a38e6940db816e8bc6a0d78d0ee98c5b0eaf1b4f30f01d180536f8817068047b6027128369a2c558bdbbab3f3ef868538d38bdd380838b0ae20773ac280818c520b7bb268f691b45b12502e09eebd015150de2d1c8a008ce637175c20d522f23d2a954e932c9f8f465ac704214226536ec081489413fe24a5405c284499386dd65e8f04bfb3c82aa822ed47593bc961a578d6de72b63e3f77217fc4964452a9ff11f953e7d0af5e081faefc38cac21a965a182928e84b8acb82fb0b747ca194611"
            );

            console.log(`gas estimate: ${gasEstimate}`);

            const verified = await rsa.connect(user1).verifySignature(
                "0x65ed20219898fd68244a9d1e562a11169f675d7cedb81408fca7c8e1b75e25c988172a5cc9f37f43a036dce135cba132374e5401015d44a26aca4381b00305a38e6940db816e8bc6a0d78d0ee98c5b0eaf1b4f30f01d180536f8817068047b6027128369a2c558bdbbab3f3ef868538d38bdd380838b0ae20773ac280818c520b7bb268f691b45b12502e09eebd015150de2d1c8a008ce637175c20d522f23d2a954e932c9f8f465ac704214226536ec081489413fe24a5405c284499386dd65e8f04bfb3c82aa822ed47593bc961a578d6de72b63e3f77217fc4964452a9ff11f953e7d0af5e081faefc38cac21a965a182928e84b8acb82fb0b747ca194611"
            );
            
            expect(verified).to.equal(true);
        });
    });
});
