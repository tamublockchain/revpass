require("@nomicfoundation/hardhat-chai-matchers")
require("hardhat-gas-reporter")
require("@nomiclabs/hardhat-etherscan")
require("solidity-coverage")
require("hardhat-deploy")

module.exports = {
    defaultNetwork: "hardhat",
    networks: {
        hardhat: {
            chainId: 31337,
        },
    },
    solidity: {
        compilers: [
            {
                version: "0.8.7",
                settings: {
                    optimizer: {
                        enabled: false,
                        runs: 1000,
                    },
                },
            },
            {
                version: "0.6.6",
            },
            {
                version: "0.8.4",
            },
            {
                version: "0.8.0",
            },
            {
                version: "0.8.15",
            },
        ],
    },
    etherscan: {
        apiKey: "",
    },
    gasReporter: {
        enabled: true,
        currency: "USD",
        outputFile: "gas-report.txt",
        noColors: true,
        token: "ETH",
    },
    namedAccounts: {
        deployer: {
            default: 0, // here this will by default take the first account as deployer
            1: 0, // similarly on mainnet it will take the first account as deployer. Note though that depending on how hardhat network are configured, the account 0 on one network can be different than on another
        },
        user1: {
            default: 1,
        },
        user2: {
            default: 2,
        },
    },
    mocha: {
        timeout: 400000, // 400 seconds max for running tests
    },
}
