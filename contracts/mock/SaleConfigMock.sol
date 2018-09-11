pragma solidity ^0.4.24;

import "../tokensale/MPLSaleConfig.sol";


/**
 * @title SaleConfigMock
 * @dev SaleConfigMock contract
 * The contract is a configuration mock for a tokensale
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subjects to Swiss Law without reference to its conflicts of law rules.
 */
contract SaleConfigMock is MPLSaleConfig {

/*  function tokensaleLot1HardCapCHF() public pure returns (uint256) {
    return 500000000;
  }

  function tokensaleLot1Supply() public pure returns (uint256) {
    return 5 * 10 ** 24;
  }
 */
  function minimalETHInvestment() public pure returns (uint256) {
    return 10;
  }
}
