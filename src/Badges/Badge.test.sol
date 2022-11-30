// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../lib/forge-std/src/Test.sol";
import {Strings} from "../../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import {Badges} from "./Badges.sol";
import {Passport} from "../Passport/Passport.sol";

contract BadgeTest is Test {
    Badges public badges;
    address public owner = address(0x1);

    Passport public passport;
    address public passport_transferer = address(0x6);

    address public alice = address(0x4);
    address public bob = address(0x5);

    uint256 alicePassportId = 0;
    uint256 bobPassportID = 1;

    uint256 badgeOne = 0;

    function setUp() public {
        passport = new Passport("Passport", "PASS", "");
        passport.grantRole(passport.TRANSFERER_ROLE(), passport_transferer);

        badges = new Badges(address(passport), "http/{id}");

        badges.transferOwnership(owner);

        // by default the passport deployer gets the minter role
        passport.safeMint(alice); // gets a passport id 0
        passport.safeMint(bob); // gets a passport id 1

        vm.prank(owner);
        badges.mint(alicePassportId, badgeOne, 1, "");
    }

    function testSetupParameters() public {
        assertEq(badges.uri(badgeOne), "http/{id}");
    }

    function testOnlyOwnerCanMint() public {
        // cant mint with msg.sender
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        badges.mint(alicePassportId, badgeOne, 3, "");
        assertEq(badges.balanceOf(alice, badgeOne), 1);
        assertEq(badges.balanceOf(alicePassportId, badgeOne), 1);

        // owner can mint
        vm.prank(owner);
        badges.mint(alicePassportId, badgeOne, 3, "");
        assertEq(badges.balanceOf(alice, badgeOne), 4);
        assertEq(badges.balanceOf(alicePassportId, badgeOne), 4);

        vm.prank(owner);
        badges.mint(alicePassportId, badgeOne, 3, "");
        assertEq(badges.balanceOf(alice, badgeOne), 7);
        assertEq(badges.balanceOf(alicePassportId, badgeOne), 7);

        uint256 newTokeId = 50;
        assertEq(badges.balanceOf(alice, newTokeId), 0);
        vm.prank(owner);
        badges.mint(alicePassportId, newTokeId, 2, "");
        assertEq(badges.balanceOf(alice, newTokeId), 2);
        assertEq(badges.balanceOf(alicePassportId, newTokeId), 2);
    }

    function testOnlyOwnerCanBurn() public {
        // the alice can't burn
        vm.expectRevert();
        badges.burn(alicePassportId, badgeOne, 1);
        assertEq(badges.balanceOf(alice, badgeOne), 1);
        assertEq(badges.balanceOf(alicePassportId, badgeOne), 1);

        // the owner can burn
        vm.prank(owner);
        badges.burn(alicePassportId, badgeOne, 1);
        assertEq(badges.balanceOf(alice, badgeOne), 0);
        assertEq(badges.balanceOf(alicePassportId, badgeOne), 0);

        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        badges.burn(alicePassportId, badgeOne, 10);
        assertEq(badges.balanceOf(alice, badgeOne), 0);

        vm.prank(owner);
        vm.expectRevert(bytes("ERC1155: burn amount exceeds balance"));
        badges.burn(alicePassportId, badgeOne, 10);
        assertEq(badges.balanceOf(alice, badgeOne), 0);
    }

    function testNobodyCanTransferer() public {
        // the token owner can't transfer
        vm.expectRevert(Badges.Disabled.selector);
        vm.prank(alice);
        badges.safeTransferFrom(alice, bob, badgeOne, 1, "");
        assertEq(badges.balanceOf(alice, badgeOne), 1);
        assertEq(badges.balanceOf(bob, badgeOne), 0);

        // the contract owner can't transfer
        vm.prank(owner);
        vm.expectRevert(Badges.Disabled.selector);
        badges.safeTransferFrom(alice, bob, badgeOne, 1, "");
        assertEq(badges.balanceOf(alice, badgeOne), 1);
        assertEq(badges.balanceOf(bob, badgeOne), 0);
    }

    function testSetApprove() public {
        // can not approve
        vm.expectRevert(Badges.Disabled.selector);
        vm.prank(alice);
        badges.setApprovalForAll(bob, true);
        assertEq(badges.isApprovedForAll(alice, bob), false);
    }

    function testGetApprovedForAll() public {
        // should get false for all addresses, except for the transferer
        assertEq(badges.isApprovedForAll(msg.sender, alice), false);
        assertEq(badges.isApprovedForAll(msg.sender, address(this)), false);
        assertEq(badges.isApprovedForAll(msg.sender, address(badges)), true);
    }

    function testUpdateOwner() public {
        uint256 superBadge = 500;
        // mint a badge to alice
        vm.prank(owner);
        badges.mint(alicePassportId, superBadge, 1, "");

        address newAlice = address(0x7);
        assertEq(badges.balanceOf(alice, superBadge), 1);
        assertEq(badges.balanceOf(newAlice, superBadge), 0);
        assertEq(badges.balanceOf(alicePassportId, superBadge), 1);

        vm.prank(passport_transferer);
        passport.safeTransferFrom(alice, newAlice, alicePassportId);

        assertEq(badges.balanceOf(alice, superBadge), 1);
        assertEq(badges.balanceOf(newAlice, superBadge), 0);
        assertEq(badges.balanceOf(alicePassportId, superBadge), 0);

        uint256[] memory badgeIds = new uint256[](1);
        badgeIds[0] = superBadge;
        badges.updateOwner(alicePassportId, badgeIds);

        assertEq(badges.balanceOf(alice, superBadge), 0);
        assertEq(badges.balanceOf(newAlice, superBadge), 1);
        assertEq(badges.balanceOf(alicePassportId, superBadge), 1);

        // TODO: test with BadgeOne

        // test implicit updateOwner
        vm.prank(passport_transferer);
        passport.safeTransferFrom(newAlice, alice, alicePassportId);

        assertEq(badges.balanceOf(newAlice, superBadge), 1);
        assertEq(badges.balanceOf(alice, superBadge), 0);
        assertEq(badges.balanceOf(alicePassportId, superBadge), 0);

        vm.prank(owner);
        badges.mint(alicePassportId, superBadge, 10, "");

        assertEq(badges.balanceOf(newAlice, superBadge), 0);
        assertEq(badges.balanceOf(alice, superBadge), 11);
        assertEq(badges.balanceOf(alicePassportId, superBadge), 11);

        vm.prank(passport_transferer);
        passport.safeTransferFrom(alice, newAlice, alicePassportId);

        vm.prank(owner);
        badges.burn(alicePassportId, superBadge, 5);
        assertEq(badges.balanceOf(newAlice, superBadge), 6);
        assertEq(badges.balanceOf(alice, superBadge), 0);
        assertEq(badges.balanceOf(alicePassportId, superBadge), 6);
    }
}
