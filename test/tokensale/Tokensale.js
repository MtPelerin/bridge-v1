'user strict';

/**
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * This content cannot be used, copied or reproduced in part or in whole
 * without the express and written permission of Mt Pelerin Group SA.
 * Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * All matters regarding the intellectual property of this code or software
 * are subjects to Swiss Law without reference to its conflicts of law rules.
 *
 */

const assertRevert = require('../helpers/assertRevert');
const StandardTokenMock = artifacts.require('mock/StandardTokenMock.sol');
const UserRegistry = artifacts.require('UserRegistry.sol');
const Tokensale = artifacts.require('tokensale/Tokensale.sol');
const RatesProvider = artifacts.require('RatesProvider.sol');

contract('Tokensale', function (accounts) {
  let sale, token, userRegistry, ratesProvider;

  const vaultERC20 = accounts[1];
  const vaultETH = accounts[0];

  const sharePurchaseAgreementHash = web3.sha3('SharePurchaseAgreement');
  const dayMinusOneTime = Math.floor((new Date()).getTime() / 1000) - 3600 * 24;
  const dayPlusOneTime = Math.floor((new Date()).getTime() / 1000) + 3600 * 24;

  beforeEach(async function () {
    token = await StandardTokenMock.new(accounts[1], 10000);
    userRegistry = await UserRegistry.new([ accounts[2], accounts[3], accounts[4] ], dayPlusOneTime);
    ratesProvider = await RatesProvider.new();
    await ratesProvider.defineAuthority('OPERATOR', accounts[0]);
    sale = await Tokensale.new(token.address, userRegistry.address, ratesProvider.address, vaultERC20, vaultETH);
    await sale.defineAuthority('OPERATOR', accounts[0]);
    await token.approve(sale.address, 10000, { from: accounts[1] });
  });

  function formatETH(value) {
    return Math.floor(1000*web3.fromWei(value, 'ether').toNumber())/1000;
  }

  it('should have a token', async function () {
    const saleTokenAddress = await sale.token();
    assert.equal(saleTokenAddress, token.address, 'token');
  });

  it('should have a vaultERC20', async function () {
    const saleVaultERC20 = await sale.vaultERC20();
    assert.equal(saleVaultERC20, vaultERC20, 'vaulrERC20');
  });

  it('should have a vaultETH', async function () {
    const saleVaultETH = await sale.vaultETH();
    assert.equal(saleVaultETH, vaultETH, 'vaulrETH');
  });

  it('should have a user registry', async function () {
    const saleUserRegistryAddress = await sale.userRegistry();
    assert.equal(saleUserRegistryAddress, userRegistry.address, 'userRegistry');
  });

  it('should have a rate provider', async function () {
    const ratesProviderAddress = await sale.ratesProvider();
    assert.equal(ratesProviderAddress, ratesProvider.address, 'ratesProvider');
  });

  it('should have a share purchase agreement hash non defini', async function () {
    const saleSharePurchaseAgreement = await sale.sharePurchaseAgreementHash();
    assert.equal(saleSharePurchaseAgreement, 0, 'sharePurchaseAgreementHash');
  });

  it('should have a start date', async function () {
    const startAt = await sale.startAt();
    assert.ok(startAt.toNumber() > dayPlusOneTime, 'startAt');
  });

  it('should have a end date', async function () {
    const endAt = await sale.endAt();
    assert.ok(endAt.toNumber() > dayPlusOneTime, 'endAt');
  });

  it('should have raised 0 ETH', async function () {
    const raisedETH = await sale.raisedETH();
    assert.equal(raisedETH.toNumber(), 0, 'raisedETH');
  });

  it('should have raised 0 CHF', async function () {
    const raisedCHF = await sale.raisedCHF();
    assert.equal(raisedCHF.toNumber(), 0, 'raisedCHF');
  });

  it('should have total raised CHF', async function () {
    const totalRaisedCHF = await sale.totalRaisedCHF();
    assert.equal(totalRaisedCHF.toNumber(), 0, 'totalRaisedCHF');
  });

  it('should have refunded 0 ETH', async function () {
    const refundedETH = await sale.refundedETH();
    assert.equal(refundedETH.toNumber(), 0, 'refundedETH');
  });

  describe('before the sale start', async function () {
    it('should let owner define SPA', async function () {
      const tx = await sale.defineSPA(sharePurchaseAgreementHash);

      assert.equal(parseInt(tx.receipt.status), 1, 'Status');
      assert.equal(tx.logs.length, 1);
      assert.equal(tx.logs[0].event, 'SalePurchaseAgreementHash', 'event');
      assert.equal(
        tx.logs[0].args.sharePurchaseAgreement,
        sharePurchaseAgreementHash,
        'sharePurchaseAgreementHash');
    });

    it('should prevent non owner to define SPA', async function () {
      await assertRevert(sale.defineSPA(sharePurchaseAgreementHash, { from: accounts[2] }));
    });

    it('should let authority allocate tokens', async function () {
      const tx = await sale.allocateTokens(accounts[2], 1000);
      assert.equal(parseInt(tx.receipt.status), 1, 'Status');
      assert.equal(tx.logs.length, 1);
      assert.equal(tx.logs[0].event, 'Allocation', 'event');
      assert.equal(tx.logs[0].args.investorId, 1, 'investorId');
      assert.equal(tx.logs[0].args.tokens, 1000, 'tokens');
    });

    it('should not let authority allocate tokens to non existing user', async function () {
      await assertRevert(sale.allocateTokens(accounts[1], 1000));
    });

    it('should not let authority allocate more tokens than available', async function () {
      await assertRevert(sale.allocateTokens(accounts[2], 10001));
    });
 
    it('should let authority allocate many tokens', async function () {
      const tx = await sale.allocateManyTokens([ accounts[2], accounts[3], accounts[2] ], [ 2000, 1000, 500 ]);
      assert.equal(parseInt(tx.receipt.status), 1, 'Status');
      assert.equal(tx.logs.length, 3);
      assert.equal(tx.logs[0].event, 'Allocation', 'event');
      assert.equal(tx.logs[0].args.investorId, 1, 'investorId');
      assert.equal(tx.logs[0].args.tokens, 2000, 'tokens');
      assert.equal(tx.logs[1].event, 'Allocation', 'event');
      assert.equal(tx.logs[1].args.investorId, 2, 'investorId');
      assert.equal(tx.logs[1].args.tokens, 1000, 'tokens');
      assert.equal(tx.logs[2].event, 'Allocation', 'event');
      assert.equal(tx.logs[2].args.investorId, 1, 'investorId');
      assert.equal(tx.logs[2].args.tokens, 500, 'tokens');
    });

    it('should not let user invest', async function () {
      await assertRevert(sale.investETH({ from: accounts[1], value: web3.toWei(1, 'ether') }));
    });
 
    describe('with SPA defined', async function () {
      beforeEach(async function () {
        await sale.defineSPA(sharePurchaseAgreementHash);
      });

      it('should let user accept SPA', async function () {
        const tx = await sale.acceptSPA(sharePurchaseAgreementHash, { from: accounts[2] });
        assert.equal(parseInt(tx.receipt.status), 1, 'Status');
      });

      it('should let user accept with a wrong SPA', async function () {
        await assertRevert(sale.acceptSPA(web3.sha3('wrong spa'), { from: accounts[2] }));
      });

      it('should not let a non user accept SPA', async function () {
        await assertRevert(sale.acceptSPA(sharePurchaseAgreementHash, { from: accounts[0] }));
      });

      it('should not let user invest while accepting SPA', async function () {
        await assertRevert(
          sale.acceptSPA(
            sharePurchaseAgreementHash,
            { from: accounts[0], value: web3.toWei(1, 'ether') }
          )
        );
      });
    });
  });

  describe('during the sale', async function () {
    beforeEach(async function () {
      await sale.updateSchedule(dayMinusOneTime, dayPlusOneTime);
    });

    it('should have a start date', async function () {
      const startAt = await sale.startAt();
      assert.ok(startAt.toNumber(), dayMinusOneTime, 'startAt');
    });

    it('should have a end date', async function () {
      const endAt = await sale.endAt();
      assert.ok(endAt.toNumber(), dayPlusOneTime, 'endAt');
    });

    describe('with SPA Defined, allocations defined, rate defined', async function () {
      beforeEach(async function () {
        await ratesProvider.defineETHCHFRate(207233, 2);
        await sale.defineSPA(sharePurchaseAgreementHash);
        await sale.allocateManyTokens([ accounts[2], accounts[3] ], [ 500, 4000 ]);
      });

      it('should allow off chain investment over allocations', async function () {
        const tx = await sale.addOffChainInvestment(accounts[2], 10000);
        assert.equal(parseInt(tx.receipt.status), 1, 'Status');
        assert.equal(tx.logs.length, 1);
        assert.equal(tx.logs[0].event, 'Investment', 'event');
        assert.equal(tx.logs[0].args.investorId, 1, 'investorId');
        assert.equal(tx.logs[0].args.spentCHF, 10000, 'tokens');
      });

      it('should allow accept SPA with value and above allocations', async function () {
        const tx = await sale.acceptSPA(sharePurchaseAgreementHash,
          { from: accounts[2], value: web3.toWei(1, 'ether') });
        assert.equal(parseInt(tx.receipt.status), 1, 'Status');
        assert.equal(tx.logs.length, 3);
        assert.equal(tx.logs[0].event, 'ChangeETHCHF', 'event');
        assert.equal(tx.logs[0].args.investor, accounts[2], 'investor');
        assert.equal(formatETH(tx.logs[0].args.amount), 0.998, 'amount change');
        assert.equal(tx.logs[0].args.converted.toNumber(), 207000, 'converted');
        assert.equal(tx.logs[0].args.rate.toNumber(), 4825486288380, 'rate');
        assert.equal(tx.logs[1].event, 'Investment', 'event');
        assert.equal(tx.logs[1].args.investorId, 1, 'investorId');
        assert.equal(tx.logs[1].args.spentCHF.toNumber(), 207000, 'spentCHF');
        assert.equal(tx.logs[2].event, 'WithdrawETH', 'event');
        assert.equal(tx.logs[2].args.receiver, vaultETH, 'vaultETH');
        assert.equal(formatETH(tx.logs[2].args.amount), 0.5, 'amount withdraw');
      });

      it('should allow accept SPA with value and below allocations', async function () {
        const tx = await sale.acceptSPA(sharePurchaseAgreementHash,
          { from: accounts[2], value: web3.toWei(1, 'ether') });
        assert.equal(parseInt(tx.receipt.status), 1, 'Status');
        assert.equal(tx.logs.length, 3);
        assert.equal(tx.logs[0].event, 'ChangeETHCHF', 'event');
        assert.equal(tx.logs[0].args.investor, accounts[2], 'investor');
        assert.equal(formatETH(tx.logs[0].args.amount), 0.998, 'amount change');
        assert.equal(tx.logs[0].args.converted.toNumber(), 207000, 'converted');
        assert.equal(tx.logs[0].args.rate.toNumber(), 4825486288380, 'rate');
        assert.equal(tx.logs[1].event, 'Investment', 'event');
        assert.equal(tx.logs[1].args.investorId, 1, 'investorId');
        assert.equal(tx.logs[1].args.spentCHF.toNumber(), 207000, 'spentCHF');
        assert.equal(tx.logs[2].event, 'WithdrawETH', 'event');
        assert.equal(tx.logs[2].args.receiver, vaultETH, 'vaultETH');
        assert.equal(formatETH(tx.logs[2].args.amount), 0.5, 'amount withdraw');
      });

      it('should allow accept SPA with value and no allocations', async function () {
        const tx = await sale.acceptSPA(sharePurchaseAgreementHash,
          { from: accounts[3], value: web3.toWei(1, 'ether') });
        assert.equal(parseInt(tx.receipt.status), 1, 'Status');
        assert.equal(tx.logs.length, 3);
        assert.equal(tx.logs[0].event, 'ChangeETHCHF', 'event');
        assert.equal(tx.logs[0].args.investor, accounts[3], 'investor');
        assert.equal(formatETH(tx.logs[0].args.amount), 0.998, 'amount change');
        assert.equal(tx.logs[0].args.converted.toNumber(), 207000, 'converted');
        assert.equal(tx.logs[0].args.rate.toNumber(), 4825486288380, 'rate');
        assert.equal(tx.logs[1].event, 'Investment', 'event');
        assert.equal(tx.logs[1].args.investorId, 2, 'investorId');
        assert.equal(tx.logs[1].args.spentCHF.toNumber(), 207000, 'spentCHF');
        assert.equal(tx.logs[2].event, 'WithdrawETH', 'event');
        assert.equal(tx.logs[2].args.receiver, vaultETH, 'vaultETH');
        assert.equal(formatETH(tx.logs[2].args.amount), 0.5, 'amount withdraw');
      });
 
      describe('and some investment already done', async function () {
        beforeEach(async function () {
          await sale.addOffChainInvestment(accounts[2], 10000);
          await sale.acceptSPA(sharePurchaseAgreementHash,
            { from: accounts[2], value: web3.toWei(0.1, 'ether') });
          await sale.acceptSPA(sharePurchaseAgreementHash,
            { from: accounts[3], value: web3.toWei(0.2, 'ether') });
        });

        it('should have availableSupply', async function () {
          const availableSupply = await sale.availableSupply();
          assert.equal(availableSupply.toNumber(), 9857, 'availableSupply');
        });

        it('should have allocatedTokens', async function () {
          const allocatedTokens = await sale.allocatedTokens();
          assert.equal(allocatedTokens.toNumber(), 4357, 'allocatedTokens');
        });

        it('should have raised ETH', async function () {
          const raisedETH = await sale.raisedETH();
          assert.equal(formatETH(raisedETH), 0.296, 'raisedETH');
        });

        it('should have raised CHF', async function () {
          const raisedCHF = await sale.raisedCHF();
          assert.equal(raisedCHF.toNumber(), 10000, 'raisedCHF');
        });

        it('should have total raised CHF', async function () {
          const totalRaisedCHF = await sale.totalRaisedCHF();
          assert.equal(totalRaisedCHF.toNumber(), 71500, 'totalRaisedCHF');
        });

        it('should have refunded ETH', async function () {
          const refundedETH = await sale.refundedETH();
          assert.equal(formatETH(refundedETH), 0, 'refundedETH');
        });

        it('should have investor unspentETH for accounts2', async function () {
          const unspentETH = await sale.investorUnspentETH(1);
          assert.equal(formatETH(unspentETH, 'ether'), 0.001, 'unspentETH 1');
        });

        it('should have investor investedCHF for accounts2', async function () {
          const investedCHF = await sale.investorInvestedCHF(1);
          assert.equal(investedCHF.toNumber(), 30500, 'invested CHF 1');
        });

        it('should have investor acceptedSPA for accounts2', async function () {
          const acceptedSPA = await sale.investorAcceptedSPA(1);
          assert.ok(acceptedSPA, 'acceptedSPA 1');
        });

        it('should have investorAllocations for accounts2', async function () {
          const allocations = await sale.investorAllocations(1);
          assert.equal(allocations.toNumber(), 439, 'allocations');
        });

        it('should have investorTokens for account2', async function () {
          const tokens = await sale.investorTokens(1);
          assert.equal(tokens.toNumber(), 61, 'tokens 1');
        });

        it('should have investor unspentETH for accounts3', async function () {
          const unspentETH = await sale.investorUnspentETH(2);
          assert.equal(formatETH(unspentETH), 0.002, 'unspentETH 2');
        });

        it('should have investor investedCHF for accounts3', async function () {
          const investedCHF = await sale.investorInvestedCHF(2);
          assert.equal(investedCHF.toNumber(), 41000, 'invested CHF 2');
        });

        it('should have investor acceptedSPA for accounts3', async function () {
          const acceptedSPA = await sale.investorAcceptedSPA(2);
          assert.ok(acceptedSPA, 'acceptedSPA 2');
        });

        it('should have investorAllocations for accounts3', async function () {
          const allocations = await sale.investorAllocations(2);
          assert.equal(allocations.toNumber(), 3918, 'allocations');
        });

        it('should have investorTokens for account3', async function () {
          const tokens = await sale.investorTokens(2);
          assert.equal(tokens.toNumber(), 82, 'tokens 2');
        });

        it('should have investor count', async function () {
          const count = await sale.investorCount();
          assert.equal(count.toNumber(), 2, 'count');
        });

        it('should let investor2 refund his ETH', async function () {
          const tx = await sale.refundUnspentETH(accounts[2]);
          assert.equal(parseInt(tx.receipt.status), 1, 'Status');
          assert.equal(tx.logs.length, 1);
          assert.equal(tx.logs[0].event, 'WithdrawETH', 'event');
          assert.equal(tx.logs[0].args.receiver, accounts[2], 'accounts2');
          assert.equal(formatETH(tx.logs[0].args.amount), 0.001, 'amount withdraw');
        });

        it('should let investor3 refund his ETH', async function () {
          const tx = await sale.refundUnspentETH(accounts[3]);
          assert.equal(parseInt(tx.receipt.status), 1, 'Status');
          assert.equal(tx.logs.length, 1);
          assert.equal(tx.logs[0].event, 'WithdrawETH', 'event');
          assert.equal(tx.logs[0].args.receiver, accounts[3], 'accounts3');
          assert.equal(formatETH(tx.logs[0].args.amount), 0.002, 'amount withdraw');
        });

        it('should let investors refund his ETH', async function () {
          const tx = await sale.refundManyUnspentETH([ accounts[2], accounts[3] ]);
          assert.equal(parseInt(tx.receipt.status), 1, 'Status');
          assert.equal(tx.logs.length, 2);
          assert.equal(tx.logs[0].event, 'WithdrawETH', 'event');
          assert.equal(tx.logs[0].args.receiver, accounts[2], 'accounts2');
          assert.equal(formatETH(tx.logs[0].args.amount), 0.001, 'amount withdraw');
          assert.equal(tx.logs[1].event, 'WithdrawETH', 'event');
          assert.equal(tx.logs[1].args.receiver, accounts[3], 'accounts3');
          assert.equal(formatETH(tx.logs[1].args.amount), 0.002, 'amount withdraw');
        });

        it('should allow withdraw ETH funds', async function () {
          const tx = await sale.withdrawETHFunds();
          assert.equal(parseInt(tx.receipt.status), 1, 'Status');
          assert.equal(tx.logs.length, 0);
        });
      });

      describe('and many investments already done', async function () {
        beforeEach(async function () {
          await sale.addOffChainInvestment(accounts[2], 10000);
          await sale.acceptSPA(sharePurchaseAgreementHash,
            { from: accounts[2], value: web3.toWei(0.1, 'ether') });
          await sale.acceptSPA(sharePurchaseAgreementHash,
            { from: accounts[3], value: web3.toWei(0.2, 'ether') });
          await sale.addOffChainInvestment(accounts[2], 2500000);
          await sale.addOffChainInvestment(accounts[3], 1333333);
          await sale.acceptSPA(sharePurchaseAgreementHash,
            { from: accounts[3], value: web3.toWei(0.2, 'ether') });
        });

        it('should throw if too much CHF investment is passed', async function () {
          await assertRevert(sale.addOffChainInvestment(accounts[3], 5000000));
        });

        it('should have availableSupply', async function () {
          const availableSupply = await sale.availableSupply();
          assert.equal(availableSupply.toNumber(), 2107, 'availableSupply');
        });

        it('should have allocatedTokens', async function () {
          const allocatedTokens = await sale.allocatedTokens();
          assert.equal(allocatedTokens.toNumber(), 1168, 'allocatedTokens');
        });

        it('should have raised ETH', async function () {
          const raisedETH = await sale.raisedETH();
          assert.equal(formatETH(raisedETH), 0.497, 'raisedETH');
        });

        it('should have raised CHF', async function () {
          const raisedCHF = await sale.raisedCHF();
          assert.equal(raisedCHF.toNumber(), 3843333, 'raisedCHF');
        });

        it('should have total raised CHF', async function () {
          const totalRaisedCHF = await sale.totalRaisedCHF();
          assert.equal(totalRaisedCHF.toNumber(), 3946500, 'totalRaisedCHF');
        });

        it('should have refunded ETH', async function () {
          const refundedETH = await sale.refundedETH();
          assert.equal(formatETH(refundedETH), 0, 'refundedETH');
        });

        it('should have investor unspentETH for accounts2', async function () {
          const unspentETH = await sale.investorUnspentETH(1);
          assert.equal(formatETH(unspentETH), 0.001, 'unspentETH 1');
        });

        it('should have investor investedCHF for accounts2', async function () {
          const investedCHF = await sale.investorInvestedCHF(1);
          assert.equal(investedCHF.toNumber(), 2530500, 'invested CHF 1');
        });

        it('should have investor acceptedSPA for accounts2', async function () {
          const acceptedSPA = await sale.investorAcceptedSPA(1);
          assert.ok(acceptedSPA, 'acceptedSPA 1');
        });

        it('should have investorAllocations for accounts2', async function () {
          const allocations = await sale.investorAllocations(1);
          assert.equal(allocations.toNumber(), 0, 'allocations');
        });

        it('should have investorTokens for account2', async function () {
          const tokens = await sale.investorTokens(1);
          assert.equal(tokens.toNumber(), 5061, 'tokens 1');
        });

        it('should have investor unspentETH for accounts3', async function () {
          const unspentETH = await sale.investorUnspentETH(2);
          assert.equal(formatETH(unspentETH), 0.001, 'unspentETH 2');
        });

        it('should have investor investedCHF for accounts3', async function () {
          const investedCHF = await sale.investorInvestedCHF(2);
          assert.equal(investedCHF.toNumber(), 1416000, 'invested CHF 2');
        });

        it('should have investor acceptedSPA for accounts3', async function () {
          const acceptedSPA = await sale.investorAcceptedSPA(2);
          assert.ok(acceptedSPA, 'acceptedSPA 2');
        });

        it('should have investorAllocations for accounts3', async function () {
          const allocations = await sale.investorAllocations(2);
          assert.equal(allocations.toNumber(), 1168, 'allocations');
        });

        it('should have investorTokens for account3', async function () {
          const tokens = await sale.investorTokens(2);
          assert.equal(tokens.toNumber(), 2832, 'tokens 2');
        });

        it('should have investor count', async function () {
          const count = await sale.investorCount();
          assert.equal(count.toNumber(), 3, 'count');
        });

        it('should let investor2 refund his ETH', async function () {
          const tx = await sale.refundUnspentETH(accounts[2]);
          assert.equal(parseInt(tx.receipt.status), 1, 'Status');
          assert.equal(tx.logs.length, 1);
          assert.equal(tx.logs[0].event, 'WithdrawETH', 'event');
          assert.equal(tx.logs[0].args.receiver, accounts[2], 'accounts2');
          assert.equal(formatETH(tx.logs[0].args.amount), 0.001, 'amount withdraw');
        });

        it('should let investor3 refund his ETH', async function () {
          const tx = await sale.refundUnspentETH(accounts[3]);
          assert.equal(parseInt(tx.receipt.status), 1, 'Status');
          assert.equal(tx.logs.length, 1);
          assert.equal(tx.logs[0].event, 'WithdrawETH', 'event');
          assert.equal(tx.logs[0].args.receiver, accounts[3], 'accounts3');
          assert.equal(formatETH(tx.logs[0].args.amount), 0.001, 'amount withdraw');
        });

        it('should let investors refund his ETH', async function () {
          const tx = await sale.refundManyUnspentETH([ accounts[2], accounts[3] ]);
          assert.equal(parseInt(tx.receipt.status), 1, 'Status');
          assert.equal(tx.logs.length, 2);
          assert.equal(tx.logs[0].event, 'WithdrawETH', 'event');
          assert.equal(tx.logs[0].args.receiver, accounts[2], 'accounts2');
          assert.equal(formatETH(tx.logs[0].args.amount), 0.001, 'amount withdraw');
          assert.equal(tx.logs[1].event, 'WithdrawETH', 'event');
          assert.equal(tx.logs[1].args.receiver, accounts[3], 'accounts3');
          assert.equal(formatETH(tx.logs[1].args.amount), 0.001, 'amount withdraw');
        });

        it('should allow withdraw ETH funds', async function () {
          const tx = await sale.withdrawETHFunds();
          assert.equal(parseInt(tx.receipt.status), 1, 'Status');
          assert.equal(tx.logs.length, 0);
        });
      });
    });
  });

  describe('after the sale', async function () {
    beforeEach(async function () {
      await sale.updateSchedule(dayMinusOneTime, dayMinusOneTime+1);
    });

    it('should allow withdraw All ETH funds', async function () {
      const tx = await sale.withdrawAllETHFunds();
      assert.equal(parseInt(tx.receipt.status), 1, 'Status');
      assert.equal(tx.logs.length, 1);
      assert.equal(tx.logs[0].event, 'WithdrawETH', 'event');
      assert.equal(tx.logs[0].args.receiver, vaultETH, 'vaultETH');
      assert.equal(formatETH(tx.logs[0].args.amount), 0, 'amount withdraw');
    });
  });
});
