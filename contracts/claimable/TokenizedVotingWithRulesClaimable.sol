pragma solidity ^0.4.24;

import "../interface/IClaimable.sol";
import "../voting/TokenizedVotingWithRules.sol";


/**
 * @title TokenizedVotingWithRulesClaimable
 * @dev TokenizedVotingWithRulesClaimable contract
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 */
contract TokenizedVotingWithRulesClaimable is IClaimable, TokenizedVotingWithRules {
  /**
   * @dev constructor
   */
  constructor(ProvableOwnershipToken _token, IRule[] _rules)
  TokenizedVotingWithRules(_token, _rules) public { }

  /**
   * @dev implements has claims
   *
   * Returns true if there was at least a vote created after that date
   */
  function hasClaimsSince(address _address, uint256 _at)
    public view returns (bool)
  {
    _address;
    return _at < proposals[proposalsCount-1].createdAt;
  }
}
