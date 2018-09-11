pragma solidity ^0.4.24;

import "./zeppelin/ownership/Ownable.sol";
import "./interface/IRates.sol";


/**
 * @title Rates
 * @dev Rates contract
 *
 * Stores the rates between a reference token and other tokens
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
 * E01: Address of the reference token must be defined
 * E02: Cannot update more rates than tokens
 * E03: Cannot update more inverted rates than tokens
 * E04: Token Id does not exists
 * E05: Token address is not defined
 * E06: Cannot add more rates than tokens
 * E07: Cannot add more inverted rates than tokens
*/
contract Rates is IRates, Ownable {

  address public referenceToken;
  uint256 public ratePrecision = 2;

  struct Rate {
    uint256 rate;
    uint256 invertedRate;
    uint256 updatedAt;
  }
  mapping(address => Rate) internal rates;
  address[] public tokens;

  /**
   * @dev Constructor
   */
  constructor(
    address _referenceToken,
    address[] _tokens,
    uint256[] _rates,
    uint256[] _invertedRates) public
  {
    require(_referenceToken != address(0), "E01");
    referenceToken = _referenceToken;
    addManyTokens(_tokens, _rates, _invertedRates);
  }

  /**
   * @dev Update many rates
   */
  function updateManyRates(
    uint256[] _tokenIds,
    uint256[] _rates,
    uint256[] _invertedRates) external onlyOwner
  {
    require(_tokenIds.length == _rates.length, "E02");
    require(_tokenIds.length == _invertedRates.length, "E03");

    for (uint256 i = 0; i < _tokenIds.length ; i++) {
      updateRate(_tokenIds[i], _rates[i], _invertedRates[i]);
    }
  }

  /**
   * @dev Return the reference token used to define the token rate against
   */
  function referenceToken() public view returns (address) {
    return referenceToken;
  }

  /**
   * @dev Return the number of digits after the decimal point for rate and invertedRate values
   */
  function ratePrecision() public view returns (uint256) {
    return ratePrecision;
  }

  /**
   * @dev Return the list of tokens inside the contract
   */
  function tokens() public view returns (address[]) {
    return tokens;
  }

  /**
   * @dev Return the rate for a token respectfully to the reference token
   */
  function rate(address _token) public view returns (uint256) {
    return rates[_token].rate;
  }

  /**
   * @dev Return the inverted rate for a token respectfully to the reference token
   */
  function invertedRate(address _token) public view returns (uint256) {
    return rates[_token].invertedRate;
  }

  /**
   * @dev Return the last time the rate was updated for a token
   */
  function updatedAt(address _token) public view returns (uint256) {
    return rates[_token].updatedAt;
  }

  /**
   * @dev Update a rate
   */
  function updateRate(uint256 _tokenId, uint256 _rate, uint256 _invertedRate)
    public onlyOwner
  {
    require(_tokenId < tokens.length, "E04");
    address token = tokens[_tokenId];
    require(token != address(0), "E05");

    rates[token].rate = _rate;
    rates[token].invertedRate = _invertedRate;
    // solium-disable-next-line security/no-block-members
    rates[token].updatedAt = now;
  }

  /**
   * @dev Add a token
   */
  function addToken(address _token, uint256 _rate, uint256 _invertedRate)
    public onlyOwner
  {
    require(_token != address(0), "E05");
    // solium-disable-next-line security/no-block-members
    rates[_token] = Rate(_rate, _invertedRate, now);
    tokens.push(_token);
  }

  /**
   * @dev Add many tokens
   */
  function addManyTokens(
    address[] _tokens,
    uint256[] _rates,
    uint256[] _invertedRates) public onlyOwner
  {
    require(_tokens.length == _rates.length, "E06");
    require(_tokens.length == _invertedRates.length, "E07");

    for (uint256 i = 0; i < _tokens.length ; i++) {
      addToken(_tokens[i], _rates[i], _invertedRates[i]);
    }
  }

  /**
   * @dev Remove a token
   */
  function removeToken(uint256 _tokenId) public onlyOwner {
    require(_tokenId < tokens.length, "E04");
    require(tokens[_tokenId] != address(0), "E05");
    delete rates[tokens[_tokenId]];
    delete tokens[_tokenId];

    if (_tokenId < tokens.length-1) {
      tokens[_tokenId] = tokens[tokens.length-1];
    }
    tokens.length--;
  }

  /**
   * @dev Remove many tokens
   */
  function removeManyTokens(uint256[] _tokenIds) public onlyOwner {
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      removeToken(_tokenIds[i]);
    }
  }

  /**
   * @dev Update the reference token
   */
  function updateReferenceToken(address _referenceToken) public onlyOwner {
    require(_referenceToken != address(0), "E01");
    referenceToken = _referenceToken;
  }

  /**
   * @dev Update the precision of rate values
   */
  function updateRatePrecision(uint256 _ratePrecision) public onlyOwner {
    ratePrecision = _ratePrecision;
  }
}
