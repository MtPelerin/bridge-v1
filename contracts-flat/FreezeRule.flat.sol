pragma solidity ^0.4.24;

// File: contracts/zeppelin/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: contracts/Authority.sol

/**
 * @title Authority
 * @dev The Authority contract has an authority address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 * Authority means to represent a legal entity that is entitled to specific rights
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subject to Swiss Law without reference to its conflicts of law rules.
 *
 * Error messages
 * AU01: Message sender must be an authority
 */
contract Authority is Ownable {

  address authority;

  /**
   * @dev Throws if called by any account other than the authority.
   */
  modifier onlyAuthority {
    require(msg.sender == authority, "AU01");
    _;
  }

  /**
   * @dev return the address associated to the authority
   */
  function authorityAddress() public view returns (address) {
    return authority;
  }

  /**
   * @dev rdefines an authority
   * @param _name the authority name
   * @param _address the authority address.
   */
  function defineAuthority(string _name, address _address) public onlyOwner {
    emit AuthorityDefined(_name, _address);
    authority = _address;
  }

  event AuthorityDefined(
    string name,
    address _address
  );
}

// File: contracts/interface/IRule.sol

/**
 * @title IRule
 * @dev IRule interface
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subject to Swiss Law without reference to its conflicts of law rules.
 **/
interface IRule {
  function isAddressValid(address _address) external view returns (bool);
  function isTransferValid(address _from, address _to, uint256 _amount)
    external view returns (bool);
}

// File: contracts/rule/FreezeRule.sol

/**
 * @title FreezeRule
 * @dev FreezeRule contract
 * This rule allow a legal authority to enforce a freeze of assets.
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subject to Swiss Law without reference to its conflicts of law rules.
 *
 * Error messages
 * E01: The address is frozen
 */
contract FreezeRule is IRule, Authority {

  mapping(address => uint256) freezer;
  uint256 allFreezedUntil;

  /**
   * @dev is rule frozen
   */
  function isFrozen() public view returns (bool) {
    // solium-disable-next-line security/no-block-members
    return allFreezedUntil > now ;
  }

  /**
   * @dev is address frozen
   */
  function isAddressFrozen(address _address) public view returns (bool) {
    // solium-disable-next-line security/no-block-members
    return freezer[_address] > now;
  }

  /**
   * @dev allow authority to freeze the address
   * @param _until allows to auto unlock if the frozen time is known initially.
   * otherwise infinity can be used
   */
  function freezeAddress(address _address, uint256 _until)
    public onlyAuthority returns (bool)
  {
    freezer[_address] = _until;
    emit Freeze(_address, _until);
  }

  /**
   * @dev allow authority to freeze several addresses
   * @param _until allows to auto unlock if the frozen time is known initially.
   * otherwise infinity can be used
   */
  function freezeManyAddresses(address[] _addresses, uint256 _until)
    public onlyAuthority returns (bool)
  {
    for (uint256 i = 0; i < _addresses.length; i++) {
      freezer[_addresses[i]] = _until;
      emit Freeze(_addresses[i], _until);
    }
  }

  /**
   * @dev freeze all until
   */
  function freezeAll(uint256 _until) public
    onlyAuthority returns (bool)
  {
    allFreezedUntil = _until;
    emit FreezeAll(_until);
  }

  /**
   * @dev validates an address
   */
  function isAddressValid(address _address) public view returns (bool) {
    return !isFrozen() && !isAddressFrozen(_address);
  }

   /**
   * @dev validates a transfer 
   */
  function isTransferValid(address _from, address _to, uint256 /* _amount */)
    public view returns (bool)
  {
    return !isFrozen() && (!isAddressFrozen(_from) && !isAddressFrozen(_to));
  }

  event FreezeAll(uint256 until);
  event Freeze(address _address, uint256 until);
}
