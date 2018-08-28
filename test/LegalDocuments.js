'user strict';

const assertRevert = require('./helpers/assertRevert');

var LegalDocuments = artifacts.require('../contracts/LegalDocuments.sol');

contract('LegalDocuments', function (accounts) {
  let legalDocuments;

  beforeEach(async function () {
    legalDocuments = await LegalDocuments.new('http://repo.url');
  });

  it('should have a repositoryURL', async function () {
    const repositoryURL = await legalDocuments.repositoryURL();
    assert.equal(repositoryURL, 'http://repo.url', 'repositoryURL');
  });

  it('should let update repositoryURL', async function () {
    const tx = await legalDocuments.updateRepositoryURL('http://repo2.url');
    assert.equal(tx.receipt.status, '0x01', 'success');

    const repositoryURL = await legalDocuments.repositoryURL();
    assert.equal(repositoryURL, 'http://repo2.url', 'repositoryURL');
  });

  it('should prevent update of repositoryURL from non owner', async function () {
    await assertRevert(legalDocuments.updateRepositoryURL('toto', { from: accounts[1] }));
  });

  it('should have 0 documents for itself', async function () {
    const documentsCount = await legalDocuments.documentsCount(legalDocuments.address);
    assert.equal(documentsCount, 0, '0 documents');
  });

  it('should have no name for itself', async function () {
    const name = await legalDocuments.documentName(legalDocuments.address, 0);
    assert.equal(name, '', 'no name');
  });

  it('should have no hash for itself', async function () {
    const hash = await legalDocuments.documentHash(legalDocuments.address, 0);
    assert.equal(hash, '0x0000000000000000000000000000000000000000000000000000000000000000', 'no hash');
  });

  it('should have version 0 for document 0 and itself', async function () {
    const version = await legalDocuments.documentVersion(legalDocuments.address, 0);
    assert.equal(version, 0, 'no version');
  });

  it('should not be active for document 0 and itself', async function () {
    const active = await legalDocuments.documentIsValid(legalDocuments.address, 0);
    assert.ok(!active, 'not active');
  });

  it('should allow to add a document on itself', async function () {
    const tx = await legalDocuments.addDocument(legalDocuments.address, 'aName', '0x001');
    assert.equal(tx.receipt.status, '0x01', 'success');
    assert.equal(tx.logs.length, 1, '1 event');
    assert.equal(tx.logs[0].event, 'DocumentAdded');
    assert.equal(tx.logs[0].args._address, legalDocuments.address, 'contract address');
    assert.equal(tx.logs[0].args.id, 0, 'id');
    assert.equal(tx.logs[0].args.name, 'aName', 'name');
    assert.equal(tx.logs[0].args.hash, '0x0010000000000000000000000000000000000000000000000000000000000000', 'hash');
  });

  it('should not allow to add a document on addresss 0', async function () {
    await assertRevert(legalDocuments.addDocument(
      '0x0000000000000000000000000000000000000000000000000000000000000000',
      'aName',
      '0x001'));
  });

  it('should not allow to add a document with no names', async function () {
    await assertRevert(legalDocuments.addDocument(
      legalDocuments.address,
      '',
      '0x001'));
  });

  it('should not allow too add a document with no hashes', async function () {
    await assertRevert(legalDocuments.addDocument(
      legalDocuments.address,
      'aName',
      ''));
  });

  it('should not allow to add a document on itself by not owner', async function () {
    await assertRevert(legalDocuments.addDocument(legalDocuments.address, 'aName', 'aHash', { from: accounts[1] }));
  });

  it('should not let updating non existing document', async function () {
    await assertRevert(legalDocuments.updateDocument(legalDocuments.address, 0, 'aName', 'aHash'));
  });

  it('should not allow to invalidate non existing document', async function () {
    await assertRevert(legalDocuments.invalidateDocument(legalDocuments.address, 0));
  });

  describe('with three documents defined for two contracts', function () {
    beforeEach(async function () {
      await legalDocuments.addDocument(accounts[8], 'aName0', '0x00001');
      await legalDocuments.addDocument(accounts[8], 'aName1', '0x00002');
      await legalDocuments.addDocument(accounts[9], 'aName2', '0x00003');
    });

    it('should have documents count for the two contracts', async function () {
      const countAccount8 = await legalDocuments.documentsCount(accounts[8]);
      assert.equal(countAccount8, 2);
      const countAccount9 = await legalDocuments.documentsCount(accounts[9]);
      assert.equal(countAccount9, 1);
    });

    it('should have a name for a document', async function () {
      const name = await legalDocuments.documentName(accounts[8], 1);
      assert.equal(name, 'aName1', 'name');
    });

    it('should have a hash for a document', async function () {
      const hash = await legalDocuments.documentHash(accounts[8], 1);
      assert.equal(hash, '0x0000200000000000000000000000000000000000000000000000000000000000', 'hash');
    });

    it('should have a version for a document', async function () {
      const version = await legalDocuments.documentVersion(accounts[8], 1);
      assert.equal(version, 0, 'version');
    });

    it('should have a document valid', async function () {
      const valid = await legalDocuments.documentIsValid(accounts[9], 0);
      assert.ok(valid, 'valid');
    });

    it('should allow update a document', async function () {
      const tx = await legalDocuments.updateDocument(accounts[8], 1, 'aNameUpdated', '0x000001234');
      assert.equal(tx.receipt.status, '0x01', 'success');
      assert.equal(tx.logs.length, 1, '1 event');
      assert.equal(tx.logs[0].event, 'DocumentUpdated');
      assert.equal(tx.logs[0].args._address, accounts[8], 'contract address');
      assert.equal(tx.logs[0].args.id, 1, 'id');
      assert.equal(tx.logs[0].args.name, 'aNameUpdated', 'name');
      assert.equal(tx.logs[0].args.hash, '0x0000012340000000000000000000000000000000000000000000000000000000', 'hash');
      assert.equal(tx.logs[0].args.version, 1, 'version');
    });

    it('should prevent update a document from non owner', async function () {
      await assertRevert(legalDocuments.updateDocument(accounts[8], 1, '', '', { from: accounts[1] }));
    });

    it('should allow invalidate a document', async function () {
      const tx = await legalDocuments.invalidateDocument(accounts[9], 0);
      assert.equal(tx.receipt.status, '0x01', 'success');
      assert.equal(tx.logs.length, 1, '1 event');
      assert.equal(tx.logs[0].event, 'DocumentInvalidated');
      assert.equal(tx.logs[0].args._address, accounts[9], 'contract address');
      assert.equal(tx.logs[0].args.id, 0, 'id');
    });

    it('should prevent invalidate a document from a non owner', async function () {
      await assertRevert(legalDocuments.invalidateDocument(accounts[9], 1, { from: accounts[1] }));
    });

    describe('and one document invalid', function () {
      beforeEach(async function () {
        await legalDocuments.invalidateDocument(accounts[8], 0);
      });

      it('document should be invalid', async function () {
        const valid = await legalDocuments.documentIsValid(accounts[8], 0);
        assert.ok(!valid, 'invalid');
      });

      it('document should become valid after update', async function () {
        await legalDocuments.updateDocument(accounts[8], 0, 'aName', '0x0001');
        const valid = await legalDocuments.documentIsValid(accounts[8], 0);
        assert.ok(valid, 'valid');
      });
    });
  });
});
