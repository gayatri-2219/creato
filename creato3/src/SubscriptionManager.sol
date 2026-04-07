// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITreasury {
    function receivePayment(address creator) external payable;
}

interface ICreatorProfile {
    struct CreatorTier {
        uint256 price;
        string name;
        string description;
        bool active;
    }

    function isRegistered(address creator) external view returns (bool);

    function getTier(address creator, uint8 tierId) external view returns (CreatorTier memory);
}

contract SubscriptionManager {
    struct Subscription {
        address subscriber;
        address creator;
        uint8 tierId;
        uint256 startTime;
        uint256 expiry;
        bool active;
    }

    address public immutable profileContract;
    address public immutable treasuryContract;

    mapping(address => mapping(address => Subscription)) public subscriptions;

    event Subscribed(address indexed subscriber, address indexed creator, uint8 tierId, uint256 expiry);
    event Renewed(address indexed subscriber, address indexed creator, uint256 newExpiry);
    event Cancelled(address indexed subscriber, address indexed creator);

    constructor(address _profileContract, address _treasuryContract) {
        profileContract = _profileContract;
        treasuryContract = _treasuryContract;
    }

    function subscribe(address creator, uint8 tierId) external payable {
        require(ICreatorProfile(profileContract).isRegistered(creator), "Creator not registered");
        ICreatorProfile.CreatorTier memory tier = ICreatorProfile(profileContract).getTier(creator, tierId);
        require(tier.active, "Tier inactive");
        require(msg.value == tier.price, "Incorrect payment");

        Subscription storage sub = subscriptions[msg.sender][creator];
        sub.subscriber = msg.sender;
        sub.creator = creator;
        sub.tierId = tierId;
        sub.startTime = block.timestamp;
        sub.expiry = block.timestamp + 30 days;
        sub.active = true;

        ITreasury(treasuryContract).receivePayment{value: msg.value}(creator);
        emit Subscribed(msg.sender, creator, tierId, sub.expiry);
    }

    function renewSubscription(address creator) external payable {
        Subscription storage sub = subscriptions[msg.sender][creator];
        require(sub.active, "Inactive subscription");
        ICreatorProfile.CreatorTier memory tier = ICreatorProfile(profileContract).getTier(creator, sub.tierId);
        require(msg.value == tier.price, "Incorrect payment");

        if (sub.expiry < block.timestamp) {
            sub.expiry = block.timestamp + 30 days;
        } else {
            sub.expiry += 30 days;
        }

        ITreasury(treasuryContract).receivePayment{value: msg.value}(creator);
        emit Renewed(msg.sender, creator, sub.expiry);
    }

    function cancelSubscription(address creator) external {
        Subscription storage sub = subscriptions[msg.sender][creator];
        sub.active = false;
        emit Cancelled(msg.sender, creator);
    }

    function checkAccess(address subscriber, address creator, uint8 tierId) external view returns (bool) {
        Subscription memory sub = subscriptions[subscriber][creator];
        return sub.active && sub.tierId >= tierId && sub.expiry > block.timestamp;
    }

    function getSubscription(address subscriber, address creator) external view returns (Subscription memory) {
        return subscriptions[subscriber][creator];
    }
}
