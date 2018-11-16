pragma solidity ^0.4.24;

import "../zeppelin/ownership/Ownable.sol";


/**
 * @title Shareholder
 * @dev Shareholder contract
 *
 * Define the shareholders
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subject to Swiss Law without reference to its conflicts of law rules.
 */
contract Shareholder is Ownable {

  address[] public shareholders;

  /**
   * @dev shareholders
   */
  function shareholders() public view returns (address[]) {
    return shareholders;
  }

  /**
   * @dev isShareholder
   */
  function isShareholder(address _address) public view returns (bool) {
    for (uint256 i = 0; i < shareholders.length; i++) {
      if (shareholders[i] == _address) {
        return true;
      }
    }
    return false;
  }

  /**
   * @dev Update shareholders
   **/
  function updateShareholders(address[] _shareholders) public onlyOwner {
    shareholders = _shareholders;
  }
}
