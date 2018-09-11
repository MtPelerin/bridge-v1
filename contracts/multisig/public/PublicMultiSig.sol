pragma solidity ^0.4.24;

import "../../zeppelin/ownership/Ownable.sol";
import "../../zeppelin/math/SafeMath.sol";
import "../../interface/IPublicMultiSig.sol";


/**
 * @title PublicMultiSig
 * @dev PublicMultiSig contract
 * Every one can suggest a new transaction
 * Every one can execut it once it is approved
 * If a threshold is defined, only participants with a weight > 0
 *   will be able to influence the approval
 * With a threshold of 0, approval is not required any more.
 * Only participants can approved transaction based on their weight
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subjects to Swiss Law without reference to its conflicts of law rules.
 *
 * Error messages
 * E01: Transaction is expired
 * E02: Transaction is cancelled
 * E03: Transaction is executed
 * E04: Transaction is locked
 * E05: Transaction is not confirmed
 * E06: Only creator can lock a transaction
 * E07: Only creator or owner can cancel a transaction
 * E08: Transaction is already confirmed
 * E09: Invalid transaction id
 * E10: Transaction is already unapproved
 */
contract PublicMultiSig is IPublicMultiSig, Ownable {
  using SafeMath for uint256;

  uint256 public threshold;
  uint256 public duration;

  struct Participant {
    uint256 weight;
  }
  mapping(address => Participant) internal participants;
  uint256 public participantCount;

  struct Transaction {
    address destination;
    uint256 value;
    bytes data;
    uint256 confirmed;
    bool locked;
    bool cancelled;
    address creator;
    uint256 createdAt;
    bool executed;
    mapping(address => bool) confirmations;
  }
  mapping(uint256 => Transaction) internal transactions;
  uint256 public transactionCount;

  /**
   * @dev Modifier for active transaction
   */
  modifier whenActive(uint256 _transactionId) {
    require(!isExpired(_transactionId), "E01");
    require(!transactions[_transactionId].cancelled, "E02");
    require(!transactions[_transactionId].executed, "E03");
    _;
  }

  /**
   * @dev contructor
   **/
  constructor(
    uint256 _threshold,
    uint256 _duration,
    address[] _participants,
    uint256[] _weights
  ) public
  {
    threshold = _threshold;
    duration = _duration;

    addManyParticipants(_participants, _weights);
    owner = address(this);
  }

  /**
   * @dev fallback function
   */
  function () external payable {}

  /**
   * @dev threshold
   */
  function threshold() public view returns (uint256) {
    return threshold;
  }

  /**
   * @dev duration
   */
  function duration() public view returns (uint256) {
    return duration;
  }

  /**
   * @dev participant count
   */
  function participantCount() public view returns (uint256) {
    return participantCount;
  }

  /**
   * @dev participant weight
   */
  function participantWeight(address _address) public view returns (uint256) {
    return participants[_address].weight;
  }

  /**
   * @dev isConfirmed
   */
  function isConfirmed(uint256 _transactionId) public view returns (bool) {
    return transactions[_transactionId].confirmed >= threshold;
  }

  /**
   * @dev hasParticipated
   */
  function hasParticipated(uint256 _transactionId, address _participationId)
    public view returns (bool)
  {
    return transactions[_transactionId].confirmations[_participationId];
  }

  /**
   * @dev isLocked
   */
  function isLocked(uint256 _transactionId) public view returns (bool) {
    return transactions[_transactionId].locked;
  }

  /**
   * @dev isExpired
   */
  function isExpired(uint256 _transactionId) public view returns (bool) {
    // solium-disable-next-line security/no-block-members
    return transactions[_transactionId].createdAt.add(duration) < now;
  }

  /**
   * @dev toBeExpiredAt
   */
  function toBeExpiredAt(uint256 _transactionId)
    public view returns (uint256)
  {
    return transactions[_transactionId].createdAt.add(duration);
  }

  /**
   * @dev isCancelled
   */
  function isCancelled(uint256 _transactionId) public view returns (bool) {
    return transactions[_transactionId].cancelled;
  }

  /**
   * @dev transactionDestination
   */
  function transactionDestination(uint256 _transactionId)
    public view returns (address)
  {
    return transactions[_transactionId].destination;
  }

  /**
   * @dev transactionValue
   */
  function transactionValue(uint256 _transactionId)
    public view returns (uint256)
  {
    return transactions[_transactionId].value;
  }

  /**
   * @dev transactionData
   */
  function transactionData(uint256 _transactionId)
    public view returns (bytes)
  {
    return transactions[_transactionId].data;
  }

  /**
   * @dev transactionCreator
   */
  function transactionCreator(uint256 _transactionId)
    public view returns (address)
  {
    return transactions[_transactionId].creator;
  }

  /**
   * @dev transactionCreatedAt
   */
  function transactionCreatedAt(uint256 _transactionId)
    public view returns (uint256)
  {
    return transactions[_transactionId].createdAt;
  }

  /**
   * @dev isExecutable
   */
  function isExecutable(uint256 _transactionId) public view returns (bool) {
    return !transactions[_transactionId].locked && (
      !transactions[_transactionId].cancelled) && ( 
      !transactions[_transactionId].executed) && (
      !isExpired(_transactionId)) && (
      transactions[_transactionId].confirmed >= threshold);
  }

  /**
   * @dev isExecuted
   */
  function isExecuted(uint256 _transactionId) public view returns (bool) {
    return transactions[_transactionId].executed;
  }

  /**
   * @dev execute
   * Execute a transaction with a specific id
   */
  function execute(uint256 _transactionId)
    public whenActive(_transactionId) returns (bool)
  {
    require(!transactions[_transactionId].locked, "E04");
    require(
      transactions[_transactionId].confirmed >= threshold,
      "E05");

    Transaction storage transaction = transactions[_transactionId];
    transaction.executed = true;
    if (
      // solium-disable-next-line security/no-call-value
      transaction.destination.call.value(transaction.value)(transaction.data))
    {
      emit Execution(_transactionId);
    } else {
      transaction.executed = false;
      emit ExecutionFailure(_transactionId);
    }
    return true;
  }

  /**
   * @dev suggest a new transaction
   */
  function suggest(address _destination, uint256 _value, bytes _data)
    public returns (bool)
  {
    transactions[transactionCount] = Transaction(
      _destination,
      _value,
      _data,
      0,
      false,
      false,
      msg.sender,
      // solium-disable-next-line security/no-block-members
      now,
      false
    );
    transactionCount++;
    emit TransactionAdded(transactionCount-1);
    return true;
  }

  /**
   * @dev set the lock state of a transaction
   */
  function lockTransaction(uint256 _transactionId, bool _locked)
    public whenActive(_transactionId) returns (bool)
  {
    require(
      transactions[_transactionId].creator == msg.sender,
      "E06");

    if (transactions[_transactionId].locked == _locked) {
      return true;
    }

    transactions[_transactionId].locked = _locked;
    if (_locked) {
      emit TransactionLocked(_transactionId);
    } else {
      emit TransactionUnlocked(_transactionId);
    }
    return true;
  }

  /**
   * @dev cancel a transaction
   */
  function cancelTransaction(uint256 _transactionId)
    public whenActive(_transactionId) returns (bool)
  {
    require(
      transactions[_transactionId].creator == msg.sender ||
      msg.sender == address(this),
      "E07"
    );

    transactions[_transactionId].cancelled = true;
    emit TransactionCancelled(_transactionId);
    return true;
  }

  /**
   * @dev approve a transaction
   */
  function approve(uint256 _transactionId)
    public whenActive(_transactionId) returns (bool)
  {
    Transaction storage transaction = transactions[_transactionId];
    require(!transaction.confirmations[msg.sender], "E08");

    transaction.confirmed = transaction.confirmed.add(
      participants[msg.sender].weight);
    transaction.confirmations[msg.sender] = true;

    if (transaction.confirmed >= threshold) {
      emit TransactionConfirmed(_transactionId);
    }
    return true;
  }

  /**
   * @dev revoke a transaction approval
   */
  function revokeApproval(uint256 _transactionId)
    public whenActive(_transactionId) returns (bool)
  {
    require(_transactionId < transactionCount, "E09");
    Transaction storage transaction = transactions[_transactionId];
    require(transaction.confirmations[msg.sender], "E10");

    transaction.confirmed = transaction.confirmed.sub(
      participants[msg.sender].weight);
    transaction.confirmations[msg.sender] = false;

    if (transaction.confirmed < threshold &&
        transaction.confirmed.add(
          participants[msg.sender].weight) >= threshold)
    {
      emit TransactionUnconfirmed(_transactionId);
    }
    return true;
  }

  /**
   * @dev add participant
   */
  function addParticipant(address _participant, uint256 _weight)
    public onlyOwner returns (bool)
  {
    participants[_participant] = Participant(_weight);
    participantCount++;

    emit ParticipantAdded(_participant, _weight);
    return true;
  }

  /**
   * @dev add many participants
   */
  function addManyParticipants(address[] _participants, uint256[] _weights)
    public onlyOwner returns (bool)
  {
    for (uint256 i = 0; i < _participants.length; i++) {
      addParticipant(_participants[i], _weights[i]);
    }
    return true;
  }

  /**
   * @dev update participant weight
   */
  function updateParticipant(address _participant, uint256 _weight)
    public onlyOwner returns (bool)
  {
    participants[_participant].weight = _weight;
    emit ParticipantUpdated(_participant, _weight);
    return true;
  }

  /**
   * @dev update many participants weight
   */
  function updateManyParticipants(address[] _participants, uint256[] _weights)
    public onlyOwner returns (bool)
  {
    for (uint256 i = 0; i < _participants.length; i++) {
      updateParticipant(_participants[i], _weights[i]);
    }
    return true;
  }

  /**
   * @dev update configuration
   */
  function updateConfiguration(uint256 _newThreshold, uint256 _newDuration)
    public onlyOwner returns (bool)
  {
    threshold = _newThreshold;
    duration = _newDuration;

    emit ConfigurationUpdated(threshold, duration);
    return true;
  }

  event TransactionAdded(uint256 transactionId);
  event TransactionCancelled(uint256 transactionId);
  event TransactionLocked(uint256 transactionId);
  event TransactionUnlocked(uint256 transactionId);
  event TransactionConfirmed(uint256 transactionId);
  event TransactionUnconfirmed(uint256 transactionId);

  event Execution(uint256 indexed transactionId);
  event ExecutionFailure(uint256 indexed transactionId);
  event ParticipantAdded(address indexed participant, uint256 weight);
  event ParticipantUpdated(address indexed participant, uint256 weight);
  event ConfigurationUpdated(uint256 threshold, uint256 duration);
}
