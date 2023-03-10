module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()

    log("----------------------------------------------------")
    log("Deploying MainPass and waiting for confirmations...")
    const name = "SportsPass"
    const symbol = "REV"
    const supply = "1000"
    const args = [name, symbol, supply]
    const Lottery = await deploy("MainPass", {
        from: deployer,
        args: args,
        log: true,
        // we need to wait if on a live network so we can verify properly
        waitConfirmations: network.config.blockConfirmations || 1,
    })
}
module.exports.tags = ["all", "mainpass"]
