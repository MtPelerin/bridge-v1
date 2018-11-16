pragma solidity ^0.4.24;


/**
 * @title IRegistry
 * @dev IRegistry interface
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subject to Swiss Law without reference to its conflicts of law rules.
 **/
contract IRegistry {
  function name() public view returns (string);
  function addressLength() public view returns (uint256);
  function addressById(uint256 id) public view returns (address);

  function addAddress(address value) public returns (uint256);
  function removeAddressById(uint256 id) public returns (address);
  function replaceAddressById(uint256 id, address value)
    public returns (address);

  event AddressAdded(uint256 id, address newValue);
  event AddressRemoved(uint256 id, address oldValue);
  event AddressReplaced(uint256 id, address newValue, address oldValue);
}
