pragma solidity ^0.4.24;

import "../interface/IClaimable.sol";
import "../voting/TokenizedVotingWithRules.sol";


/**
 * @title TokenizedVotingWithRulesClaimable
 * @dev TokenizedVotingWithRulesClaimable contract
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subjects to Swiss Law without reference to its conflicts of law rules.
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
