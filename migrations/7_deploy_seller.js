const { deployProxy } = require('@openzeppelin/truffle-upgrades');
const KaijuRouter = artifacts.require("KaijuRouter");
const PackSeller = artifacts.require("PackSeller");
const Factory = artifacts.require("Factory");
const KaijuFT = artifacts.require("KaijuFT");
module.exports = async function (deployer) {
    var amounts = [0,0, 1600, 1000, 800, 800];

    var prices = ["0","0","172000000000000000", "242000000000000000","382000000000000000","1042000000000000000"]
    var startTime = 1630339200;
    
    var router = await KaijuRouter.deployed();

    var factory = await Factory.deployed();
    var kaijuPack = await KaijuFT.at(await factory.getFTContract("PACK"));
    await deployProxy(PackSeller, [prices, amounts, kaijuPack.address, startTime, KaijuRouter.address], {deployer});

    await router.setSellerAddress(PackSeller.address);
    
    // console.log(PackSeller.address);
    for (var i = 0; i < amounts.length; i++) {
        if (amounts[i] > 0) {
            await kaijuPack.mintByOwner(PackSeller.address,i, amounts[i]);
        }
    }
}