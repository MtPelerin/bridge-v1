pragma solidity ^0.4.24;


/**
 * @title ISaleConfig interface
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
contract ISaleConfig {
  function termsOfSaleHash() public view returns (bytes32);
  function updateTermsOfSaleHash(bytes32 _hash) public;

  function tokenSupply() public pure returns (uint256);
  function tokenizedSharePercent() public pure returns (uint256); 
  function tokensaleLot1HardCapCHF() public pure returns (uint256);
  function tokensaleLot1SharePercent() public pure returns (uint256);
  function tokensaleLot1Supply() public pure returns (uint256);
  function tokensaleLot2SharePercent() public pure returns (uint256);
  function tokensaleLot2Supply() public pure returns (uint256);
  function reservedSupply() public pure returns (uint256);
  function tokensAmountPerCHF() public pure returns (uint256);
  function minimalETHInvestment() public pure returns (uint256);

  function openingTime() public view returns (uint256);
  function duration() public view returns (uint256);

  function closingTime() public view returns (uint256);
  function mintingDelay() public view returns (uint256);
}
