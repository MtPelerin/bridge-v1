pragma solidity ^0.4.24;

import "./zeppelin/ownership/Ownable.sol";
import "./interface/IWhitelist.sol";


/**
 * @title Whitelistable
 * @dev Whitelistable contract
 *
 * Error messages
 * WHITELISTABLE_01: address is not whitelisted
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 */
contract Whitelistable is Ownable {
  
  IWhitelist public whitelist;

  modifier onlyWhitelisted(address _address) {
    require(whitelist.isWhitelisted(_address), "WHITELISTABLE_01");
    _;
  }

  function updateWhitelist(IWhitelist _whitelist) public onlyOwner {
    whitelist = _whitelist;
    emit WhitelistUpdated(whitelist);
  }

  event WhitelistUpdated(IWhitelist whitelist);
}
