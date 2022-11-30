// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../lib/forge-std/src/Test.sol";
import {Strings} from "../../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import {Passport} from "./Passport.sol";

contract PassportTest is Test {
    Passport public passport;
    address public admin = address(0x1);
    address public minter = address(0x2);
    address public transferer = address(0x3);

    address public alice = address(0x4);
    address public bob = address(0x5);

    function setUp() public {
        passport = new Passport("Passport", "PASS", "");
        passport.grantRole(passport.DEFAULT_ADMIN_ROLE(), admin);
        passport.grantRole(passport.MINTER_ROLE(), minter);
        passport.grantRole(passport.TRANSFERER_ROLE(), transferer);

        passport.revokeRole(passport.MINTER_ROLE(), address(this));
        passport.revokeRole(passport.TRANSFERER_ROLE(), address(this));
        passport.revokeRole(passport.DEFAULT_ADMIN_ROLE(), address(this));
    }

    function testSetupParameters() public {
        assertEq(passport.name(), "Passport");
        assertEq(passport.symbol(), "PASS");
    }

    function testOnlyMinterCanSafeMint() public {
        // cant mint with msg.sender
        vm.expectRevert(missingRoleError(passport.MINTER_ROLE(), address(this)));
        passport.safeMint(msg.sender);
        assertEq(passport.balanceOf(msg.sender), 0);

        // can mint with minter
        vm.prank(minter);
        passport.safeMint(msg.sender);
        assertEq(passport.balanceOf(msg.sender), 1);
    }

    function testOnlyTransfererCanTransfer() public {
        // mint a Passport to alice
        vm.prank(minter);
        passport.safeMint(alice);

        // the owner (alice) can't transfer
        vm.expectRevert(missingRoleError(passport.TRANSFERER_ROLE(), alice));
        vm.prank(alice);
        passport.transferFrom(alice, bob, 0);
        assertEq(passport.balanceOf(alice), 1);
        assertEq(passport.balanceOf(bob), 0);

        // the transferer can transfer
        vm.prank(transferer);
        passport.transferFrom(alice, bob, 0);
        assertEq(passport.balanceOf(alice), 0);
        assertEq(passport.balanceOf(bob), 1);
    }

    function testOnlyTransfererCanSafeTransfer() public {
        // mint a Passport to the msg.sender
        vm.prank(minter);
        passport.safeMint(alice);

        // the owner (msg.sender) can't transfer
        vm.expectRevert(missingRoleError(passport.TRANSFERER_ROLE(), alice));
        vm.prank(alice);
        passport.safeTransferFrom(alice, bob, 0);
        assertEq(passport.balanceOf(alice), 1);
        assertEq(passport.balanceOf(bob), 0);

        // the transferer can transfer
        vm.prank(transferer);
        passport.safeTransferFrom(alice, bob, 0);
        assertEq(passport.balanceOf(alice), 0);
        assertEq(passport.balanceOf(bob), 1);
    }

    function testOnlyAdminCanUpdateBaseURI() public {
        // mint a Passport to the msg.sender
        vm.prank(minter);
        passport.safeMint(msg.sender);

        // cant update baseURI with msg.sender
        vm.expectRevert(missingRoleError(passport.DEFAULT_ADMIN_ROLE(), address(this)));
        passport.updateBaseURI("https://example.com/");
        assertEq(passport.tokenURI(0), "");

        // can update baseURI with admin
        vm.prank(admin);
        passport.updateBaseURI("https://example.com/");
        assertEq(passport.tokenURI(0), "https://example.com/0");
    }

    function testSetApprove() public {
        // mint a Passport to alice
        vm.prank(minter);
        passport.safeMint(alice);

        // can not approve
        vm.expectRevert(Passport.Disabled.selector);
        vm.prank(alice);
        passport.approve(bob, 0);
        assertEq(passport.getApproved(0), address(0));
    }

    function testSetApprovalForAll() public {
        // mint a Passport to alice
        vm.prank(minter);
        passport.safeMint(alice);

        // can not approve
        vm.expectRevert(Passport.Disabled.selector);
        vm.prank(alice);
        passport.setApprovalForAll(bob, true);
        assertEq(passport.getApproved(0), address(0));
    }

    function testGetApproved() public {
        // mint a Passport to the msg.sender
        vm.prank(minter);
        passport.safeMint(msg.sender);

        // should get "empty" approval for minted token
        assertEq(passport.getApproved(0), address(0));

        // should revert for non-excising token
        vm.expectRevert(bytes("ERC721: invalid token ID"));
        passport.getApproved(1);
    }

    function testGetApprovedForAll() public {
        // should get false for all addresses, except for the transferer
        assertEq(passport.isApprovedForAll(msg.sender, alice), false);
        assertEq(passport.isApprovedForAll(msg.sender, address(this)), false);
        assertEq(passport.isApprovedForAll(msg.sender, transferer), true);
    }
}

function missingRoleError(bytes32 role, address account) pure returns (bytes memory) {
    return bytes(
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
