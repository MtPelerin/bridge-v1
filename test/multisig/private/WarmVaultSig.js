'user strict';

const assertRevert = require('../../helpers/assertRevert');

var WarmVaultSig = artifacts.require('../contracts/multisig/private/WarmVaultSig.sol');
var StandardTokenMock = artifacts.require('mock/StandardTokenMock.sol');

contract('WarmVaultSig', function (accounts) {
  let warmVaultSig;
  let token;
  let request1;

  let sign = async function (address) {
    const hash = await warmVaultSig.replayProtection();
    const signedHash = web3.eth.sign(address, hash);

    return {
      r: '0x' + signedHash.slice(2).slice(0, 64),
      s: '0x' + signedHash.slice(2).slice(64, 128),
      v: web3.toDecimal(signedHash.slice(2).slice(128, 130)),
    };
  };

  describe('with one address and threshold of 1 and 2 delegates', function () {
    beforeEach(async function () {
      warmVaultSig = await WarmVaultSig.new([ accounts[1] ], 1);
      token = await StandardTokenMock.new(warmVaultSig.address, 100000000);
      request1 = token.transfer.request(accounts[0], 100);
      const signer1 = await sign(accounts[1]);
      await warmVaultSig.addGrant(
        [ signer1.r ], [ signer1.s ], [ signer1.v ],
        request1.params[0].to,
        request1.params[0].data.substring(0, 10),
        [ accounts[2], accounts[3] ], 1);
      await warmVaultSig.endDefinition(
        [ signer1.r ], [ signer1.s ], [ signer1.v ]);
    });

    it('it should have allowances not be defined', async function () {
      const allowancesDefined = await warmVaultSig.allowancesDefined();
      assert.ok(!allowancesDefined, 'Allowances defined');
    });

    it('it should have 0 eth allowance limit', async function () {
      const ethAllowanceLimit = await warmVaultSig.ethAllowanceLimit();
      assert.equal(ethAllowanceLimit.toNumber(), 0, 'eth allowance limit');
    });

    it('it should have 0 eth allowance rate', async function () {
      const ethAllowanceRate = await warmVaultSig.ethAllowanceRate();
      assert.equal(ethAllowanceRate.toNumber(), 0, 'eth allowance rate');
    });

    it('it should have 0 eth allowance at once limit', async function () {
      const ethAllowanceAtOnceLimit = await warmVaultSig.ethAllowanceAtOnceLimit();
      assert.equal(ethAllowanceAtOnceLimit.toNumber(), 0, 'eth allowance at once limmit');
    });

    it('it should have 0 eth allowance last spend at', async function () {
      const ethAllowanceLastSpentAt = await warmVaultSig.ethAllowanceLastSpentAt();
      assert.equal(ethAllowanceLastSpentAt.toNumber(), 0, 'eth allowance last spent at');
    });

    it('it should have 0 eth allowance remaining', async function () {
      const ethAllowanceRemaining = await warmVaultSig.ethAllowanceRemaining();
      assert.equal(ethAllowanceRemaining.toNumber(), 0, 'eth allowance remaining');
    });

    it('it should have 0 token allowance limit', async function () {
      const allowanceLimit = await warmVaultSig.allowanceLimit(token.address);
      assert.equal(allowanceLimit.toNumber(), 0, 'allowance limit');
    });

    it('it should have 0 token allowance rate', async function () {
      const allowanceRate = await warmVaultSig.allowanceRate(token.address);
      assert.equal(allowanceRate.toNumber(), 0, 'allowance rate');
    });

    it('it should have 0 token allowance at once limit', async function () {
      const allowanceAtOnceLimit = await warmVaultSig.allowanceAtOnceLimit(token.address);
      assert.equal(allowanceAtOnceLimit.toNumber(), 0, 'allowance at once limit');
    });

    it('it should have 0 token allowance last spent at', async function () {
      const allowanceLastSpentAt = await warmVaultSig.allowanceLastSpentAt(token.address);
      assert.equal(allowanceLastSpentAt.toNumber(), 0, 'allowance last spent at');
    });

    it('it should have 0 token allowance remaining', async function () {
      const allowanceRemaining = await warmVaultSig.allowanceRemaining(token.address);
      assert.equal(allowanceRemaining.toNumber(), 0, 'allowance remaining');
    });

    it('should let add allowance', async function () {
      const signer1 = await sign(accounts[1]);
      const tx = await warmVaultSig.addAllowance(
        [ signer1.r ], [ signer1.s ], [ signer1.v ],
        token.address,
        100000,
        100,
        1000
      );
      assert.equal(tx.receipt.status, '0x01', 'status');
      assert.equal(tx.logs.length, 0, 'logs');
    });

    it('should let end allowance definition', async function () {
      const signer1 = await sign(accounts[1]);
      const tx = await warmVaultSig.endAllowancesDefinition(
        [ signer1.r ], [ signer1.s ], [ signer1.v ]
      );
      assert.equal(tx.receipt.status, '0x01', 'status');
      assert.equal(tx.logs.length, 0, 'logs');
    });

    it('should not allow 0 eth transfer', async function () {
      const signer2 = await sign(accounts[2]);
      await assertRevert(warmVaultSig.transferOnBehalf(
        [ signer2.r ], [ signer2.s ], [ signer2.v ],
        accounts[9],
        0));
    });

    it('should not allow 0 ERC20 transfer', async function () {
      const signer2 = await sign(accounts[2]);
      await assertRevert(warmVaultSig.transferERC20OnBehalf(
        [ signer2.r ], [ signer2.s ], [ signer2.v ],
        token.address,
        accounts[9],
        0));
    });

    it('should not allow execute 0 transfer', async function () {
      const signer2 = await sign(accounts[2]);
      await assertRevert(warmVaultSig.executeOnBehalf(
        [ signer2.r ], [ signer2.s ], [ signer2.v ],
        accounts[9],
        0, ''));
    });

    it('should not allow execute 0 erc20 transfer', async function () {
      const signer2 = await sign(accounts[2]);
      const request2 = token.transfer.request(accounts[0], 0);
      await assertRevert(warmVaultSig.executeOnBehalf(
        [ signer2.r ], [ signer2.s ], [ signer2.v ],
        token.address,
        0,
        request2.params[0].data));
    });

    describe('and 2 allowances', function () {
      beforeEach(async function () {
        const signer1 = await sign(accounts[1]);
        await warmVaultSig.addEthAllowance(
          [ signer1.r ], [ signer1.s ], [ signer1.v ],
          100000,
          100,
          1000
        );
        const signer2 = await sign(accounts[1]);
        await warmVaultSig.addAllowance(
          [ signer2.r ], [ signer2.s ], [ signer2.v ],
          token.address,
          200000,
          200,
          2000
        );
      });

      it('it should have allowances not be defined', async function () {
        const allowancesDefined = await warmVaultSig.allowancesDefined();
        assert.ok(!allowancesDefined, 'Allowances defined');
      });

      it('it should have 100000 eth allowance limit', async function () {
        const ethAllowanceLimit = await warmVaultSig.ethAllowanceLimit();
        assert.equal(ethAllowanceLimit.toNumber(), 100000, 'eth allowance limit');
      });

      it('it should have 100 eth allowance rate', async function () {
        const ethAllowanceRate = await warmVaultSig.ethAllowanceRate();
        assert.equal(ethAllowanceRate.toNumber(), 100, 'eth allowance rate');
      });

      it('it should have 1000 eth allowance at once limit', async function () {
        const ethAllowanceAtOnceLimit = await warmVaultSig.ethAllowanceAtOnceLimit();
        assert.equal(ethAllowanceAtOnceLimit.toNumber(), 1000, 'eth allowance at once limmit');
      });

      it('it should have 0 eth allowance last spend at', async function () {
        const ethAllowanceLastSpentAt = await warmVaultSig.ethAllowanceLastSpentAt();
        assert.equal(ethAllowanceLastSpentAt.toNumber(), 0, 'eth allowance last spent at');
      });

      it('it should have 100000 eth allowance remaining', async function () {
        const ethAllowanceRemaining = await warmVaultSig.ethAllowanceRemaining();
        assert.equal(ethAllowanceRemaining.toNumber(), 100000, 'eth allowance remaining');
      });

      it('it should have 200000 token allowance limit', async function () {
        const allowanceLimit = await warmVaultSig.allowanceLimit(token.address);
        assert.equal(allowanceLimit.toNumber(), 200000, 'allowance limit');
      });

      it('it should have 200 token allowance rate', async function () {
        const allowanceRate = await warmVaultSig.allowanceRate(token.address);
        assert.equal(allowanceRate.toNumber(), 200, 'allowance rate');
      });

      it('it should have 2000 token allowance at once limit', async function () {
        const allowanceAtOnceLimit = await warmVaultSig.allowanceAtOnceLimit(token.address);
        assert.equal(allowanceAtOnceLimit.toNumber(), 2000, 'allowance at once limit');
      });

      it('it should have 0 token allowance last spent at', async function () {
        const allowanceLastSpentAt = await warmVaultSig.allowanceLastSpentAt(token.address);
        assert.equal(allowanceLastSpentAt.toNumber(), 0, 'allowance last spent at');
      });

      it('it should have 200000 token allowance remaining', async function () {
        const allowanceRemaining = await warmVaultSig.allowanceRemaining(token.address);
        assert.equal(allowanceRemaining.toNumber(), 200000, 'allowance remaining');
      });

      describe('with allowances defined', function () {
        beforeEach(async function () {
          const signer1 = await sign(accounts[1]);
          await warmVaultSig.endAllowancesDefinition(
            [ signer1.r ], [ signer1.s ], [ signer1.v ]
          );
          await new Promise(
            (resolve, reject) => web3.eth.sendTransaction({
              from: accounts[9],
              to: warmVaultSig.address,
              value: web3.toWei(1, 'gwei'),
            }, (err, data) => {
              if (err) {
                reject(err);
              } else {
                resolve();
              }
            })
          );
        });

        it('it should have allowances defined', async function () {
          const allowancesDefined = await warmVaultSig.allowancesDefined();
          assert.ok(allowancesDefined, 'Allowances defined');
        });

        it('should allow 100 wei transfer', async function () {
          const signer2 = await sign(accounts[2]);
          const tx = await warmVaultSig.transferOnBehalf(
            [ signer2.r ], [ signer2.s ], [ signer2.v ],
            accounts[9],
            100);
          assert.equal(tx.receipt.status, '0x01', 'status');
          assert.equal(tx.logs.length, 1, 'logs');
          assert.equal(tx.logs[0].event, 'Execution');
          assert.equal(tx.logs[0].args.to, accounts[9], 'to');
          assert.equal(tx.logs[0].args.value, 100, 'value');
          assert.equal(tx.logs[0].args.data, '0x', 'data');
        });

        it('should allow 100 ERC20 transfer', async function () {
          const signer2 = await sign(accounts[2]);
          const request2 = token.transfer.request(accounts[9], 100);
          const tx = await warmVaultSig.transferERC20OnBehalf(
            [ signer2.r ], [ signer2.s ], [ signer2.v ],
            token.address,
            accounts[9],
            100);
          assert.equal(tx.receipt.status, '0x01', 'status');
          assert.equal(tx.logs.length, 1, 'logs');
          assert.equal(tx.logs[0].event, 'Execution');
          assert.equal(tx.logs[0].args.to, token.address, 'to');
          assert.equal(tx.logs[0].args.value.toNumber(), 0, 'value');
          assert.equal(tx.logs[0].args.data, request2.params[0].data, 'data');
        });

        it('should allow execute 100 wei transfer', async function () {
          const signer2 = await sign(accounts[2]);
          const tx = await warmVaultSig.executeOnBehalf(
            [ signer2.r ], [ signer2.s ], [ signer2.v ],
            accounts[9],
            100, '');
          assert.equal(tx.receipt.status, '0x01', 'status');
          assert.equal(tx.logs.length, 1, 'logs');
          assert.equal(tx.logs[0].event, 'Execution');
          assert.equal(tx.logs[0].args.to, accounts[9], 'to');
          assert.equal(tx.logs[0].args.value, 100, 'value');
          assert.equal(tx.logs[0].args.data, '0x', 'data');
        });

        it('should allow execute 100 erc20 transfer', async function () {
          const signer2 = await sign(accounts[2]);
          const request2 = token.transfer.request(accounts[0], 100);
          const tx = await warmVaultSig.executeOnBehalf(
            [ signer2.r ], [ signer2.s ], [ signer2.v ],
            token.address,
            0,
            request2.params[0].data);
          assert.equal(tx.receipt.status, '0x01', 'status');
          assert.equal(tx.logs.length, 1, 'logs');
          assert.equal(tx.logs[0].event, 'Execution');
          assert.equal(tx.logs[0].args.to, token.address, 'to');
          assert.equal(tx.logs[0].args.value, 0, 'value');
          assert.equal(tx.logs[0].args.data, request2.params[0].data, 'data');
        });

        it('should not allow 100001 wei transfer', async function () {
          const signer2 = await sign(accounts[2]);
          await assertRevert(warmVaultSig.transferOnBehalf(
            [ signer2.r ], [ signer2.s ], [ signer2.v ],
            accounts[9],
            100001));
        });

        it('should not allow 200001 ERC20 transfer', async function () {
          const signer2 = await sign(accounts[2]);
          await assertRevert(warmVaultSig.transferERC20OnBehalf(
            [ signer2.r ], [ signer2.s ], [ signer2.v ],
            token.address,
            accounts[9],
            200001));
        });
      });
    });
  });
});
