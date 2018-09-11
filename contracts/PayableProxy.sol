pragma solidity ^0.4.24;

import "./zeppelin/ownership/Ownable.sol";


/**
 * @title PayableProxy
 * @dev PayableProxy is a proxy which redirect all incoming transaction
 * to either one account or one payable function of a contract.
 * In the first case, the transaction data will contains the incoming msg.data.
 * In the second case, the payable function will be called with two parameters 
 * the incoming message msg.sender and msg.data
 *
 * To avoid abuse the configuration need to be locked before the redirection is active
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subjects to Swiss Law without reference to its conflicts of law rules.
 *
 * Error messages
 * PAYABLE_PROXY_01: configuration is locked
 * PAYABLE_PROXY_02: configuration has not been locked
 * PAYABLE_PROXY_03: redirection is not started yet
 * PAYABLE_PROXY_04: redirection has failed
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 */
contract PayableProxy is Ownable {

  // Address of the targeted account contract 
  address public payableAddr;

  // Encoded abi of the payable function to be called if the target is a contract
  bytes4 public payableFunction;

  // Redirection start datetime
  uint256 public startAt;

  // Is configuration locked
  bool private configLocked;

  modifier configNotLocked() {
    require(!configLocked, "PAYABLE_PROXY_01");
    _;
  }

  constructor(address _payableAddr, string _payableAbi, uint256 _startAt)
    public
  {
    configure(_payableAddr, _payableAbi, _startAt);
  }

  function () external payable {
    require(configLocked, "PAYABLE_PROXY_02");
    // solium-disable-next-line security/no-block-members
    require(now > startAt, "PAYABLE_PROXY_03");
    callPayable(msg.value, msg.sender, msg.data);
  }

  function payableAddr() public view returns (address) {
    return payableAddr;
  }

  function payableFunction() public view returns (bytes4) {
    return payableFunction;
  }

  function startAt() public view returns (uint256) {
    return startAt;
  }

  function isConfigLocked() public view returns (bool) {
    return configLocked;
  }

  /* @dev configure the proxy with the following parameters
   * @param _payableAddr Address of the  to be redirected to
   * @param _abi ABI of the function to be executed.
   *        Example 'function(address,bytes)'
   * @param _startAt seconds at which the will start redirecting
   *        to the real contract
   */
  function configure(
    address _payableAddr,
    string _payableAbi,
    uint256 _startAt
    ) public onlyOwner configNotLocked
  {
    payableAddr = _payableAddr;
    payableFunction = bytes4(keccak256(abi.encodePacked(_payableAbi)));
    startAt = _startAt;

    emit NewConfig(_payableAddr, _payableAbi, _startAt);
  }

  /* @dev Lock the configuration
   */
  function lockConfig() public onlyOwner configNotLocked {
    dryRun();
    configLocked = true;
    emit ConfigLocked();
  }

  /*
   * @dev Allow to quick check the configuration
   * while the configuration is still unlocked
   */
  function dryRun() public {
    callPayable(0, msg.sender, "test");
  }

  /*
   * @dev Send the received ETH to the configured and locked contract address
   * The call can be done only when the redirection has started
   */
  function callPayable(uint256 _value, address _sender, bytes _data)
    internal
  {
    require(
      // solium-disable-next-line security/no-call-value
      payableAddr.call.value(_value)(payableFunction, _sender, _data),
      "PAYABLE_PROXY_04");
  }

  event NewConfig(address payableAddr, string payableAbi, uint256 startAt);
  event ConfigLocked();
}
