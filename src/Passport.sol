// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC721OnlyOwnerTransferable} from "./ERC721OnlyOwnerTransferable.sol";
import {Counters} from "../lib/openzeppelin-contracts/contracts/utils/Counters.sol";

contract Passport is ERC721OnlyOwnerTransferable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721OnlyOwnerTransferable("Passport", "PASS", "") {}

    // OnlyOwner functions
    function safeMint(address to, string memory uri) public {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function updateBaseURI(string memory newBaseURI) public onlyOwner {
        _baseURI = newBaseURI;
    }

    function updateName(string memory newName) public onlyOwner {
        _name = newName;
    }

    function updateSymbol(string memory newSymbol) public onlyOwner {
        _symbol = newSymbol;
    }
}
