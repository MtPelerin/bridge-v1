'user strict';

const assertRevert = require('../helpers/assertRevert');

var SaleConfigMock = artifacts.require('mock/SaleConfigMock.sol');
var MPLTokensalePlanMock = artifacts.require('mock/MPLTokensalePlanMock.sol');

contract('MPLTokensalePlan', function (accounts) {
  let salePlan, config;
  let now = (new Date().getTime() / 1000);

  beforeEach(async function () {
    config = await SaleConfigMock.new();
    salePlan = await MPLTokensalePlanMock.new(config.address);
  });

  it('should have no steps', async function () {
    const stepsCount = await salePlan.stepsCount();
    assert.equal(stepsCount, 0, 'no steps');
  });

  it('should have sale config', async function () {
    const configAddr = await salePlan.saleConfig();
    assert.equal(configAddr, config.address, 'Sale Config');
  });

  it('should not be at step 0', async function () {
    await assertRevert(salePlan.dummyWhenStepIs(0));
  });

  it('should not be between steps 0 and 1', async function () {
    await assertRevert(salePlan.dummyWhenBetweenSteps(0, 1));
  });

  describe('with the sale planned', function () {
    beforeEach(async function () {
      const tx = await salePlan.plan();
      assert.equal(tx.receipt.status, '0x01', 'status');
    });

    it('should have 8 steps', async function () {
      const stepsCount = await salePlan.stepsCount();
      assert.equal(stepsCount.toNumber(), 8, '8 steps');
    });

    it('should be in step 0', async function () {
      const currentStep = await salePlan.currentStep();
      assert.equal(currentStep.toNumber(), 0, 'step 0');
    });

    it('should not accept to plan again', async function () {
      await assertRevert(salePlan.plan());
    });

    it('should have modifier true for step 0', async function () {
      const yes = await salePlan.dummyWhenStepIs(0);
      assert.ok(yes, 'step 0');
    });

    it('should have modifier failed for step not 0', async function () {
      await assertRevert(salePlan.dummyWhenStepIs(1));
    });

    it('should have modifier true for between 0, 1', async function () {
      const yes = await salePlan.dummyWhenBetweenSteps(0, 1);
      assert.ok(yes, 'between 0 and 1');
    });

    it('should have a modifier failed for between 0,0', async function () {
      await assertRevert(salePlan.dummyWhenBetweenSteps(0, 0));
    });

    it('should have a modifier failed for between 1,0', async function () {
      await assertRevert(salePlan.dummyWhenBetweenSteps(1, 0));
    });

    it('should have sale live at for READY(1) step', async function () {
      const saleLiveAtConfig = await config.openingTime();
      const saleLiveAt = await salePlan.mockedStepTransitionEndTime(1);
      assert.equal(saleLiveAt.toNumber(),
        saleLiveAtConfig.toNumber(), 'sale live at');
    });

    it('should have sale closed at for LIVE(1) step', async function () {
      const durationConfig = await config.duration();
      const saleDuration = await salePlan.mockedStepTransitionDelay(2);
      assert.equal(saleDuration.toNumber(),
        durationConfig.toNumber(), 'sale closed at');
    });

    it('should have a delay for MINTING(5) step', async function () {
      const delayConfig = await config.mintingDelay();
      const mintingDelay = await salePlan.mockedStepTransitionDelay(5);
      assert.equal(mintingDelay.toNumber(),
        delayConfig.toNumber(), 'delay for minting');
    });

    it('should not allow to adjust opening time', async function () {
      await assertRevert(salePlan.updateSaleOpeningTime(now + 3600));
    });
  
    describe('with the configuration persisted', function () {
      beforeEach(async function () {
        await salePlan.nextStepPublic();
      });

      it('should be between steps 0 and 1', async function () {
        const between = salePlan.dummyWhenBetweenSteps(0, 1);
        assert.ok(between, 'between 0 and 1');
      });

      it('should be between steps 1 and 2', async function () {
        const between = salePlan.dummyWhenBetweenSteps(1, 2);
        assert.ok(between, 'between 1 and 2');
      });

      it('with one more step, should not be between steps 0 and 1',
        async function () {
          await salePlan.nextStepPublic();
          await assertRevert(salePlan.dummyWhenBetweenSteps(0, 1));
        }
      );

      it('should allow to adjust opening time', async function () {
        const tx = await salePlan.updateSaleOpeningTime(now + 3600);
        assert.equal(tx.receipt.status, '0x01', 'status');
      });
    });
  });
});
