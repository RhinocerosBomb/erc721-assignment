const BankWithChequing = artifacts.require('BankWithChequing');
const truffleAssert = require('truffle-assertions');

contract("Bank", async accounts => {
    it('Should withdraw and deposit eth', async () => {
        const BankInstance = await BankWithChequing.deployed();
        const initialBalance = await BankInstance.getEthBalance.call(accounts[0]);
        const amount = web3.utils.toWei('1', 'ether');
        assert(initialBalance.toString() === '0', 'Eth balance should start with 0');

        const depositTx = await BankInstance.deposit.sendTransaction({from: accounts[0], value: amount});

        truffleAssert.eventEmitted(depositTx, 'Deposit', ev => {
            return ev['accountOwner'].toString() === accounts[0].toString() && ev['amount'].toString() === amount
        }, 'Deposit failed');
      
        const balanceAfterDeposit = await BankInstance.getEthBalance.call(accounts[0]);
        assert(amount == balanceAfterDeposit.toString(), 'Balance should be 1 Eth');

        const withdrawTx = await BankInstance.withdraw.sendTransaction(amount, {from: accounts[0]});

        truffleAssert.eventEmitted(withdrawTx, 'Withdraw', ev => {
            return ev['accountOwner'].toString() === accounts[0].toString() && ev['amount'].toString() === amount;
        }, 'Withdraw failed');

        const balanceAfterWithdrawl = await BankInstance.getEthBalance.call(accounts[0]);

        assert(balanceAfterWithdrawl.toString() == '0', 'Balance should be 0');
    });
});
