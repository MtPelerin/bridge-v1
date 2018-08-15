pragma solidity ^0.4.24;

import "../interface/IClaimable.sol";
import "../dividend/Dividend.sol";


/**
 * @title DividendClaimable
 * @dev DividendClaimable contract
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 */
contract DividendClaimable is IClaimable, Dividend {

  /**
   * @dev constructor
   */
  constructor(ProvableOwnershipToken _token)
  Dividend(_token) public { }

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
