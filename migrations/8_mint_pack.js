const KaijuRouter = artifacts.require("KaijuRouter");
const PackSeller = artifacts.require("PackSeller");

const Factory = artifacts.require("Factory");
const KaijuFT = artifacts.require("KaijuFT");
module.exports = async function (deployer) {
    var amounts = [
        0,
        0, 4000, 2500, 2000, 2000
    ]
    var factory = await Factory.deployed();
    var kaijuPack = await KaijuFT.at(await factory.getFTContract("PACK"));
    var seller = await PackSeller.deployed();
    for (var i = 0; i < amounts.length; i++) {
        if (amounts[i] > 0) {
            await kaijuPack.mintByOwner(seller.address, i, amounts[i]);
        }
    }
  
}