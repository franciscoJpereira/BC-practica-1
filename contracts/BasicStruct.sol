//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.30;

contract StructGen {
    struct Person {
        string name;
        uint8 age;
    }
    Person owner = Person("Francisco", 27);

    Person[] public participants;

    function getOwner() public view returns (string memory) {
        return owner.name;
    }

    function getOwnerAge() public view returns (uint8) {
        return owner.age;
    }

    function addMe(string calldata name, uint8 age) public {
        participants.push(Person(name, age));
    }

    function checkMe(string calldata name) public view returns (bool) {
        bytes32 encName = keccak256(bytes(name));
        for (uint32 i = 0; i < participants.length; i++) {
            if (keccak256(bytes(participants[i].name)) == encName) {
                return true;
            }
        }
        return false;
    }
}
