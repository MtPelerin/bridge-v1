pragma solidity ^0.4.24;

import "../zeppelin/token/ERC20/ERC20.sol";
import "../zeppelin/ownership/Ownable.sol";
import "../zeppelin/math/SafeMath.sol";
import "../token/component/ProvableOwnershipToken.sol";
import "./Voting.sol";


/**
 * @title TokenizedVoting
 * @dev TokenizedVoting contract
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
 * TV01: Vote must be opened
 * TV02: Participant must have weight
 */
contract TokenizedVoting is Voting {

  ProvableOwnershipToken public token;

  /**
   * @dev constructor
   */
  constructor(ProvableOwnershipToken _token) public {
    token = _token;
  }

  /**
   * @dev returns token
   */
  function token() public view returns (ProvableOwnershipToken) {
    return token;
  }

  /**
   * @dev votes available from the balance if no transactions was made since
   * the beginning of the vote
   */
  function votesAvailable(uint256 _proposalId, address _holder)
    public view returns (uint256)
  {
    if (token.lastTransactionAt(_holder) < proposals[_proposalId].createdAt) {
      return token.balanceOf(_holder);
    }
    return 0;
  }

  /**
   * @dev votes available with proof of ownership
   */
  function votesAvailableWithProof(
    uint256 _proposalId,
    address _holder,
    uint256 _proofId) public view returns (uint256)
  {
    return token.checkProof(
      _holder,
      _proofId,
      proposals[_proposalId].createdAt);
  }

  /**
   * @dev vote without proof of ownership
   */
  function vote(uint256 _proposalId, uint8 _option) public {
    require(isOnGoing(_proposalId), "TV01");
   
    uint256 weight = votesAvailable(_proposalId, msg.sender);
    require(weight != 0, "TV02");
    weightedVote(_proposalId, _option, weight);
  }

  /**
   * @dev vote with proof of ownership
   */
  function voteWithProof(
    uint256 _proposalId,
    uint8 _option,
    uint256 _proofId) public
  {
    require(isOnGoing(_proposalId), "TV01");
   
    uint256 weight = votesAvailableWithProof(
      _proposalId, msg.sender, _proofId);

    require(weight != 0, "TV02");
    weightedVote(_proposalId, _option, weight);
  }

  /**
   * @dev update token
   */
  function updateToken(ProvableOwnershipToken _token) public onlyOwner {
    token = _token;
  }
}
