'user strict';

var YesNoRule = artifacts.require('../../contracts/rule/YesNoRule.sol');

contract('YesNoRule', function (accounts) {
  it('should have all addresses valid with a Yes Rule', async function () {
    const rule = await YesNoRule.new(true);

    const account0IsValid = await rule.isAddressValid(accounts[0]);
    assert.ok(account0IsValid, 'account 0 valid');

    const account1IsValid = await rule.isAddressValid(accounts[1]);
    assert.ok(account1IsValid, 'account 1 valid');
  });

  it('should have all addresses invalid with a No Rule', async function () {
    const rule = await YesNoRule.new(false);

    const account0IsValid = await rule.isAddressValid(accounts[0]);
    assert.ok(!account0IsValid, 'account 0 invalid');

    const account1IsValid = await rule.isAddressValid(accounts[1]);
    assert.ok(!account1IsValid, 'account 1 invalid');
  });

  it('should have all transfers valid with a Yes Rule', async function () {
    const rule = await YesNoRule.new(true);

    const account01IsValid = await rule.isTransferValid(accounts[0], accounts[1], 10);
    assert.ok(account01IsValid, 'transfer 0 to 1 valid');

    const account12IsValid = await rule.isTransferValid(accounts[1], accounts[2], 10);
    assert.ok(account12IsValid, 'transfer 1 to 2 valid');
 
    const account10IsValid = await rule.isTransferValid(accounts[1], accounts[0], 10);
    assert.ok(account10IsValid, 'transfer 1 to 0 valid');
  });

  it('should have all transfers invalid with a No Rule', async function () {
    const rule = await YesNoRule.new(false);

    const account01IsValid = await rule.isTransferValid(accounts[0], accounts[1], 10);
    assert.ok(!account01IsValid, 'transfer 0 to 1 valid');

    const account12IsValid = await rule.isTransferValid(accounts[1], accounts[2], 10);
    assert.ok(!account12IsValid, 'transfer 1 to 2 valid');
 
    const account10IsValid = await rule.isTransferValid(accounts[1], accounts[0], 10);
    assert.ok(!account10IsValid, 'transfer 1 to 0 valid');
  });
});
