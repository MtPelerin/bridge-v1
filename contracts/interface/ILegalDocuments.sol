pragma solidity ^0.4.24;


/**
 * @title LegalDocuments interface
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
*/
contract ILegalDocuments {
  
  function repositoryURL() public view returns (string);

  function documentsCount(address _address)
    public view returns (uint32);

  function documentName(address _address, uint32 _id)
    public view returns (string);

  function documentHash(address _address, uint32 _id)
    public view returns (bytes32);

  function documentVersion(address _address, uint32 _id)
    public view returns (uint32);

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
