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
  },
  settings: {
    optimizer: {
      enabled: true,
      runs: 1000,
    },
  },
};
