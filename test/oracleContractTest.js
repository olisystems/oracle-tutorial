var OracleContract = artifacts.require('OracleContract')

contract('OracleContract', function (accounts) {
    const TEST_ORACLES_COUNT = 20;

    var oracleContract;
    before('setup contract', async () => {
        oracleContract = await OracleContract.deployed()
    });

    // 1st Test
    it("can register oracle", async () => {

        // get registrtion fee
        let fee = await oracleContract.REGISTRATION_FEE.call()

        for (let a = 1; a < TEST_ORACLES_COUNT; a++) {
            await oracleContract.registerOracle({ from: accounts[a], value: fee })
            let result = await oracleContract.getOracle.call(accounts[a], { from: accounts[0] })

            console.log(result[0].toNumber(), result[1].toNumber(), result[2].toNumber());
        }
    })
});