pragma solidity ^0.4.24;


/**
 * @title IWhitelist
 * @dev IWhitelist interface
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * This content cannot be used, copied or reproduced in part or in whole
 * without the express and written permission of Mt Pelerin Group SA.
 * Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * All matters regarding the intellectual property of this code or software
 * are subjects to Swiss Law without reference to its conflicts of law rules.
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
