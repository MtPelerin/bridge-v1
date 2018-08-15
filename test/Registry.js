'user strict';

const assertRevert = require('./helpers/assertRevert');

var Registry = artifacts.require('../contracts/Registry.sol');

contract('Registry', function (accounts) {
  let registry;

  beforeEach(async function () {
    registry = await Registry.new('MtPelerin', [accounts[1], accounts[2]]);

    const count = await registry.addressLength();
    assert.equal(count.toNumber(), 2, 'count');

    const address1 = await registry.addressById(0);
    assert.equal(address1, accounts[1], 'address1');

    const address2 = await registry.addressById(1);
    assert.equal(address2, accounts[2], 'address2');
  });

  it('should have a name', async function () {
    const name = await registry.name();
    assert.equal(name, 'MtPelerin');
  });

  it('should have a registry count', async function () {
    const count = await registry.addressLength();
    assert.equal(count.toNumber(), 2, 'count');
  });

  it('should return address by Id', async function () {
    let address = await registry.addressById(1); ;
    assert.equal(address, accounts[2], 'address');
  });

  it('should add address', async function () {
    await registry.addAddress(accounts[3]);

    const count = await registry.addressLength();
    assert.equal(count.toNumber(), 3, 'count');

    const address = await registry.addressById(2);
    assert.equal(address, accounts[3], 'address');
  });

  it('should log an event when added', async function () {
    const receipt = await registry.addAddress(accounts[5]);
    assert.equal(receipt.logs.length, 1);
    assert.equal(receipt.logs[0].event, 'AddressAdded');

    assert.equal(receipt.logs[0].args.id.toNumber(), 3);
    assert.equal(receipt.logs[0].args.newValue, accounts[5]);
  });

  it('should not remove address if not exist', async function () {
    await assertRevert(registry.removeAddressById(10));

    const count = await registry.addressLength();
    assert.equal(count.toNumber(), 2, 'count');
  });

  it('should remove address', async function () {
    await registry.removeAddressById(0);

    let count = await registry.addressLength();
    assert.equal(count.toNumber(), 1, 'count');

    const address = await registry.addressById(0);
    assert.equal(address, accounts[2], 'address');
 
    await registry.removeAddressById(0);

    count = await registry.addressLength();
    assert.equal(count.toNumber(), 0, 'count');
  });

  it('should log an event when removing', async function () {
    const receipt = await registry.removeAddressById(0);
    assert.equal(receipt.logs.length, 1);
    assert.equal(receipt.logs[0].event, 'AddressRemoved');

    assert.equal(receipt.logs[0].args.id.toNumber(), 0);
    assert.equal(receipt.logs[0].args.oldValue, accounts[1]);
  });

  it('should not replace address if id not exist', async function () {
    await assertRevert(registry.replaceAddressById(10, accounts[4]));
  });

  it('should replace address', async function () {
    await registry.replaceAddressById(0, accounts[5]);

    const count = await registry.addressLength();
    assert.equal(count.toNumber(), 2, 'count');
    
    const address1 = await registry.addressById(0);
    assert.equal(address1, accounts[5], 'address1');

    const address2 = await registry.addressById(1);
    assert.equal(address2, accounts[2], 'address2');
  });

  it('should log an event when replacing', async function () {
    const receipt = await registry.replaceAddressById(1, accounts[5]);
    assert.equal(receipt.logs.length, 1);
    assert.equal(receipt.logs[0].event, 'AddressReplaced');

    assert.equal(receipt.logs[0].args.id.toNumber(), 1);
    assert.equal(receipt.logs[0].args.newValue, accounts[5]);
    assert.equal(receipt.logs[0].args.oldValue, accounts[2]);
  });

  it('should not allow other than owner to add an address', async function () {
    await assertRevert(registry.addAddress(accounts[0], { from: accounts[4] }));
  });

  it('should not allow other than owner to replace an address', async function () {
    await assertRevert(registry.replaceAddressById(1, accounts[4], { from: accounts[1] }));
  });

  it('should not allow other than owner to remove address', async function () {
    await assertRevert(registry.removeAddressById(1, { from: accounts[1] }));
  });

  it('should replace many addresses', async function () {
    const tx = await registry.replaceManyAddressesByIds([ 0, 1 ], [ accounts[3], accounts[4] ]);
    assert.equal(tx.receipt.status, '0x01', 'status');
    assert.equal(tx.logs.length, 2);
    assert.equal(tx.logs[0].event, 'AddressReplaced');
    assert.equal(tx.logs[0].args.id.toNumber(), 0);
    assert.equal(tx.logs[0].args.newValue, accounts[3]);
    assert.equal(tx.logs[0].args.oldValue, accounts[1]);
    assert.equal(tx.logs[1].args.id.toNumber(), 1);
    assert.equal(tx.logs[1].args.newValue, accounts[4]);
    assert.equal(tx.logs[1].args.oldValue, accounts[2]);

    const length = await registry.addressLength();
    assert.equal(length, 2, 'length');
  });

  it('should not replace many addresses with 0 addresses', async function () {
    await assertRevert(registry.replaceManyAddressesByIds([], []));
  });

  it('should not replace many addresses with too few addresses', async function () {
    await assertRevert(registry.replaceManyAddressesByIds([ 0, 1 ], [ accounts[3] ]));
  });

  it('should not replace many addresses with too much addresses', async function () {
    await assertRevert(registry.replaceManyAddressesByIds([ 0, 1 ], [ accounts[3], accounts[4], accounts[5] ]));
  });
});
