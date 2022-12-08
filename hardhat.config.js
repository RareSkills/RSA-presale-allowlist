require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-ethers");
require("hardhat-gas-reporter");

module.exports = {
  solidity: "0.8.17",
  settings: {
    optimizer: {
      enabled: true,
      runs: 1000000,
    },
  },
  networks: {
    /* For live deployment see 
        https://hardhat.org/tutorial/deploying-to-a-live-network *
    */
  },
};
