const { deployProxy } = require('@openzeppelin/truffle-upgrades');
const Marketplace = artifacts.require("Marketplace");
const KaijuRouter = artifacts.require("KaijuRouter");
const KaijuToken = artifacts.require("KaijuToken");
module.exports = async function (deployer, network) {
    await deployProxy(Marketplace, [KaijuRouter.address], {deployer});
    var marketplace = await Marketplace.deployed();
    var tokenAddress = "";
    if(network=="development"||network=="testnet"){
        tokenAddress = KaijuToken.address;
    }
    if(network=="bsc"){
        tokenAddress = "0x6fB9D47EA4379CcF00A7dcb17E0a2C6C755a9b4b";
    }
    await marketplace.setKaijuToken(tokenAddress);
    // await marketplace.setFeeReceivers();
}