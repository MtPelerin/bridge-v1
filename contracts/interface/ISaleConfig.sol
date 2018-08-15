pragma solidity ^0.4.24;


/**
 * @title ISaleConfig interface
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 */
contract ISaleConfig {
  function termsOfSaleHash() public pure returns (bytes32);
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
