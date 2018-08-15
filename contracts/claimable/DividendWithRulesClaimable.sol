pragma solidity ^0.4.24;

import "../interface/IClaimable.sol";
import "../dividend/DividendWithRules.sol";


/**
 * @title DividendWithRulesClaimable
 * @dev DividendWithRulesClaimable contract
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 */
contract DividendWithRulesClaimable is IClaimable, DividendWithRules {

  /**
   * @dev constructor
   */
  constructor(ProvableOwnershipToken _token, IRule[] _rules)
  DividendWithRules(_token, _rules) public { }

  /**
   * @dev implements has claims
   *
   * Returns true if there was at least a dividend created after that date
   */
  function hasClaimsSince(address /*_address*/, uint256 _at)
    public view returns (bool)
  {
    return _at < dividends[dividendsCount-1].createdAt;
  }
}
