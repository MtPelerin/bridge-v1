pragma solidity ^0.4.24;

import "../interface/ISaleConfig.sol";
import "../interface/IMintable.sol";
import "../interface/IUserRegistry.sol";


/**
 * @title IMPLTokensale
 * @dev IMPLTokensale interface
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
contract IMPLTokensale {
  function () external payable;

  function convertFromETHCHF(
    uint256 _rateETHCHF,
    uint256 _rateETHCHFDecimal) public pure returns (uint256);

  function convertToETHCHF(
    uint256 _rateWEIPerCHFCent,
    uint256 _rateETHCHFDecimal) public pure returns (uint256);

  function vault() public view returns (address);
  function minter() public view returns (IMintable);
  function userRegistry() public view returns (IUserRegistry);

  function investorDepositETH(uint256 _userId)
    public view returns (uint256);

  function investorDepositCHF(uint256 _userId)
    public view returns (uint256);

  function investorDestination(uint256 _userId)
    public view returns (address);

  function investorTokens(uint256 _userId) public view returns (uint256);
  function investorIsRefunded(uint256 _userId) public view returns (bool);
  function investorIsPrepared(uint256 _userId) public view returns (bool);
  function investorIsMinted(uint256 _userId) public view returns (bool);

  function investorCount() public view returns (uint256);
  function contributorCount() public view returns (uint256);
  function preparedCount() public view returns (uint256);
  function mintedCount() public view returns (uint256);

  function rateWEIPerCHFCent() public view returns (uint256);
  function rateETHCHF(uint256 _rateETHCHFDecimal)
    public view returns (uint256);

  function raisedCHF() public view returns (uint256);
  function totalRaisedCHF() public view returns (uint256);
  function raisedETH() public view returns (uint256);
  function refundETH() public view returns (uint256);
  function refundRatio() public view returns (uint256);
  function refundETHPrecision() public pure returns (uint256);
  function refundCHFUnspentMin() public pure returns (uint256);

  function investETH() public payable;
  function addOffChainInvestment(address _investor, uint256 _amountCHF)
    public;

  function rejectETHFunds(uint256 _userId, uint256 _amount) public;
  function rejectCHFFunds(uint256 _userId, uint256 _amount) public;
  function defineRate(uint256 _rateETHCHF, uint256 _rateETHCHFDecimal)
    public;

  function processSale() public;

  function prepareMinting(uint256 _userId) public;
  function prepareMintingForManyUsers(uint256[] _userIds) public;
  function mint(uint256 _userId) public;
  function mintForManyUsers(uint256[] _userIds) public;
  function withdrawETHFunds() public;

  function finishDistribution() public;

  event Investment(
    address investor,
    uint256 amountETH,
    uint256 amountCHF
  );
  event InvestmentETHRejected(address investor, uint256 amount);
  event InvestmentCHFRejected(address investor, uint256 amount);
  event SaleProcessed(uint256 raisedCHF, uint256 refundETH);
  event WithdrawETH(uint256 amount);
}
