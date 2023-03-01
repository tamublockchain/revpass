const { ethers } = require("hardhat")

const networkConfig = {
    31337: {
        name: "hardhat",
    },
    5: {
        name: "goerli",
    },
    1: {
        name: "mainnet",
    },
}

const developmentChains = ["hardhat", "localhost"]

module.exports = {
    networkConfig,
    developmentChains,
}
