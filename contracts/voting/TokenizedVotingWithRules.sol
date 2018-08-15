pragma solidity ^0.4.24;

import "./TokenizedVoting.sol";
import "../rule/WithRules.sol";


/**
 * @title TokenizedVotingWithRules
 * @dev TokenizedVotingWithRules contract
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
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
