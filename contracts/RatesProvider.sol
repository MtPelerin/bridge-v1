pragma solidity ^0.4.24;

import "./zeppelin/math/SafeMath.sol";
import "./interface/IRatesProvider.sol";
import "./Authority.sol";


/**
 * @title RatesProvider
 * @dev RatesProvider interface
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
 */
contract RatesProvider is IRatesProvider, Authority {
  using SafeMath for uint256;

  // WEICHF rate is in ETH_wei/CHF_cents with no fractional parts
  uint256 public rateWEIPerCHFCent;

  /**
   * @dev constructor
   */
  constructor() public {
  }

  /**
   * @dev convert rate from ETHCHF to WEICents
   */
  function convertRateFromETHCHF(
    uint256 _rateETHCHF,
    uint256 _rateETHCHFDecimal
  ) public pure returns (uint256) {
    if (_rateETHCHF == 0) {
      return 0;
    }

    return uint256(
      10**(_rateETHCHFDecimal.add(18 - 2))
    ).div(_rateETHCHF);
  }

  /**
   * @dev convert rate from WEICents to ETHCHF
   */
  function convertRateToETHCHF(
    uint256 _rateWEIPerCHFCent,
    uint256 _rateETHCHFDecimal) public pure returns (uint256) {
    if (_rateWEIPerCHFCent == 0) {
      return 0;
    }

    return uint256(
      10**(_rateETHCHFDecimal.add(18 - 2))
    ).div(_rateWEIPerCHFCent);
  }

  /**
   * @dev convert CHF to ETH
   */
  function convertCHFCentToWEI(uint256 _amountCHFCent)
    public view returns (uint256) {
    if (rateWEIPerCHFCent == 0) {
      return 0;
    }

    return _amountCHFCent.mul(rateWEIPerCHFCent);
  }

  /**
   * @dev convert ETH to CHF
   */
  function convertWEItoCHFCent(uint256 _amountETH)
    public view returns (uint256) {
    if (rateWEIPerCHFCent == 0) {
      return 0;
    }

    return _amountETH.div(rateWEIPerCHFCent);
  }

  /* Current ETHCHF rates */
  function rateWEIPerCHFCent() public view returns (uint256) {
    return rateWEIPerCHFCent;
  }
  
  /**
   * @dev rate ETHCHF
   */
  function rateETHCHF(uint256 _rateETHCHFDecimal)
    public view returns (uint256)
  {
    return convertRateToETHCHF(rateWEIPerCHFCent, _rateETHCHFDecimal);
  }

  /**
   * @dev define rate
   */
  function defineRate(uint256 _rateWEIPerCHFCent)
    public onlyAuthority
  {
    rateWEIPerCHFCent = _rateWEIPerCHFCent;
    emit Rate(currentTime(), _rateWEIPerCHFCent);
  }

  /**
   * @dev define rate with decimals
   */
  function defineRateWithDecimals(uint256 _rateETHCHF, uint256 _rateETHCHFDecimal)
    public onlyAuthority
  {
    // The rate is inverted to maximize the decimals stored
    defineRate(convertRateFromETHCHF(_rateETHCHF, _rateETHCHFDecimal));
  }

  /**
   * @dev current time
   */
  function currentTime() private view returns (uint256) {
    // solium-disable-next-line security/no-block-members
    return now;
  }

  event Rate(uint256 at, uint256 rateWEIPerCHFCent);
}
