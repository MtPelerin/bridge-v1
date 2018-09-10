pragma solidity ^0.4.24;


/**
 * @title IIssuable
 * @dev IIssuable interface
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * This content cannot be used, copied or reproduced in part or in whole
 * without the express and written permission of Mt Pelerin Group SA.
 * Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * All matters regarding the intellectual property of this code or software
 * are subjects to Swiss Law without reference to its conflicts of law rules.
 **/
contract IIssuable {
  function issue(uint256 _amount) public;
  function redeem(uint256 _amount) public;
  event Issue(uint256 amount);
  event Redeem(uint256 amount);
}
