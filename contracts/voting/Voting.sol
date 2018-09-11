pragma solidity ^0.4.24;

import "../zeppelin/token/ERC20/ERC20.sol";
import "../zeppelin/ownership/Ownable.sol";
import "../zeppelin/math/SafeMath.sol";
import "../interface/IVoting.sol";
import "./VotingCore.sol";


/**
 * @title Voting
 * @dev Voting contract
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
 * E01: Vote must be closed
 * E02: Vote must be opened
 */
contract Voting is IVoting, VotingCore {

  uint256 public defaultDuration = 2 weeks;
  uint256 public defaultQuorum = 0;
  uint256 public defaultMinScore = 0; 

  struct Rule {
    uint256 duration;
    uint256 quorum;
    uint256 minScore;
  }
  mapping(uint256 => Rule) internal votingRules;
  uint256 public latestVotingTime;

  /**
   * @dev returns the default duration rule to be used for new votes
   */
  function defaultDuration() public view returns (uint256) {
    return defaultDuration;
  }

  /**
   * @dev returns the default Quorum rule to be used for new votes
   */
  function defaultQuorum() public view returns (uint256) {
    return defaultQuorum;
  }

  /**
   * @dev returns the default minimum score rule to be used for new votes
   */
  function defaultMinScore() public view returns (uint256) {
    return defaultMinScore;
  }

  /**
   * @dev returns the latest time to vote
   * Allows to quickly know if there are any votes going on.
   */
  function latestVotingTime() public view returns (uint256) {
    return latestVotingTime;
  }

  /**
   * @dev returns the vote duration rule used in the vote associated with a proposal
   */
  function voteDuration(uint256 _proposalId) public view returns (uint256) {
    return votingRules[_proposalId].duration;
  }

  /**
   * @dev returns the min participants rule used in the vote associated with a proposal
   */
  function voteQuorum(uint256 _proposalId) public view returns (uint256) {
    return votingRules[_proposalId].quorum;
  }

  /**
   * @dev returns the min relative majority rule used in the vote associated with a proposal
   */
  function voteMinScore(uint256 _proposalId) public view returns (uint256) {
    return votingRules[_proposalId].minScore;
  }

  /**
   * @dev return true if the vote associated with the proposalid is on going
   */
  function isOnGoing(uint256 _proposalId) public view returns (bool) {
    return
      currentTime() < proposals[_proposalId].createdAt.add(
      votingRules[_proposalId].duration);
  }

  /**
   * @dev return true if there are any votes on going
   *
   * Beware that this method does not take in consideration that the vote 
   * was closed sooner by the contract owner
   */
  function areAnyOnGoing() public view returns (bool) {
    return currentTime() < latestVotingTime;
  }

  /**
   * @dev provide the result of the vote
   *
   * fails if the vote is still ongoing
   * returns 0 if the quorum or relative majority is not reached
   */
  function result(uint256 _proposalId) public view returns (uint256) {
    require(!isOnGoing(_proposalId), "E01");
    Proposal storage proposal = proposals[_proposalId];
    Rule storage rule = votingRules[_proposalId];

    if (proposal.participation.sub(proposal.ballot[0]) < rule.quorum) {
      return 0;
    }

    uint256 score;
    uint256 first;
    for (uint256 i = 1; i < proposal.ballot.length; i++) {
      if (proposal.ballot[i] > score) {
        first = i;
        score = proposal.ballot[i];
      }
    }

    if (score < rule.minScore) {
      return 0;
    }
    return first;
  }

  /**
   * @dev add a proposal
   */
  function addProposal(
    string _question,
    string _url,
    uint256 _hash,
    uint8 _optionsAvailable
  ) public onlyOwner
  {
    super.addProposal(
      _question,
      _url,
      _hash,
      _optionsAvailable
    );
    votingRules[proposalsCount-1] = Rule(
      defaultDuration, defaultQuorum, defaultMinScore);

    uint256 endVotingTime = proposals[proposalsCount-1]
      .createdAt.add(defaultDuration);

    if (endVotingTime > latestVotingTime) {
      latestVotingTime = endVotingTime;
    }
  }

  /**
   * @dev override vote function
   */
  function vote(uint256 _proposalId, uint8 _option) public {
    require(isOnGoing(_proposalId), "E02");
    weightedVote(_proposalId, _option, 1);
  }

  /**
   * @dev close vote
   * Does not update latestVotingTime value
   * which will eventually fixed itself
   */
  function closeVote(uint256 _proposalId) public onlyOwner {
    require(isOnGoing(_proposalId), "E02");

    uint256 newDuration = currentTime() - proposals[_proposalId].createdAt;
    votingRules[_proposalId].duration = newDuration;

    emit VoteClosed(_proposalId);
  }

  /**
   * @dev update voting rule
   * Existing votes are not affected by the new rule
   */
  function updateVotingRule(
    uint256 _duration,
    uint256 _quorum,
    uint256 _minScore) public onlyOwner
  {
    defaultDuration = _duration;
    defaultQuorum = _quorum;
    defaultMinScore = _minScore;

    emit VotingRuleUpdated(_duration, _quorum, _minScore);
  }

  /**
   * @dev currentTime
   */
  function currentTime() internal view returns (uint256) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp;
  }

  event VotingRuleUpdated(
  uint256 duration,
  uint256 quorum,
  uint256 minScore);

  event VoteClosed(uint256 proposalId);
}
