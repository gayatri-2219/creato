// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/CreatorProfile.sol";
import "../src/CreatorTreasury.sol";
import "../src/SubscriptionManager.sol";

contract SubscriptionManagerTest is Test {
    CreatorProfile private profile;
    CreatorTreasury private treasury;
    SubscriptionManager private manager;

    address private creator = address(0x1);
    address private subscriber = address(0x2);

    uint256 private constant PRICE = 1e15;

    function setUp() public {
        profile = new CreatorProfile();
        treasury = new CreatorTreasury(address(this));
        manager = new SubscriptionManager(address(profile), address(treasury));
        treasury.setAuthorizedCaller(address(manager));

        vm.prank(creator);
        profile.registerCreator("Alice", "Bio", "coding", "alice.init");
        vm.prank(creator);
        profile.createTier(PRICE, "Basic", "Desc");

        vm.deal(subscriber, 10 ether);
    }

    function testSubscribeSuccess() public {
        vm.prank(subscriber);
        manager.subscribe{value: PRICE}(creator, 0);

        SubscriptionManager.Subscription memory sub = manager.getSubscription(subscriber, creator);
        assertTrue(sub.active);
        assertEq(sub.creator, creator);
        assertEq(sub.subscriber, subscriber);
        assertEq(sub.tierId, 0);
        assertEq(sub.expiry, sub.startTime + 30 days);
    }

    function testWrongPaymentReverts() public {
        vm.prank(subscriber);
        vm.expectRevert();
        manager.subscribe{value: PRICE - 1}(creator, 0);
    }

    function testCheckAccessTrue() public {
        vm.prank(subscriber);
        manager.subscribe{value: PRICE}(creator, 0);

        bool ok = manager.checkAccess(subscriber, creator, 0);
        assertTrue(ok);
    }

    function testExpiredReturnsFalse() public {
        vm.prank(subscriber);
        manager.subscribe{value: PRICE}(creator, 0);

        vm.warp(block.timestamp + 31 days);
        bool ok = manager.checkAccess(subscriber, creator, 0);
        assertFalse(ok);
    }

    function testCancelSetsActiveFalse() public {
        vm.prank(subscriber);
        manager.subscribe{value: PRICE}(creator, 0);

        vm.prank(subscriber);
        manager.cancelSubscription(creator);

        SubscriptionManager.Subscription memory sub = manager.getSubscription(subscriber, creator);
        assertFalse(sub.active);
    }

    function testRenewExtendsExpiry() public {
        vm.prank(subscriber);
        manager.subscribe{value: PRICE}(creator, 0);

        SubscriptionManager.Subscription memory beforeSub = manager.getSubscription(subscriber, creator);
        vm.warp(block.timestamp + 10 days);

        vm.prank(subscriber);
        manager.renewSubscription{value: PRICE}(creator);

        SubscriptionManager.Subscription memory afterSub = manager.getSubscription(subscriber, creator);
        assertEq(afterSub.expiry, beforeSub.expiry + 30 days);
    }
}
