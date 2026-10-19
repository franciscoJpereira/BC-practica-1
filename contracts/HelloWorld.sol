//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.30;

contract HelloWorld {
    string public greet = "Hello World!";

    function getTimestamp() public view returns(uint256) {
        return block.timestamp;
    }
}
