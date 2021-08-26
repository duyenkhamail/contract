// const ConvertLib = artifacts.require("ConvertLib");
// const MetaCoin = artifacts.require("MetaCoin");

const { deployProxy } = require('@openzeppelin/truffle-upgrades');
const KaijuFT = artifacts.require("KaijuFT");
const KaijuRouter = artifacts.require("KaijuRouter");
const Factory = artifacts.require("Factory");
module.exports = async function (deployer) {
    var ftBaseUri = "https://data.kaijuworlds.io/ft/";
    var fts = [
        "AVATAR",
        "TOKEN_CARD",
        "PACK",
        "SKILL_BASE"
    ];
    var factory = await Factory.deployed();
    var router = await KaijuRouter.deployed();
    for (var i = 0; i < fts.length; i++) {
        var oldAddress = await factory.getFTContract(fts[i]);
        if (oldAddress == "0x0000000000000000000000000000000000000000") {
            var ft = await deployProxy(KaijuFT, [ftBaseUri, fts[i]], { deployer });
            await factory.setFTContract(fts[i], ft.address);
            await ft.grantRouter(router.address);
        }

    }


};