
# Bridge Multi Token

### Variant 1:

-> BridgeToken (ERC20 Contract)
|-> BridgeTokenCore (Contract / Storage)
 |-> BridgeEngine (Lib)
  |-> RuleEngine (ERC1592 Lib)
  |-> ProcessorEngine (Lib)
   |-> Processors (Contract)

Storage is part of the token core.
It is injected into the BridgeEngine.


### Variant 2:

-> BridgeToken (ERC20 Contract)
|-> BridgeEngine (Contract)
 |-> RuleEngine (ERC1592 Lib)
 |-> ProcessorEngine (Lib)
  |-> Processors (Contract)
|-> BridgeStorage (Contract / Storage)

Storage has its specific class.
It is then injected into the BridgeEngine.


### Asset class configuration

1. Issuable vs Mintable
2. Rules default setup
3. Processor default setup

Asset creation is done ideally in one Tx. 
It should be auto configured based on its asset class.


### Asset Registry

Should it be an external contract ?

