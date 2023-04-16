require("dotenv").config();
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomiclabs/hardhat-ethers";

const config: HardhatUserConfig = {
  solidity: "0.8.18",
  networks: {
    mumbai: {
      url: process.env.TESTNET_ALCHEMY_URL,
      accounts: [process.env.TESTNET_PRIVATE_KEY],
    },
    mainnet: {
      url: process.env.MAINNET_ALCHEMY_URL,
      accounts: [process.env.MAINNET_PRIVATE_KEY],
    },
  },
};

export default config;
