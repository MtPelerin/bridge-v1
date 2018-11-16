pragma solidity ^0.4.24;

import "../governance/BoardSig.sol";


/**
 * @title MPSBoardSig
 * @dev MPSBoardSig contract
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subject to Swiss Law without reference to its conflicts of law rules.
 *
 * @notice Swissquote Bank SA solely is entitled to the GNU LGPL.
 * @notice Any other party is subject to the copyright mentioned in the software.
 *
 * Error messages
 */
contract MPSBoardSig is BoardSig {

  string public companyName = "MtPelerin Group SA";
  string public country = "Switzerland";
  string public registeredNumber = "CHE-188.552.084";

  /**
   * @dev constructor function
   */
  constructor(address[] _addresses, uint8 _threshold) public
    BoardSig(_addresses, _threshold)
  {
  }
}
