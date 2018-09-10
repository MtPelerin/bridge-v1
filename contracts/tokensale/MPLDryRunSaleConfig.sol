pragma solidity ^0.4.24;

import "./MPLSaleConfig.sol";


/**
 * @title MPLDryRunConfig
 * @dev MPLDryRunConfig contract
 * The contract configure the MPL tokensale
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * This content cannot be used, copied or reproduced in part or in whole
 * without the express and written permission of Mt Pelerin Group SA.
 * Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * All matters regarding the intellectual property of this code or software
 * are subjects to Swiss Law without reference to its conflicts of law rules.
 */
contract MPLDryRunSaleConfig is MPLSaleConfig {

  // 2 Days: duration of the sale
  uint256 constant public DURATION = 2*3600;

  // 2 Days: delay for mint self
  uint256 constant public MINT_DELAY = 2*3600;

  /**
   * @dev getter need to be declared to comply with ISaleConfig interface
   */
  function openingTime() public view returns (uint256) {
    return OPENING_TIME;
  }

  /**
   * @dev getter need to be declared to comply with ISaleConfig interface
   */
  function duration() public view returns (uint256) {
    return DURATION;
  }

  /**
   * @dev closing time for the sale
   * It is no more possible to send any ETH after
   */
  function closingTime() public view returns (uint256) {
    return OPENING_TIME + DURATION;
  }

  /**
   * @dev delay for investors to mint their tokens
   */
  function mintingDelay() public view returns (uint256) {
    return MINT_DELAY;
  }
}
