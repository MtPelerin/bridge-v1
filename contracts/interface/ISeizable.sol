pragma solidity ^0.4.24;


/**
 * @title ISeizable
 * @dev ISeizable interface
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 **/
contract ISeizable {
  function seize(address _account, uint256 _value) public;
  event Seize(address account, uint256 amount);
}
