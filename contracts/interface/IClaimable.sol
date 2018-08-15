pragma solidity ^0.4.24;


/**
 * @title IClaimable
 * @dev IClaimable interface
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 **/
interface IClaimable {
  function hasClaimsSince(address _address, uint256 at)
    external view returns (bool);
}
