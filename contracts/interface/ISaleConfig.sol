pragma solidity ^0.4.24;


/**
 * @title ISaleConfig interface
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subject to Swiss Law without reference to its conflicts of law rules.
 */
contract ISaleConfig {

  struct Tokensale {
    uint256 lotId;
    uint256 tokenPriceCHFCent;
  }

  function tokenSupply() public pure returns (uint256);
  function tokensaleLotSupplies() public view returns (uint256[]);

  function tokenizedSharePercent() public pure returns (uint256); 
  function tokenPriceCHF() public pure returns (uint256);

  function minimalCHFInvestment() public pure returns (uint256);
  function maximalCHFInvestment() public pure returns (uint256);

  function tokensalesCount() public view returns (uint256);
  function lotId(uint256 _tokensaleId) public view returns (uint256);
  function tokenPriceCHFCent(uint256 _tokensaleId)
    public view returns (uint256);
}
