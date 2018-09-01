'user strict';

const assertRevert = require('./helpers/assertRevert');

var AuthorityMock = artifacts.require('../contracts/AuthorityMock.sol');

contract('Authority', function (accounts) {
  let authority;
  const authorityAddress = accounts[2];

  beforeEach(async function () {
    authority = await AuthorityMock.new();
  });

  it('should have no authority', async function () {
    const authorityCheck = await authority.authorityAddress('REGULATOR');
    assert.equal(authorityCheck, '0x0000000000000000000000000000000000000000');
  });

  it('should allow owner to set a new authority', async function () {
    const tx = await authority.defineAuthority('REGULATOR', authorityAddress);
    assert.equal(tx.receipt.status, '0x01', 'status');
    assert.equal(tx.logs.length, 1);
    assert.equal(tx.logs[0].event, 'AuthorityDefined');
    assert.equal(tx.logs[0].args.name, 'REGULATOR');
    assert.equal(tx.logs[0].args._address, authorityAddress);
  });

  describe('with authorities defined', function () {
    beforeEach(async function () {
      await authority.defineAuthority('REGULATOR', authorityAddress);
      await authority.defineAuthority('LEGAL1', accounts[1]);
    });

    it('should allow authority through onlyAuthority modifier', async function () {
      await authority.testOnlyAuthority('REGULATOR', { from: accounts[2] });
    });

    it('should not allow another authority through onlyAuthority modifier', async function () {
      await assertRevert(authority.testOnlyAuthority('REGULATOR', { from: accounts[1] }));
    });
     
    it('should not allow non authority through onlyAuthority modifier', async function () {
      await assertRevert(authority.testOnlyAuthority('REGULATOR'));
    });
  });
});
