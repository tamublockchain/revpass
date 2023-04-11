module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()

    log("----------------------------------------------------")
    log("Deploying MainPass and waiting for confirmations...")
    const name = "RevPass"
    const symbol = "REV"
    const supply = "1000"
    const args = [name, symbol, supply]
    const Lottery = await deploy("RevPass", {
        from: deployer,
        args: args,
        log: true,
        // we need to wait if on a live network so we can verify properly
        waitConfirmations: network.config.blockConfirmations || 1,
    })
    const Lotto = await deploy("Marketplace", {
        from: deployer,
        log: true,
        // we need to wait if on a live network so we can verify properly
        waitConfirmations: network.config.blockConfirmations || 1,
        })
}
module.exports.tags = ["all", "revpass"]

