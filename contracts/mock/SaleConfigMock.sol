pragma solidity ^0.4.24;

import "../tokensale/MPLSaleConfig.sol";


/**
 * @title SaleConfigMock
 * @dev SaleConfigMock contract
 * The contract is a configuration mock for a tokensale
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
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
