
/**
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * This content cannot be used, copied or reproduced in part or in whole
 * without the express and written permission of Mt Pelerin Group SA.
 * Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * All matters regarding the intellectual property of this code or software
 * are subjects to Swiss Law without reference to its conflicts of law rules.
 *
 */
const abi = require('ethjs-abi');

module.exports = {
  buildHash: async function (destination, value, data, validity) {
    const replayProtection = await this.multiSig.replayProtection();

    let encodedParams = 0;
    if (web3.toHex(data) === '0x0') {
      encodedParams = abi.encodeParams(
        [ 'address', 'uint256', 'uint256', 'bytes32' ],
        [ destination,
          web3.toHex(value),
          web3.toHex(validity),
          replayProtection,
        ]
      );
    } else {
      encodedParams = abi.encodeParams(
        [ 'address', 'uint256', 'bytes', 'uint256', 'bytes32' ],
        [ destination,
          web3.toHex(value),
          data,
          web3.toHex(validity),
          replayProtection,
        ]
      );
    }
    const hash = web3.sha3(encodedParams, { encoding: 'hex' });
    return hash;
  },
  sign: async function (destination, value, data, validity, address) {
    const hash = await this.buildHash(destination, value, data, validity);
    const signedHash = web3.eth.sign(address, hash);

    return {
      r: '0x' + signedHash.slice(2).slice(0, 64),
      s: '0x' + signedHash.slice(2).slice(64, 128),
      v: web3.toDecimal(signedHash.slice(2).slice(128, 130)),
    };
  },
};
