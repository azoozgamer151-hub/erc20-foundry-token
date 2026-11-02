// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {FairToken} from "../src/FairToken.sol";

/// Usage (testnet):
///   TOKEN_NAME="Fair Token" TOKEN_SYMBOL=FAIR TOKEN_SUPPLY=1000000 \
///   forge script script/Deploy.s.sol --rpc-url $RPC_URL --account deployer --broadcast --verify
contract Deploy is Script {
    function run() external returns (FairToken token) {
        string memory name = vm.envOr("TOKEN_NAME", string("Fair Token"));
        string memory symbol = vm.envOr("TOKEN_SYMBOL", string("FAIR"));
        uint256 supply = vm.envOr("TOKEN_SUPPLY", uint256(1_000_000)) * 1e18;

        vm.startBroadcast();
        token = new FairToken(name, symbol, supply, msg.sender);
        vm.stopBroadcast();

        console.log("FairToken deployed at:", address(token));
        console.log("Supply minted to:", msg.sender);
    }
}
