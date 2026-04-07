// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CreatorProfile {
    struct Creator {
        address wallet;
        string initUsername;
        string displayName;
        string bio;
        string category;
        bool active;
        uint256 createdAt;
    }

    struct CreatorTier {
        uint256 price;
        string name;
        string description;
        bool active;
    }

    mapping(address => Creator) public creators;
    mapping(address => mapping(uint8 => CreatorTier)) public tiers;
    mapping(address => uint8) public tierCount;

    event CreatorRegistered(address indexed wallet, string initUsername);
    event TierCreated(address indexed creator, uint8 indexed tierId, uint256 price);
    event TierUpdated(address indexed creator, uint8 indexed tierId, uint256 price, bool active);

    function registerCreator(
        string memory displayName,
        string memory bio,
        string memory category,
        string memory initUsername
    ) external {
        require(!creators[msg.sender].active, "Already registered");

        creators[msg.sender] = Creator({
            wallet: msg.sender,
            initUsername: initUsername,
            displayName: displayName,
            bio: bio,
            category: category,
            active: true,
            createdAt: block.timestamp
        });

        emit CreatorRegistered(msg.sender, initUsername);
    }

    function createTier(
        uint256 price,
        string memory name,
        string memory description
    ) external returns (uint8 tierId) {
        require(creators[msg.sender].active, "Creator not registered");
        require(price > 0, "Price must be > 0");

        tierId = tierCount[msg.sender];
        tiers[msg.sender][tierId] = CreatorTier({
            price: price,
            name: name,
            description: description,
            active: true
        });
        tierCount[msg.sender] = tierId + 1;

        emit TierCreated(msg.sender, tierId, price);
    }

    function updateTier(
        uint8 tierId,
        uint256 price,
        string memory name,
        string memory description,
        bool active
    ) external {
        require(creators[msg.sender].active, "Creator not registered");
        require(tierId < tierCount[msg.sender], "Invalid tier");

        tiers[msg.sender][tierId] = CreatorTier({
            price: price,
            name: name,
            description: description,
            active: active
        });

        emit TierUpdated(msg.sender, tierId, price, active);
    }

    function getCreator(address creator) external view returns (Creator memory) {
        return creators[creator];
    }

    function getTier(address creator, uint8 tierId) external view returns (CreatorTier memory) {
        return tiers[creator][tierId];
    }

    function getActiveTiers(
        address creator
    ) external view returns (CreatorTier[] memory activeTiers, uint8[] memory tierIds) {
        uint8 count = 0;
        uint8 total = tierCount[creator];
        for (uint8 i = 0; i < total; i++) {
            if (tiers[creator][i].active) {
                count++;
            }
        }

        activeTiers = new CreatorTier[](count);
        tierIds = new uint8[](count);
        uint8 idx = 0;
        for (uint8 i = 0; i < total; i++) {
            if (tiers[creator][i].active) {
                activeTiers[idx] = tiers[creator][i];
                tierIds[idx] = i;
                idx++;
            }
        }
    }

    function isRegistered(address creator) external view returns (bool) {
        return creators[creator].active;
    }
}
