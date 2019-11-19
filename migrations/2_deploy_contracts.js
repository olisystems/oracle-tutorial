const OracleContract = artifacts.require("OracleContract");

module.exports = function (deployer) {
    deployer.deploy(OracleContract);
};