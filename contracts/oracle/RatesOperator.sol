pragma solidity ^0.4.24;

import "../zeppelin/math/SafeMath.sol";
import "./RatesProvider.sol";
import "../Operator.sol";


/**
 * @title RatesOperator
 * @dev RatesOperator interface
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subjects to Swiss Law without reference to its conflicts of law rules.
 *
 * Error messages
 * RO01:
 * RO02:
 * RO03:
 * RO04:
 */
contract RatesOperator is Operator {
  using SafeMath for uint256;

  uint256 public constant PERCENT = 100;

  struct OperatorActivity {
    uint256 lastOperationAt;
    uint256 frequencyCounter;

    uint256 frequencyPeriod;
    uint256 frequencyThreshold;
    uint256 variationThreshold;
  }

  RatesProvider public ratesProvider;
  mapping (uint8 => OperatorActivity) private operatorsActivity;

  /**
   * @dev constructor
   */
  constructor(RatesProvider _ratesProvider) public {
    ratesProvider = _ratesProvider;
  }

  /**
   * @dev lastOperationAt
   */
  function lastOperationAt(uint8 _operatorId) public view returns (uint256) {
    return operatorsActivity[_operatorId].lastOperationAt;
  }

  /**
   * @dev frequencyCounter
   */
  function frequencyCounter(uint8 _operatorId) public view returns (uint256) {
    return operatorsActivity[_operatorId].frequencyCounter;
  }

  /**
   * @dev frequencyPeriod
   */
  function frequencyPeriod(uint8 _operatorId) public view returns (uint256) {
    return operatorsActivity[_operatorId].frequencyPeriod;
  }

  /**
   * @dev frequencyThreshold
   */
  function frequencyThreshold(uint8 _operatorId)
    public view returns (uint256)
  {
    return operatorsActivity[_operatorId].frequencyThreshold;
  }

  /**
   * @dev variationThreshold
   */
  function variationThreshold(uint8 _operatorId)
    public view returns (uint256)
  {
    return operatorsActivity[_operatorId].variationThreshold;
  }

  /**
   * @dev defineOperatorThresholds
   */
  function defineOperatorThresholds(
    uint8 _operatorId,
    uint256 _frequencyPeriod,
    uint256 _frequencyThreshold,
    uint256 _variationThreshold)
    public
  {
    operatorsActivity[_operatorId] = OperatorActivity(
      0,
      0,
      _frequencyPeriod,
      _frequencyThreshold,
      _variationThreshold
    );
    emit OperatorThresholdsDefined(
      _operatorId,
      _frequencyPeriod,
      _frequencyThreshold,
      _variationThreshold
    );
  }

  /**
   * @dev variation percentage
   */
  function evalVariation(uint256 _newValue) public view returns (uint256) {
    uint256 oldValue = ratesProvider.rateWEIPerCHFCent();
    
    return (
      oldValue == 0 || _newValue == 0
    ) ? 0 : _newValue.mul(PERCENT).div(oldValue);
  }

  /**
   * @dev frequency counter
   */
  function evalFrequency(
    uint256 _oldFrequencyCounter,
    uint256 _lastOperationAt,
    uint256 _frequencyPeriod,
    uint256 _frequencyThreshold)
    public view returns (uint256)
  {
    uint256 delta = currentTime().sub(_lastOperationAt);

    uint256 newFrequencyCounter = _frequencyPeriod;
    if (delta < _frequencyPeriod) {
      uint256 recovery = delta.mul(_frequencyThreshold);
      if (recovery < _oldFrequencyCounter) {
        newFrequencyCounter = newFrequencyCounter.add(
          _oldFrequencyCounter).sub(recovery);
      }
    }
    return newFrequencyCounter;
  }

  /**
   * @dev define rate
   */
  function defineRate(uint256 _rateWEIPerCHFCent)
    public onlyOperator
  {
    uint8 operatorId = operatorIds[msg.sender];
    OperatorActivity storage activity = operatorsActivity[operatorId];

    if (activity.frequencyThreshold > 0) {
      activity.frequencyCounter = evalFrequency(
        activity.frequencyCounter,
        activity.lastOperationAt,
        activity.frequencyPeriod,
        activity.frequencyThreshold);
      require(
        activity.frequencyCounter <= activity.frequencyThreshold.mul(
          activity.frequencyPeriod),
        "RO01");
      activity.lastOperationAt = currentTime();
    }

    if (activity.variationThreshold > 0) {
      require(_rateWEIPerCHFCent != 0, "R002");
      uint256 variation = evalVariation(_rateWEIPerCHFCent);
      if (variation != 0) {
        require(variation > PERCENT.sub(activity.variationThreshold), "RO03");
        require(variation < PERCENT.add(activity.variationThreshold), "RO04");
      }
    }

    ratesProvider.defineRate(_rateWEIPerCHFCent);
  }

  /**
   * @dev define rate with decimals
   */
  function defineETHCHFRate(uint256 _rateETHCHF, uint256 _rateETHCHFDecimal)
    public onlyOperator
  {
    defineRate(
      ratesProvider.convertRateFromETHCHF(_rateETHCHF, _rateETHCHFDecimal));
  }

  /**
   * @dev current time
   */
  function currentTime() private view returns (uint256) {
    // solium-disable-next-line security/no-block-members
    return now;
  }

  event OperatorThresholdsDefined(
    uint8 operatorId,
    uint256 period,
    uint256 frequency,
    uint256 variation
  );
}
