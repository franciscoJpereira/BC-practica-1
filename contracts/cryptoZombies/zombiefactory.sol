//SPDX-License-Identifier: GPL 3.0
pragma solidity ^0.8.34;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ZombieFactory is Ownable{


    constructor() Ownable(msg.sender) {

    }

    // declara nuestro evento aquí
    event NewZombie(uint zombieId, string name, uint dna);

    uint dnaDigits = 16;
    uint dnaModulus = 10 ** dnaDigits;
    uint cooldownTime = 1 days;

    struct Zombie {
        string name;
        uint dna;
        uint32 level;
        uint32 readyTime;
    }

    Zombie[] zombies;

    mapping (uint => address) public zombieToOwner;
    mapping (address => uint) ownerZombieCount;


    function _createZombie(string memory _name, uint _dna) internal {
        
        zombies.push(Zombie(_name, _dna, 1, uint32(block.timestamp + 1 days)));
        uint id = zombies.length - 1;
        zombieToOwner[id] = msg.sender;
        ownerZombieCount[msg.sender]++;
        emit NewZombie(id, _name, _dna);
    }

    function _generateRandomDna(string calldata _str) private view returns (uint) {
        uint rand = uint(keccak256(abi.encodePacked(_str)));
        return rand % dnaModulus;
    }

    function createRandomZombie(string calldata _name) public {
        uint randDna = _generateRandomDna(_name);
        _createZombie(_name, randDna);
    }

}