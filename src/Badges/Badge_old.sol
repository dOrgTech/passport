// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ERC721} from "../../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {Counters} from "../../lib/openzeppelin-contracts/contracts/utils/Counters.sol";
import {ERC721Enumerable} from "../../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import {Passport} from "../Passport/Passport.sol";

/**
 * It should be possible for a passport to hold multiples of one badge.
 *
 * The badges should show up in the passport owners wallet.
 *
 * It should be possible for the owner (Avatar) to mint and burn badges.
 *
 * TODO: Research implementation that reads the owner directly from the passport, where
 * the update address function only emits Transfer events.
 */
contract Badge is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    error Disabled();
    Counters.Counter private _tokenIdCounter;

    Passport public immutable passport;
    mapping(uint256 => address) private passportToAddress;
    string private baseURI;

    modifier updateAddress(uint256 passportId) {
        updateOwner(passportId);
        _;
    }

    constructor(
        address passport_,
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) ERC721(name_, symbol_) {
        passport = Passport(passport_);
        baseURI = baseURI_;
    }

    function updateOwner(uint256 passportId) public {
        if (passportToAddress[passportId] == address(0)) {
            // its the first time we see this passport
            passportToAddress[passportId] = passport.ownerOf(passportId);
            return;
        }
        if (passportToAddress[passportId] != passport.ownerOf(passportId)) {
            // the passport has moved

            uint256 balance = balanceOf(passportToAddress[passportId]);
            for (uint256 i = 0; i < balance; i++) {
                _transfer(
                    passportToAddress[passportId],
                    passport.ownerOf(passportId),
                    tokenOfOwnerByIndex(passportToAddress[passportId], i)
                );
            }

            passportToAddress[passportId] = passport.ownerOf(passportId);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function safeMint(uint256 passportId)
        public
        onlyOwner
        updateAddress(passportId)
    {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(passport.ownerOf(passportId), tokenId);
    }

    function burnFrom(uint256 passportId, uint256 tokenId)
        public
        onlyOwner
        updateAddress(passportId)
    {
        _burn(tokenId);
    }

    function balanceOf(uint256 passportId) public view returns (uint256) {
        return balanceOf(passport.ownerOf(passportId));
    }

    function isApprovedForAll(
        address, /* owner */
        address operator /* operator */
    ) public view override(ERC721, IERC721) returns (bool) {
        return operator == address(this);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        override
        returns (bool)
    {
        _requireMinted(tokenId);
        return isApprovedForAll(address(0), spender);
    }

    function transferFrom(
        address, /* from */
        address, /* to */
        uint256 /* tokenId */
    ) public pure override {
        revert Disabled();
    }

    function safeTransferFrom(
        address, /* from */
        address, /* to */
        uint256, /* tokenId */
        bytes memory /* data */
    ) public pure override {
        revert Disabled();
    }

    function approve(
        address, /* to */
        uint256 /* tokenId */
    ) public pure override {
        revert Disabled();
    }

    function setApprovalForAll(
        address, /* operator */
        bool /* approved */
    ) public pure override {
        revert Disabled();
    }

    function getApproved(uint256 tokenId)
        public
        view
        override
        returns (address)
    {
        _requireMinted(tokenId);

        return address(0);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
