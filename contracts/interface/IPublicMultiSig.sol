pragma solidity ^0.4.24;


/**
 * @title IPublicMultiSig
 * @dev IPublicMultiSig interface
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * This content cannot be used, copied or reproduced in part or in whole
 * without the express and written permission of Mt Pelerin Group SA.
 * Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * All matters regarding the intellectual property of this code or software
 * are subjects to Swiss Law without reference to its conflicts of law rules.
**/
contract IPublicMultiSig {
  function () external payable;

  function threshold() public view returns (uint256);
  function duration() public view returns (uint256);

  function participantCount() public view returns (uint256);
  function participantWeight(address _participant)
    public view returns (uint256);

  function isConfirmed(uint256 _transactionId) public view returns (bool);
  function hasParticipated(uint256 _transactionId, address _participationId)
    public view returns (bool);

  function isLocked(uint256 _transactionId) public view returns (bool);
  function isExpired(uint256 _transactionId) public view returns (bool);
  function isCancelled(uint256 _transactionId) public view returns (bool);
  function transactionCreator(uint256 _transactionId)
    public view returns (address);

  function transactionCreatedAt(uint256 _transactionId)
    public view returns (uint256);

  function isExecuted(uint256 _transactionId) public view returns (bool);
  
  function execute(uint256 _transactionId) public returns (bool);

  function suggest(address _destination, uint256 _value, bytes _data)
    public returns (bool);

  function lockTransaction(uint256 _transactionId, bool _locked)
    public returns (bool);

  function cancelTransaction(uint256 _transactionId) public returns (bool);
  function approve(uint256 _transactionId) public returns (bool);
  function revokeApproval(uint256 _transactionId) public returns (bool);

  function addParticipant(address _participant, uint256 _weight)
    public returns (bool);

  function addManyParticipants(address[] _participants, uint256[] _weights)
    public returns (bool);

  function updateParticipant(address _participant, uint256 _weight)
    public returns (bool);

  function updateManyParticipants(address[] _participants, uint256[] _weights)
    public returns (bool);

  function updateConfiguration(uint256 _newThreeshold, uint256 _newDuration)
    public returns (bool);

  event TransactionAdded(uint256 indexed _transactionId);
  event TransactionCancelled(uint256 indexed _transactionId);
  event TransactionLocked(uint256 indexed _transactionId);
  event TransactionUnlocked(uint256 indexed _transactionId);
  event TransactionConfirmed(uint256 indexed _transactionId);
  event TransactionUnconfirmed(uint256 indexed _transactionId);

  event Execution(uint256 indexed _transactionId);
  event ExecutionFailure(uint256 indexed _transactionId);
  event ParticipantAdded(address indexed _participant, uint256 _weight);
  event ParticipantUpdated(address indexed _participant, uint256 _weight);
  event ConfigurationUpdated(uint256 _threshold, uint256 _duration);
}
