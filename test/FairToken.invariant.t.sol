// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {FairToken} from "../src/FairToken.sol";

/// @dev Random sequences of transfers / approvals / burns between a fixed set of actors.
contract Handler is Test {
    FairToken public token;
    address[] public actors;
    uint256 public burned;

    constructor(FairToken token_, address[] memory actors_) {
        token = token_;
        actors = actors_;
    }

    function transfer(uint256 fromSeed, uint256 toSeed, uint256 amount) external {
        address from = actors[fromSeed % actors.length];
        address to = actors[toSeed % actors.length];
        amount = bound(amount, 0, token.balanceOf(from));
        vm.prank(from);
        token.transfer(to, amount);
    }

    function approveAndPull(uint256 ownerSeed, uint256 spenderSeed, uint256 amount) external {
        address owner = actors[ownerSeed % actors.length];
        address spender = actors[spenderSeed % actors.length];
        amount = bound(amount, 0, token.balanceOf(owner));
        vm.prank(owner);
        token.approve(spender, amount);
        vm.prank(spender);
        token.transferFrom(owner, spender, amount);
    }

    function burn(uint256 fromSeed, uint256 amount) external {
        address from = actors[fromSeed % actors.length];
        amount = bound(amount, 0, token.balanceOf(from));
        vm.prank(from);
        token.burn(amount);
        burned += amount;
    }

    function actorCount() external view returns (uint256) {
        return actors.length;
    }
}

contract FairTokenInvariantTest is Test {
    FairToken token;
    Handler handler;
    uint256 constant SUPPLY = 1_000_000 ether;

    function setUp() public {
        address[] memory actors = new address[](4);
        for (uint256 i; i < actors.length; i++) {
            actors[i] = makeAddr(string(abi.encodePacked("actor", vm.toString(i))));
        }
        token = new FairToken("Fair Token", "FAIR", SUPPLY, actors[0]);
        handler = new Handler(token, actors);
        targetContract(address(handler));
    }

    /// Supply can only go down (burns), never up: there is no way to mint.
    function invariant_SupplyOnlyDecreasesByBurns() public view {
        assertEq(token.totalSupply(), SUPPLY - handler.burned());
    }

    /// Sum of all balances always equals total supply (no tokens created or lost).
    function invariant_BalancesSumToSupply() public view {
        uint256 sum;
        for (uint256 i; i < handler.actorCount(); i++) {
            sum += token.balanceOf(handler.actors(i));
        }
        assertEq(sum, token.totalSupply());
    }
}
