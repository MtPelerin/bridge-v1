pragma solidity ^0.4.24;

import "./interface/ILegalDocuments.sol";
import "./zeppelin/ownership/Ownable.sol";


/**
 * @title LegalDocuments
 * @dev LegalDocuments contract
 * This contract track the legal documents associated with some addresses.
 * It is done through a versioning of the document hash
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * Error messages
 * //E01: address Id does not exist
*/
contract LegalDocuments is ILegalDocuments, Ownable {

  string public repositoryURL;

  struct Document {
    string name;
    bytes32 hash;
    uint32 version;
    bool valid;
  }

  mapping(address => uint32) documentsCounts;
  mapping(address => mapping(uint32 => Document)) documents;

  constructor(string _repositoryURL) public {
    repositoryURL = _repositoryURL;
  }

  /**
   * @dev returns the document repository URL
   */
  function repositoryURL() public view returns (string) {
    return repositoryURL;
  }

  /**
   * @dev returns the count of documents for an address
   */
  function documentsCount(address _address)
    public view returns (uint32)
  {
    return documentsCounts[_address];
  }

  /**
   * @dev returns the document name
   */
  function documentName(address _address, uint32 _id)
    public view returns (string)
  {
    return documents[_address][_id].name;
  }

  /**
   * @dev returns the document hash
   */
  function documentHash(address _address, uint32 _id)
    public view returns (bytes32)
  {
    return documents[_address][_id].hash;
  }

  /**
   * @dev returns the document version
   */
  function documentVersion(address _address, uint32 _id)
    public view returns (uint32)
  {
    return documents[_address][_id].version;
  }

  /**
   * @dev returns if the document is valid
   */
  function documentIsValid(address _address, uint32 _id)
    public view returns (bool)
  {
    return documents[_address][_id].valid;
  }

  /**
   * @dev update repository URL
   */
  function updateRepositoryURL(string _repositoryURL)
    public onlyOwner returns (bool)
  {
    repositoryURL = _repositoryURL;
    return true;
  }

  /**
   * @dev add the document with name and hash to an address
   */
  function addDocument(
    address _address,
    string _name,
    bytes32 _hash) public onlyOwner returns (bool)
  {
    require(_address != address(0));
    require(bytes(_name).length != 0);
    require(_hash != 0);
   
    uint32 id = documentsCounts[_address];
    Document memory document = Document(
      _name,
      _hash,
      0,
      true
    );
    documents[_address][id] = document;
    documentsCounts[_address] = id+1;

    emit DocumentAdded(
      _address,
      id,
      _name,
      _hash
    );
    return true;
  }

  /**
   * @dev update an existing document name and hash
   */
  function updateDocument(
    address _address,
    uint32 _id,
    string _name,
    bytes32 _hash) public onlyOwner returns (bool)
  {
    Document storage document = documents[_address][_id];
    require(document.hash != 0);

    document.name = _name;
    document.hash = _hash;
    document.version++;
    document.valid = true;

    emit DocumentUpdated(
      _address,
      _id,
      _name,
      _hash,
      document.version
    );
    return true;
  }

  /**
   * @dev invalid a document from a address
   */
  function invalidateDocument(
    address _address,
    uint32 _id) public onlyOwner returns (bool)
  {
    Document storage document = documents[_address][_id];
    require(document.hash != 0);

    document.valid = false;
    emit DocumentInvalidated(_address, _id);
    return true;
  }
}
