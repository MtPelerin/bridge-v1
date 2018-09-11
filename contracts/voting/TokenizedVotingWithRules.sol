pragma solidity ^0.4.24;

import "./TokenizedVoting.sol";
import "../rule/WithRules.sol";


/**
 * @title TokenizedVotingWithRules
 * @dev TokenizedVotingWithRules contract
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subjects to Swiss Law without reference to its conflicts of law rules.
*/
contract TokenizedVotingWithRules is TokenizedVoting, WithRules {

  /**
   * @dev constructor
   */
  constructor(ProvableOwnershipToken _token, IRule[] _rules)
    public TokenizedVoting(_token) WithRules(_rules)
  { }

  /**
   * @dev vote without proof of ownership
   */
  function vote(uint256 _proposalId, uint8 _option)
    public whenAddressRulesAreValid(msg.sender) 
  {
    super.vote(_proposalId, _option);
  }

  /**
   * @dev vote with proof of ownership
   */
  function voteWithProof(
    uint256 _proposalId,
    uint8 _option,
    uint256 _proofId) public whenAddressRulesAreValid(msg.sender)
  {
    super.voteWithProof(_proposalId, _option, _proofId);
  }
}
