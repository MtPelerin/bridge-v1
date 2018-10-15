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
 * CMTASD01: Agreement Hash must be defined
 * CMTASD02: Token must not be already configured
 * CMTASD03: Token must exists
 * CMTASD04: Token Agreement must be accepted
 * CMTASD05: Token owner must be this contract
 * CMTASD06: Same number of shareholders and amount must be provided
 * CMTASD07: All tokens must belong to this contract
 * CMTASD08: This contract must be KYCed for the distribution
 * CMTASD09: Allocations must be finished
 * CMTASD10: Sender must have tokens allocated
 * CMTASD11: Distribution hash must be signed by sender
 * CMTASD12: Unable to transfer tokens to holder
 * CMTASD13: Distribution must be over
 * CMTASD13: Sender must have a participation
 * CMTASD14: Unable to reclaim more than what available
 * CMTASD15: Unable to reclaim tokens
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
    require(_agreementHash != 0, "CMTASD01");
    agreementHash = _agreementHash;
    distributionEnd = _distributionEnd;
  }

  /**
   * @dev configure Token
   */
  function configureToken(CMTAPocToken _token, bytes32 _agreementHash) public onlyOwner {
    require(address(token) == address(0), "CMTASD02");
    require(address(_token) != address(0), "CMTASD03");
    token = _token;
    require(token.acceptAgreement(_agreementHash), "CMTASD04");
  }

  /**
   * @dev allocate shares
   */
  function allocateShares(address _shareholder, uint256 _amount)
    public onlyOwner returns (bool)
  {
    require(!allocationFinished, "CMTASD05");
    uint256 currentAllocation = allocations[_shareholder];
    allocations[_shareholder] = _amount;
    totalAllocations = totalAllocations.sub(currentAllocation).add(_amount);

    emit Allocation(_shareholder, _amount);
    return true;
  }

  /**
   * @dev Allocates many shares
   */
  function allocateManyShares(
    address[] _shareholders, uint256[] _amounts)
    public onlyOwner returns (bool)
  {
    require(_shareholders.length == _amounts.length, "CMTASD06");
    for (uint256 i = 0; i < _shareholders.length; i++) {
      allocateShares(_shareholders[i], _amounts[i]);
    }

    return true;
  }

  /**
   * @dev finish allocations
   */
  function finishAllocations() public onlyOwner returns (bool) {
    require(!allocationFinished, "CMTASD05");
    require(token.balanceOf(this) == token.totalSupply(), "CMTASD07");
    require(token.validUntil(this) >= distributionEnd, "CMTASD08");
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
    require(allocationFinished, "CMTASD09");
    require(allocations[msg.sender] > 0, "CMTASD10");
    require(agreementHash == _agreementHash, "CMTASD11");
    require(token.transfer(msg.sender, allocations[msg.sender]), "CMTASD12");
    delete allocations[msg.sender];
  }

  /**
   * @dev reclaim shares
   * Allow owner to reclaim non distributed shares once the distribution has ended
   **/
  function reclaimShares(uint256 _amount) public onlyOwner {
    // solium-disable-next-line security/no-block-members
    require(now > distributionEnd, "CMTASD13");
    require(_amount <= token.balanceOf(this), "CMTASD14");
    require(token.transfer(msg.sender, _amount), "CMTASD15");
  }

  event Allocation(address holder, uint256 amount);
  event AllocationFinished();
}
