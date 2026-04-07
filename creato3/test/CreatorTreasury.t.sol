// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/CreatorTreasury.sol";

contract CreatorTreasuryTest is Test {
    CreatorTreasury private treasury;

    address private owner = address(0x10);
    address private caller = address(0x20);
    address private creator = address(0x30);

    function setUp() public {
        treasury = new CreatorTreasury(owner);
        vm.prank(owner);
        treasury.setAuthorizedCaller(caller);
        vm.deal(caller, 10 ether);
    }

    function testReceivePaymentIncrementsBalance() public {
        vm.prank(caller);
        treasury.receivePayment{value: 1 ether}(creator);

        assertEq(treasury.getBalance(creator), 1 ether);
        assertEq(treasury.getTotalEarned(creator), 1 ether);
    }

    function testWithdrawSendsFullAmountZeroFee() public {
        vm.prank(caller);
        treasury.receivePayment{value: 2 ether}(creator);

        uint256 beforeBal = creator.balance;
        vm.prank(creator);
        treasury.withdraw();
        uint256 afterBal = creator.balance;

        assertEq(afterBal - beforeBal, 2 ether);
        assertEq(treasury.getBalance(creator), 0);
    }

    function testUnauthorizedCallerReverts() public {
        address unauthorized = address(0x40);
        vm.deal(unauthorized, 1 ether);
        vm.prank(unauthorized);
        vm.expectRevert();
        treasury.receivePayment{value: 1 ether}(creator);
    }
}
