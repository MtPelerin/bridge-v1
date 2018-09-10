pragma solidity ^0.4.24;

import "../interface/IRule.sol";


/**
 * @title YesNoRule
 * @dev YesNoRule interface
 * The rule always answer the same response through isValid
 * Usefull for testing IWithRule implementation
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * This content cannot be used, copied or reproduced in part or in whole
 * without the express and written permission of Mt Pelerin Group SA.
 * Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * All matters regarding the intellectual property of this code or software
 * are subjects to Swiss Law without reference to its conflicts of law rules.
 */
contract YesNoRule is IRule {
  bool public yesNo;

  constructor(bool _yesNo) public {
    yesNo = _yesNo;
  }

  function isAddressValid(address /* _from */) public view returns (bool) {
    return yesNo;
  }

  function isTransferValid(
    address /* _from */,
    address /*_to */,
    uint256 /*_amount */)
    public view returns (bool)
  {
    return yesNo;
  }
}
