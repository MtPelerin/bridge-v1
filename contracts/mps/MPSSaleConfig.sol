pragma solidity ^0.4.24;

import "../interface/ISaleConfig.sol";
import "../zeppelin/ownership/Ownable.sol";


/**
 * @title MPSSaleConfig
 * @dev MPSSaleConfig contract
 * The contract configure the sale for the MPS token
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
contract MPSSaleConfig is ISaleConfig, Ownable {
  // Terms of sale Hash SHA3-256
  bytes32 constant public TOKEN_AGREEMENT_HASH
  = 0xe3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855;

  // Token supply cap: 10M
  uint256 constant public TOKEN_SUPPLY = 10 ** 7;
 
  // 100% of Mt Pelerin's shares are tokenized
  uint256 constant public TOKENSALE_LOT1_SHARE_PERCENT = 5;
  uint256 constant public TOKENSALE_LOT2_SHARE_PERCENT = 95;
  uint256 constant public TOKENIZED_SHARE_PERCENT
  = TOKENSALE_LOT1_SHARE_PERCENT + TOKENSALE_LOT2_SHARE_PERCENT;

  uint256 constant public TOKENSALE_LOT1_SUPPLY
  = TOKEN_SUPPLY * TOKENSALE_LOT1_SHARE_PERCENT / 100;
  uint256 constant public TOKENSALE_LOT2_SUPPLY
  = TOKEN_SUPPLY * TOKENSALE_LOT2_SHARE_PERCENT / 100;

  uint256[] public tokensaleLotSupplies
  = [ TOKENSALE_LOT1_SUPPLY, TOKENSALE_LOT2_SUPPLY ];

  // Tokens amount per CHF
  uint256 constant public TOKEN_PRICE_CHF_CENT = 500;

  // HardCap of the sale in CHF cents: 2.5M CHF defined in cents
  uint256 constant public TOKENSALE_HARDCAP_CHF_CENT = 25 * (10 ** 5);

  // Minimal CHF investment
  uint256 constant public MINIMAL_CHF_INVESTMENT = 10 ** 4;

  // Maximal CHF investment
  uint256 constant public MAXIMAL_CHF_INVESTMENT = 10 ** 10;

  Tokensale[] public tokensales;

  /**
   * @dev constructor
   */
  constructor() public {
    tokensales.push(Tokensale(
      0xe3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855,
      0,
      TOKEN_PRICE_CHF_CENT * 80 / 100,
      1541026800,
      3*24*3600,
      0,
      2*24*3600
    ));

    tokensales.push(Tokensale(
      0xe3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855,
      0,
      TOKEN_PRICE_CHF_CENT,
      1541026800,
      0,
      1544914800,
      2*24*3600
    ));
  }

  /**
   * @dev getter need to be declared to comply with ISaleConfig interface
   */
  function tokenAgreementHash() public pure returns (bytes32) {
    return TOKEN_AGREEMENT_HASH;
  }

  /**
   * @dev getter need to be declared to comply with ISaleConfig interface
   */
  function tokenSupply() public pure returns (uint256) {
    return TOKEN_SUPPLY;
  }

  /**
   * @dev getter need to be declared to comply with ISaleConfig interface
   */
  function tokensaleLotSupplies() public view returns (uint256[]) {
    return tokensaleLotSupplies;
  }

  /**
   * @dev getter need to be declared to comply with ISaleConfig interface
   */
  function tokenizedSharePercent() public pure returns (uint256) {
    return TOKENIZED_SHARE_PERCENT;
  }

  /**
   * @dev getter need to be declared to comply with ISaleConfig interface
   */
  function tokenPriceCHF() public pure returns (uint256) {
    return TOKEN_PRICE_CHF_CENT;
  }

  /**
   * @dev getter need to be declared to comply with ISaleConfig interface
   */
  function minimalCHFInvestment() public pure returns (uint256) {
    return MINIMAL_CHF_INVESTMENT;
  }

  /**
   * @dev getter need to be declared to comply with ISaleConfig interface
   */
  function maximalCHFInvestment() public pure returns (uint256) {
    return MAXIMAL_CHF_INVESTMENT;
  }

  /**
   * @dev tokensale count
   */
  function tokensalesCount() public view returns (uint256) {
    return tokensales.length;
  }

  /**
   * @dev getter need to be declared to comply with ISaleConfig interface
   */
  function purchaseAgreement(uint256 _tokensaleId)
    public view returns (bytes32)
  {
    return tokensales[_tokensaleId].purchaseAgreement;
  }

  /**
   * @dev getter need to be declared to comply with ISaleConfig interface
   */
  function lotId(uint256 _tokensaleId) public view returns (uint256) {
    return tokensales[_tokensaleId].lotId;
  }

  /**
   * @dev getter need to be declared to comply with ISaleConfig interface
   */
  function tokenPriceCHFCent(uint256 _tokensaleId)
    public view returns (uint256)
  {
    return tokensales[_tokensaleId].tokenPriceCHFCent;
  }

  /**
   * @dev getter need to be declared to comply with ISaleConfig interface
   */
  function openingTime(uint256 _tokensaleId) public view returns (uint256) {
    return tokensales[_tokensaleId].openingTime;
  }

  /**
   * @dev getter need to be declared to comply with ISaleConfig interface
   */
  function duration(uint256 _tokensaleId) public view returns (uint256) {
    return tokensales[_tokensaleId].duration;
  }

  /**
   * @dev closing time for the sale
   * It is no more possible to send any ETH after
   */
  function closingTime(uint256 _tokensaleId) public view returns (uint256) {
    return tokensales[_tokensaleId].closingTime;
  }

  /**
   * @dev delay for investors to mint their tokens
   */
  function mintingDelay(uint256 _tokensaleId) public view returns (uint256) {
    return tokensales[_tokensaleId].mintingDelay;
  }
}
