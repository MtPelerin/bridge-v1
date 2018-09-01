pragma solidity ^0.4.24;

import "../Authority.sol";


/**
 * @title AuthorityMock
 * @dev Mock the Authority class
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 */
contract AuthorityMock is Authority {

  function testOnlyAuthority(string _name) public onlyAuthority(_name) view returns (bool) {
    return true;
  }
}
