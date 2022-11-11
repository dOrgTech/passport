// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../lib/forge-std/src/Test.sol";
import {Passport} from "./Passport.sol";

contract PassportTest is Test {
    Passport public token;

    function setUp() public {
        token = new Passport("A Token", "AT", "");
    }

    function testSetupParameters() public {
        assertEq(token.name(), "A Token");
        assertEq(token.symbol(), "AT");
    }
}
