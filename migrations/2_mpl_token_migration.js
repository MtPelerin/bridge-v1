var UserRegistry = artifacts.require('./UserRegistry.sol');
var MPSSaleConfig = artifacts.require('./mps/MPSSaleConfig.sol');
var MPSBridgeToken = artifacts.require('../mps/MPSBridgeToken.sol');
var TokenMinter = artifacts.require('./tokensale/TokenMinter.sol');

module.exports = function (deployer, network, accounts) {
  return deployer.deploy([
    [ UserRegistry, [], 0 ],
    [ MPSSaleConfig ],
    [ MPSBridgeToken ],
  ]).then(function () {
    return deployer.deploy([
      [ TokenMinter, MPSSaleConfig.address, accounts[0], [ accounts[1], accounts[2] ] ],
    ]);
  }).then(function () {
    return MPSBridgeToken.at(
      MPSBridgeToken.address
    ).transferOwnership(TokenMinter.address);
  }).then(function () {
    return TokenMinter.at(
      TokenMinter.address
    ).setup(MPSBridgeToken.address, [ accounts[3], accounts[4] ]);
  });
};
