require("@nomiclabs/hardhat-waffle");
require("dotenv").config();

const PRIVATE_KEY = process.env.PRIVATE_KEY;
const INFURA_PROJECT_ID = process.env.INFURA_PROJECT_ID;
const MORALIS_PROJECT_ID = process.env.MORALIS_PROJECT_ID;

module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      chainId: 4,
    },
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/1ea58fa1a6d74295b39bd860fb84bb39`,
      accounts: [PRIVATE_KEY],
    },
    mainnet: {
      url: `https://mainnet.infura.io/v3/${INFURA_PROJECT_ID}`,
      accounts: [PRIVATE_KEY],
    },
    BSC_MAINNET: {
      url: `https://speedy-nodes-nyc.moralis.io/${MORALIS_PROJECT_ID}/bsc/mainnet/archive`,
      accounts: [PRIVATE_KEY],
    },
    BSC_TESTNET: {
      url: `https://speedy-nodes-nyc.moralis.io/${MORALIS_PROJECT_ID}/bsc/testnet`,
      accounts: [PRIVATE_KEY],
    },
    POLYGON_MAINNET: {
      url: `https://speedy-nodes-nyc.moralis.io/${MORALIS_PROJECT_ID}/polygon/mainnet/archive`,
      accounts: [PRIVATE_KEY],
    },
    POLYGON_TESTNET: {
      url: `https://speedy-nodes-nyc.moralis.io/${MORALIS_PROJECT_ID}/polygon/mainnet/archive`,
      accounts: [PRIVATE_KEY],
    },
  },
  solidity: {
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
        runs: 500,
      },
    },
  },
};
