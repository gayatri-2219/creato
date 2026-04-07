// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/CreatorProfile.sol";

contract CreatorProfileTest is Test {
    CreatorProfile private profile;
    address private creator = address(0x1);

    function setUp() public {
        profile = new CreatorProfile();
    }

    function testRegisterSucceedsWithCorrectData() public {
        vm.prank(creator);
        profile.registerCreator("Alice", "Bio", "coding", "alice.init");

        CreatorProfile.Creator memory stored = profile.getCreator(creator);
        assertEq(stored.wallet, creator);
        assertEq(stored.displayName, "Alice");
        assertEq(stored.bio, "Bio");
        assertEq(stored.category, "coding");
        assertEq(stored.initUsername, "alice.init");
        assertTrue(stored.active);
        assertGt(stored.createdAt, 0);
    }

    function testDuplicateRegisterReverts() public {
        vm.prank(creator);
        profile.registerCreator("Alice", "Bio", "coding", "alice.init");

        vm.prank(creator);
        vm.expectRevert();
        profile.registerCreator("Alice", "Bio", "coding", "alice.init");
    }

    function testCreateTierStoresCorrectly() public {
        vm.prank(creator);
        profile.registerCreator("Alice", "Bio", "coding", "alice.init");

        vm.prank(creator);
        uint8 tierId = profile.createTier(100, "Basic", "Desc");
        assertEq(tierId, 0);

        CreatorProfile.CreatorTier memory tier = profile.getTier(creator, 0);
        assertEq(tier.price, 100);
        assertEq(tier.name, "Basic");
        assertEq(tier.description, "Desc");
        assertTrue(tier.active);
    }

    function testGetActiveTiersReturnsOnlyActive() public {
        vm.prank(creator);
        profile.registerCreator("Alice", "Bio", "coding", "alice.init");

        vm.prank(creator);
        profile.createTier(100, "Basic", "Desc");
        vm.prank(creator);
        profile.createTier(200, "Premium", "Desc2");

        vm.prank(creator);
        profile.updateTier(1, 200, "Premium", "Desc2", false);

        (CreatorProfile.CreatorTier[] memory tiers, uint8[] memory ids) = profile.getActiveTiers(creator);
        assertEq(tiers.length, 1);
        assertEq(ids.length, 1);
        assertEq(ids[0], 0);
        assertEq(tiers[0].name, "Basic");
    }

    function testUnregisteredCreatorCannotCreateTier() public {
        vm.prank(creator);
        vm.expectRevert();
        profile.createTier(100, "Basic", "Desc");
    }

    function testUpdateTierUpdatesData() public {
        vm.prank(creator);
        profile.registerCreator("Alice", "Bio", "coding", "alice.init");

        vm.prank(creator);
        profile.createTier(100, "Basic", "Desc");

        vm.prank(creator);
        profile.updateTier(0, 250, "Plus", "New", false);

        CreatorProfile.CreatorTier memory tier = profile.getTier(creator, 0);
        assertEq(tier.price, 250);
        assertEq(tier.name, "Plus");
        assertEq(tier.description, "New");
        assertFalse(tier.active);
    }
}
