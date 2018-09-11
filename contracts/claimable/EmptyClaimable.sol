pragma solidity ^0.4.24;

import "../interface/IClaimable.sol";


/**
 * @title EmptyClaimable
 * @dev EmptyClaimable interface
 *
 * This contract provide an empty claim
 * Usefull for testing IWithClaims implementation
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subjects to Swiss Law without reference to its conflicts of law rules.
 */
contract EmptyClaimable is IClaimable {
  bool public active;

  constructor(bool _active) public {
    active = _active;
  }
  
  function hasClaimsSince(address /*_address*/, uint256 /*_at*/)
    public view returns (bool)
  {
    return active;
  }
}
