pragma solidity ^0.4.24;

import "../zeppelin/ownership/Ownable.sol";
import "../zeppelin/token/ERC20/StandardToken.sol";


/**
 * @title TokenMigrations
 * @dev TokenMigrations contract
 * @dev This version is compatible with all ERC20 tokens
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
 * TM01: Not enough tokens available to cover supply of previous token contract
 * TM02: All tokens should be allocated to the migrations contract to start migration
 * TM03: No tokens to migrate
 * TM04: Insufficient allowance
 * TM05: Unable to lock tokens
 * TM06: Migration is already done
 * TM07: Missing latest tokens
 * TM08: Unable to migrate tokens
 */
contract TokenMigrations is Ownable {
  struct Migration {
    uint256 totalMigrated;
    uint256 accountsMigrated;
    mapping(address => bool) accounts;
  }
  mapping(address => Migration) private migrations;

  StandardToken public latestToken;
  uint256 public version;

  /**
   * @dev contructor
   **/
  constructor(StandardToken _token) public {
    latestToken = _token;
  }

  /**
   * @dev isAccountMigrated
   */
  function isAccountMigrated(StandardToken _token, address _account)
    public view returns (bool)
  {
    return migrations[_token].accounts[_account];
  }

  /**
   * @dev accountsMigrated
   */
  function accountsMigrated(StandardToken _token)
    public view returns (uint256)
  {
    return migrations[_token].accountsMigrated;
  }

  /**
   * @dev totalMigrated
   */
  function totalMigrated(StandardToken _token)
    public view returns (uint256)
  {
    return migrations[_token].totalMigrated;
  }

  /**
   * @dev latestToken
   */
  function latestToken()
    public view returns (StandardToken)
  {
    return latestToken;
  }

  /**
   * @dev version
   */
  function version()
    public view returns (uint256)
  {
    return version;
  }

  /**
   * @dev upgrade
   */
  function upgrade(StandardToken _newToken) public onlyOwner {
    require(_newToken.balanceOf(this) == _newToken.totalSupply(), "TM01");
    require(_newToken.balanceOf(this) == latestToken.totalSupply(), "TM02");

    migrations[latestToken] = Migration(0, 0);
   
    version++; 
    emit NewMigration(latestToken);
    latestToken = _newToken;
  }

  /**
   * @dev acceptMigration
   * `acceptMigration` may be overriden by children contracts
   * acceptMigration must do checks and operations to ensure
   * that old tokens will be locked forever !
   */
  function acceptMigration(StandardToken _oldToken) public {
    uint256 amount = _oldToken.balanceOf(msg.sender);
    require(amount > 0, "TM03");
    require(_oldToken.allowance(msg.sender, this) == amount, "TM04");
    require(_oldToken.transferFrom(msg.sender, this, amount), "TM05");
    migrateInternal(_oldToken, amount);
  }

  /**
   * @dev migrateInternal
   */
  function migrateInternal(StandardToken _oldToken, uint256 _amount)
    internal
  {
    require(!migrations[_oldToken].accounts[msg.sender], "TM06");
    require(latestToken.balanceOf(this) >= _amount, "TM07");

    migrations[_oldToken].totalMigrated += _amount;
    migrations[_oldToken].accountsMigrated ++;
    migrations[_oldToken].accounts[msg.sender] = true;

    require(latestToken.transfer(msg.sender, _amount), "TM08");
  }

  event NewMigration(StandardToken oldToken);
}
