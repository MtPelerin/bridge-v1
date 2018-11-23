pragma solidity ^0.4.24;


import "../../zeppelin/math/SafeMath.sol";


/**
 * @title TokenCore
 * @dev TokenCore contract
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subjects to Swiss Law without reference to its conflicts of law rules.
 */
contract TokenCore {
  using SafeMath for uint256;

  struct Token {
    address address_;
    mapping(address => uint256) balances;
    uint256 totalSupply_;
    mapping (address => mapping (address => uint256)) allowed;
  }

  mapping(address => Token) internal tokens;

  /**
   * @dev token address
   */
  function tokenAddress() public view returns (address) {
    return tokens[msg.sender].address_;
  }

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return tokens[msg.sender].totalSupply_;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return tokens[msg.sender].balances[_owner];
  }

  /**
  * @dev setup a token
  **/
  function setupToken(address _token) public {
    Token storage token = tokens[_token];
    require(token.address_ == address(0));
    token.address_ = _token;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _spender,
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    Token storage token = tokens[msg.sender];

    require(_to != address(0));
    require(_value <= token.balances[_from]);
    require(_value <= token.allowed[_from][_spender]);

    token.balances[_from] = token.balances[_from].sub(_value);
    token.balances[_to] = token.balances[_to].add(_value);
    token.allowed[_from][_spender] = token.allowed[_from][_spender].sub(_value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _owner, address _spender, uint256 _value) public returns (bool) {
    Token storage token = tokens[msg.sender];

    token.allowed[_owner][_spender] = _value;
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return tokens[msg.sender].allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _owner,
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    Token storage token = tokens[msg.sender];

    token.allowed[_owner][_spender] = (
      token.allowed[_owner][_spender].add(_addedValue));
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _owner,
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    Token storage token = tokens[msg.sender];

    uint256 oldValue = token.allowed[_owner][_spender];
    if (_subtractedValue > oldValue) {
      token.allowed[_owner][_spender] = 0;
    } else {
      token.allowed[_owner][_spender] = oldValue.sub(_subtractedValue);
    }
    return true;
  }
}
