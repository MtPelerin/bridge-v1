var UserRegistry = artifacts.require('./UserRegistry.sol');
var MPLSaleConfig = artifacts.require('./tokensale/MPLSaleConfig.sol');
var MintableBridgeToken = artifacts.require('../token/MintableBridgeToken.sol');
var TokenMinter = artifacts.require('./tokensale/TokenMinter.sol');
var MPLTokensale = artifacts.require('./tokensale/MPLTokensale.sol');

module.exports = function (deployer, network, accounts) {
  return deployer.deploy([
    [ UserRegistry, [], 0 ],
    [ MPLSaleConfig ],
    [ MintableBridgeToken, 'Mt Pelerin', 'MPL' ],
  ]).then(function () {
    return deployer.deploy([
      [ TokenMinter, MPLSaleConfig.address, accounts[0] ],
    ]);
  }).then(function () {
    return MintableBridgeToken.at(
      MintableBridgeToken.address
    ).transferOwnership(TokenMinter.address);
  }).then(function () {
    return TokenMinter.at(
      TokenMinter.address
    ).setupToken(MintableBridgeToken.address, accounts[0], accounts[1], accounts[2]);
  }).then(function () {
    return deployer.deploy([
      [ MPLTokensale,
        accounts[9],
        MPLSaleConfig.address,
        UserRegistry.address,
      ],
    ]);
  }).then(function () {
    return TokenMinter.at(
      TokenMinter.address
    ).transferOwnership(MPLTokensale.address);
  }).then(function () {
    return MPLTokensale.at(
      MPLTokensale.address
    ).plan();
  }).then(function () {
    return MPLTokensale.at(
      MPLTokensale.address
    ).setupMinter(TokenMinter.address);
  });
};
