pragma solidity ^0.4.23;

import "./zeppelin/ownership/Ownable.sol";


/**
 * @title Operator
 * @dev The Operator contract contains list of addresses authorized to specific operations
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subject to Swiss Law without reference to its conflicts of law rules.
 *
 * Error messages
 * OP01: Message sender must be an authority
 */
contract Operator is Ownable {

  mapping (address => uint8) operatorIds;
  address[] public operators;

  /**
   * @dev Throws if called by any account other than the operator
   */
  modifier onlyOperator {
    require(operatorIds[msg.sender] > 0, "OP01");
    _;
  }

  /**
   * @dev return the count of operator
   */
  function operatorCount() public view returns (uint256) {
    return operators.length;
  }

  /**
   * @dev return the address associated to the _operatorId
   */
  function operatorAddress(uint8 _operatorId) public view returns (address) {
    return operators[_operatorId];
  }

  /**
   * @dev defineOperator role
   * @param _names operators names
   * @param _addresses operator addresses.
   */
  function defineOperators(bytes32[] _names, address[] _addresses)
    public onlyOwner
  {
    require(_names.length == _addresses.length, "OP02");

    for (uint256 i = 0; i < operators.length; i++) {
      delete operatorIds[operators[i]];
    }
    emit OperatorsCleared(operators.length);

    for (uint256 j = 0; j < _names.length; j++) {
      emit OperatorDefined(_names[j], _addresses[j]);
      operatorIds[_addresses[j]] = uint8(j + 1);
    }
    operators = _addresses;
  }

  event OperatorsCleared(uint256 size);
  event OperatorDefined(
    bytes32 name,
    address _address
  );
}
