pragma solidity ^0.4.24;


/**
 * @title IWhitelist
 * @dev IWhitelist interface
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 **/
contract IWhitelist {
  function approveManyAddresses(address[] _addresses) external;
  function rejectManyAddresses(address[] _addresses) external;

  function whitelistCount() public view returns (uint256);
  function isWhitelisted(address _address) public view returns (bool);
  function approveAddress(address _address) public;
  function rejectAddress(address _address) public;

  event AddressApproved(address indexed _address);
  event AddressRejected(address indexed _address);
}
