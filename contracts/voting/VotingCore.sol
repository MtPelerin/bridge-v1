pragma solidity ^0.4.24;

import "../zeppelin/token/ERC20/ERC20.sol";
import "../zeppelin/ownership/Ownable.sol";
import "../zeppelin/math/SafeMath.sol";


/**
 * @title VotingCore
 * @dev VotingCore contract
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
 * VC01: Question must be defined
 * VC02: Url must be defined
 * VC03: Hash must be defined
 * VC04: Option must exist
 * VC05: Proposal must exist
 * VC06: Vote must be new or changed
 */
contract VotingCore is Ownable {
  using SafeMath for uint256;

  struct Vote {
    uint8 option;
    bool declared;
    bool locked;
  }

  struct Proposal {
    string question;
    string url;
    uint256 hash;
    uint256 participation;
    uint256 createdAt;
    uint256[] ballot; // ballot[0] correspond to blank vote
    mapping(address => Vote) votes;
  }

  mapping(uint256 => Proposal) internal proposals;
  uint256 public proposalsCount;

  /**
   * @dev returns the count of proposals
   */
  function proposalsCount() public view returns (uint256) {
    return proposalsCount;
  }

  /**
   * @dev returns the question of the proposal _proposalId
   */
  function proposalQuestion(uint256 _proposalId) public view returns (string) {
    return proposals[_proposalId].question;
  }

  /**
   * @dev returns the url of the proposal _proposalId
   */
  function proposalUrl(uint256 _proposalId) public view returns (string) {
    return proposals[_proposalId].url;
  }

  /**
   * @dev returns the hash of the proposal _proposalId
   */
  function proposalHash(uint256 _proposalId) public view returns (uint256) {
    return proposals[_proposalId].hash;
  }

  /**
   * @dev returns the number of choices of the proposal _proposalId
   */
  function proposalOptionsAvailable(uint256 _proposalId)
    public view returns (uint8)
  {
    return uint8(proposals[_proposalId].ballot.length-1);
  }

  /**
   * @dev returns the participation of the proposal _proposalId
   * The participation is the number of votes that has been used for this proposal
   */
  function participation(uint256 _proposalId) public view returns (uint256) {
    return proposals[_proposalId].participation;
  }

  /**
   * @dev returns the time of creation of the proposal _proposalId
   */
  function proposalCreatedAt(uint256 _proposalId)
    public view returns (uint256)
  {
    return proposals[_proposalId].createdAt;
  }

  /**
   * @dev returns the ballot of the proposal _proposalId
   */
  function ballot(uint256 _proposalId) public view returns (uint256[]) {
    return proposals[_proposalId].ballot;
  }

  /**
   * @dev returns the choice made by a participant for a proposal
   */
  function optionVoted(uint256 _proposalId, address _participant)
    public view returns (uint8)
  {
    return proposals[_proposalId].votes[_participant].option;
  }

  /**
   * @dev returns true if the participant is declared
   */
  function isDeclared(uint256 _proposalId, address _participant)
    public view returns (bool)
  {
    return proposals[_proposalId].votes[_participant].declared;
  }

  /**
   * @dev returns true if the participant is declared and lock his vote
   */
  function isVoteLocked(uint256 _proposalId, address _participant)
    public view returns (bool)
  {
    return proposals[_proposalId].votes[_participant].locked;
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
    require(bytes(_question).length > 0, "VC01");
    require(bytes(_url).length > 0, "VC02");
    require(_hash > 0, "VC03");

    proposals[proposalsCount] = Proposal(
      _question,
      _url,
      _hash,
      0,
      // solium-disable-next-line security/no-block-members
      block.timestamp,
      new uint256[](_optionsAvailable+1)
    );
    proposalsCount++;
    emit ProposalAdded(proposalsCount-1);
  }

  /**
   * @dev vote for a proposal
   */
  function vote(uint256 _proposalId, uint8 _option) public {
    weightedVote(_proposalId, _option, 1);
  }

  /**
   * @dev vote for a proposal and lock it
   */
  function lockVote(uint256 _proposalId, uint8 _option) public {
    vote(_proposalId, _option);
    proposals[_proposalId].votes[msg.sender].locked = true;
  }

  /**
   * @dev vote for a proposal with a weight
   *
   * Child contract must define the correct weight for the msg.sender
   */
  function weightedVote(
    uint256 _proposalId,
    uint8 _option,
    uint256 _weight) internal
  {
    Proposal storage proposal = proposals[_proposalId];
    Vote storage lastVote = proposal.votes[msg.sender];

    require(_option < proposals[_proposalId].ballot.length, "VC04");
    require(_proposalId < proposalsCount, "VC05");
    require(lastVote.option != _option, "VC06");

    if (proposal.votes[msg.sender].declared) {
      proposal.ballot[lastVote.option] = proposal
        .ballot[lastVote.option].sub(_weight);
    } else {
      proposal.participation = proposal.participation.add(_weight);
      proposal.votes[msg.sender].declared = true;
    }

    proposal.ballot[_option] = proposal.ballot[_option].add(_weight);
    proposal.votes[msg.sender].option = _option;
  }

  event ProposalAdded(uint256 proposalId);
}
