pragma solidity ^0.4.24;

import "../zeppelin/ownership/Ownable.sol";
import "../zeppelin/token/ERC20/ERC20.sol";
import "../zeppelin/math/SafeMath.sol";
import "../token/component/ProvableOwnershipToken.sol";
import "../interface/IDividend.sol";


/**
 * @title Dividend
 * @dev Dividend contract
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subject to Swiss Law without reference to its conflicts of law rules.
 *
 * Error messages
 * DI01: This contract must have access to the funds
 * DI02: Not enough funds have been provided
*/
contract Dividend is IDividend, Ownable {
  using SafeMath for uint256;

  // Dividends are distributed proportionnaly to ownership of (token)
  ProvableOwnershipToken public token;

  struct DividendRecord {
    // Token to be distributed as dividend
    ERC20 payToken;
    // Address containing the payTokens
    address vault;
    // Amount of payToken to be distributed
    uint256 amount;
    // Total Supply of ProvableOwnershipToken at Dividend distribution time
    uint256 totalSupply;
    // Dividend distribution time
    uint256 createdAt;
    // have the user claimed his dividends
    mapping(address => uint256) claimed;
  }
  mapping(uint256 => DividendRecord) internal dividends;
  uint256 public dividendsCount;

  /**
   * @dev constructor
   */
  constructor(ProvableOwnershipToken _token) public { 
    token = _token;
  }

  /**
   * @dev returns the token representing
   * the part of the dividend to be distributed
   */
  function token() public view returns (ProvableOwnershipToken) {
    return token;
  }

  /**
   * @dev number of dividends which have been created
   */
  function dividendsCount() public view returns (uint256) {
    return dividendsCount;
  }

  /**
   * @dev token in which the dividend will be payed
   */
  function dividendPayToken(uint256 _dividendId)
    public view returns (ERC20)
  {
    return dividends[_dividendId].payToken;
  }

  /**
   * @dev  amount of a dividend to be distributed among the parties
   */
  function dividendAmount(uint256 _dividendId)
    public view returns (uint256)
  {
    return dividends[_dividendId].amount;
  }

  /**
   * @dev total supply of dividend
   */
  function dividendTotalSupply(uint256 _dividendId)
    public view returns (uint256)
  {
    return dividends[_dividendId].totalSupply;
  }

  /**
   * @dev dividend creation date
   */
  function dividendCreatedAt(uint256 _dividendId)
    public view returns (uint256)
  {
    return dividends[_dividendId].createdAt;
  }

  /**
   * @dev dividend claimed
   */
  function dividendClaimed(uint256 _dividendId, address _address)
    public view returns (uint256)
  {
    return dividends[_dividendId].claimed[_address];
  }

  /**
   * @dev dividend available
   */
  function dividendAvailable(uint256 _dividendId, address _address)
    public view returns (uint256)
  {
    return evalDividendAvailable(
      _dividendId,
      _address,
      token.balanceOf(_address)
    );
  }

  /**
   * @dev dividend available with proof
   */
  function dividendAvailableWithProof(
    uint256 _dividendId,
    address _address,
    uint256 _proofId) public view returns (uint256)
  {
    return evalDividendAvailable(
      _dividendId,
      _address,
      token.checkProof(_address, _proofId, dividends[_dividendId].createdAt)
    );
  }

  /**
   * @dev claim the dividend _dividendId without a proof of ownership
   */
  function claimDividend(uint256 _dividendId) public {
    processDividendDistribution(
      _dividendId,
      dividendAvailable(_dividendId, msg.sender));
  }

  /**
   * @dev claim the dividend _dividendId with a proof of ownership
   */
  function claimDividendWithProof(uint256 _dividendId, uint256 _proofId)
    public
  {
    processDividendDistribution(
      _dividendId,
      dividendAvailableWithProof(_dividendId, msg.sender, _proofId)
    );
  }

  /**
   * @dev create a new dividend
   */
  function createDividend(ERC20 _payToken, address _vault, uint256 _amount)
    public onlyOwner
  {
    require(_payToken.allowance(_vault, address(this)) >= _amount, "DI01");
    require(_payToken.balanceOf(_vault) >= _amount, "DI02");
    dividends[dividendsCount] = DividendRecord(
      _payToken,
      _vault,
      _amount,
      token.totalSupply(),
      // solium-disable-next-line security/no-block-members
      now
    );
    emit DividendAdded(dividendsCount, _payToken, _amount);
    dividendsCount++;
  }

  /**
   * @dev number of dividends created
   */
  function updateToken(ProvableOwnershipToken _token) public onlyOwner {
    token = _token;
    emit TokenUpdated(token);
  }

  /**
   * @dev distribute the dividend corresponding to the ownership of the token
   * found for that specific address
   */
  function processDividendDistribution(
    uint256 _dividendId,
    uint256 _amountClaimed) internal
  {
    if (_amountClaimed > 0) {
      DividendRecord storage dividend = dividends[_dividendId];
      if (dividend.payToken.balanceOf(dividend.vault) >= _amountClaimed &&
        dividend.payToken.allowance(
          dividend.vault, address(this)) >= _amountClaimed)
      {
        dividend.payToken.transferFrom(
          dividend.vault, msg.sender, _amountClaimed);
        dividends[_dividendId].claimed[msg.sender] = _amountClaimed;
        emit DividendClaimed(_dividendId, msg.sender, _amountClaimed);
      }
    }
  }

  /**
   * @dev dividend available
   */
  function evalDividendAvailable(
    uint256 _dividendId,
    address _address,
    uint256 _addressBalance) private view returns (uint256)
  {
    DividendRecord storage dividend = dividends[_dividendId];
    if (token.lastTransactionAt(_address) < dividend.createdAt) {
      uint256 alreadyClaimed = dividends[_dividendId].claimed[_address];
      return _addressBalance.mul(dividend.amount)
        .div(dividend.totalSupply).sub(alreadyClaimed);
    }
    return 0;
  }

  event DividendAdded(uint256 indexed id, address payToken, uint256 amount);
  event DividendClaimed(uint256 indexed id, address indexed holder,
  uint256 amount);
  event TokenUpdated(ProvableOwnershipToken token);
}
