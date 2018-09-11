pragma solidity ^0.4.24;

import "../../zeppelin/token/ERC20/StandardToken.sol";
import "../../zeppelin/lifecycle/Pausable.sol";
import "../../demo/KnowYourCustomer.sol";


/**
 * @title CMTARestrictedToken
 * @dev CMTARestrictedToken contract
 *
 * Token with restriction on transferability due to several rules:
 * - KnowYourCustomer
 * - Pausable
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subjects to Swiss Law without reference to its conflicts of law rules.
 */
contract CMTARestrictedToken is StandardToken, KnowYourCustomer, Pausable {

  /**
   * @dev ERC20 transfer
   */
  function transfer(address _to, uint256 _value) public
    whenKYCisValid(msg.sender)
    whenNotPaused returns (bool)
  {
    return super.transfer(_to, _value);
  }

  /**
   * @dev ERC20 transferFrom
   */
  function transferFrom(address _from, address _to, uint256 _value) public
    whenKYCisValid(_from) whenKYCisValid(msg.sender)
    whenNotPaused returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }
}
