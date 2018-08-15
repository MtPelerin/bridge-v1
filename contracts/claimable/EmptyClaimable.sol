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
