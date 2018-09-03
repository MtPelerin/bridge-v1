pragma solidity ^0.4.24;

import "./MultiSig.sol";


/**
 * @title LockableSig
 * @dev LockableSig contract
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * Error messages
 */
contract LockableSig is MultiSig {

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
  function lock(bytes32[] _sigR, bytes32[] _sigS, uint8[] _sigV)
    thresholdRequired(1, _sigR, _sigS, _sigV) public
  {
    locked = true;
  }

  /**
   * @dev unlock the contract
   */
  function unlock(bytes32[] _sigR, bytes32[] _sigS, uint8[] _sigV)
    thresholdRequired(threshold, _sigR, _sigS, _sigV) public
  {
    locked = false;
  }

  /**
   * @dev override execute internal call
   */
  function executeInternal(address _destination, uint256 _value, bytes _data)
    internal
  {
    require(!locked);
    super.executeInternal(_destination, _value, _data);
  }
}
