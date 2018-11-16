pragma solidity ^0.4.24;

import "./zeppelin/ownership/Ownable.sol";
import "./interface/IWhitelist.sol";


/**
 * @title Whitelist
 * @dev Whitelist contract
 *
 * Whitelist a list of addresses only updatable by the owner
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subject to Swiss Law without reference to its conflicts of law rules.
 *
 */
contract Whitelist is IWhitelist, Ownable {

  mapping(address => bool) internal whitelist;
  uint256 public whitelistCount;

  /**
   * @dev Constructor
   */
  constructor(address[] _addresses) public {
    for (uint256 i = 0; i < _addresses.length; i++) {
      approveAddress(_addresses[i]);
    }
  }

  /**
   * @dev Approve many addresses
   **/
  function approveManyAddresses(address[] _addresses) external onlyOwner {
    for (uint256 i = 0; i < _addresses.length; i++) {
      approveAddress(_addresses[i]);
    }
  }

  /**
   * @dev Reject many addresses
   **/
  function rejectManyAddresses(address[] _addresses) external onlyOwner {
    for (uint256 i = 0; i < _addresses.length; i++) {
      rejectAddress(_addresses[i]);
    }
  }

  /**
   * @dev getter need to be declared to comply with IWhitelist interface
   */
  function whitelistCount() public view returns (uint256) {
    return whitelistCount;
  }

  /**
   * @dev Is the address whitelisted
   **/
  function isWhitelisted(address _address) public view returns (bool) {
    return whitelist[_address];
  }

  /** 
   * @dev Approve the provided address
   **/
  function approveAddress(address _address) public onlyOwner {
    if (!whitelist[_address]) {
      whitelist[_address] = true;
      whitelistCount++;
      emit AddressApproved(_address);
    }
  }

  /**
   * @dev Reject the provided address
   **/
  function rejectAddress(address _address) public onlyOwner {
    if (whitelist[_address]) {
      whitelist[_address] = false;
      whitelistCount--;
      emit AddressRejected(_address);
    }
  }

  event AddressApproved(address indexed _address);
  event AddressRejected(address indexed _address);
}
