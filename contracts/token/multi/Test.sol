pragma solidity ^0.4.24;


/**
 * @title Test
 * @dev Test contract
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subjects to Swiss Law without reference to its conflicts of law rules.
 */
contract Test {

  struct Struct {
    uint256 basic;
  }

  struct ComplexStruct {
    mapping(bytes32 => uint256) complex;
  }

  uint256 internal basic;
  Struct internal basicStruct;

  mapping(bytes32 => uint256) internal complex;
  ComplexStruct complexStruct;

  mapping(bytes32 => Struct) internal mappingStruct;
  mapping(bytes32 => ComplexStruct) internal mappingComplexStruct;

  function setBasic(uint256 _basic) public {
    basic = _basic;
  }

  function getBasic() public view returns (uint256) {
    return basic;
  }

  function setBasicStruct(uint256 _basic) public {
    basicStruct = Struct(_basic);
  }

  function getBasicStruct() public view returns (uint256) {
    return basicStruct.basic;
  }

  function setComplex(bytes32 _key, uint256 _value) public {
    complex[_key] = _value;
  }
  
  function getComplex(bytes32 _key) public view returns (uint256) {
    return complex[_key];
  }

  function setComplexStruct(bytes32 _key, uint256 _value) public {
    complexStruct = ComplexStruct();
    complexStruct.complex[_key] = _value;
  }

  function getComplexStruct(bytes32 _key) public view returns (uint256) {
    return complexStruct.complex[_key]; 
  }

  function setMappingStruct(bytes32 _key, uint256 _value) public {
    mappingStruct[_key] = Struct(_value);
  }

  function getMappingStruct(bytes32 _key) public view returns (uint256) {
    return mappingStruct[_key].basic;
  }

  function setMappingComplexStruct(bytes32 _key, uint256 _value) public {
    mappingComplexStruct[_key] = ComplexStruct();
    mappingComplexStruct[_key].complex[_key] = _value;
  }

  function getMappingComplexStruct(bytes32 _key) public view returns (uint256) {
    return mappingComplexStruct[_key].complex[_key];
  }

}
