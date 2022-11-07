// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../lib/forge-std/src/Test.sol";
import {ERC721OnlyOwnerTransferable} from "./ERC721OnlyOwnerTransferable.sol";

contract ERC721OnlyOwnerTransferableTest is Test {
    ERC721OnlyOwnerTransferable public token;

    function setUp() public {
        token = new ERC721OnlyOwnerTransferable("A Token", "AT", "");
    }

    function testSetupParameters() public {
        assertEq(token.name(), "A Token");
        assertEq(token.symbol(), "AT");
    }
}
