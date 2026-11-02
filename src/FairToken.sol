// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/// @title FairToken
/// @notice A trust-minimized ERC-20: the whole supply is minted once at deploy time.
/// @dev Deliberately has NO owner, NO mint function, NO fees/taxes, NO blacklist and NO pause.
///      Those are the levers used in most rug pulls and honeypots, so this token simply doesn't have them.
///      Holders can burn their own tokens and use EIP-2612 permit for gasless approvals.
contract FairToken is ERC20, ERC20Burnable, ERC20Permit {
    error ZeroRecipient();
    error ZeroSupply();

    constructor(string memory name_, string memory symbol_, uint256 supply_, address recipient_)
        ERC20(name_, symbol_)
        ERC20Permit(name_)
    {
        if (recipient_ == address(0)) revert ZeroRecipient();
        if (supply_ == 0) revert ZeroSupply();
        _mint(recipient_, supply_);
    }
}
