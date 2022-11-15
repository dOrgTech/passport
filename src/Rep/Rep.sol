// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Snapshot} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import {AccessControl} from "../../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import {ERC20Permit} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import {ERC20Votes} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract Rep is
    ERC20,
    ERC20Burnable,
    ERC20Snapshot,
    AccessControl,
    ERC20Permit,
    ERC20Votes
{
    error Disabled();

    bytes32 public constant SNAPSHOT_ROLE = keccak256("SNAPSHOT_ROLE");
    bytes32 public constant MINTER_BURNER_ROLE =
        keccak256("MINTER_BURNER_ROLE");

    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
        ERC20Permit(name_)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SNAPSHOT_ROLE, msg.sender);
        _grantRole(MINTER_BURNER_ROLE, msg.sender);
    }

    function snapshot() public onlyRole(SNAPSHOT_ROLE) {
        _snapshot();
    }

    function mint(address to, uint256 amount)
        public
        onlyRole(MINTER_BURNER_ROLE)
    {
        _mint(to, amount);
    }

    function transfer(
        address, /* to */
        uint256 /* amount */
    ) public pure override returns (bool) {
        revert Disabled();
    }

    function transferFrom(
        address, /* from */
        address, /* to */
        uint256 /* amount */
    ) public virtual override returns (bool) {
        revert Disabled();
    }

    function increaseAllowance(
        address, /* spender */
        uint256 /* addedValue */
    ) public pure override returns (bool) {
        revert Disabled();
    }

    function decreaseAllowance(
        address, /* spender */
        uint256 /* subtractedValue */
    ) public pure override returns (bool) {
        revert Disabled();
    }

    function allowance(
        address, /* owner */
        address /* spender */
    ) public pure override returns (uint256) {
        return 0;
    }

    function approve(
        address, /* spender */
        uint256 /* amount */
    ) public pure override returns (bool) {
        revert Disabled();
    }

    function burnFrom(address account, uint256 amount)
        public
        override
        onlyRole(MINTER_BURNER_ROLE)
    {
        _burn(account, amount);
    }

    function burn(
        uint256 /* amount */
    ) public pure override {
        revert Disabled();
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Snapshot) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
        onlyRole(MINTER_BURNER_ROLE)
    {
        super._burn(account, amount);
    }
}
