pragma solidity ^0.4.24;

import "../zeppelin/ownership/Ownable.sol";
import "../interface/IRule.sol";
import "../interface/IUserRegistry.sol";


/**
 * @title UserKycRule
 * @dev UserKycRule contract
 *  UserRegistry with the implementation of IRule
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subjects to Swiss Law without reference to its conflicts of law rules.
 *
 * Error messages
 * UKR01: The owner of the address is not identified
 */
contract UserKycRule is IRule {

  IUserRegistry public userRegistry;

  /**
   * @dev constructor
   **/
  constructor(IUserRegistry _userRegistry) public {
    userRegistry = _userRegistry;
  }

  function userRegistry() public view returns (IUserRegistry) {
    return userRegistry;
  }

  /**
   * @dev validates an address
   */
  function isAddressValid(address _address) public view returns (bool) {
    return userRegistry.isAddressValid(_address);
  }

   /**
   * @dev validates a transfer of ownership
   */
  function isTransferValid(address _from, address _to, uint256 /* _amount */)
    public view returns (bool)
  {
    return userRegistry.isAddressValid(_from) &&
      userRegistry.isAddressValid(_to);
  }
}
