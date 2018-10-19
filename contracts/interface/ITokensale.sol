pragma solidity ^0.4.24;

import "../interface/ISaleConfig.sol";
import "../interface/IUserRegistry.sol";
import "../zeppelin/token/ERC20/ERC20.sol";


/**
 * @title ITokensale
 * @dev ITokensale interface
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
contract ITokensale {
  function () external payable;

  function convertFromETHCHF(
    uint256 _rateETHCHF,
    uint256 _rateETHCHFDecimal) public pure returns (uint256);

  function convertToETHCHF(
    uint256 _rateWEIPerCHFCent,
    uint256 _rateETHCHFDecimal) public pure returns (uint256);
  function convertCHFCentToWEI(
    uint256 _amountCHF) public view returns (uint256);
  function convertWEItoCHFCent(
    uint256 _amountETH) public view returns (uint256);

  /* General sale details */
  function token() public view returns (ERC20);
  function vaultETH() public view returns (address);
  function vaultERC20() public view returns (address);
  function userRegistry() public view returns (IUserRegistry);
  function sharePurchaseAgreementHash() public view returns (bytes32);

  /* Sale status */
  function startAt() public view returns (uint256);
  function endAt() public view returns (uint256);
  function raisedETH() public view returns (uint256);
  function raisedCHF() public view returns (uint256);
  function totalRaisedCHF() public view returns (uint256);
  function refundedETH() public view returns (uint256);

  /* Investor specific attributes */
  function investorUnspentETH(uint256 _investorId)
    public view returns (uint256);

  function investorDepositCHF(uint256 _investorId)
    public view returns (uint256);

  function investorSPAAccepted(uint256 _investorId)
    public view returns (bool);

  function investorAllocations(uint256 _investorId)
    public view returns (uint256);

  function investorTokens(uint256 _investorId) public view returns (uint256);
  function investorCount() public view returns (uint256);

  /* Current ETHCHF rates */
  function rateWEIPerCHFCent() public view returns (uint256);
  function rateETHCHF(uint256 _rateETHCHFDecimal)
    public view returns (uint256);

  /* Share Purchase Agreement */
  function defineSPA(bytes32 _sharePurchaseAgreementHash)
    public returns (bool);
  function acceptSPA(bytes32 _sharePurchaseAgreementHash)
    public payable returns (bool);

  /* Investment */
  function investETH() public payable;
  function addOffChainInvestment(address _investor, uint256 _amountCHF)
    public;

  /* Schedule */
  function updateSchedule(uint256 _startAt, uint256 _endAt)
    public returns (uint256);

  /* Allocations admin */
  function allocate(address _investor, uint256 _amount)
    public returns (bool);
  function allocateMany(address[] _investors, uint256[] _amounts)
    public returns (bool);
  function finishAllocations() public returns (bool);

  /* Rates admin */
  function defineRate(uint256 _rateWEIPerCHFCent) public;
  function defineRateWithDecimals(
    uint256 _rateETHCHF, uint256 _rateETHCHFDecimal) public;

  /* ETH administration */
  function refundUnspentETH() public;
  function withdrawETHFunds() public;
  function autoWithdrawETHFunds() public;

  event Rate(uint256 at, uint256 rateWEIPerCHFCent);
  event SalePurchaseAgreementHash(bytes32 _sharePurchaseAgreement);
  event Allocation(
    uint256 investorId,
    uint256 shares
  );
  event Investment(
    uint256 investorId,
    uint256 spentCHF,
    uint256 unspentCHF
  );
  event ChangeETHCHF(
    address investor,
    uint256 amount,
    uint256 converted,
    uint256 rate
  );
  event WithdrawETH(
    address receiver,
    uint256 amount
  );
}
