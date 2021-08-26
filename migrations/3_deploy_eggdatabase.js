// const ConvertLib = artifacts.require("ConvertLib");
// const MetaCoin = artifacts.require("MetaCoin");
const { deployProxy } = require('@openzeppelin/truffle-upgrades');
var mixing = require("../data/mix.json");
const Eggs = artifacts.require("Eggs.sol");
const KaijuDatabase = artifacts.require("KaijuDatabase");
module.exports = async function (deployer) {
    var x = [];
    var y = [];
    var data = [];
    for (var i = 0; i < mixing.length; i++) {
        var item = mixing[i];
        x.push(item.egg_1);
        y.push(item.egg_2);
        data.push(item.result);
    }

    var ftBaseUri = "https://data.kaijuworlds.io/ft/";
    var database = await deployProxy(KaijuDatabase, [x, y, data],{deployer} );
    var egg = await deployProxy(Eggs, [ftBaseUri],{deployer, initializer:'initializeEgg'} );
    
   
};