pragma solidity ^0.4.24;

import "../interface/IUserRegistry.sol";
import "../interface/IRatesProvider.sol";
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
 * @notice are subject to Swiss Law without reference to its conflicts of law rules.
 */
contract ITokensale {

  function () external payable;

  // Minimal Auto Withdraw must be allow the nominal price
  // to ensure enough remains on the balance to refund the investors
  uint256 constant MINIMAL_AUTO_WITHDRAW = 0.5 ether;
  uint256 constant MINIMAL_BALANCE = 0.5 ether;
  uint256 constant BASE_PRICE_CHF_CENT = 500;

  function minimalAutoWithdraw() public view returns (uint256);
  function minimalBalance() public view returns (uint256);
  function basePriceCHFCent() public view returns (uint256);

  /* General sale details */
  function token() public view returns (ERC20);
  function vaultETH() public view returns (address);
  function vaultERC20() public view returns (address);
  function userRegistry() public view returns (IUserRegistry);
  function ratesProvider() public view returns (IRatesProvider);
  function sharePurchaseAgreementHash() public view returns (bytes32);

  /* Sale status */
  function startAt() public view returns (uint256);
  function endAt() public view returns (uint256);
  function raisedETH() public view returns (uint256);
  function raisedCHF() public view returns (uint256);
  function totalRaisedCHF() public view returns (uint256);
  function refundedETH() public view returns (uint256);
  function availableSupply() public view returns (uint256);

  /* Investor specific attributes */
  function investorUnspentETH(uint256 _investorId)
    public view returns (uint256);

  function investorInvestedCHF(uint256 _investorId)
    public view returns (uint256);

  function investorAcceptedSPA(uint256 _investorId)
    public view returns (bool);

  function investorAllocations(uint256 _investorId)
    public view returns (uint256);

  function investorTokens(uint256 _investorId) public view returns (uint256);
  function investorCount() public view returns (uint256);

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
  function updateSchedule(uint256 _startAt, uint256 _endAt) public;

  /* Allocations admin */
  function allocateTokens(address _investor, uint256 _amount)
    public returns (bool);

  function allocateManyTokens(address[] _investors, uint256[] _amounts)
    public returns (bool);

  /* ETH administration */
  function fundETH() public payable;
  function refundManyUnspentETH(address[] _receivers) public;
  function refundUnspentETH(address _receiver) public;
  function withdrawETHFunds() public;
  function autoWithdrawETHFunds() private;

  event SalePurchaseAgreementHash(bytes32 sharePurchaseAgreement);
  event Allocation(
    uint256 investorId,
    uint256 tokens
  );
  event Investment(
    uint256 investorId,
    uint256 spentCHF
  );
  event ChangeETHCHF(
    address investor,
    uint256 amount,
    uint256 converted,
    uint256 rate
  );
  event FundETH(uint256 amount);
  event WithdrawETH(address receiver, uint256 amount);
}
