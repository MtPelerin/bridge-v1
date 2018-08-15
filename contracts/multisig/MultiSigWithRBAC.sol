pragma solidity ^0.4.24;

import "./MultiSig.sol";


/**
 * @title MultiSigWithRBAC
 * @dev MultiSigWithRBAC contract
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * Error messages
 * E01: msg.sender is not a suggester
 * E02: msg.sender is not an approver
 * E03: msg.sender is not an executer
 */
contract MultiSigWithRBAC is MultiSig {

  struct ParticipantRBAC {
    bool suggester;
    bool approver;
    bool executer;
  }
  mapping(address => ParticipantRBAC) internal participantRBACs;

  /**
   * @dev Modifier for suggester only
   */
  modifier onlySuggester() {
    require(participantRBACs[msg.sender].suggester, "E01");
    _;
  }

  /**
   * @dev Modifier for approver only
   */
  modifier onlyApprover() {
    require(participantRBACs[msg.sender].approver, "E02");
    _;
  }

  /**
   * @dev Modifier for executer only
   */
  modifier onlyExecuter() {
    require(participantRBACs[msg.sender].executer, "E03");
    _;
  }

  /**
   * @dev contructor
   **/
  constructor(
    uint256 _threshold,
    uint256 _duration,
    address[] _participants,
    uint256[] _weights,
    bool[] _suggesters,
    bool[] _approvers,
    bool[] _executers)
    MultiSig(_threshold, _duration, _participants, _weights) public
  {
    updateManyParticipantsRBAC(
      _participants,
      _suggesters,
      _approvers,
      _executers
    );
  }

  function isParticipantSuggester(address _address)
    public view returns (bool)
  {
    return participantRBACs[_address].suggester;
  }

  function isParticipantApprover(address _address) public view returns (bool) {
    return participantRBACs[_address].approver;
  }

  function isParticipantExecuter(address _address) public view returns (bool) {
    return participantRBACs[_address].executer;
  }

  function execute(uint256 _transactionId) public onlyExecuter returns (bool) {
    return super.execute(_transactionId);
  }

  function suggest(
    address _destination,
    uint256 _value,
    bytes _data) public onlySuggester returns (bool)
  {
    return super.suggest(_destination, _value, _data);
  }

  function approve(
    uint256 _transactionId) public onlyApprover returns (bool)
  {
    return super.approve(_transactionId);
  }

  function revokeApproval(
    uint256 _transactionId) public onlyApprover returns (bool)
  {
    return super.revokeApproval(_transactionId);
  }

  function addParticipant(
    address _participant,
    uint256 _weight) public onlyOwner returns (bool)
  {
    return addParticipantWithRBAC(
      _participant,
      _weight,
      false,
      false,
      false
    );
  }

  function addManyParticipants(
    address[] _participants,
    uint256[] _weights) public onlyOwner returns (bool)
  {
    for (uint256 i = 0; i < _participants.length; i++) {
      addParticipantWithRBAC(
        _participants[i],
        _weights[i],
        false,
        false,
        false
      );
    }
    return true;
  }

  function addParticipantWithRBAC(
    address _participant,
    uint256 _weight,
    bool _suggester,
    bool _approver,
    bool _executer) public onlyOwner returns (bool)
  {
    super.addParticipant(_participant, _weight);
    updateParticipantRBAC(
      _participant,
      _suggester,
      _approver,
      _executer
    );
    return true;
  }

  function addManyParticipantsWithRBAC(
    address[] _participants,
    uint256[] _weights,
    bool[] _suggesters,
    bool[] _approvers,
    bool[] _executers) public onlyOwner returns (bool)
  {
    super.addManyParticipants(_participants, _weights);
    updateManyParticipantsRBAC(
      _participants,
      _suggesters,
      _approvers,
      _executers
    );
    return true;
  }

  function updateParticipantRBAC(
    address _participant, 
    bool _suggester,
    bool _approver,
    bool _executer) public onlyOwner returns (bool)
  {
    ParticipantRBAC storage participantRBAC = participantRBACs[_participant];

    if (participantRBAC.suggester != _suggester) {
      participantRBAC.suggester = _suggester;
    }

    if (participantRBAC.approver != _approver) {
      participantRBAC.approver = _approver;
    }

    if (participantRBAC.executer != _executer) {
      participantRBAC.executer = _executer;
    }
    emit ParticipantRolesUpdated(
      _participant,
      _suggester,
      _approver,
      _executer
    );
    return true;
  }

  function updateManyParticipantsRBAC(
    address[] _participants,
    bool[] _suggesters,
    bool[] _approvers,
    bool[] _executers) public onlyOwner returns (bool)
  {
    for (uint256 i = 0; i < _participants.length; i++) {
      updateParticipantRBAC(
        _participants[i],
        _suggesters[i],
        _approvers[i],
        _executers[i]
      );
    }
    return true;
  }

  event ParticipantRolesUpdated(
    address indexed participant,
    bool _suggester,
    bool _approver,
    bool _executer
  );
}
