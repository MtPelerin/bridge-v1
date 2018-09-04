pragma solidity ^0.4.24;

import "../multisig/private/DelegateSig.sol";


/**
 * @title DelegateSigMock
 * @dev Mock the DelegateSig class
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 */
contract DelegateSigMock is DelegateSig {
  /**
   * @dev constructor
   */
  constructor(address[] _signers, uint8 _threshold)
    MultiSig(_signers, _threshold) public {
  }
}
