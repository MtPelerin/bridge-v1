pragma solidity ^0.4.24;

import "../zeppelin/token/ERC20/ERC20Basic.sol";
import "../zeppelin/ownership/Ownable.sol";
import "../zeppelin/math/SafeMath.sol";


/**
 * @title DemoVoting
 * @dev DemoVoting contract
 *
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
 * E01: Vote must be open
 * E02: Participant has already voted
 * E03: Participant has no voting tokens
 */
contract DemoVoting is Ownable {
  using SafeMath for uint256;
  uint256 constant UINT256_MAX = ~uint256(0);

  struct Proposal {
    string url;
    uint256 hash;
    uint256 startedAt;
    uint256 closedAt;
    uint256 approvals;
    uint256 rejections;
    mapping(address => bool) participants;
  }
  Proposal internal currentProposal;
  uint256 internal proposalCount;

  ERC20Basic public votingToken;

  /**
   * @dev constructor
   **/
  constructor(ERC20Basic _token) public {
    votingToken = _token;
  }

  /**
   * @dev voting token
   */
  function votingToken() public view returns (ERC20Basic) {
    return votingToken;
  }

  /**
   * @dev current proposal id
   */
  function currentProposalId() public view returns (uint256) {
    return proposalCount;
  }

  /**
   * @dev current proposal url
   */
  function currentUrl() public view returns (string) {
    return currentProposal.url;
  }

  /**
   * @dev current proposal hash
   */
  function currentHash() public view returns (uint256) {
    return currentProposal.hash;
  }

  /**
   * @dev current proposal started at
  */
  function startedAt() public view returns (uint256) {
    return currentProposal.startedAt;
  }

  /**
   * @dev current proposal closed at
   */
  function closedAt() public view returns (uint256) {
    return currentProposal.closedAt;
  }

  /**
   * @dev current proposal approvals
   */
  function voteApprovals() public view returns (uint256) {
    return currentProposal.approvals;
  }

  /**
   * @dev current proposal rejections
   */
  function voteRejections() public view returns (uint256) {
    return currentProposal.rejections;
  }

  /**
   * @dev current proposal hasVoted
   */
  function hasVoted(address _address) public view returns (bool) {
    return currentProposal.participants[_address];
  }

  /**
   * @dev propose a new vote. Owner only
   */
  function proposeVote(string url, uint256 hash) public onlyOwner {
    currentProposal = Proposal(
      url,
      hash,
      currentTime(),
      UINT256_MAX,
      0,
      0
    );
    proposalCount++;
    emit NewProposal(proposalCount);
  }

  /**
   * @dev close the current vote. Owner only
   */
  function closeVote() public onlyOwner {
    uint256 totalSupply = votingToken.totalSupply();
    if (currentProposal.approvals > totalSupply / 2) {
      emit Approved(
        proposalCount,
        totalSupply,
        currentProposal.approvals,
        currentProposal.rejections
      );
    } else {
      emit Rejected(
        proposalCount,
        totalSupply,
        currentProposal.approvals,
        currentProposal.rejections
      );
    }
    currentProposal.closedAt = currentTime();
  }

  /**
   * @dev approve the current vote
   */
  function approveProposal() public {
    require(currentProposal.closedAt > currentTime(), "E01");
    require(!currentProposal.participants[msg.sender], "E02");
    uint256 balance = votingToken.balanceOf(msg.sender);
    require(balance > 0, "E03");

    currentProposal.approvals = currentProposal.approvals.add(balance);
    currentProposal.participants[msg.sender] = true;
  }

  /**
   * @dev reject the current vote
   */
  function rejectProposal() public {
    require(currentProposal.closedAt > currentTime(), "E01");
    require(!currentProposal.participants[msg.sender], "E02");
    uint256 balance = votingToken.balanceOf(msg.sender);
    require(balance > 0, "E03");

    currentProposal.rejections = currentProposal.rejections.add(balance);
    currentProposal.participants[msg.sender] = true;
  }

  /**
   * @dev currentTime
   */
  function currentTime() internal view returns (uint256) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp;
  }

  event NewProposal(uint256 proposalId);
  event Approved(
  uint256 proposalId,
  uint256 total,
  uint256 approvals,
  uint256 rejections);
  event Rejected(
  uint256 proposalId,
  uint256 total,
  uint256 approvals,
  uint256 rejections);
}
