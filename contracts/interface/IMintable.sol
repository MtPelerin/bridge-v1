pragma solidity ^0.4.24;


/**
 * @title Mintable interface
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 */
contract IMintable {
  function mintingFinished() public view returns (bool);

  function mint(address _to, uint256 _amount) public returns (bool);
  function finishMinting() public returns (bool);
 
  event Mint(address indexed to, uint256 amount);
  event MintFinished();
}
