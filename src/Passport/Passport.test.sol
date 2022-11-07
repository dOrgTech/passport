// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../lib/forge-std/src/Test.sol";
import {Passport} from "./Passport.sol";

contract PassportTest is Test {
    address public deployer = 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84;
    address public alice = 0xD028d504316FEc029CFa36bdc3A8f053F6E5a6e4;
    address public bob = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    Passport public passport;

    function setUp() public {
        passport = new Passport("Passport", "PAS", "");
    }

    function testSetupParameters() public {
        assertEq(passport.name(), "Passport");
        assertEq(passport.symbol(), "PAS");
    }

    function testMint() public {
        passport.safeMint(alice, "");
        assertEq(passport.balanceOf(alice), 1);
    }

    function testOnlyOwnerCanMint() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(bob);
        passport.safeMint(alice, "");
    }
}
