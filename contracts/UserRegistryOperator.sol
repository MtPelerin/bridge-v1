pragma solidity ^0.4.24;

import "./zeppelin/ownership/Ownable.sol";
import "./Operator.sol";
import "./interface/IUserRegistry.sol";


/**
 * @title UserRegistryOperator
 * @dev UserRegistryOperator operate the user registry
 * It will update the user registry based on KYC
 *
 * @notice Copyright © 2016 - 2019 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subjects to Swiss Law without reference to its conflicts of law rules.
 *
 * Error messages
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 */
contract UserRegistryOperator is Operator {

  bytes4 constant REGISTER_USER_BYTES = bytes4(keccak256('registerUser(address,uint256)'));
  bytes4 constant ATTACH_ADDRESS_BYTES = bytes4(keccak256('attachAddress(uint256,address)'));

  IUserRegistry public userRegistry;

  struct Operation {
    bytes data;
    bytes32 trigger;
    uint256 expireAt;
  }
 
  mapping (address => Operation) public operations;

  /**
   * @dev constructor
   */
  constructor (IUserRegistry _userRegistry) public {
    userRegistry = _userRegistry;
  }

  /**
   * @dev default function
   */
  function () external payable {
    require(msg.value == 0, "UO01");
    execute(msg.data);
  }

  /**
   * @dev execute trigger
   */
  function execute(bytes _trigger) public {
    Operation storage operation = operations[msg.sender];
    require(operation.expireAt >= now, "UO02");
    require(keccak256(_trigger) == operation.trigger, "UO03");

    require(address(userRegistry).call(operation.data), "UO04");
  }

  /**
   * @dev plan an 'attach address' operation
   */
  function planAttachAddress(uint256 _userId, address _address, bytes32 _trigger) public onlyOperator {
    operations[_address] = Operation(
      abi.encode(ATTACH_ADDRESS_BYTES, _userId, _address),
      _trigger,
      now + 1 days
    );
    emit OperationPlanned(ATTACH_ADDRESS_BYTES, _address);
  }

  /**
   * @dev plan an 'attach address' operation
   */
  function planAttachAddressSelf(address _address, bytes32 _trigger) public {
    uint256 userId = userRegistry.validUserId(msg.sender);
    require(userId != 0, "UO05");

    operations[_address] = Operation(
      abi.encode(ATTACH_ADDRESS_BYTES, userId, _address),
      _trigger,
      now + 6 hours
    );
    emit OperationPlanned(ATTACH_ADDRESS_BYTES, _address);
  }

  /**
   * @dev plan a 'register user' operation
   */
  function planRegisterUser(address _address, uint256 _validUntilTime, bytes32 _trigger)
    public onlyOperator
  {
    operations[_address] = Operation(
      abi.encode(REGISTER_USER_BYTES, _address, _validUntilTime),
      _trigger,
      now + 1 days
    );
    emit OperationPlanned(REGISTER_USER_BYTES, _address);
  }

  event OperationPlanned(bytes4 indexed _type, address indexed actor);
}
