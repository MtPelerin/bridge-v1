pragma solidity ^0.4.24;


/**
 * @title IRates
 * @dev IRates interface
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 **/
contract IRates {
  function updateManyRates(
    uint256[] _tokenIds,
    uint256[] _rates,
    uint256[] _invertedRates) external;

  function referenceToken() public view returns (address);
  function ratePrecision() public view returns (uint256);
  function tokens() public view returns (address[]);
  
  function rate(address _token) public view returns (uint256);
  function invertedRate(address _token) public view returns (uint256);
  function updatedAt(address _token) public view returns (uint256);

  function updateRate(uint256 _tokenId, uint256 _rate, uint256 _invertedRate)
    public;

  function addToken(address _token, uint256 _rate, uint256 _invertedRate)
    public;

  function addManyTokens(
    address[] _tokens,
    uint256[] _rates,
    uint256[] _invertedRates) public;

  function removeToken(uint256 _tokenId) public;
  function removeManyTokens(uint256[] _tokenIds) public;
 
  function updateReferenceToken(address _referenceToken) public;
  function updateRatePrecision(uint256 _ratePrecision) public;
}
