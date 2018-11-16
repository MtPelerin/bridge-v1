pragma solidity ^0.4.24;

import "./MultiSig.sol";


/**
 * @title LockableSig
 * @dev LockableSig contract
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subject to Swiss Law without reference to its conflicts of law rules.
 *
 * Error messages
 * LS1: Contract must be unlocked to execute
 */
contract LockableSig is MultiSig {

  bytes public constant LOCK = abi.encodePacked(keccak256("LOCK"));
  bool private locked;

  /**
   * @dev constructor
   */
  constructor(address[] _addresses, uint8 _threshold)
    MultiSig(_addresses, _threshold) public
  {
  }

  /**
   * @dev is the contract locked
   */
  function isLocked() public view returns (bool) {
    return locked;
  }

  /**
   * @dev lock the contract
   */
  function lock() public onlySigners {
    locked = true;
  }

  /**
   * @dev unlock the contract
   */
  function unlock(bytes32[] _sigR, bytes32[] _sigS, uint8[] _sigV)
    public
    thresholdRequired(address(this), 0, LOCK, 0,
      threshold, _sigR, _sigS, _sigV)
  {
    locked = false;
  }

  /**
   * @dev override execute internal call
   */
  function executeInternal(address _destination, uint256 _value, bytes _data)
    internal
  {
    require(!locked, "LS1");
    super.executeInternal(_destination, _value, _data);
  }
}
