pragma solidity ^0.4.24;

import "./LockableSig.sol";
import "./DelegateSig.sol";


/**
 * @title ProcessSig
 * @dev ProcessSig contract
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * Error messages
 * E01: ETH transfers not allowed
 */
contract ProcessSig is DelegateSig, LockableSig {

  /**
   * @dev fallback function
   */
  constructor(address[] _addresses, uint8 _threshold) public
    LockableSig(_addresses, _threshold)
  {
  }

  /**
   * @dev fallback function
   */
  function () payable public {
    revert();
  }
}
