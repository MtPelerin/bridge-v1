pragma solidity ^0.4.24;


/**
 * @title ContractMock
 * @dev ContractMock allows testing of contract interacting
 *
 * @author cyril.lapinte@mtpelerin.com
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subject to Swiss Law without reference to its conflicts of law rules.
 */
contract ContractMock {

  function () external payable {
    emit LogMsg(
      msg.sender,
      // solium-disable-next-line security/no-tx-origin
      tx.origin,
      msg.value,
      msg.data
    );
  }

  function testMe() external payable returns (bool) {
    emit LogFuncCall(
      "testMe",
      msg.sender,
      msg.value,
      msg.data);
  }

  function testMeWithParams(address _address, bytes _data)
    external payable returns (bool)
  {
    emit LogFuncCall(
      "testMeWithParams",
      msg.sender,
      uint256(_address),
      _data);
  }

  function throwMe() external payable returns (bool) {
    assert(false);
  }

  function revertMe() external payable returns (bool) {
    revert("Reverting !");
  }

  function computeMe(uint256 _max) external payable returns (bool) {
    for (uint i = 0; i < _max; i++) {}
    emit LogFuncCall(
      "computeMe",
      msg.sender,
      msg.value,
      msg.data
    );
  }

  event LogMsg(address sender, address origin, uint256 value, bytes data);
  event LogFuncCall(string funcName, address sender, uint256 value,
  bytes data);
}
