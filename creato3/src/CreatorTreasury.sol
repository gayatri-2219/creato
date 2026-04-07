// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CreatorTreasury {
    address public owner;
    address public authorizedCaller;

    mapping(address => uint256) public balances;
    mapping(address => uint256) public totalEarned;

    event PaymentReceived(address indexed creator, uint256 amount);
    event Withdrawal(address indexed creator, uint256 amount, uint256 timestamp);
    event AuthorizedCallerSet(address indexed caller);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _owner) {
        owner = _owner;
    }

    function setAuthorizedCaller(address _caller) external onlyOwner {
        require(authorizedCaller == address(0), "Caller already set");
        authorizedCaller = _caller;
        emit AuthorizedCallerSet(_caller);
    }

    function receivePayment(address _creator) external payable {
        require(msg.sender == authorizedCaller, "Unauthorized caller");
        balances[_creator] += msg.value;
        totalEarned[_creator] += msg.value;
        emit PaymentReceived(_creator, msg.value);
    }

    function withdraw() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance");
        balances[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdraw failed");
        emit Withdrawal(msg.sender, amount, block.timestamp);
    }

    function getBalance(address _creator) external view returns (uint256) {
        return balances[_creator];
    }

    function getTotalEarned(address _creator) external view returns (uint256) {
        return totalEarned[_creator];
    }
}
