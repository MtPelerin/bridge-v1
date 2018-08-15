pragma solidity ^0.4.24;

import "../zeppelin/token/ERC20/StandardToken.sol";
import "../zeppelin/ownership/Ownable.sol";
import "../interface/IMintable.sol";


/**
 * @title MintableToken
 * @dev MintableToken contract
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * Error messages
 * E01: Token is already minted
*/
contract MintableToken is StandardToken, Ownable, IMintable {

  bool public mintingFinished = false;

  function mintingFinished() public view returns (bool) {
    return mintingFinished;
  }

  modifier canMint() {
    require(!mintingFinished, "E01");
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address _to,
    uint256 _amount
  ) public canMint onlyOwner returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() public canMint onlyOwner returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }

  event Mint(address indexed to, uint256 amount);
  event MintFinished();
}
