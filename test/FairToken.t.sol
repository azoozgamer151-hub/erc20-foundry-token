// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {FairToken} from "../src/FairToken.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract FairTokenTest is Test {
    FairToken token;
    address deployer = makeAddr("deployer");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    uint256 constant SUPPLY = 1_000_000 ether;

    function setUp() public {
        vm.prank(deployer);
        token = new FairToken("Fair Token", "FAIR", SUPPLY, deployer);
    }

    // ---------- deployment ----------
    function test_MetadataAndSupply() public view {
        assertEq(token.name(), "Fair Token");
        assertEq(token.symbol(), "FAIR");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), SUPPLY);
        assertEq(token.balanceOf(deployer), SUPPLY);
    }

    function test_RevertWhen_RecipientIsZero() public {
        vm.expectRevert(FairToken.ZeroRecipient.selector);
        new FairToken("X", "X", 1, address(0));
    }

    function test_RevertWhen_SupplyIsZero() public {
        vm.expectRevert(FairToken.ZeroSupply.selector);
        new FairToken("X", "X", 0, alice);
    }

    // ---------- "no hidden powers" checks (what a buyer should verify) ----------
    function test_NoOwnerFunction() public {
        (bool ok,) = address(token).call(abi.encodeWithSignature("owner()"));
        assertFalse(ok, "token must not have an owner");
    }

    function test_NoMintFunction() public {
        (bool ok,) = address(token).call(abi.encodeWithSignature("mint(address,uint256)", alice, 1));
        assertFalse(ok, "token must not be mintable");
    }

    function test_NoTaxOnTransfer() public {
        vm.prank(deployer);
        token.transfer(alice, 1000 ether);
        assertEq(token.balanceOf(alice), 1000 ether, "receiver gets the full amount");
    }

    function test_AnyHolderCanSell() public {
        // a honeypot lets you buy but blocks selling; here any holder can always move tokens
        vm.prank(deployer);
        token.transfer(alice, 10 ether);
        vm.prank(alice);
        token.transfer(bob, 10 ether);
        assertEq(token.balanceOf(bob), 10 ether);
    }

    // ---------- transfers & approvals ----------
    function test_RevertWhen_TransferExceedsBalance() public {
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, alice, 0, 1));
        vm.prank(alice);
        token.transfer(bob, 1);
    }

    function test_ApproveAndTransferFrom() public {
        vm.prank(deployer);
        token.approve(alice, 50 ether);
        vm.prank(alice);
        token.transferFrom(deployer, bob, 20 ether);
        assertEq(token.balanceOf(bob), 20 ether);
        assertEq(token.allowance(deployer, alice), 30 ether);
    }

    function test_RevertWhen_TransferFromExceedsAllowance() public {
        vm.prank(deployer);
        token.approve(alice, 1 ether);
        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, alice, 1 ether, 2 ether)
        );
        vm.prank(alice);
        token.transferFrom(deployer, bob, 2 ether);
    }

    // ---------- burn ----------
    function test_BurnReducesSupply() public {
        vm.prank(deployer);
        token.burn(100 ether);
        assertEq(token.totalSupply(), SUPPLY - 100 ether);
    }

    // ---------- permit (EIP-2612) ----------
    function test_Permit() public {
        (address owner, uint256 pk) = makeAddrAndKey("permitOwner");
        vm.prank(deployer);
        token.transfer(owner, 5 ether);

        uint256 deadline = block.timestamp + 1 hours;
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                owner, alice, 5 ether, token.nonces(owner), deadline
            )
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, digest);

        token.permit(owner, alice, 5 ether, deadline, v, r, s);
        assertEq(token.allowance(owner, alice), 5 ether);
        assertEq(token.nonces(owner), 1);
    }

    // ---------- fuzz ----------
    function testFuzz_TransferKeepsSupply(address to, uint256 amount) public {
        vm.assume(to != address(0) && to != deployer);
        amount = bound(amount, 0, SUPPLY);
        vm.prank(deployer);
        token.transfer(to, amount);
        assertEq(token.balanceOf(to), amount);
        assertEq(token.balanceOf(deployer), SUPPLY - amount);
        assertEq(token.totalSupply(), SUPPLY);
    }
}
