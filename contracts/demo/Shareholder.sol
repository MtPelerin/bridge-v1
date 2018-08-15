pragma solidity ^0.4.24;

import "../zeppelin/ownership/Ownable.sol";


/**
 * @title Shareholder
 * @dev Shareholder contract
 *
 * Define the shareholders
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
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
