require("@nomicfoundation/hardhat-chai-matchers")
require("hardhat-gas-reporter")
require("@nomiclabs/hardhat-etherscan")
require("solidity-coverage")
require("hardhat-deploy")

module.exports = {
    defaultNetwork: "goerli",
    networks: {
        hardhat: {
            chainId: 31337,
        },
        goerli: {
            url: "https://eth-goerli.g.alchemy.com/v2/YHdnX43tJdX_ySXJAyo8yVI7mZdiW5Cs",
            accounts: ["5f1a95bfbfe7aec9cf3d05fe47f4fcbbc4f0707a21b7ebd7f515a58559b4ecde"],
            chainId: 5,
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
