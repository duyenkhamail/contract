// const ConvertLib = artifacts.require("ConvertLib");
// const MetaCoin = artifacts.require("MetaCoin");
const { deployProxy } = require('@openzeppelin/truffle-upgrades');
const Eggs = artifacts.require("Eggs.sol");
const KaijuRouter = artifacts.require("KaijuRouter");
const Factory = artifacts.require("Factory");
module.exports = async function (deployer) {

    var kaijuRouter = await KaijuRouter.deployed();

    var factory = await deployProxy(Factory, [KaijuRouter.address], {deployer});
    await kaijuRouter.setFactory(factory.address);
    await factory.setFTContract("EGG", Eggs.address);
   
};