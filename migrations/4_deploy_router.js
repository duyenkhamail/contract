
const Eggs = artifacts.require("Eggs.sol");
const KaijuToken = artifacts.require("KaijuToken");
const KaijuRouter = artifacts.require("KaijuRouter");
const KaijuDatabase = artifacts.require("KaijuDatabase");
const Factory = artifacts.require("Factory");

const { deployProxy } = require('@openzeppelin/truffle-upgrades');
module.exports = async function (deployer,network) {
    var databaseInstance = await KaijuDatabase.deployed();

    var tokenAddress = "";
    if(network=="development"||network=="testnet"){
        tokenAddress = KaijuToken.address;
    }
    if(network=="bsc"){
        tokenAddress = "0x6fB9D47EA4379CcF00A7dcb17E0a2C6C755a9b4b";
    }
    await deployProxy(KaijuRouter, [tokenAddress, KaijuDatabase.address], {deployer});
    var kaijuRouter = await KaijuRouter.deployed();
    
    var eggInstance = await Eggs.deployed();
    var databaseInstance = await KaijuDatabase.deployed();
    await eggInstance.grantRouter(KaijuRouter.address);
   
    await kaijuRouter.setStakingContractAddress("0x0CFa0e0603fCA9D0699B93AC9E1fAAa070cb8b7C");
};