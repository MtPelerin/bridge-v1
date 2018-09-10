pragma solidity ^0.4.24;

import "../zeppelin/token/ERC20/StandardToken.sol";
import "../interface/IAuditableToken.sol";


/**
 * @title AuditableToken
 * @dev AuditableToken contract
 * AuditableToken provides transaction data which can be used
 * in other smart contracts
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * This content cannot be used, copied or reproduced in part or in whole
 * without the express and written permission of Mt Pelerin Group SA.
 * Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * All matters regarding the intellectual property of this code or software
 * are subjects to Swiss Law without reference to its conflicts of law rules.
 **/
contract AuditableToken is IAuditableToken, StandardToken {

   // Although very unlikely, the following values below may overflow:
   //   receivedCount, sentCount, totalReceivedAmount, totalSentAmount
   // This contract and his childs should expect it to happened and consider
   // these values as only the first 256 bits of the complete value.
  struct Audit {
    uint256 createdAt;
    uint256 lastReceivedAt;
    uint256 lastSentAt;
    uint256 receivedCount; // potential overflow
    uint256 sentCount; // poential overflow
    uint256 totalReceivedAmount; // potential overflow
    uint256 totalSentAmount; // potential overflow
  }
  mapping(address => Audit) internal audits;

  /**
   * @dev Time of the creation of the audit struct
   */
  function auditCreatedAt(address _address) public view returns (uint256) {
    return audits[_address].createdAt;
  }

  /**
   * @dev Time of the last transaction
   */
  function lastTransactionAt(address _address) public view returns (uint256) {
    return ( audits[_address].lastReceivedAt > audits[_address].lastSentAt ) ?
      audits[_address].lastReceivedAt : audits[_address].lastSentAt;
  }

  /**
   * @dev Time of the last received transaction
   */
  function lastReceivedAt(address _address) public view returns (uint256) {
    return audits[_address].lastReceivedAt;
  }

  /**
   * @dev Time of the last sent transaction
   */
  function lastSentAt(address _address) public view returns (uint256) {
    return audits[_address].lastSentAt;
  }

  /**
   * @dev Count of transactions
   */
  function transactionCount(address _address) public view returns (uint256) {
    return audits[_address].receivedCount + audits[_address].sentCount;
  }

  /**
   * @dev Count of received transactions
   */
  function receivedCount(address _address) public view returns (uint256) {
    return audits[_address].receivedCount;
  }

  /**
   * @dev Count of sent transactions
   */
  function sentCount(address _address) public view returns (uint256) {
    return audits[_address].sentCount;
  }

  /**
   * @dev All time received
   */
  function totalReceivedAmount(address _address)
    public view returns (uint256)
  {
    return audits[_address].totalReceivedAmount;
  }

  /**
   * @dev All time sent
   */
  function totalSentAmount(address _address) public view returns (uint256) {
    return audits[_address].totalSentAmount;
  }

  /**
   * @dev Overriden transfer function
   */
  function transfer(address _to, uint256 _value) public returns (bool) {
    if (!super.transfer(_to, _value)) {
      return false;
    }
    updateAudit(msg.sender, _to, _value);
    return true;
  }

  /**
   * @dev Overriden transferFrom function
   */
  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool)
  {
    if (!super.transferFrom(_from, _to, _value)) {
      return false;
    }

    updateAudit(_from, _to, _value);
    return true;
  }

  /**
   * @dev Update audit data
   */
  function updateAudit(address _sender, address _receiver, uint256 _value)
    private returns (uint256)
  {
    // solium-disable-next-line security/no-block-members
    uint256 currentTime = now;

    Audit storage senderAudit = audits[_sender];
    senderAudit.lastSentAt = currentTime;
    senderAudit.sentCount++;
    senderAudit.totalSentAmount += _value;
    if (senderAudit.createdAt == 0) {
      senderAudit.createdAt = currentTime;
    }

    Audit storage receiverAudit = audits[_receiver];
    receiverAudit.lastReceivedAt = currentTime;
    receiverAudit.receivedCount++;
    receiverAudit.totalReceivedAmount += _value;
    if (receiverAudit.createdAt == 0) {
      receiverAudit.createdAt = currentTime;
    }
  }
}
