pragma solidity ^0.4.24;

import "../zeppelin/ownership/Ownable.sol";
import "../zeppelin/math/SafeMath.sol";
import "../interface/IMultiSig.sol";


/**
 * @title MultiSig
 * @dev MultiSig contract
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
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
contract MultiSig is IMultiSig, Ownable {
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

  function () external payable {}

  function threshold() public view returns (uint256) {
    return threshold;
  }

  function duration() public view returns (uint256) {
    return duration;
  }

  function participantCount() public view returns (uint256) {
    return participantCount;
  }

  function participantWeight(address _address) public view returns (uint256) {
    return participants[_address].weight;
  }

  function isConfirmed(uint256 _transactionId) public view returns (bool) {
    return transactions[_transactionId].confirmed >= threshold;
  }

  function hasParticipated(uint256 _transactionId, address _participationId)
    public view returns (bool)
  {
    return transactions[_transactionId].confirmations[_participationId];
  }

  function isLocked(uint256 _transactionId) public view returns (bool) {
    return transactions[_transactionId].locked;
  }

  function isExpired(uint256 _transactionId) public view returns (bool) {
    // solium-disable-next-line security/no-block-members
    return transactions[_transactionId].createdAt.add(duration) < now;
  }

  function toBeExpiredAt(uint256 _transactionId)
    public view returns (uint256)
  {
    return transactions[_transactionId].createdAt.add(duration);
  }

  function isCancelled(uint256 _transactionId) public view returns (bool) {
    return transactions[_transactionId].cancelled;
  }

  function transactionCreator(uint256 _transactionId)
    public view returns (address)
  {
    return transactions[_transactionId].creator;
  }

  function transactionCreatedAt(uint256 _transactionId)
    public view returns (uint256)
  {
    return transactions[_transactionId].createdAt;
  }

  function isExecutable(uint256 _transactionId) public view returns (bool) {
    return !transactions[_transactionId].locked && (
      !transactions[_transactionId].cancelled) && ( 
      !transactions[_transactionId].executed) && (
      !isExpired(_transactionId)) && (
      transactions[_transactionId].confirmed >= threshold);
  }

  function isExecuted(uint256 _transactionId) public view returns (bool) {
    return transactions[_transactionId].executed;
  }

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

  function addParticipant(address _participant, uint256 _weight)
    public onlyOwner returns (bool)
  {
    participants[_participant] = Participant(_weight);
    participantCount++;

    emit ParticipantAdded(_participant, _weight);
    return true;
  }

  function addManyParticipants(address[] _participants, uint256[] _weights)
    public onlyOwner returns (bool)
  {
    for (uint256 i = 0; i < _participants.length; i++) {
      addParticipant(_participants[i], _weights[i]);
    }
    return true;
  }

  function updateParticipant(address _participant, uint256 _weight)
    public onlyOwner returns (bool)
  {
    participants[_participant].weight = _weight;
    emit ParticipantUpdated(_participant, _weight);
    return true;
  }

  function updateManyParticipants(address[] _participants, uint256[] _weights)
    public onlyOwner returns (bool)
  {
    for (uint256 i = 0; i < _participants.length; i++) {
      updateParticipant(_participants[i], _weights[i]);
    }
    return true;
  }

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
