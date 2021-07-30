require("@nomiclabs/hardhat-waffle");

/**
 * @type import('hardhat/config').HardhatUserConfig
 */

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

module.exports = {
  solidity: "0.8.3",
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545",
      gasPrice: 1,
      skipDryRun: true
    },
    bscTestnet: {
      networkCheckTimeout: 12000,
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      network_id: 97,
      confirmations: 5,
      timeoutBlocks: 200,
      skipDryRun: true,
      accounts: ["c222256bf7b17a70295462cf2a5c47b5b2fc9dddfc8a33d45d24d28905b82e0d"]
    },
    bscMainnet: {
      networkCheckTimeout: 12000,
      url: "https://bsc-dataseed.binance.org/",
      network_id: 56,
      confirmations: 5,
      timeoutBlocks: 200,
      skipDryRun: true,
      accounts: ["124d8cdc94853cf9ae0886297228bb2142fd5eab0ed3f77edb30701666158578"]
    }
  },  
  settings: {
    optimizer: {
      enabled: true,
      runs: 1000,
    },
  },
};
