pragma solidity ^0.4.24;


import "../../zeppelin/ownership/Ownable.sol";
import "./BridgeToken.sol";
import "./BridgeTokenCore.sol";


/**
 * @title BridgeToken
 * @dev BridgeToken contract
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subjects to Swiss Law without reference to its conflicts of law rules.
 */
contract IssuableBridgeToken is BridgeToken, Ownable {

  /**
   * @dev called by the owner to increase the supply
   */
  function issue(uint256 _amount) public onlyOwner returns (bool) {
    if(core.issue(owner, _amount)) {
      emit Issued(_amount);
      return true;
    }
    return false;
  }

  /**
   * @dev called by the owner to decrease the supply
   */
  function redeem(uint256 _amount) public onlyOwner returns (bool) {
    if(core.redeem(owner, _amount)) {
      emit Redeemed(_amount);
      return true;
    }
    return false;
  }

  event Issued(uint256 amount);
  event Redeemed(uint256 amount);
}
