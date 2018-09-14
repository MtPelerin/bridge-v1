pragma solidity ^0.4.24;

import "../../zeppelin/ownership/Ownable.sol";
import "./CMTAPocToken.sol";


/**
 * @title CMTAShareholderAgreement
 * @dev CMTAShareholderAgreement contract
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subjects to Swiss Law without reference to its conflicts of law rules.
 *
 * Error messages
 */
contract CMTAShareholderAgreement is Ownable {

  mapping(address => uint256) allocations;
  uint256 public totalAllocations;
  bool public allocationFinished;

  CMTAPocToken public token;
  bytes32 public agreementHash;

  /**
   * @dev fallback function
   */
  constructor(CMTAPocToken _token, bytes32 _agreementHash) public
  {
    require(_token.owner() == address(this));
    require(_token.totalSupply() == _token.balanceOf(this));
    token = _token;
    agreementHash = _agreementHash;
  }

  /**
   * @dev allocate shares
   */
  function allocateShares(address _shareholder, uint256 _amount)
    onlyOwner public
  {
    require(!allocationFinished);
    uint256 currentAllocation = allocations[_shareholder];
    allocations[_shareholder] = _amount;
    totalAllocations += (_amount - currentAllocation);
  }

  /**
   * @dev finish allocations
   */
  function finishAllocations() onlyOwner public {
    require(token.balanceOf(this) == totalAllocations);
    allocationFinished = true;
    token.transferOwnership(owner);
    emit AllocationFinished();
  }

  /**
   * @dev claim shares
   */
  function claimShares(bytes32 _agreementHash) public {
    require(allocationFinished);
    require(allocations[msg.sender] > 0);
    require(agreementHash == _agreementHash);
    require(token.transfer(msg.sender, allocations[msg.sender]));
    delete allocations[msg.sender];
  }

  event AllocationFinished();
}
