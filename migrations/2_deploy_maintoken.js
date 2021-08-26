// const ConvertLib = artifacts.require("ConvertLib");
// const MetaCoin = artifacts.require("MetaCoin");

const MainToken = artifacts.require("KaijuToken");
module.exports = async function (deployer, network) {
    // console.log(network)
    if (network == "development" || network == "testnet") {

        await deployer.deploy(MainToken);
        const mainToken = MainToken.address;
    }
    if (network == "bsc") {
        // console.log("BSC")
        // tokenAddress = "0x6fB9D47EA4379CcF00A7dcb17E0a2C6C755a9b4b";
    }
   
};