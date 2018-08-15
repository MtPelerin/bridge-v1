pragma solidity ^0.4.24;

import "../interface/IClaimable.sol";
import "../voting/TokenizedVoting.sol";


/**
 * @title TokenizedVotingClaimable
 * @dev TokenizedVotingClaimable contract
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 */
contract TokenizedVotingClaimable is IClaimable, TokenizedVoting {

  /**
   * @dev constructor
   */
  constructor(ProvableOwnershipToken _token)
  TokenizedVoting(_token) public { }

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
