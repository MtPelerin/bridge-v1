pragma solidity ^0.4.24;

import "./zeppelin/ownership/Ownable.sol";
import "./interface/IWhitelist.sol";


/**
 * @title Whitelistable
 * @dev Whitelistable contract
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
 * Error messages
 * W01: address is not whitelisted
 *
 */
contract Whitelistable is Ownable {
  
  IWhitelist public whitelist;

  modifier onlyWhitelisted(address _address) {
    require(whitelist.isWhitelisted(_address), "W01");
    _;
  }

  function updateWhitelist(IWhitelist _whitelist) public onlyOwner {
    whitelist = _whitelist;
    emit WhitelistUpdated(whitelist);
  }

  event WhitelistUpdated(IWhitelist whitelist);
}
