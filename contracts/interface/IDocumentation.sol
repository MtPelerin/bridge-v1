pragma solidity ^0.4.24;


/**
 * @title Documentation interface
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * This content cannot be used, copied or reproduced in part or in whole
 * without the express and written permission of Mt Pelerin Group SA.
 * Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * All matters regarding the intellectual property of this code or software
 * are subjects to Swiss Law without reference to its conflicts of law rules.
*/
contract IDocumentation {

  function repositoryURL() public view returns (string);

  function documentsCount(address _address)
    public view returns (uint32);

  function documentName(address _address, uint32 _id)
    public view returns (string);

  function documentHash(address _address, uint32 _id)
    public view returns (bytes32);

  function documentVersion(address _address, uint32 _id)
    public view returns (uint32);

  function documentLastUpdate(address _address, uint32 _id)
    public view returns (uint256);

  function documentIsValid(address _address, uint32 _id)
    public view returns (bool);

  function updateRepositoryURL(string _repositoryURL)
    public returns (bool);

  function addDocument(
    address _address, string _name, bytes32 _hash)
    public returns (bool);

  function updateDocument(
    address _address, uint32 _id, string _name, bytes32 _hash)
    public returns(bool);

  function invalidateDocument(
    address _address, uint32 _id) public returns (bool);

  event DocumentAdded(address _address, uint32 id, string name, bytes32 hash);
  event DocumentUpdated(
    address _address, uint32 id, string name, bytes32 hash, uint32 version
  );
  event DocumentInvalidated(address _address, uint32 id);
}
