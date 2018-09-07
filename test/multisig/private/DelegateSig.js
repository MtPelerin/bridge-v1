'user strict';

const assertRevert = require('../../helpers/assertRevert');

var DelegateSig = artifacts.require('../contracts/mock/DelegateSigMock.sol');
var StandardTokenMock = artifacts.require('mock/StandardTokenMock.sol');

contract('DelegateSig', function (accounts) {
  let delegateSig;
  let token, request1, request2, request3;

  let sign = async function (address) {
    const hash = await delegateSig.replayProtection();
    const signedHash = web3.eth.sign(address, hash);

    return {
      r: '0x' + signedHash.slice(2).slice(0, 64),
      s: '0x' + signedHash.slice(2).slice(64, 128),
      v: web3.toDecimal(signedHash.slice(2).slice(128, 130)),
    };
  };

  describe('with one address and a threshold of 1', function () {
    beforeEach(async function () {
      delegateSig = await DelegateSig.new([ accounts[1] ], 1);
      token = await StandardTokenMock.new(delegateSig.address, 1000);
      await token.approve(accounts[0], 500);
      request1 = token.transfer.request(accounts[0], 100);
      request2 = token.approve.request(accounts[1], 500);
      request3 = token.transferFrom.request(delegateSig.address, accounts[0], 100);
    });

    it('should review signatures', async function () {
      const rsv = await sign(accounts[1]);
      const review = await delegateSig.reviewSignatures(
        [ rsv.r ], [ rsv.s ], [ rsv.v ]);
      assert.equal(review.toNumber(), 1);
    });

    it('should have no grants not defined', async function () {
      const grantsDefined = await delegateSig.grantsDefined();
      assert.ok(!grantsDefined, 'grantsDefined');
    });

    it('should have no grant delegates', async function () {
      const grantDelegates = await delegateSig.grantDelegates(
        request1.params[0].to,
        request1.params[0].data.substring(0, 10));
      assert.deepEqual(grantDelegates, [], 'grant delegates');
    });

    it('should have no grant threshold', async function () {
      const grantThreshold = await delegateSig.grantThreshold(
        request1.params[0].to,
        request1.params[0].data.substring(0, 10)
      );
      assert.equal(grantThreshold, 0, 'no threshold');
    });

    it('should not be possible to add grant without signers', async function () {
      await assertRevert(delegateSig.addGrant(
        [], [], [],
        request1.params[0].to,
        request1.params[0].data.substring(0, 10),
        accounts, 3
      ));
    });

    it('should not be possible to add grant with wrong signers', async function () {
      const rsv1 = await sign(accounts[2]);
      await assertRevert(delegateSig.addGrant(
        [ rsv1.r ], [ rsv1.s ], [ rsv1.v ],
        request1.params[0].to,
        request1.params[0].data.substring(0, 10),
        accounts, 3
      ));
    });

    it('should be possible to add grant', async function () {
      const signer = await sign(accounts[1]);
      const tx = await delegateSig.addGrant(
        [ signer.r ], [ signer.s ], [ signer.v ],
        request1.params[0].to,
        request1.params[0].data.substring(0, 10),
        accounts, 3
      );
      assert.equal(tx.receipt.status, '0x01', 'status');
      assert.equal(tx.logs.length, 0);
    });

    it('should not be possible to end defintion without signers', async function () {
      await assertRevert(delegateSig.endDefinition(
        [ ], [ ], [ ]));
    });

    it('should not be possible to end defintion with wrong signers', async function () {
      const rsv1 = await sign(accounts[2]);
      await assertRevert(delegateSig.endDefinition(
        [ rsv1.r ], [ rsv1.s ], [ rsv1.v ]));
    });

    it('should be possible to end defintion', async function () {
      const signer = await sign(accounts[1]);
      const tx = await delegateSig.endDefinition(
        [ signer.r ], [ signer.s ], [ signer.v ]);
      assert.equal(tx.receipt.status, '0x01', 'status');
      assert.equal(tx.logs.length, 0);
    });

    it('should not be possible to executeOnBehalf', async function () {
      const rsv1 = await sign(accounts[2]);
      await assertRevert(delegateSig.executeOnBehalf(
        [ rsv1.r ], [ rsv1.s ], [ rsv1.v ],
        request1.params[0].to, 0, request1.params[0].data)
      );
    });

    describe('with two grants defined', function () {
      beforeEach(async function () {
        const signer1 = await sign(accounts[1]);
        await delegateSig.addGrant(
          [ signer1.r ], [ signer1.s ], [ signer1.v ],
          request1.params[0].to,
          request1.params[0].data.substring(0, 10),
          [ accounts[2], accounts[3] ], 1
        );
        const signer2 = await sign(accounts[1]);
        await delegateSig.addGrant(
          [ signer2.r ], [ signer2.s ], [ signer2.v ],
          request2.params[0].to,
          request2.params[0].data.substring(0, 10),
          [ accounts[2], accounts[4], accounts[5] ], 2
        );
      });

      it('should have grant delegates', async function () {
        const grantDelegates = await delegateSig.grantDelegates(
          request1.params[0].to,
          request1.params[0].data.substring(0, 10));
        assert.deepEqual(grantDelegates, [ accounts[2], accounts[3] ], 'grant delegates');
      });

      it('should have grant threshold', async function () {
        const grantThreshold = await delegateSig.grantThreshold(
          request1.params[0].to,
          request1.params[0].data.substring(0, 10)
        );
        assert.equal(grantThreshold, 1, 'threshold');
      });

      it('should be possible to add grant', async function () {
        const signer3 = await sign(accounts[1]);
        const tx = await delegateSig.addGrant(
          [ signer3.r ], [ signer3.s ], [ signer3.v ],
          request3.params[0].to,
          request3.params[0].data.substring(0, 10),
          accounts, 3
        );
        assert.equal(tx.receipt.status, '0x01', 'status');
        assert.equal(tx.logs.length, 0);
      });

      it('should not be possible to executeOnBehalf', async function () {
        const rsv1 = await sign(accounts[2]);
        await assertRevert(delegateSig.executeOnBehalf(
          [ rsv1.r ], [ rsv1.s ], [ rsv1.v ],
          request1.params[0].to, 0, request1.params[0].data)
        );
      });

      describe('with two grants defined and definition ended', function () {
        beforeEach(async function () {
          const signer3 = await sign(accounts[1]);
          await delegateSig.endDefinition(
            [ signer3.r ], [ signer3.s ], [ signer3.v ]);
        });

        it('should no be possible to end definition twice', async function () {
          const signer4 = await sign(accounts[1]);
          await assertRevert(delegateSig.endDefinition(
            [ signer4.r ], [ signer4.s ], [ signer4.v ]));
        });

        it('should not be possible to add grant', async function () {
          const signer4 = await sign(accounts[1]);
          await assertRevert(delegateSig.addGrant(
            [ signer4.r ], [ signer4.s ], [ signer4.v ],
            request3.params[0].to,
            request3.params[0].data.substring(0, 10),
            accounts, 3
          ));
        });

        it('should not be possible to executeOnBehalf with incorrect delegates', async function () {
          const rsv1 = await sign(accounts[4]);
          await assertRevert(delegateSig.executeOnBehalf(
            [ rsv1.r ], [ rsv1.s ], [ rsv1.v ],
            request1.params[0].to, 0, request1.params[0].data)
          );
        });

        it('should not be possible to executeOnBehalf with insufficient delegates', async function () {
          const rsv1 = await sign(accounts[2]);
          await assertRevert(delegateSig.executeOnBehalf(
            [ rsv1.r ], [ rsv1.s ], [ rsv1.v ],
            request2.params[0].to, 0, request2.params[0].data)
          );
        });

        it('should be possible to executeOnBehalf with grant1', async function () {
          const rsv1 = await sign(accounts[2]);
          const tx = await delegateSig.executeOnBehalf(
            [ rsv1.r ], [ rsv1.s ], [ rsv1.v ],
            request1.params[0].to, 0, request1.params[0].data);
          assert.equal(tx.receipt.status, '0x01', 'status');
          assert.equal(tx.logs.length, 1, 'logs');
          assert.equal(tx.logs[0].event, 'Execution');
          assert.equal(tx.logs[0].args.to, token.address, 'to');
          assert.equal(tx.logs[0].args.value, 0, 'value');
          assert.equal(tx.logs[0].args.data, request1.params[0].data, 'data');
        });

        it('should be possible to executeOnBehalf with grant2', async function () {
          const rsv1 = await sign(accounts[2]);
          const rsv2 = await sign(accounts[4]);
          const tx = await delegateSig.executeOnBehalf(
            [ rsv1.r, rsv2.r ], [ rsv1.s, rsv2.s ], [ rsv1.v, rsv2.v ],
            request2.params[0].to, 0, request2.params[0].data);
          assert.equal(tx.receipt.status, '0x01', 'status');
          assert.equal(tx.logs.length, 1, 'logs');
          assert.equal(tx.logs[0].event, 'Execution');
          assert.equal(tx.logs[0].args.to, token.address, 'to');
          assert.equal(tx.logs[0].args.value, 0, 'value');
          assert.equal(tx.logs[0].args.data, request2.params[0].data, 'data');
        });
      });
    });
  });
});
