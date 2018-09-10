pragma solidity ^0.4.24;

import "../interface/IClaimable.sol";
import "../dividend/Dividend.sol";


/**
 * @title DividendClaimable
 * @dev DividendClaimable contract
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * This content cannot be used, copied or reproduced in part or in whole
 * without the express and written permission of Mt Pelerin Group SA.
 * Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * All matters regarding the intellectual property of this code or software
 * are subjects to Swiss Law without reference to its conflicts of law rules.
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
