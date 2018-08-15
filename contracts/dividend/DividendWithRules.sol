pragma solidity ^0.4.24;

import "../zeppelin/ownership/Ownable.sol";
import "../zeppelin/token/ERC20/ERC20.sol";
import "../zeppelin/math/SafeMath.sol";
import "../token/ProvableOwnershipToken.sol";
import "../dividend/Dividend.sol";
import "../rule/WithRules.sol";


/**
 * @title DividendWithRules
 * @dev DividendWithRules contract
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 */
contract DividendWithRules is Dividend, WithRules {

  /**
   * @dev constructor
   */
  constructor(ProvableOwnershipToken _token, IRule[] _rules) public
    Dividend(_token) WithRules(_rules)
  { }

  /**
   * @dev claim the next dividend without a proof of ownership
   */
  function claimDividend(uint256 _dividendId) public
    whenAddressRulesAreValid(msg.sender)
  {
    super.claimDividend(_dividendId);
  }

  /**
   * @dev claim the next dividend with a proof of ownership
   */
  function claimDividendWithProof(uint256 _dividendId, uint256 _proofId) public
    whenAddressRulesAreValid(msg.sender)
  {
    super.claimDividendWithProof(_dividendId, _proofId);
  }
}
