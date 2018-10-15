pragma solidity ^0.4.24;

import "../zeppelin/token/ERC20/ERC20.sol";
import "../zeppelin/ownership/Ownable.sol";
import "../zeppelin/math/SafeMath.sol";
import "./Shareholder.sol";


/**
 * @title DemoShare
 * @dev DemoShare contract
 *
 * Voting mechanism to distribute shares
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
 * DEMOS1: Previous vote must be closed
 * DEMOS2: Current vote must be open
 * DEMOS3: Participant has already voted
 * DEMOS4: Participant has no tokens
 * DEMOS5: Current vote must be closed
 * DEMOS6: Cannot distribute more ETH than available
*/
contract DemoShare is Shareholder {
  using SafeMath for uint256;
  uint256 constant UINT256_MAX = ~uint256(0);

  struct Proposal {
    string url;
    uint256 hash;
    ERC20 dividendToken;
    uint256 startedAt;
    uint256 closedAt;
    uint256 approvals;
    uint256 rejections;
  }
  Proposal internal currentProposal;

  mapping(uint256 => mapping(address => bool)) participants;
  uint256 internal proposalCount;

  ERC20 public token;

  /**
   * @dev constructor
   **/
  constructor(ERC20 _token) public {
    token = _token;
  }

  /**
   * @dev token
   */
  function token() public view returns (ERC20) {
    return token;
  }

  /**
   * @dev update token
   */
  function updateToken(ERC20 _token) public onlyOwner {
    token = _token;
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
   * @dev current proposal dividend token
   */
  function currentDividendToken() public view returns (ERC20) {
    return currentProposal.dividendToken;
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
    return participants[proposalCount][_address];
  }

  /**
   * @dev propose a new vote. Owner only
   */
  function proposeVote(
    string _url,
    uint256 _hash,
    ERC20 _dividendToken) public onlyOwner
  {
    require(currentProposal.closedAt < currentTime(), "DEMOS1");

    if (proposalCount > 0) {
      delete currentProposal;
    }
    currentProposal = Proposal(
      _url,
      _hash,
      _dividendToken,
      currentTime(),
      UINT256_MAX,
      0,
      0
    );
    emit NewProposal(proposalCount);
  }

  /**
   * @dev close the current vote. Owner only
   */
  function closeVote() public onlyOwner {
    require(currentProposal.closedAt > currentTime(), "DEMOS2");
    uint256 totalSupply = token.totalSupply();
    if ((2*currentProposal.approvals) > totalSupply) {
      emit Approved(
        proposalCount,
        totalSupply,
        currentProposal.approvals,
        currentProposal.rejections
      );
      currentProposal.closedAt = currentTime();
    } else {
      emit Rejected(
        proposalCount,
        totalSupply,
        currentProposal.approvals,
        currentProposal.rejections
      );
      currentProposal.closedAt = currentTime();
    }
  }

  /**
   * @dev close the current if approval. Owner only
   */
  function closeVoteApproval() public onlyOwner {
    require(currentProposal.closedAt > currentTime(), "DEMOS2");
    uint256 totalSupply = token.totalSupply();

    emit Approved(
      proposalCount,
      totalSupply,
      currentProposal.approvals,
      currentProposal.rejections
    );
    currentProposal.closedAt = currentTime();
  }

  /**
   * @dev close the current vote. Owner only
   */
  function closeVoteRejection() public onlyOwner {
    require(currentProposal.closedAt > currentTime(), "DEMOS2");
    uint256 totalSupply = token.totalSupply();

    emit Rejected(
      proposalCount,
      totalSupply,
      currentProposal.approvals,
      currentProposal.rejections
    );
    currentProposal.closedAt = currentTime();
  }

  /**
   * @dev close the current vote. Owner only
   */
  function forceCloseVoteNoActions() public onlyOwner {
    require(currentProposal.closedAt > currentTime(), "DEMOS2");
    currentProposal.closedAt = currentTime();
    proposalCount++;
  }

  /**
   * @dev approve the current vote
   */
  function approveProposal() public {
    require(currentProposal.closedAt > currentTime(), "DEMOS2");
    require(!participants[proposalCount][msg.sender], "DEMOS3");
    uint256 balance = token.balanceOf(msg.sender);
    require(balance > 0, "DEMOS4");

    if (proposalCount > 0) {
      delete participants[proposalCount-1][msg.sender];
    }
 
    currentProposal.approvals = currentProposal.approvals.add(balance);
    participants[proposalCount][msg.sender] = true;
  }

  /**
   * @dev reject the current vote
   */
  function rejectProposal() public {
    require(!participants[proposalCount][msg.sender], "DEMOS3");
    uint256 balance = token.balanceOf(msg.sender);
    require(balance > 0, "DEMOS4");

    if (proposalCount > 0) {
      delete participants[proposalCount-1][msg.sender];
    }

    currentProposal.rejections = currentProposal.rejections.add(balance);
    participants[proposalCount][msg.sender] = true;
  }

  /**
   * @dev Distribute token dividend
   */
  function distribute() public onlyOwner returns (bool) {
    require(currentProposal.closedAt <= currentTime(), "DEMOS5");
    
    ERC20 dividendToken = currentProposal.dividendToken;
    uint256 balance = dividendToken.balanceOf(this);
    distributeInternal(balance, dividendToken, shareholders);
    proposalCount++;
    return true;
  }

  /**
   * @dev Distribute special dividend
   */
  function distributeSpecial(
    uint256 _dividendAmount,
    ERC20 _token, address[] _addresses) public onlyOwner returns (bool)
  {
    return distributeInternal(_dividendAmount, _token, _addresses);
  }

  /**
   * @dev distribute internal
   */
  function distributeInternal(
    uint256 _dividendAmount,
    ERC20 _token, address[] _addresses) internal returns (bool)
  {
    uint256 balance = _token.balanceOf(this);
    require(balance >= _dividendAmount, "DEMOS6");

    for (uint256 i = 0; i < _addresses.length; i++) {
      uint256 value = _dividendAmount.mul(
        token.balanceOf(_addresses[i])).div(token.totalSupply()
      );
      if (value > 0) {
        _token.transfer(_addresses[i], value);
      }
    }

    emit Distribution(proposalCount, address(_token), _dividendAmount);
    return true;
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
    uint256 rejections
  );
  event Rejected(
    uint256 proposalId,
    uint256 total,
    uint256 approvals,
    uint256 rejections
  );
  event Distribution(
    uint256 proposalId,
    address token,
    uint256 dividendAmount
  );
}
