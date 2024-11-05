+ forge create src/Permit2/TokenBankPermit2.sol:TokenBank  --account 8888  --rpc-url sepolia --constructor-args 0x000000000022D473030F116dDEE9F6B43aC78BA3

+ forge verify-contract --chain sepolia --constructor-args $(cast abi-encode "constructor(address _permit2)" 0x000000000022D473030F116dDEE9F6B43aC78BA3) 0xF08212D4EAe91985fDADb69077B4A5f24086513D src/Permit2/TokenBankPermit2.sol:TokenBank

deploy contract to anvil
+ forge create ./src/Demo/esRNT.d.sol:esRNT --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80