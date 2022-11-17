// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../lib/forge-std/src/Test.sol";
import {Strings} from "../../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import {Rep} from "./Rep.sol";
import {Passport} from "../Passport/Passport.sol";

contract RepTest is Test {
    Rep public rep;
    address public admin = address(0x1);
    address public minter_burner = address(0x2);
    address public snapshoter = address(0x3);

    Passport public passport;
    address public passport_transferer = address(0x6);

    address public alice = address(0x4);
    address public bob = address(0x5);

    uint256 alicePassportId = 0;
    uint256 bobPassportID = 1;

    function setUp() public {
        passport = new Passport("Passport", "PASS", "");
        passport.grantRole(passport.TRANSFERER_ROLE(), passport_transferer);

        rep = new Rep(address(passport), "Reputation", "REP");
        rep.grantRole(rep.DEFAULT_ADMIN_ROLE(), admin);
        rep.grantRole(rep.MINTER_BURNER_ROLE(), minter_burner);
        rep.grantRole(rep.SNAPSHOT_ROLE(), snapshoter);

        rep.revokeRole(rep.MINTER_BURNER_ROLE(), address(this));
        rep.revokeRole(rep.SNAPSHOT_ROLE(), address(this));
        rep.revokeRole(rep.DEFAULT_ADMIN_ROLE(), address(this));

        // by default the passport deployer gets the minter role
        passport.safeMint(alice); // gets a passport id 0
        passport.safeMint(bob); // gets a passport id 1
    }

    function testSetupParameters() public {
        assertEq(passport.ownerOf(0), alice);
        assertEq(passport.ownerOf(1), bob);
        assertEq(rep.name(), "Reputation");
        assertEq(rep.symbol(), "REP");
    }

    function testUpdateOwner() public {
        // mint a rep to alice
        vm.prank(minter_burner);
        rep.mint(alicePassportId, 100);

        address newAlice = address(0x7);
        assertEq(rep.balanceOf(alice), 100);
        assertEq(rep.balanceOf(newAlice), 0);
        assertEq(rep.balanceOf(alicePassportId), 100);

        vm.prank(passport_transferer);
        passport.safeTransferFrom(alice, newAlice, alicePassportId);

        assertEq(rep.balanceOf(alice), 100);
        assertEq(rep.balanceOf(newAlice), 0);
        assertEq(rep.balanceOf(alicePassportId), 0);

        rep.updateOwner(alicePassportId);

        assertEq(rep.balanceOf(alice), 0);
        assertEq(rep.balanceOf(newAlice), 100);
        assertEq(rep.balanceOf(alicePassportId), 100);

        // test implicit updateOwner
        vm.prank(passport_transferer);
        passport.safeTransferFrom(newAlice, alice, alicePassportId);

        assertEq(rep.balanceOf(newAlice), 100);
        assertEq(rep.balanceOf(alice), 0);
        assertEq(rep.balanceOf(alicePassportId), 0);

        vm.prank(minter_burner);
        rep.mint(alicePassportId, 100);

        assertEq(rep.balanceOf(newAlice), 0);
        assertEq(rep.balanceOf(alice), 200);
        assertEq(rep.balanceOf(alicePassportId), 200);
    }

    function testOnlyMinterBurnerCanMint() public {
        // cant mint with msg.sender
        vm.expectRevert(
            missingRoleError(rep.MINTER_BURNER_ROLE(), address(this))
        );
        rep.mint(alicePassportId, 100);
        assertEq(rep.balanceOf(alice), 0);

        // can mint with minter
        vm.prank(minter_burner);
        rep.mint(alicePassportId, 100);
        assertEq(rep.balanceOf(alice), 100);
    }

    function testNobodyCanTransferer() public {
        // mint a rep to alice
        vm.prank(minter_burner);
        rep.mint(alicePassportId, 100);

        // the owner (msg.sender) can't transfer
        vm.expectRevert(Rep.Disabled.selector);
        vm.prank(alice);
        rep.transfer(bob, 10);
        assertEq(rep.balanceOf(alice), 100);
        assertEq(rep.balanceOf(bob), 0);

        // non of the other roles can transfer
        vm.prank(admin);
        vm.expectRevert(Rep.Disabled.selector);
        rep.transferFrom(alice, bob, 10);

        vm.prank(snapshoter);
        vm.expectRevert(Rep.Disabled.selector);
        rep.transferFrom(alice, bob, 10);

        vm.prank(minter_burner);
        vm.expectRevert(Rep.Disabled.selector);
        rep.transferFrom(alice, bob, 10);

        assertEq(rep.balanceOf(alice), 100);
        assertEq(rep.balanceOf(bob), 0);
    }

    function testOnlyMinterBurnerCanBurn() public {
        // mint a rep to the msg.sender
        vm.prank(minter_burner);
        rep.mint(alicePassportId, 200);

        // the owner (msg.sender) can't burn
        vm.expectRevert(
            missingRoleError(rep.MINTER_BURNER_ROLE(), address(this))
        );
        rep.burnFrom(alicePassportId, 100);
        assertEq(rep.balanceOf(alice), 200);

        // the minter_burner can burn
        vm.prank(minter_burner);
        rep.burnFrom(alicePassportId, 50);
        assertEq(rep.balanceOf(alice), 150);
    }

    function testSetApprove() public {
        // mint a rep to the msg.sender
        vm.prank(minter_burner);
        rep.mint(alicePassportId, 100);

        // can not approve
        vm.expectRevert(Rep.Disabled.selector);
        rep.approve(alice, 10);
        assertEq(rep.allowance(msg.sender, alice), 0);
    }

    function testGetAllowance() public {
        // mint a rep to the msg.sender
        vm.prank(minter_burner);
        rep.mint(alicePassportId, 100);

        // should get false for all addresses, except for the transferer
        assertEq(rep.allowance(msg.sender, alice), 0);
        assertEq(rep.allowance(msg.sender, address(this)), 0);
    }

    // we must detect when a passport has moved and update the rep accordingly when a function is called
    function testBurnWhenPassportMove() public {
        // mint a rep to the msg.sender
        vm.prank(minter_burner);
        rep.mint(alicePassportId, 100);

        address aliceNewAddress = address(0x44);

        vm.prank(passport_transferer);
        passport.safeTransferFrom(alice, aliceNewAddress, alicePassportId);
        assertEq(passport.ownerOf(alicePassportId), aliceNewAddress);

        // should still be able to burn Alice's rep (even though the passport has moved)
        vm.prank(minter_burner);
        rep.burnFrom(alicePassportId, 70);
        assertEq(rep.balanceOf(alicePassportId), 30);
    }
}

function missingRoleError(bytes32 role, address account)
    pure
    returns (bytes memory)
{
    return
        bytes(
            string(
                abi.encodePacked(
                    "AccessControl: account ",
                    Strings.toHexString(account),
                    " is missing role ",
                    Strings.toHexString(uint256(role), 32)
                )
            )
        );
}
