pragma solidity ^0.4.24;

import "./IClaimable.sol";


/**
 * @title IWithClaims
 * @dev IWithClaims interface
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 **/
contract IWithClaims {
  function claimableLength() public view returns (uint256);
  function claimable(uint256 _claimableId) public view returns (IClaimable);
  function hasClaims(address _holder) public view returns (bool);
  function addClaimable(IClaimable _claimable) public;
  function addManyClaimables(IClaimable[] _claimables) public;
  function removeClaimable(uint256 _claimableId) public;

  event ClaimableAdded(uint256 claimableId);
  event ClaimableRemoved(uint256 claimableId);
}
