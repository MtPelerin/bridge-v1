pragma solidity ^0.4.24;


/**
 * @title IRule
 * @dev IRule interface
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 **/
interface IRule {
  function isAddressValid(address _address) external view returns (bool);
  function isTransferValid(address _from, address _to, uint256 _amount)
    external view returns (bool);
}
