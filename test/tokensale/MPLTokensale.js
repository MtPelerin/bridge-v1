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

const assertThrow = require('../helpers/assertThrow');
const assertRevert = require('../helpers/assertRevert');
const SaleConfigMock = artifacts.require('mock/SaleConfigMock.sol');
const UserRegistry = artifacts.require('UserRegistry.sol');
const MintableToken = artifacts.require('token/MintableToken.sol');
const TokenMinter = artifacts.require('tokensale/TokenMinter.sol');
const MPLTokensaleMock = artifacts.require('mock/MPLTokensaleMock.sol');

contract('MPLTokensale', function (accounts) {
  let sale, saleConfig, minter, token, userRegistry;

  const currentTime = Math.floor((new Date()).getTime() / 1000);
  const dayPlusOneTime = currentTime + 3600 * 24;
  const userAddresses = [
    accounts[0],
    accounts[1],
    accounts[2],
    accounts[3],
    accounts[4],
    accounts[5],
  ];

  // There is no possibility currently in truffle to give more
  // than 100 ETH to test accounts to run all the tests
  // Fake rate in order for 1 milli == 500'000 CHF
  const fakeRateETHCHF = 5 * 10 ** (5 /* CHF */ + 3 /* milli */);

  const planAndSetupMinter = async function () {
    await sale.plan();
    token = await MintableToken.new();
    minter = await TokenMinter.new(saleConfig.address, accounts[0]);
    await token.transferOwnership(minter.address);
    await minter.setupToken(token.address, accounts[4], accounts[1], accounts[2]);
    await minter.transferOwnership(sale.address);
    await sale.setupMinter(minter.address);
  };

  before(async function () {
    // account 0 need more than 100 ETH to do all test
    await new Promise((resolve, reject) => web3.eth.sendTransaction({
      from: accounts[9],
      to: accounts[0],
      value: web3.toWei(99, 'ether'),
    }, (err, data) => {
      if (err) {
        reject(err);
      } else {
        resolve();
      }
    }));
  });

  beforeEach(async function () {
    saleConfig = await SaleConfigMock.new();
    userRegistry = await UserRegistry.new(userAddresses, dayPlusOneTime);

    sale = await MPLTokensaleMock.new(
      accounts[9],
      saleConfig.address,
      userRegistry.address,
    );
  });

  it('should convert from ETHCHF with no rate', async function () {
    const rateWEIPerCHFCent = await sale.convertFromETHCHF(0, 0);
    assert.equal(rateWEIPerCHFCent.toNumber(), 0, '0 rate from ETHCHF');
  });

  it('should convert from ETHCHF with a rate and no decimals', async function () {
    const rateWEIPerCHFCent = await sale.convertFromETHCHF(5 * (10 ** (5 + 3)), 0);
    assert.equal(rateWEIPerCHFCent.toNumber(), 2 * (10 ** 7), '20\'000\'000 rate from ETHCHF');
  });

  it('should convert from ETHCHF with a rate and 2 decimals', async function () {
    const rateWEIPerCHFCent = await sale.convertFromETHCHF(5 * (10 ** (5 + 3)), 2);
    assert.equal(rateWEIPerCHFCent.toNumber(), 2 * (10 ** (7 + 2)), '20\'000 rate from ETHCHF');
  });

  it('should convert from ETHCHF with a realistic rate and 2 decimals', async function () {
    const rateWEIPerCHFCent = await sale.convertFromETHCHF(50057, 2);
    assert.equal(rateWEIPerCHFCent.toNumber(), 19977225962402, '19977225962402 rate from ETHCHF');
  });

  it('should convert to ETHCHF with no rate', async function () {
    const rateWEIPerCHFCent = await sale.convertToETHCHF(0, 0);
    assert.equal(rateWEIPerCHFCent.toNumber(), 0, '0 rate to ETHCHF');
  });

  it('should convert to ETHCHF with a rate and no decimals', async function () {
    const rateWEIPerCHFCent = await sale.convertToETHCHF(2 * (10 ** 7), 0);
    assert.equal(rateWEIPerCHFCent.toNumber(), 5 * (10 ** (5 + 3)), '500\'000 rate to ETHCHF');
  });

  it('should convert to ETHCHF with a rate and 2 decimals', async function () {
    const rateWEIPerCHFCent = await sale.convertToETHCHF(2 * (10 ** 9), 2);
    assert.equal(rateWEIPerCHFCent.toNumber(), 5 * (10 ** (5 + 3)), '500\'000 rate to ETHCHF');
  });

  it('should convert to ETHCHF with a 100*rate and 2 decimals', async function () {
    const rateWEIPerCHFCent = await sale.convertToETHCHF(2 * (10 ** 11), 2);
    assert.equal(rateWEIPerCHFCent.toNumber(), 5 * (10 ** (5 + 3 - 2)), '5\'000 rate to ETHCHF');
  });

  it('should have a sale config', async function () {
    const saleConfigAddr = await sale.saleConfig();
    assert.equal(saleConfigAddr, saleConfig.address, 'saleConfig');
  });

  it('should have a userRegistry', async function () {
    const userRegistryAddr = await sale.userRegistry();
    assert.equal(userRegistryAddr, userRegistry.address, 'userRegistry');
  });

  it('should have a vault', async function () {
    const vault = await sale.vault();
    assert.equal(vault, accounts[9], 'vault');
  });

  it('should have a ETHCHF rate', async function () {
    const rateETHCHF = await sale.rateETHCHF(2);
    assert.equal(rateETHCHF.toNumber(), 0, 'rateETHCHF');
  });

  it('should have a rate WEICHF equal 0', async function () {
    const rateWEIPerCHFCent = await sale.rateWEIPerCHFCent();
    assert.equal(rateWEIPerCHFCent.toNumber(), 0, 'rate WEI CHF');
  });

  it('should have an ETH refund precision equal 10**9', async function () {
    const refundETHPrecision = await sale.refundETHPrecision();
    assert.equal(refundETHPrecision.toNumber(), 10 ** 9, 'refundETHPrecision');
  });

  it('should have a refund CHF unspent min equal 10', async function () {
    const refundCHFUnspentMin = await sale.refundCHFUnspentMin();
    assert.equal(refundCHFUnspentMin.toNumber(), 10, 'refundCHFUnspentMin');
  });

  it('should have a refund ratio equal 0', async function () {
    const refundRatio = await sale.refundRatio();
    assert.equal(refundRatio.toNumber(), 0, 'refundRatio');
  });

  it('should have refund ETH equal 0', async function () {
    const refundETH = await sale.refundETH();
    assert.equal(refundETH.toNumber(), 0, 'refundETH');
  });

  it('should have raised 0 ETH', async function () {
    const raisedETH = await sale.raisedETH();
    assert.equal(raisedETH.toNumber(), 0, 'raisedETH');
  });

  it('should have raised 0 CHF', async function () {
    const raisedCHF = await sale.raisedCHF();
    assert.equal(raisedCHF.toNumber(), 0, 'raisedCHF');
  });

  it('should have raised 0 CHF totally', async function () {
    const totalRaisedCHF = await sale.totalRaisedCHF();
    assert.equal(totalRaisedCHF.toNumber(), 0, 'totalRaisedCHF');
  });

  it('should have 0 deposit ETH for investor', async function () {
    const depositETH = await sale.investorDepositETH(1);
    assert.equal(depositETH.toNumber(), 0, 'depositETH');
  });

  it('should have 0 deposit CHF for investor', async function () {
    const depositCHF = await sale.investorDepositCHF(1);
    assert.equal(depositCHF.toNumber(), 0, 'depositCHF');
  });

  it('should have no destination for investor', async function () {
    const destination = await sale.investorDestination(1);
    assert.equal(destination,
      '0x0000000000000000000000000000000000000000',
      'destination');
  });

  it('should have 0 tokens for investor', async function () {
    const tokens = await sale.investorTokens(1);
    assert.equal(tokens.toNumber(), 0, 'tokens');
  });

  it('should not be refunded', async function () {
    const refunded = await sale.investorIsRefunded(1);
    assert.ok(!refunded, 'refunded');
  });

  it('should not be minted', async function () {
    const minted = await sale.investorIsMinted(1);
    assert.ok(!minted, 'minted');
  });

  it('should have 0 investors', async function () {
    const investorCount = await sale.investorCount();
    assert.equal(investorCount.toNumber(), 0, 'investor count');
  });

  it('should have 0 contributors', async function () {
    const contributorCount = await sale.contributorCount();
    assert.equal(contributorCount.toNumber(), 0, 'contributor count');
  });

  it('should have 0 prepared', async function () {
    const preparedCount = await sale.preparedCount();
    assert.equal(preparedCount.toNumber(), 0, 'prepared count');
  });

  it('should have 0 minted', async function () {
    const mintedCount = await sale.mintedCount();
    assert.equal(mintedCount.toNumber(), 0, 'minted count');
  });

  it('should not be possible to invest ETH', async function () {
    await assertThrow(
      new Promise((resolve, reject) => web3.eth.sendTransaction({
        from: accounts[0],
        to: sale.address,
        value: web3.toWei(1, 'milli'),
      }, (err, data) => {
        if (err) {
          reject(err);
        } else {
          resolve();
        }
      }))
    );
  });

  it('should not be possible to add off chain investment',
    async function () {
      await assertRevert(
        sale.addOffChainInvestment(accounts[1], 100)
      );
    });

  it('ahould not be possible to define a rate', async function () {
    await assertRevert(sale.defineRate(fakeRateETHCHF, 0));
  });

  it('should not be possible to processed sale', async function () {
    await assertRevert(sale.processSale());
  });

  it('should not be possible to prepareMinting', async function () {
    await assertRevert(sale.prepareMinting(1));
  });

  it('should not be possible to mint self', async function () {
    await assertRevert(sale.mintSelf());
  });

  it('should not be possible to mint', async function () {
    await assertRevert(sale.mint(1));
  });

  it('should not be possible to mint many', async function () {
    await assertRevert(sale.mintForManyUsers([ 1 ]));
  });

  it('should be possible to withdraw ETH', async function () {
    const tx = await sale.withdrawETHFunds();
    assert.equal(parseInt(tx.receipt.status), 1, 'status');
    assert.equal(tx.logs.length, 1);
    assert.equal(tx.logs[0].event, 'WithdrawETH');
    assert.equal(tx.logs[0].args.amount, 0, 'amount');
  });

  describe('before the sale', function () {
    it('should setup minter', async function () {
      await planAndSetupMinter();
      const minterAddr = await sale.minter();
      assert.equal(minterAddr, minter.address, 'sale');
    });

    it('should not be possible to add off chain investment',
      async function () {
        await assertRevert(
          sale.addOffChainInvestment(accounts[1], 100)
        );
      });

    it('should not be possible to define a rate', async function () {
      await assertRevert(sale.defineRate(fakeRateETHCHF, 0));
    });

    it('should not be possible to finalize the sale', async function () {
      await assertRevert(sale.processSale());
    });

    it('should not be possible to prepareMinting', async function () {
      await assertRevert(sale.prepareMinting(1));
    });

    it('should not be possible to mint', async function () {
      await assertRevert(sale.mint(1));
    });

    it('should not be possible to mint many', async function () {
      await assertRevert(sale.mintForManyUsers([ 1 ]));
    });

    describe('with a minter setup', function () {
      beforeEach(async function () {
        await planAndSetupMinter();
      });

      it('should be possible to add off chain investment',
        async function () {
          const tx = await sale.addOffChainInvestment(accounts[1], 100);
          assert.equal(parseInt(tx.receipt.status), 1, 'status');
          assert.equal(tx.logs.length, 1);
          assert.equal(tx.logs[0].event, 'Investment');
          assert.equal(tx.logs[0].args.investor, accounts[1], 'investor');
          assert.equal(tx.logs[0].args.amountETH.toNumber(), 0, 'amountETH');
          assert.equal(
            tx.logs[0].args.amountCHF.toNumber(),
            100,
            'amountCHF',
          );
        });

      it('should not be possible to define a rate', async function () {
        await assertRevert(sale.defineRate(fakeRateETHCHF, 0));
      });

      it('should not be possible to finalize sale', async function () {
        await assertRevert(sale.processSale());
      });

      it('should not be possible to prepareMinting', async function () {
        await assertRevert(sale.prepareMinting(1));
      });

      it('should not be possible to mint self', async function () {
        await assertRevert(sale.mintSelf());
      });

      it('should not be possible to mint', async function () {
        await assertRevert(sale.mint(1));
      });

      it('should not be possible to mint many', async function () {
        await assertRevert(sale.mintForManyUsers([ 1 ]));
      });
    });
  });

  describe('at the begining of the sale', function () {
    beforeEach(async function () {
      await planAndSetupMinter();
      await sale.setStep(2);
    });

    it('should not be possible to invest 0 ETH', async function () {
      await assertRevert(
        new Promise((resolve, reject) => web3.eth.sendTransaction({
          from: accounts[0],
          to: sale.address,
          value: 0,
          gas: 500000,
        }, (err, data) => {
          if (err) {
            reject(err);
          } else {
            resolve();
          }
        }))
      );
    });

    it('should not be possible to invest ETH with data', async function () {
      await assertRevert(
        new Promise((resolve, reject) => web3.eth.sendTransaction({
          from: accounts[0],
          to: sale.address,
          value: web3.toWei(1, 'milli'),
          data: web3.fromAscii('test'),
          gas: 500000,
        }, (err, data) => {
          if (err) {
            reject(err);
          } else {
            resolve();
          }
        }))
      );
    });

    it('should be possible to invest ETH', async function () {
      web3.eth.sendTransaction({
        from: accounts[0],
        to: sale.address,
        value: web3.toWei(1, 'milli'),
        gas: 500000,
      });
      const depositETH = await sale.investorDepositETH(1);
      assert.equal(
        web3.fromWei(depositETH, 'milli').toNumber(),
        1,
        'depositETH',
      );
      const depositCHF = await sale.investorDepositCHF(1);
      assert.equal(depositCHF.toNumber(), 0, 'depositCHF');
    });

    it('should be possible to add off chain investment', async function () {
      const tx = await sale.addOffChainInvestment(accounts[1], 100);
      assert.equal(parseInt(tx.receipt.status), 1, 'status');
      assert.equal(tx.logs.length, 1);
      assert.equal(tx.logs[0].event, 'Investment');
      assert.equal(tx.logs[0].args.investor, accounts[1], 'investor');
      assert.equal(tx.logs[0].args.amountETH.toNumber(), 0, 'amountETH');
      assert.equal(tx.logs[0].args.amountCHF.toNumber(), 100, 'amountCHF');

      const depositETH = await sale.investorDepositETH(2);
      assert.equal(
        web3.fromWei(depositETH, 'milli').toNumber(),
        0,
        'depositETH'
      );
      const depositCHF = await sale.investorDepositCHF(2);
      assert.equal(depositCHF.toNumber(), 100, 'depositCHF');
    });
  });

  describe('during the sale', function () {
    beforeEach(async function () {
      await planAndSetupMinter();
      await sale.setStep(2);
      await web3.eth.sendTransaction({
        from: accounts[0],
        to: sale.address,
        value: web3.toWei(1, 'milli'),
        gas: 500000,
      });
      await sale.addOffChainInvestment(accounts[0], 100);
    });

    it('should have one investor', async function () {
      const investorCount = await sale.investorCount();
      assert.equal(investorCount.toNumber(), 1, 'investor count');
    });

    it('should have 0 contributors', async function () {
      const contributorCount = await sale.contributorCount();
      assert.equal(contributorCount.toNumber(), 0, 'contributor count');
    });

    it('should have 0 prepared', async function () {
      const preparedCount = await sale.preparedCount();
      assert.equal(preparedCount.toNumber(), 0, 'prepared count');
    });

    it('should have 0 minted', async function () {
      const mintedCount = await sale.mintedCount();
      assert.equal(mintedCount.toNumber(), 0, 'minted count');
    });

    it('should have investor not prepared', async function () {
      const prepared = await sale.investorIsPrepared(1);
      assert.ok(!prepared, 'prepared');
    });

    it('should have investor not refunded', async function () {
      const refunded = await sale.investorIsRefunded(1);
      assert.ok(!refunded, 'refunded');
    });

    it('should have investor not minted', async function () {
      const minted = await sale.investorIsMinted(1);
      assert.ok(!minted, 'prepared');
    });

    it('should have a destination for existing investor', async function () {
      const destination = await sale.investorDestination(1);
      assert.equal(destination, accounts[0], 'destination');
    });

    it('should have ETH deposit for existing ETH investor', async function () {
      const depositETH = await sale.investorDepositETH(1);
      assert.equal(depositETH.toNumber(), web3.toWei(1, 'milli'), 'depositETH');
    });

    it('should have CHF deposit for existing CHF investor', async function () {
      const depositCHF = await sale.investorDepositCHF(1);
      assert.equal(depositCHF.toNumber(), 100, 'depositCHF');
    });

    it('should be possible to invest ETH', async function () {
      await web3.eth.sendTransaction({
        from: accounts[0],
        to: sale.address,
        value: web3.toWei(1, 'milli'),
        gas: 500000,
      });
      const depositETH = await sale.investorDepositETH(1);
      assert.equal(
        web3.fromWei(depositETH, 'milli').toNumber(),
        2,
        'depositETH'
      );
      const depositCHF = await sale.investorDepositCHF(1);
      assert.equal(depositCHF.toNumber(), 100, 'depositCHF');
    });

    it('should be possible to add off chain investment', async function () {
      const tx = await sale.addOffChainInvestment(accounts[1], 100);
      assert.equal(parseInt(tx.receipt.status), 1, 'status');
      assert.equal(tx.logs.length, 1);
      assert.equal(tx.logs[0].event, 'Investment');
      assert.equal(tx.logs[0].args.investor, accounts[1], 'investor');
      assert.equal(tx.logs[0].args.amountETH.toNumber(), 0, 'amountETH');
      assert.equal(tx.logs[0].args.amountCHF.toNumber(), 100, 'amountCHF');

      const depositETH = await sale.investorDepositETH(2);
      assert.equal(
        web3.fromWei(depositETH, 'milli').toNumber(),
        0,
        'depositETH'
      );
      const depositCHF = await sale.investorDepositCHF(2);
      assert.equal(depositCHF.toNumber(), 100, 'depositCHF');
    });

    it('should be possible to increase off chain investment',
      async function () {
        const tx = await sale.addOffChainInvestment(accounts[0], 100);
        assert.equal(parseInt(tx.receipt.status), 1, 'status');
        assert.equal(tx.logs.length, 1);
        assert.equal(tx.logs[0].event, 'Investment');
        assert.equal(tx.logs[0].args.investor, accounts[0], 'investor');
        assert.equal(
          web3.fromWei(tx.logs[0].args.amountETH, 'milli').toNumber(),
          0,
          'amountETH'
        );
        assert.equal(tx.logs[0].args.amountCHF.toNumber(), 100, 'amountCHF');

        const depositETH = await sale.investorDepositETH(1);
        assert.equal(
          web3.fromWei(depositETH, 'milli').toNumber(),
          1,
          'depositETH'
        );
        const depositCHF = await sale.investorDepositCHF(1);
        assert.equal(depositCHF.toNumber(), 200, 'depositCHF');
      });

    it('should be possible to add off chain investment up to hardcap',
      async function () {
        const hardCapCHF = await saleConfig.tokensaleLot1HardCapCHF();
        const tx = await sale.addOffChainInvestment(accounts[0], hardCapCHF.minus(100));
        assert.equal(parseInt(tx.receipt.status), 1, 'status');
        assert.equal(tx.logs.length, 1);
        assert.equal(tx.logs[0].event, 'Investment');
        assert.equal(tx.logs[0].args.investor, accounts[0], 'investor');
        assert.equal(
          web3.fromWei(tx.logs[0].args.amountETH, 'milli').toNumber(),
          0,
          'amountETH'
        );
        assert.equal(tx.logs[0].args.amountCHF.toNumber(), hardCapCHF.minus(100), 'amountCHF');

        const depositCHF = await sale.investorDepositCHF(1);
        assert.equal(depositCHF.toNumber(), hardCapCHF.toNumber(), 'depositCHF');
      });

    it('should not be possible to add off chain investment over hardcap',
      async function () {
        const hardCapCHF = await saleConfig.tokensaleLot1HardCapCHF();
        await assertRevert(
          sale.addOffChainInvestment(accounts[0], hardCapCHF)
        );
      });

    it('should be possible to reject 0.1 ETH', async function () {
      const tx = await sale.rejectETHFunds(1, web3.toWei(0.1, 'milli'));
      assert.equal(parseInt(tx.receipt.status), 1, 'status');
      assert.equal(tx.logs.length, 1);
      assert.equal(tx.logs[0].event, 'InvestmentETHRejected');
      assert.equal(tx.logs[0].args.investor, accounts[0], 'investor');
      assert.equal(
        web3.fromWei(tx.logs[0].args.amount, 'milli').toNumber(),
        0.1,
        'amountETH'
      );

      const depositETH = await sale.investorDepositETH(1);
      assert.equal(
        web3.fromWei(depositETH, 'milli').toNumber(),
        0.9,
        'depositETH'
      );
      const depositCHF = await sale.investorDepositCHF(1);
      assert.equal(depositCHF.toNumber(), 100, 'depositCHF');
    });

    it('should be possible to reject 10 CHF', async function () {
      const tx = await sale.rejectCHFFunds(1, 10);
      assert.equal(parseInt(tx.receipt.status), 1, 'status');
      assert.equal(tx.logs.length, 1);
      assert.equal(tx.logs[0].event, 'InvestmentCHFRejected');
      assert.equal(tx.logs[0].args.investor, accounts[0], 'investor');
      assert.equal(tx.logs[0].args.amount.toNumber(), 10, 'amountCHF');

      const depositCHF = await sale.investorDepositCHF(1);
      assert.equal(depositCHF.toNumber(), 90, 'depositCHF');
    });

    it('should not be possible to reject more ETH than deposited',
      async function () {
        await assertRevert(
          sale.rejectETHFunds(1, web3.toWei(100, 'milli'))
        );
      });

    it('should not be possible to reject more CHF than deposited',
      async function () {
        await assertRevert(sale.rejectCHFFunds(1, 1000));
      });

    it('should not be possible to define a rate',
      async function () {
        await assertRevert(sale.defineRate(fakeRateETHCHF, 0));
      });

    it('should not be possible to finalize the sale',
      async function () {
        await assertRevert(sale.processSale());
      });

    it('should not be possible to prepareMinting', async function () {
      await assertRevert(sale.prepareMinting(1));
    });

    it('should not be possible to mint self', async function () {
      await assertRevert(sale.mintSelf());
    });

    it('should not be possible to mint', async function () {
      await assertRevert(sale.mint(1));
    });

    it('should not be possible to mint many', async function () {
      await assertRevert(sale.mintForManyUsers([ 1 ]));
    });

    it('should be possible to withdraw ETH', async function () {
      const tx = await sale.withdrawETHFunds();
      assert.equal(parseInt(tx.receipt.status), 1, 'status');
      assert.equal(tx.logs.length, 1);
      assert.equal(tx.logs[0].event, 'WithdrawETH');
      assert.equal(
        web3.fromWei(tx.logs[0].args.amount, 'milli').toNumber(),
        1,
        'amount'
      );
    });
  });

  describe('during the review with too much ETH raised', function () {
    beforeEach(async function () {
      await planAndSetupMinter();
      await sale.setStep(2);
      await sale.addOffChainInvestment(accounts[1], 225000000);
      await web3.eth.sendTransaction({
        from: accounts[0],
        to: sale.address,
        value: web3.toWei(1, 'milli'),
        gas: 500000,
      });
      await sale.setStep(3);
    });

    it('should have two investors', async function () {
      const investorCount = await sale.investorCount();
      assert.equal(investorCount.toNumber(), 2, 'investor count');
    });

    it('should have 0 contributors', async function () {
      const contributorCount = await sale.contributorCount();
      assert.equal(contributorCount.toNumber(), 0, 'contributor count');
    });

    it('should have 0 prepared', async function () {
      const preparedCount = await sale.preparedCount();
      assert.equal(preparedCount.toNumber(), 0, 'prepared count');
    });

    it('should have 0 minted', async function () {
      const mintedCount = await sale.mintedCount();
      assert.equal(mintedCount.toNumber(), 0, 'minted count');
    });

    it('should be possible to define a rate and no decimals', async function () {
      const tx = await sale.defineRate(5 * 10 ** (3 + 5), 0);
      assert.equal(parseInt(tx.receipt.status), 1, 'status');
      assert.equal(tx.logs.length, 0);

      const raisedETH = await sale.raisedETH();
      assert.equal(raisedETH.toNumber(), web3.toWei(1, 'milli'), 'raisedETH');
      const refundETH = await sale.refundETH();
      assert.equal(refundETH.toNumber(), web3.toWei(0.5, 'milli'), 'refundETH');
      const totalRaisedCHF = await sale.totalRaisedCHF();
      assert.equal(totalRaisedCHF.toNumber(), 2.5 * 10 ** (6 + 2 /* cents */), 'totalRaisedCHF');
    });

    it('should be possible to define a rate*100 with 2 decimals', async function () {
      const tx = await sale.defineRate(5 * 10 ** (3 + 5 + 2), 2);
      assert.equal(parseInt(tx.receipt.status), 1, 'status');
      assert.equal(tx.logs.length, 0);

      const raisedETH = await sale.raisedETH();
      assert.equal(raisedETH.toNumber(), web3.toWei(1, 'milli'), 'raisedETH');
      const refundETH = await sale.refundETH();
      assert.equal(refundETH.toNumber(), web3.toWei(0.5, 'milli'), 'refundETH');
      const totalRaisedCHF = await sale.totalRaisedCHF();
      assert.equal(totalRaisedCHF.toNumber(), 2.5 * 10 ** (6 + 2 /* cents */), 'totalRaisedCHF');
    });

    it('should be possible to define rate*10000 and 2 decimals', async function () {
      const tx = await sale.defineRate(5 * 10 ** (3 + 5 + 4), 2);
      assert.equal(parseInt(tx.receipt.status), 1, 'status');
      assert.equal(tx.logs.length, 0);

      const raisedETH = await sale.raisedETH();
      assert.equal(raisedETH.toNumber(), web3.toWei(1, 'milli'), 'raisedETH');
      const refundETH = await sale.refundETH();
      assert.equal(refundETH.toNumber(), web3.toWei(0.995, 'milli'), 'refundETH');
      const totalRaisedCHF = await sale.totalRaisedCHF();
      assert.equal(totalRaisedCHF.toNumber(), 2.5 * 10 ** (6 + 2 /* cents */), 'totalRaisedCHF');
    });

    it('should be possible to define rate and 2 decimals and redefine it', async function () {
      await sale.defineRate(12 * 10 ** (3 + 5 + 3), 4);
      const tx = await sale.defineRate(5 * 10 ** (3 + 5), 0);
      assert.equal(parseInt(tx.receipt.status), 1, 'status');
      assert.equal(tx.logs.length, 0);

      const raisedETH = await sale.raisedETH();
      assert.equal(raisedETH.toNumber(), web3.toWei(1, 'milli'), 'raisedETH');
      const refundETH = await sale.refundETH();
      assert.equal(refundETH.toNumber(), web3.toWei(0.5, 'milli'), 'refundETH');
      const totalRaisedCHF = await sale.totalRaisedCHF();
      assert.equal(totalRaisedCHF.toNumber(), 2.5 * 10 ** (6 + 2 /* cents */), 'totalRaisedCHF');
    });

    describe('with a rate defined', function () {
      beforeEach(async function () {
        await sale.defineRate(5 * 10 ** (3 + 5 + 4), 2);
      });

      it('should be possible to finalize the sale', async function () {
        const tx = await sale.processSale();
        assert.equal(parseInt(tx.receipt.status), 1, 'status');
        assert.equal(tx.logs.length, 1);
        assert.equal(tx.logs[0].event, 'SaleProcessed');
        assert.equal(tx.logs[0].args.raisedCHF.toNumber(), 2.5 * 10 ** (6 + 2 /* cents */), 'raisedCHF');
        assert.equal(tx.logs[0].args.refundETH.toNumber(), web3.toWei(0.995, 'milli'), 'refundETH');
      });

      it('should be possible to finalize the sale after rate redefined', async function () {
        await sale.defineRate(5 * 10 ** (3 + 5 + 3), 2);

        const tx = await sale.processSale();
        assert.equal(parseInt(tx.receipt.status), 1, 'status');
        assert.equal(tx.logs.length, 1);
        assert.equal(tx.logs[0].event, 'SaleProcessed');
        assert.equal(tx.logs[0].args.raisedCHF.toNumber(), 2.5 * 10 ** (6 + 2 /* cents */), 'raisedCHF');
        assert.equal(tx.logs[0].args.refundETH.toNumber(), web3.toWei(0.95, 'milli'), 'refundETH');
      });
    });

    describe('and processed', function () {
      beforeEach(async function () {
        await sale.defineRate(fakeRateETHCHF, 0);
        await sale.processSale();
      });

      it('should have a ETHCHF rate', async function () {
        const rateETHCHF = await sale.rateETHCHF(0);
        assert.equal(rateETHCHF.toNumber(), fakeRateETHCHF, 'rateETHCHF');
      });

      it('should have a ETHCHF rate with more than 2 decimals', async function () {
        const rateETHCHF = await sale.rateETHCHF(4);
        assert.equal(rateETHCHF.toNumber(), 5 * 10 ** (5 + 3 + 4), 'rateETHCHF');
      });

      it('should have a WEIPerCHFCent rate', async function () {
        const rateWEIPerCHFCent = await sale.rateWEIPerCHFCent();
        assert.equal(rateWEIPerCHFCent.toNumber(), 0.2 * 10 ** (18 - 2 - 5 - 3), 'rateWEIPerCHFCent');
      });

      it('should have ETH', async function () {
        const balanceETH = await web3.eth.getBalance(sale.address);
        assert.equal(balanceETH.toNumber(), web3.toWei(1, 'milli', 'balanceETH'));
      });

      it('should have raised CHF', async function () {
        const raisedCHF = await sale.raisedCHF();
        assert.equal(raisedCHF.toNumber(), 225000000, 'raisedCHF');
      });

      it('should have a refund ratio', async function () {
        const refundRatio = await sale.refundRatio();
        const refundETHPrecision = await sale.refundETHPrecision();
        assert.equal(refundETHPrecision, 10 ** 9, 'refundETHPrecision');
        assert.equal(refundRatio.toNumber(), 2 * refundETHPrecision, 'refundRatio');
      });

      it('should not allow non-investor to prepareMint', async function () {
        await assertRevert(sale.prepareMinting(1000));
      });

      it('should allow prepareMinting for ETH investor', async function () {
        const tx = await sale.prepareMinting(1);
        assert.equal(tx.logs.length, 0);
        assert.equal(parseInt(tx.receipt.status), 1, 'status');

        const tokens = await sale.investorTokens(1);
        assert.equal(tokens.toString(10), '500000', 'tokens');
        const refunded = await sale.investorIsRefunded(1);
        assert.ok(refunded, 'refunded');
      });

      it('should not allow prepareMinting twice ETH investor', async function () {
        const tx = await sale.prepareMinting(1);
        assert.equal(tx.logs.length, 0);
        assert.equal(parseInt(tx.receipt.status), 1, 'status');

        await assertRevert(sale.prepareMinting(1));
      });

      it('should allow prepareMinting for CHF investor', async function () {
        const tx = await sale.prepareMinting(2);
        assert.equal(tx.logs.length, 0);
        assert.equal(parseInt(tx.receipt.status), 1, 'status');
        
        const tokens = await sale.investorTokens(2);
        assert.equal(tokens.toString(10), '4500000', 'tokens');
        const refunded = await sale.investorIsRefunded(2);
        assert.ok(!refunded, 'refunded');
      });

      it('should allow prepareMinting for many users', async function () {
        const tx = await sale.prepareMintingForManyUsers([1, 2]);
        assert.equal(tx.logs.length, 0);
        assert.equal(parseInt(tx.receipt.status), 1, 'status');
      });

      describe('after prepareMinting', function () {
        beforeEach(async function () {
          await sale.prepareMintingForManyUsers([1, 2]);
          await sale.enableMinting();
        });

        it('should have 2 investors', async function () {
          const investorCount = await sale.investorCount();
          assert.equal(investorCount.toNumber(), 2, 'investor count');
        });

        it('should have 2 contributors', async function () {
          const contributorCount = await sale.contributorCount();
          assert.equal(contributorCount.toNumber(), 2, 'contributor count');
        });

        it('should have 2 prepared', async function () {
          const preparedCount = await sale.preparedCount();
          assert.equal(preparedCount.toNumber(), 2, 'prepared count');
        });

        it('should have 0 minted', async function () {
          const mintedCount = await sale.mintedCount();
          assert.equal(mintedCount.toNumber(), 0, 'minted count');
        });

        it('should not allow non investor to mint', async function () {
          await assertRevert(sale.mintSelf({ from: accounts[9] }));
        });

        it('should not allow to mint twice', async function () {
          const tx = await sale.mintSelf({ from: userAddresses[1] });
          assert.equal(tx.logs.length, 0);
          assert.equal(parseInt(tx.receipt.status), 1, 'status');

          await assertRevert(sale.mintSelf({ from: userAddresses[1] }));
        });

        it('should allow Mint self', async function () {
          const tx = await sale.mintSelf({ from: userAddresses[1] });
          assert.equal(tx.logs.length, 0);
          assert.equal(parseInt(tx.receipt.status), 1, 'status');

          const minted = await sale.investorIsMinted(2);
          assert.ok(minted, 'minted');
        });

        it('should allow Mint for ETH investor', async function () {
          const tx = await sale.mint(1);
          assert.equal(tx.logs.length, 0);
          assert.equal(parseInt(tx.receipt.status), 1, 'status');

          const minted = await sale.investorIsMinted(1);
          assert.ok(minted, 'minted');
        });

        it('should allow Mint for CHF investor', async function () {
          const tx = await sale.mint(2);
          assert.equal(tx.logs.length, 0);
          assert.equal(parseInt(tx.receipt.status), 1, 'status');

          const minted = await sale.investorIsMinted(2);
          assert.ok(minted, 'minted');
        });

        it('should allow Mint for Many investor', async function () {
          const tx = await sale.mintForManyUsers([ 1, 2 ]);
          assert.equal(tx.logs.length, 0);
          assert.equal(parseInt(tx.receipt.status), 1, 'status');

          const minted1 = await sale.investorIsMinted(1);
          assert.ok(minted1, 'minted');
          const minted2 = await sale.investorIsMinted(2);
          assert.ok(minted2, 'minted');
        });
  
        it('should have ETH', async function () {
          const balanceETH = await web3.eth.getBalance(sale.address);
          assert.equal(balanceETH.toNumber(), web3.toWei(0.5, 'milli', 'balanceETH'), 'balance');
        });
      });
    });
  });

  describe('during the review with not enough raised', function () {
    beforeEach(async function () {
      await planAndSetupMinter();
      await sale.setStep(2);
      await sale.addOffChainInvestment(accounts[1], 175000000);
      await web3.eth.sendTransaction({
        from: accounts[0],
        to: sale.address,
        value: web3.toWei(1, 'milli'),
        gas: 500000,
      });
      await sale.setStep(3);
    });

    it('should be possible to define a realistic rate and 2 decimals', async function () {
      const tx = await sale.defineRate(50145 /* 501,45 CHF */, 2);
      assert.equal(parseInt(tx.receipt.status), 1, 'status');
      assert.equal(tx.logs.length, 0);

      const raisedETH = await sale.raisedETH();
      assert.equal(raisedETH.toNumber(), web3.toWei(1, 'milli'), 'raisedETH');
      const refundETH = await sale.refundETH();
      assert.equal(refundETH.toNumber(), 0, 'refundETH');
      const totalRaisedCHF = await sale.totalRaisedCHF();
      assert.equal(totalRaisedCHF.toNumber(), 175000050, 'totalRaisedCHF');
    });

    it('should be possible to define a rate with 2 decimals', async function () {
      const tx = await sale.defineRate(5 * 10 ** (3 + 5), 2);
      assert.equal(parseInt(tx.receipt.status), 1, 'status');
      assert.equal(tx.logs.length, 0);

      const raisedETH = await sale.raisedETH();
      assert.equal(raisedETH.toNumber(), web3.toWei(1, 'milli'), 'raisedETH');
      const refundETH = await sale.refundETH();
      assert.equal(refundETH.toNumber(), 0, 'refundETH');
      const totalRaisedCHF = await sale.totalRaisedCHF();
      assert.equal(totalRaisedCHF.toNumber(), 175500000, 'totalRaisedCHF');
    });

    describe('and a rate defined', function () {
      beforeEach(async function () {
        await sale.defineRate(5 * 10 ** (3 + 5), 2);
      });

      it('should process the sale', async function () {
        const tx = await sale.processSale();
        assert.equal(parseInt(tx.receipt.status), 1, 'status');
        assert.equal(tx.logs.length, 1);
        assert.equal(tx.logs[0].event, 'SaleProcessed');
        assert.equal(tx.logs[0].args.raisedCHF.toNumber(), 175500000, 'raisedCHF');
        assert.equal(tx.logs[0].args.refundETH.toNumber(), 0, 'refundETH');
      });
    });

    describe('and processed', function () {
      beforeEach(async function () {
        await sale.defineRate(fakeRateETHCHF, 0);
        await sale.processSale();
      });

      it('should have no refund', async function () {
        const refundRatio = await sale.refundRatio();
        assert.equal(refundRatio.toNumber(), 0, 'refundRatio');
      });

      it('should have ETH', async function () {
        const balanceETH = await web3.eth.getBalance(sale.address);
        assert.equal(balanceETH.toNumber(), web3.toWei(1, 'milli', 'balanceETH'));
      });

      it('should have raised CHF', async function () {
        const raisedCHF = await sale.raisedCHF();
        assert.equal(raisedCHF.toNumber(), 175000000, 'raisedCHF');
      });

      it('should allow prepareMinting for ETH investor', async function () {
        const tx = await sale.prepareMinting(1);
        assert.equal(tx.logs.length, 0);
        assert.equal(parseInt(tx.receipt.status), 1, 'status');

        const tokens = await sale.investorTokens(1);
        assert.equal(tokens.toString(10), '1000000', 'tokens');
        const refunded = await sale.investorIsRefunded(1);
        assert.ok(!refunded, 'refunded');
      });

      it('should allow prepareMinting for CHF investor', async function () {
        const tx = await sale.prepareMinting(2);
        assert.equal(tx.logs.length, 0);
        assert.equal(parseInt(tx.receipt.status), 1, 'status');
        
        const tokens = await sale.investorTokens(2);
        assert.equal(tokens.toString(10), '3500000', 'tokens');
        const refunded = await sale.investorIsRefunded(2);
        assert.ok(!refunded, 'refunded');
      });

      it('should allow prepareMinting for many users', async function () {
        const tx = await sale.prepareMintingForManyUsers([1, 2]);
        assert.equal(tx.logs.length, 0);
        assert.equal(parseInt(tx.receipt.status), 1, 'status');
      });

      describe('after prepareMinting', function () {
        beforeEach(async function () {
          await sale.prepareMintingForManyUsers([1, 2]);
          await sale.enableMinting();
        });

        it('should have 2 investors', async function () {
          const investorCount = await sale.investorCount();
          assert.equal(investorCount.toNumber(), 2, 'investor count');
        });

        it('should have 2 contributors', async function () {
          const contributorCount = await sale.contributorCount();
          assert.equal(contributorCount.toNumber(), 2, 'contributor count');
        });

        it('should have 2 prepared', async function () {
          const preparedCount = await sale.preparedCount();
          assert.equal(preparedCount.toNumber(), 2, 'prepared count');
        });

        it('should have 0 minted', async function () {
          const mintedCount = await sale.mintedCount();
          assert.equal(mintedCount.toNumber(), 0, 'minted count');
        });

        it('should allow Mint self', async function () {
          const tx = await sale.mintSelf({ from: userAddresses[1] });
          assert.equal(tx.logs.length, 0);
          assert.equal(parseInt(tx.receipt.status), 1, 'status');

          const minted = await sale.investorIsMinted(2);
          assert.ok(minted, 'minted');
        });

        it('should allow Mint for ETH investor', async function () {
          const tx = await sale.mint(1);
          assert.equal(tx.logs.length, 0);
          assert.equal(parseInt(tx.receipt.status), 1, 'status');

          const minted = await sale.investorIsMinted(1);
          assert.ok(minted, 'minted');
        });

        it('should allow Mint for CHF investor', async function () {
          const tx = await sale.mint(2);
          assert.equal(tx.logs.length, 0);
          assert.equal(parseInt(tx.receipt.status), 1, 'status');

          const minted = await sale.investorIsMinted(2);
          assert.ok(minted, 'minted');
        });

        it('should have ETH', async function () {
          const balanceETH = await web3.eth.getBalance(sale.address);
          assert.equal(balanceETH.toNumber(), web3.toWei(1, 'milli'), 'balance');
        });
      });
    });
  });

  describe('during the review with all ETH refunded', function () {
    beforeEach(async function () {
      await planAndSetupMinter();
      await sale.setStep(2);
      await sale.addOffChainInvestment(accounts[1], 250000000);
      await web3.eth.sendTransaction({
        from: accounts[0],
        to: sale.address,
        value: web3.toWei(1, 'milli'),
        gas: 500000,
      });
      await sale.setStep(3);
    });

    describe('and processed', function () {
      beforeEach(async function () {
        await sale.defineRate(fakeRateETHCHF, 2);
        await sale.processSale();
      });

      it('should have all ETH refunded', async function () {
        const refundRatio = await sale.refundRatio();
        const refundETHPrecision = await sale.refundETHPrecision();
        assert.equal(refundRatio.toNumber(), 1 * refundETHPrecision, 'refundRatio');
      });

      it('should have ETH', async function () {
        const balanceETH = await web3.eth.getBalance(sale.address);
        assert.equal(balanceETH.toNumber(), web3.toWei(1, 'milli', 'balanceETH'));
      });

      it('should have raised CHF', async function () {
        const raisedCHF = await sale.raisedCHF();
        assert.equal(raisedCHF.toNumber(), 250000000, 'raisedCHF');
      });

      it('should allow prepareMinting for ETH investor', async function () {
        const tx = await sale.prepareMinting(1);
        assert.equal(tx.logs.length, 0);
        assert.equal(parseInt(tx.receipt.status), 1, 'status');

        const tokens = await sale.investorTokens(1);
        assert.equal(tokens.toString(10), '0', 'tokens');
        const refunded = await sale.investorIsRefunded(1);
        assert.equal(refunded, true, 'refunded');
      });

      it('should allow prepareMinting for CHF investor', async function () {
        const tx = await sale.prepareMinting(2);
        assert.equal(tx.logs.length, 0);
        assert.equal(parseInt(tx.receipt.status), 1, 'status');
        
        const tokens = await sale.investorTokens(2);
        assert.equal(tokens.toString(10), '5000000', 'tokens');
        const refunded = await sale.investorIsRefunded(2);
        assert.ok(!refunded, 'refunded');
      });

      it('should allow prepareMinting for many users', async function () {
        const tx = await sale.prepareMintingForManyUsers([1, 2]);
        assert.equal(tx.logs.length, 0);
        assert.equal(parseInt(tx.receipt.status), 1, 'status');
      });

      describe('after prepareMinting', function () {
        beforeEach(async function () {
          await sale.prepareMintingForManyUsers([1, 2]);
          await sale.enableMinting();
        });

        it('should have two investors prepared', async function () {
          const preparedCount = await sale.preparedCount();
          assert.equal(preparedCount.toNumber(), 2, 'prepared investor count');
        });

        it('should not allow mint self ETH investor', async function () {
          await assertRevert(sale.mintSelf({ from: accounts[0] }));
        });
        
        it('should allow mint self CHF investor', async function () {
          const tx = await sale.mintSelf({ from: accounts[1] });
          assert.equal(tx.logs.length, 0);
          assert.equal(parseInt(tx.receipt.status), 1, 'status');

          const minted = await sale.investorIsMinted(1);
          assert.ok(!minted, 'minted');
        });

        it('should not allow to mint for ETH investor', async function () {
          await assertRevert(sale.mint(1));
        });

        it('should allow Mint for CHF investor', async function () {
          const tx = await sale.mint(2);
          assert.equal(tx.logs.length, 0);
          assert.equal(parseInt(tx.receipt.status), 1, 'status');

          const minted = await sale.investorIsMinted(2);
          assert.ok(minted, 'minted');
        });

        it('should have no ETH', async function () {
          const balanceETH = await web3.eth.getBalance(sale.address);
          assert.equal(balanceETH.toNumber(), 0, 'balance');
        });
      });
    });
  });

  describe('after the distribution', function () {
    beforeEach(async function () {
      await planAndSetupMinter();
      await sale.setStep(2);
      await sale.addOffChainInvestment(accounts[1], 100);
      await sale.setStep(3);
      await sale.defineRate(fakeRateETHCHF, 2);
      await sale.processSale();
      await sale.prepareMinting(2);
      await sale.enableMinting();
      await sale.mint(2);
      await sale.setStep(6);
    });

    it('should have one investors minted', async function () {
      const mintedCount = await sale.mintedCount();
      assert.equal(mintedCount.toNumber(), 1, 'investors minted');
    });

    it('should finish distribution', async function () {
      const tx = await sale.finishDistribution();
      assert.equal(parseInt(tx.receipt.status), 1, 'status');
      assert.equal(tx.logs.length, 1);
      assert.equal(tx.logs[0].event, 'OwnershipTransferred');
      assert.equal(
        tx.logs[0].args.previousOwner,
        sale.address,
        'previousOwner'
      );
      assert.equal(
        tx.logs[0].args.newOwner,
        accounts[0],
        'newOwner'
      );
    });
  });
});
