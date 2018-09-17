pragma solidity ^0.4.24;

import "../../zeppelin/ownership/Ownable.sol";
import "../../zeppelin/math/SafeMath.sol";
import "./CMTAPocToken.sol";


/**
 * @title CMTAShareDistribution
 * @dev CMTAShareDistribution contract
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subjects to Swiss Law without reference to its conflicts of law rules.
 *
 * @notice Swissquote Bank SA solely is entitled to the GNU LGPL.
 * @notice Any other party is subject to the copyright mentioned in the software.
 *
 * Error messages
 * E01: Agreement Hash must be defined
 * E02: Token must not be already configured
 * E03: Token must exists
 * E04: Token owner must be this contract
 * E05: Token must have supply
 * E06: All tokens must belong to this contract
 * E07: Token must be configured
 * E08: Allocations must not be finished
 * E09: Total allocations must matched token supply
 * E10: Allocations must be finished
 * E11: Sender must have a participation
 * E12: Sender hash must matched contract hash
 * E13: Unable to transfer shares to holder
 */
contract CMTAShareDistribution is Ownable {
  using SafeMath for uint256;

  mapping(address => uint256) allocations;
  uint256 public totalAllocations;
  bool public allocationFinished;

  CMTAPocToken public token;

  bytes32 public agreementHash;
  uint256 public distributionEnd;

  /**
   * @dev constructor function
   */
  constructor(bytes32 _agreementHash, uint256 _distributionEnd) public
  {
    require(_agreementHash != 0, "E01");
    agreementHash = _agreementHash;
    distributionEnd = _distributionEnd;
  }

  /**
   * @dev configure Token
   */
  function configureToken(CMTAPocToken _token) public onlyOwner {
    require(address(token) == address(0), "E02");
    require(address(_token) != address(0), "E03");
    token = _token;
  }

  /**
   * @dev allocate shares
   */
  function allocateShares(address _shareholder, uint256 _amount)
    onlyOwner public
  {
    require(!allocationFinished, "E04");
    uint256 currentAllocation = allocations[_shareholder];
    allocations[_shareholder] = _amount;
    totalAllocations = totalAllocations.sub(currentAllocation).add(_amount);
  }

  /**
   * @dev finish allocations
   */
  function finishAllocations() onlyOwner public returns (bool) {
    require(!allocationFinished, "E04");
    require(token.balanceOf(this) == totalAllocations, "E05");
    require(token.validUntil(this) >= distributionEnd, "E06");
    allocationFinished = true;
    emit AllocationFinished();
    return true;
  }

  /**
   * @dev claim shares
   * By providing the hash of the document, he signs explicitly that he agrees on
   * the shareholder terms and conditions
   */
  function claimShares(bytes32 _agreementHash) public {
    require(allocationFinished, "E07");
    require(allocations[msg.sender] > 0, "E08");
    require(agreementHash == _agreementHash, "E09");
    require(token.transfer(msg.sender, allocations[msg.sender]), "E10");
    delete allocations[msg.sender];
  }

  /**
   * @dev reclaim shares
   * Allow owner to reclaim non distributed shares once the distribution has ended
   **/
  function reclaimShares(uint256 _amount) onlyOwner public {
    // solium-disable-next-line security/no-block-members
    require(now > distributionEnd, "E11");
    require(_amount <= token.balanceOf(this), "E12");
    require(token.transfer(msg.sender, _amount), "E13");
  }

  event AllocationFinished();
}
