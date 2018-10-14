var UserRegistry = artifacts.require('./UserRegistry.sol');
var MPSSaleConfig = artifacts.require('./tokensale/MPSSaleConfig.sol');
var MintableBridgeToken = artifacts.require('../token/MintableBridgeToken.sol');
var TokenMinter = artifacts.require('./tokensale/TokenMinter.sol');

module.exports = function (deployer, network, accounts) {
  return deployer.deploy([
    [ UserRegistry, [], 0 ],
    [ MPSSaleConfig ],
    [ MintableBridgeToken, 'Mt Pelerin Share', 'MPS' ],
  ]).then(function () {
    return deployer.deploy([
      [ TokenMinter, MPSSaleConfig.address, accounts[0], [ accounts[1], accounts[2] ] ],
    ]);
  }).then(function () {
    return MintableBridgeToken.at(
      MintableBridgeToken.address
    ).transferOwnership(TokenMinter.address);
  }).then(function () {
    return TokenMinter.at(
      TokenMinter.address
    ).setup(MintableBridgeToken.address, [ accounts[3], accounts[4] ]);
  });
};
