pragma solidity ^0.4.24;

import "../zeppelin/token/ERC20/StandardToken.sol";


/**
 * @title IAuditableToken
 * @dev IAuditableToken interface describing the audited data
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 **/
contract IAuditableToken {
  function lastTransactionAt(address _address) public view returns (uint256);
  function lastReceivedAt(address _address) public view returns (uint256);
  function lastSentAt(address _address) public view returns (uint256);
  function transactionCount(address _address) public view returns (uint256);
  function receivedCount(address _address) public view returns (uint256);
  function sentCount(address _address) public view returns (uint256);
  function totalReceivedAmount(address _address) public view returns (uint256);
  function totalSentAmount(address _address) public view returns (uint256);
}
