// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ERC1155} from "../../lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ERC1155Burnable} from "../../lib/openzeppelin-contracts/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

import {Passport} from "../Passport/Passport.sol";

contract Badges is ERC1155, Ownable, ERC1155Burnable {
    Passport public immutable passport;
    mapping(uint256 => mapping(uint256 => address))
        private passportToTokenToAddress;
    string private baseURI;

    error Disabled();

    modifier updateAddress(uint256 passportId, uint256[] memory tokenIds) {
        updateOwner(passportId, tokenIds);
        _;
    }

    constructor(address passport_, string memory uri_) ERC1155(uri_) {
        passport = passport_;
    }

    function updateOwner(uint256 passportId, uint256[] tokenIds) public {
        for (uint tokenIndex = 0; i < tokenIds.length; i++) {
            address storage tokenOwner = passportToTokenToAddress[passportId][
                tokenIds[tokenIndex]
            ];
            if (tokenOwner == address(0)) {
                // its the first time we see this passport for this token
                tokenOwner = passport.ownerOf(passportId);
                return;
            }
            if (tokenOwner != passport.ownerOf(passportId)) {
                // the passport has moved
                uint256 balance = balanceOf(
                    passportToTokenToAddress[passportId],
                    tokenIds[tokenIndex]
                );
                _safeTransferFrom(
                    tokenOwner,
                    passport.ownerOf(passportId),
                    tokenIds[tokenIndex],
                    balance,
                    ""
                );

                tokenOwner = passport.ownerOf(passportId);
            }
        }
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(
        uint256 passportId,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public onlyOwner updateAddress(passportId, [tokenId]) {
        _mint(passport.ownerOf(passportId), tokenId, amount, data);
    }

    function mintBatch(
        uint256 passportId,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyOwner updateAddress(passportId, tokenIds) {
        _mintBatch(passport.ownerOf(passportId), tokenIds, amounts, data);
    }

    // function _beforeTokenTransfer(
    //     address /* operator */,
    //     address /* from */,
    //     address /* to */,
    //     uint256[] memory /* ids */,
    //     uint256[] memory /* amounts */,
    //     bytes memory /* data */
    // ) internal override onlyOwner {}

    // NEW:

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function burn(
        uint256 passportId,
        uint256 tokenId,
        uint256 value
    ) public override onlyOwner updateAddress(passportId, [tokenId]) {
        _burn(passport.ownerOf(passportId), tokenId, value);
    }

    function burnBatch(
        uint256 passportId,
        uint256[] memory tokenIds,
        uint256[] memory values
    ) public override onlyOwner updateAddress(passportId, tokenIds) {
        _burnBatch(passport.ownerOf(passportId), tokenIds, values);
    }

    function balanceOf(
        uint256 passportId,
        uint256 tokenId
    ) public view returns (uint256) {
        return balanceOf(passport.ownerOf(passportId), tokenId);
    }

    function balanceOfBatch(
        uint256[] passportIds,
        uint256[] memory ids
    ) public view override returns (uint256[] memory) {
        uint256[] memory accounts = new uint256[](passportIds.length);

        for (uint256 i = 0; i < passportIds.length; ++i) {
            tokenIds[i] = passport.ownerOf(passportIds[i]);
        }
        return balanceOfBatch(accounts, ids);
    }

    function setApprovalForAll(
        address /* operator */,
        bool /* approved */
    ) public virtual override {
        revert Disabled();
    }

    function isApprovedForAll(
        address account,
        address operator
    ) public view virtual override returns (bool) {
        return address(this) == operator;
    }

    function safeTransferFrom(
        address /* from */,
        address /* to */,
        uint256 /* tokenId */,
        bytes memory /* data */
    ) public pure override {
        revert Disabled();
    }

    function safeBatchTransferFrom(
        address /* from*/,
        address /* to*/,
        uint256[] memory /* ids*/,
        uint256[] memory /* amounts*/,
        bytes memory data
    ) public override {
        revert Disabled();
    }
}
