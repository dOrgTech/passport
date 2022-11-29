// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../lib/forge-std/src/Test.sol";
import {Strings} from "../../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import {Badge} from "./Badge.sol";
import {Passport} from "../Passport/Passport.sol";

contract BadgeTest is Test {
    Badge public badge;
    address public owner = address(0x1);

    Passport public passport;
    address public passport_transferer = address(0x6);

    address public alice = address(0x4);
    address public bob = address(0x5);

    uint256 alicePassportId = 0;
    uint256 bobPassportID = 1;

    function setUp() public {
        passport = new Passport("Passport", "PASS", "");
        passport.grantRole(passport.TRANSFERER_ROLE(), passport_transferer);

        badge = new Badge(address(passport), "Badge1", "B1", "http/");

        badge.transferOwnership(owner);

        // by default the passport deployer gets the minter role
        passport.safeMint(alice); // gets a passport id 0
        passport.safeMint(bob); // gets a passport id 1
    }

    function testSetupParameters() public {
        assertEq(badge.name(), "Badge1");
        assertEq(badge.symbol(), "B1");
    }

    function testOnlyOwnerCanSafeMint() public {
        // cant mint with msg.sender
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        badge.safeMint(msg.sender);
        assertEq(badge.balanceOf(msg.sender), 0);

        // owner can mint
        vm.prank(owner);
        badge.safeMint(msg.sender);
        assertEq(badge.balanceOf(msg.sender), 1);
    }

    function testOnlyOwnerCanBurn() public {
        vm.prank(owner);
        badge.safeMint(alicePassportId);
        uint256 newBadgeId = badge.totalSupply() - 1;

        // the alice can't burn
        vm.expectRevert();
        badge.burnFrom(alicePassportId, newBadgeId);
        assertEq(badge.balanceOf(alice), 1);

        // the owner can burn
        vm.prank(owner);
        badge.burnFrom(alicePassportId, newBadgeId);
        assertEq(badge.balanceOf(alice), 0);
    }

    function testNobodyCanTransferer() public {
        // mint a badge to alice
        vm.prank(owner);
        badge.safeMint(alice);

        // the owner (msg.sender) can't transfer
        vm.expectRevert(Badge.Disabled.selector);
        vm.prank(alice);
        badge.transferFrom(alice, bob, 0);
        assertEq(badge.balanceOf(alice), 1);
        assertEq(badge.balanceOf(bob), 0);

        vm.expectRevert(Badge.Disabled.selector);
        vm.prank(alice);
        badge.safeTransferFrom(alice, bob, 0);
        assertEq(badge.balanceOf(alice), 1);
        assertEq(badge.balanceOf(bob), 0);

        // non of the other roles can transfer
        vm.prank(owner);
        vm.expectRevert(Badge.Disabled.selector);
        badge.transferFrom(alice, bob, 1);
    }

    function testSetApprove() public {
        // mint a Passport to the msg.sender
        vm.prank(owner);
        badge.safeMint(alice);

        // can not approve
        vm.expectRevert(Badge.Disabled.selector);
        vm.prank(alice);
        badge.approve(bob, 0);
        assertEq(badge.getApproved(0), address(0));
    }

    function testSetApprovalForAll() public {
        // mint a Passport to alice
        vm.prank(owner);
        badge.safeMint(alice);

        // can not approve
        vm.expectRevert(Badge.Disabled.selector);
        vm.prank(alice);
        badge.setApprovalForAll(bob, true);
        assertEq(badge.getApproved(0), address(0));
    }

    function testGetApproved() public {
        // mint a Passport to the msg.sender
        vm.prank(owner);
        badge.safeMint(msg.sender);

        // should get "empty" approval for minted token
        assertEq(badge.getApproved(0), address(0));

        // should revert for non-excising token
        vm.expectRevert(bytes("ERC721: invalid token ID"));
        badge.getApproved(1);
    }

    function testGetApprovedForAll() public {
        // should get false for all addresses, except for the transferer
        assertEq(badge.isApprovedForAll(msg.sender, alice), false);
        assertEq(badge.isApprovedForAll(msg.sender, address(this)), false);
        assertEq(badge.isApprovedForAll(msg.sender, address(badge)), true);
    }
}
