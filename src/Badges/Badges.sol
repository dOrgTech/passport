// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ERC1155} from "../../lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

import {Passport} from "../Passport/Passport.sol";

contract Badges is ERC1155, Ownable {
    Passport public immutable passport;
    mapping(uint256 => mapping(uint256 => address)) private passportToTokenToAddress;

    error Disabled();

    modifier updateAddress(uint256 passportId, uint256[] memory tokenIds) {
        updateOwner(passportId, tokenIds);
        _;
    }

    constructor(address passport_, string memory uri_) ERC1155(uri_) {
        passport = Passport(passport_);
    }

    function updateOwner(uint256 passportId, uint256[] memory tokenIds) public {
        for (uint256 tokenIndex = 0; tokenIndex < tokenIds.length; tokenIndex++) {
            address tokenOwner = passportToTokenToAddress[passportId][tokenIds[tokenIndex]];
            if (tokenOwner == address(0)) {
                // its the first time we see this passport for this token
                passportToTokenToAddress[passportId][tokenIds[tokenIndex]] = passport.ownerOf(passportId);
            } else if (tokenOwner != passport.ownerOf(passportId)) {
                // the passport has moved
                uint256 balance =
                    balanceOf(passportToTokenToAddress[passportId][tokenIds[tokenIndex]], tokenIds[tokenIndex]);
                _safeTransferFrom(tokenOwner, passport.ownerOf(passportId), tokenIds[tokenIndex], balance, "");

                passportToTokenToAddress[passportId][tokenIds[tokenIndex]] = passport.ownerOf(passportId);
            }
        }
    }

    function setURI(string memory newUri) public onlyOwner {
        _setURI(newUri);
    }

    function mint(uint256 passportId, uint256 tokenId, uint256 amount, bytes memory data) public onlyOwner {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        updateOwner(passportId, tokenIds);
        _mint(passport.ownerOf(passportId), tokenId, amount, data);
    }

    function mintBatch(uint256 passportId, uint256[] memory tokenIds, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
        updateAddress(passportId, tokenIds)
    {
        _mintBatch(passport.ownerOf(passportId), tokenIds, amounts, data);
    }

    function burn(uint256 passportId, uint256 tokenId, uint256 amount) public onlyOwner {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        updateOwner(passportId, tokenIds);
        _burn(passport.ownerOf(passportId), tokenId, amount);
    }

    function burnBatch(uint256 passportId, uint256[] memory tokenIds, uint256[] memory values)
        public
        onlyOwner
        updateAddress(passportId, tokenIds)
    {
        _burnBatch(passport.ownerOf(passportId), tokenIds, values);
    }

    function balanceOf(uint256 passportId, uint256 tokenId) public view returns (uint256) {
        return super.balanceOf(passport.ownerOf(passportId), tokenId);
    }

    function balanceOfBatch(uint256[] memory passportIds, uint256[] memory ids)
        public
        view
        returns (uint256[] memory)
    {
        address[] memory accounts = new address[](passportIds.length);

        for (uint256 i = 0; i < passportIds.length; ++i) {
            accounts[i] = passport.ownerOf(passportIds[i]);
        }
        return balanceOfBatch(accounts, ids);
    }

    function setApprovalForAll(address, /* operator */ bool /* approved */ ) public pure override {
        revert Disabled();
    }

    function isApprovedForAll(address, /* account */ address operator) public view override returns (bool) {
        return address(this) == operator;
    }

    function safeTransferFrom(
        address, /* from */
        address, /* to */
        uint256, /* tokenId */
        uint256, /*amount*/
        bytes memory /* data */
    ) public pure override {
        revert Disabled();
    }

    function safeBatchTransferFrom(
        address, /* from*/
        address, /* to*/
        uint256[] memory, /* ids*/
        uint256[] memory, /* amounts*/
        bytes memory /* data */
    ) public pure override {
        revert Disabled();
    }
}
