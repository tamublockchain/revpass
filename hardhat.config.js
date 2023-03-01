require("@nomicfoundation/hardhat-chai-matchers")
require("hardhat-gas-reporter")
require("@nomiclabs/hardhat-etherscan")
require("dotenv").config()
require("solidity-coverage")
require("hardhat-deploy")

const GOERLI_RPC_URL =
    process.env.GOERLI_RPC_URL || "https://eth-goerli.alchemyapi.io/v2/your-api-key"
const PRIVATE_KEY = process.env.PRIVATE_KEY || ""
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || ""
const MAINNET_RPC_URL = process.env.MAINNET_RPC_URL || ""

module.exports = {
    defaultNetwork: "hardhat",
    networks: {
        hardhat: {
            chainId: 31337,
            gasPrice: 22000000000, //22 Gwei
            blockConfirmations: 1,
        },
        goerli: {
            url: GOERLI_RPC_URL,
            accounts: [PRIVATE_KEY],
            chainId: 5,
            blockConfirmations: 6,
        },
        mainnet: {
            url: MAINNET_RPC_URL,
            accounts: [PRIVATE_KEY],
            chainId: 1,
            blockConfirmations: 6,
            gasPrice: 17000000000,
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
        ],
    },
    etherscan: {
        apiKey: ETHERSCAN_API_KEY,
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