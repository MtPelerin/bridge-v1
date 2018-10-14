pragma solidity ^0.4.24;

import "./ProvableOwnershipToken.sol";
import "../../interface/IClaimable.sol";
import "../../interface/IWithClaims.sol";


/**
 * @title TokenWithClaims
 * @dev TokenWithClaims contract
 * TokenWithClaims is a token that will create a
 * proofOfOwnership during transfers if a claim can be made.
 * Holder may ask for the claim later using the proofOfOwnership
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subjects to Swiss Law without reference to its conflicts of law rules.
 *
 * Error messages
 * E01: Claimable address must be defined
 * E02: Claimables parameter must not be empty
 * E03: Claimable does not exist
**/
contract TokenWithClaims is IWithClaims, ProvableOwnershipToken {

  IClaimable[] claimables;

  /**
   * @dev Constructor
   */
  constructor(IClaimable[] _claimables) public {
    claimables = _claimables;
  }

  /**
   * @dev Returns the number of claimables
   */
  function claimableLength() public view returns (uint256) {
    return claimables.length;
  }

  /**
   * @dev Returns the Claimable associated to the specified claimableId
   */
  function claimable(uint256 _claimableId) public view returns (IClaimable) {
    return claimables[_claimableId];
  }

  /**
   * @dev Returns true if there are any claims associated to this token
   * to be made at this time for the _holder
   */
  function hasClaims(address _holder) public view returns (bool) {
    uint256 lastTransaction = lastTransactionAt(_holder);
    for (uint256 i = 0; i < claimables.length; i++) {
      if (claimables[i].hasClaimsSince(_holder, lastTransaction)) {
        return true;
      }
    }
    return false;
  }

  /**
   * @dev Override the transfer function with transferWithProofs
   * A proof of ownership will be made if any claims can be made by the participants
   */
  function transfer(address _to, uint256 _value) public returns (bool) {
    bool proofFrom = hasClaims(msg.sender);
    bool proofTo = hasClaims(_to);

    return super.transferWithProofs(
      _to,
      _value,
      proofFrom,
      proofTo
    );
  }

  /**
   * @dev Override the transfer function with transferWithProofs
   * A proof of ownership will be made if any claims can be made by the participants
   */
  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool)
  {
    bool proofFrom = hasClaims(_from);
    bool proofTo = hasClaims(_to);

    return super.transferFromWithProofs(
      _from,
      _to,
      _value,
      proofFrom,
      proofTo
    );
  }

  /**
   * @dev transfer with proofs
   */
  function transferWithProofs(
    address _to,
    uint256 _value,
    bool _proofFrom,
    bool _proofTo
  ) public returns (bool)
  {
    bool proofFrom = _proofFrom || hasClaims(msg.sender);
    bool proofTo = _proofTo || hasClaims(_to);

    return super.transferWithProofs(
      _to,
      _value,
      proofFrom,
      proofTo
    );
  }

  /**
   * @dev transfer from with proofs
   */
  function transferFromWithProofs(
    address _from,
    address _to,
    uint256 _value,
    bool _proofFrom,
    bool _proofTo
  ) public returns (bool)
  {
    bool proofFrom = _proofFrom || hasClaims(_from);
    bool proofTo = _proofTo || hasClaims(_to);

    return super.transferFromWithProofs(
      _from,
      _to,
      _value,
      proofFrom,
      proofTo
    );
  }

  /**
   * @dev add a claimable contract to this token
   */
  function addClaimable(IClaimable _claimable) public onlyOwner {
    require(_claimable != address(0), "E01");
    claimables.push(_claimable);
    emit ClaimableAdded(claimables.length-1);
  }

  /**
   * @dev add several claimables
   */
  function addManyClaimables(IClaimable[] _claimables) public onlyOwner {
    require(_claimables.length > 0, "E02");
    for (uint256 i = 0; i < _claimables.length; i++) {
      addClaimable(_claimables[i]);
    }
  }

  /**
   * @dev remove the claimable at claimableId
   */
  function removeClaimable(uint256 _claimableId) public onlyOwner {
    require(_claimableId < claimables.length, "E03");

    delete claimables[_claimableId];
    if (_claimableId != claimables.length-1) {
      claimables[_claimableId] = claimables[claimables.length-1];
    }
    claimables.length--;
    emit ClaimableRemoved(_claimableId);
  }

  event ClaimableAdded(uint256 claimableId);
  event ClaimableRemoved(uint256 claimableId);
}
