'user strict';

var MPLDryRunSaleConfig = artifacts.require('tokensale/MPLDryRunSaleConfig.sol');

contract('MPLDryRunSaleConfig', function (accounts) {
  let mplSaleConfig;

  const OPENING_TIME = 1546300800;

  beforeEach(async function () {
    mplSaleConfig = await MPLDryRunSaleConfig.new();
  });

  it('should have the terms of sale hash', async function () {
    const hash = await mplSaleConfig.termsOfSaleHash();
    assert.equal(hash,
      '0xe3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      'termsOfSale');
  });

  it('should have a token supply', async function () {
    const tokenSupply = await mplSaleConfig.tokenSupply();
    assert.equal(tokenSupply, 21 * (10 ** 6) * (10 ** 18), 'tokenSupply');
  });

  it('should have a tokenized share percent', async function () {
    const tokenizedSharePercent = await mplSaleConfig.tokenizedSharePercent();
    assert.equal(tokenizedSharePercent.toNumber(), 21, 'tokenizedSharePercent');
  });

  it('should have a tokensale hardCap CHF for Lot1', async function () {
    const tokensaleLot1HardCapCHF = await mplSaleConfig.tokensaleLot1HardCapCHF();
    assert.equal(
      tokensaleLot1HardCapCHF.toNumber(),
      2.5 * (10 ** 6) * (10 ** 2),
      'tokensaleLot1HardCapCHF'
    );
  });

  it('should have a tokensale lot1 share percent', async function () {
    const tokensaleLot1SharePercent = await mplSaleConfig.tokensaleLot1SharePercent();
    assert.equal(tokensaleLot1SharePercent.toNumber(), 23, 'tokensaleLot1SharePercent');
  });

  it('should have a tokensale lot1 supply', async function () {
    const tokensaleLot1Supply = await mplSaleConfig.tokensaleLot1Supply();
    assert.equal(
      tokensaleLot1Supply.toNumber(),
      5 * (10 ** 6) * (10 ** 18),
      'tokensaleLot1Supply'
    );
  });

  it('should have a tokensale lot2 share percent', async function () {
    const tokensaleLot2SharePercent = await mplSaleConfig.tokensaleLot2SharePercent();
    assert.equal(tokensaleLot2SharePercent.toNumber(), 66, 'tokensaleLot2SharePercent');
  });

  it('should have a tokensale lot2 supply', async function () {
    const tokensaleLot2Supply = await mplSaleConfig.tokensaleLot2Supply();
    assert.equal(
      tokensaleLot2Supply.toNumber(),
      14 * (10 ** 6) * (10 ** 18),
      'tokensaleLot2Supply'
    );
  });

  it('should have a reserved supply', async function () {
    const reservedSupply = await mplSaleConfig.reservedSupply();
    assert.equal(
      reservedSupply.toNumber(),
      2 * (10 ** 6) * (10 ** 18),
      'reservedSupply'
    );
  });

  it('should have a tokens amount per CHF (cents !)', async function () {
    const tokensAmountPerCHFCent = await mplSaleConfig.tokensAmountPerCHF();
    assert.equal(
      tokensAmountPerCHFCent.toNumber(),
      2 * (10 ** 16),
      'tokensAmountPerCHF'
    );
  });

  it('should have a minimal investement', async function () {
    const minimalETHInvestment = await mplSaleConfig.minimalETHInvestment();
    assert.equal(
      web3.fromWei(minimalETHInvestment.toNumber(), 'ether'),
      0.1,
      'minimalETHInvestment'
    );
  });

  it('should have an opening time', async function () {
    const openingTime = await mplSaleConfig.openingTime();
    assert.equal(openingTime, OPENING_TIME, 'openingTime');
  });

  it('should have a duration', async function () {
    const duration = await mplSaleConfig.duration();
    assert.equal(duration, 2 * 3600, 'duration');
  });

  it('should have a sale closing time', async function () {
    const saleClosingTime =
      await mplSaleConfig.closingTime();
    assert.equal(
      saleClosingTime,
      OPENING_TIME + 2 * 3600,
      'saleClosingTime'
    );
  });

  it('should have a minting delay', async function () {
    const mintingDelay =
      await mplSaleConfig.mintingDelay();
    assert.equal(
      mintingDelay.toNumber(),
      2 * 3600,
      'minting delay'
    );
  });
});
