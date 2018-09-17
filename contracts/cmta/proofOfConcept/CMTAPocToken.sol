pragma solidity ^0.4.24;

import "../../token/IssuableToken.sol";
import "./CMTARestrictedToken.sol";


/**
 * @title CMTAPocToken
 * @dev CMTAPocToken contract
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
 * @notice Swissquote Bank SA solely is entitled to the GNU LGPL.
 * @notice Any other party is subject to the copyright mentioned in the software.
 */
contract CMTAPocToken is CMTARestrictedToken, IssuableToken {
  string public name;
  string public symbol;

  string public issuer;
  string public registeredNumber;
  string public corporateRegistryURL;
  uint256 public valuePerShareCHF; // Price in CHF cents with 2 decimmals

  uint256 public decimals = 0;

  /**
   * @dev called by the owner to construct the CMTAPocToken
   */
  constructor(string _name,
    string _symbol,
    string _issuer,
    string _registeredNumber,
    string _corporateRegistryURL,
    uint256 _valuePerShareCHF) public {
    name = _name;
    symbol = _symbol;
    issuer = _issuer;
    registeredNumber = _registeredNumber;
    corporateRegistryURL = _corporateRegistryURL;
    valuePerShareCHF = _valuePerShareCHF;
  }
}
