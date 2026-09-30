// SPDX-License-Identifier: Unlicenced
pragma solidity ^0.8.34;

contract TokenContract {
    address public owner;
    uint256 public tokenCost = 5 ether;

    struct Receivers {
        string name;
        uint256 tokens;
    }

    mapping(address => Receivers) public users;
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier enoughLeft(uint256 _amount) {
        require(users[owner].tokens >= _amount, "Not enough tokens left to sell");
        _;
    }

    constructor() {
        owner = msg.sender;
        users[owner].tokens = 100;
    }

    function double(uint256 _value) public pure returns (uint256) {
        return _value * 2;
    }

    function register(string memory _name) public {
        users[msg.sender].name = _name;
    }

    function showTotalEther() public view onlyOwner returns(uint256){
        return address(this).balance;
    }


    function giveToken(address _receiver, uint256 _amount) public onlyOwner {
        require(users[owner].tokens >= _amount);
        users[owner].tokens -= _amount;
        users[_receiver].tokens += _amount;
    }

    function totalCost(uint256 _amount) public view returns(uint256) {
        return _amount * tokenCost;
    }

    function buyToken(uint256 _amount) public payable enoughLeft(_amount) {
        uint256 transactionCost = totalCost(_amount);
        require(msg.value == transactionCost, "Payed quantity was different than expected");
        users[owner].tokens -= _amount;
        users[msg.sender].tokens += _amount;
    }
}
