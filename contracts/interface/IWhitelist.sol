pragma solidity ^0.4.24;


/**
 * @title IWhitelist
 * @dev IWhitelist interface
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subjects to Swiss Law without reference to its conflicts of law rules.
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
