'user strict';

const assertRevert = require('../helpers/assertRevert');

var AuditableTokenMock = artifacts.require('mocks/AuditableTokenMock.sol');

contract('AuditableToken', function (accounts) {
  let token;
  let beforeReceivedDate;
  let afterReceivedDate;
  let beforeSentDate;
  let afterSentDate;

  beforeEach(async function () {
    token = await AuditableTokenMock.new(accounts[0], 100);
    beforeReceivedDate = Math.floor((new Date()).getTime() / 1000);
    await token.transfer(accounts[1], 20);
    afterReceivedDate = Math.floor((new Date()).getTime() / 1000);
    beforeSentDate = afterReceivedDate;
    await token.approve(accounts[0], 100, { from: accounts[1] });
    await token.transferFrom(accounts[1], accounts[2], 10);
    afterSentDate = Math.floor((new Date()).getTime() / 1000);
    await assertRevert(token.transfer(accounts[1], 100));
    await assertRevert(token.transferFrom(accounts[1], accounts[2], 100));
  });

  it('should have createdAt account1', async function () {
    const createdAt = await token.auditCreatedAt(accounts[1]);
    assert.ok(createdAt.toNumber() <= beforeReceivedDate + 1, 'createdAt beforeReceivedDate');
    assert.ok(createdAt.toNumber() >= beforeSentDate, 'createdAt beforeSentDate');
  });

  it('should have last transaction time for account1', async function () {
    const lastTransactionAt = await token.lastTransactionAt(accounts[1]);
    assert.ok(lastTransactionAt.toNumber() <= afterSentDate + 1, 'lastTransactionAt afterSentData');
    assert.ok(lastTransactionAt.toNumber() >= beforeSentDate, 'lastTransactionAt');
  });

  it('should have last received time for account1', async function () {
    const lastReceivedAt = await token.lastReceivedAt(accounts[1]);
    assert.ok(lastReceivedAt.toNumber() >= beforeReceivedDate, 'lastReceivedAt');
  });

  it('should have last sent time for account1', async function () {
    const lastSentAt = await token.lastSentAt(accounts[1]);
    assert.ok(lastSentAt.toNumber() >= beforeSentDate, 'lastSentAt');
  });

  it('should have transaction count for account1', async function () {
    const count = await token.transactionCount(accounts[1]);
    assert.equal(count.toNumber(), 2, 'transactionCount');
  });

  it('should have received transaction count for account1', async function () {
    const count = await token.receivedCount(accounts[1]);
    assert.equal(count.toNumber(), 1, 'receivedCount');
  });

  it('should have sent transaction count for account1', async function () {
    const count = await token.sentCount(accounts[1]);
    assert.equal(count.toNumber(), 1, 'sentCount');
  });

  it('should have all time received for account1', async function () {
    const allTime = await token.totalReceivedAmount(accounts[1]);
    assert.equal(allTime.toNumber(), 20, 'totalReceivedAmount');
  });

  it('should have all time sent for account1', async function () {
    const allTime = await token.totalSentAmount(accounts[1]);
    assert.equal(allTime.toNumber(), 10, 'totalSentAmount');
  });
});
