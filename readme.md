_Warning: this is WIP. Do not use._

## Passport

[![Passport overview](https://cdn.loom.com/sessions/thumbnails/1fdc5c939543498b969f9fafc9e0f530-with-play.gif)](https://www.loom.com/share/1fdc5c939543498b969f9fafc9e0f530 "Passport overview")

A Passport NFT (ERC-721) is meant to represent membership in a DAO.
This Passport can only be minted or transferred by the DAO.

The DAO can also issue a non-transferable token called Rep (ERC-20), a token that can be used for voting, etc.

The DAO can also issue non-transferable Badges. The badges can be fungible, non-fungible, or semi-fungible tokens (ERC-1155).

If the Passport owner changes, all Badge tokens, and the Rep token will "follow" the Passport owner. To make the Badges and the Rep visible in the Passport holder's wallet. Anybody can manually trigger the move of the Rep and Badges to the new Passport owner, or it will happen automatically the next time any of the tokens are burned or new tokens are minted.

### Deployment Examples

Passport:

```
forge create src/Passport/Passport.sol:Passport --constructor-args 0xOwner "dOrg Passport v1" "dPass" "https://www.dorg.tech/passport/" --private-key "xxx" --rpc-url "https://rpc.ankr.com/eth_goerli" --verify --etherscan-api-key "xxx"
```

Rep:

```
forge create src/Rep/Rep.sol:Rep --constructor-args 0xOwner 0xPassport "dOrg Rep v1" "dRep" --private-key "xxx" --rpc-url "https://rpc.ankr.com/eth_goerli" --verify --etherscan-api-key "xxx"
```

Badges:

```
forge create src/Badges/Badges.sol:Badges --constructor-args 0xOwner 0xPassport "https://www.dorg.tech/badges/" --private-key "xxx" --rpc-url "https://rpc.ankr.com/eth_goerli" --verify --etherscan-api-key "xxx"
```
