//SPDX-License-Identifier: GPL 3.0
pragma solidity ^0.8.34;

import {ZombieFeeding} from "./zombiefeeding.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ZombieHelper is ZombieFeeding {

    uint levelUpFee = 0.001 ether;

    modifier aboveLevel(uint _zombieId, uint _level) {
        require(zombies[_zombieId].level >= _level);
        _;
    }

    function levelUp(uint _zombieId) external payable {
        require(msg.value == levelUpFee);
        zombies[_zombieId].level++;
    }

    function withdraw() external Ownable.onlyOwner {
        address payable _owner = payable(Ownable.owner());
        (bool success, ) = _owner.call{value: address(this).balance}("");
        require(success);
    }

    function changeName(uint _zombieId, string calldata _newName) external aboveLevel(_zombieId, 2) onlyOwnerOf(_zombieId) {
        zombies[_zombieId].name = _newName;
    }

    function changeDna(uint _zombieId, uint _newDna) external aboveLevel(_zombieId, 20) onlyOwnerOf(_zombieId) {
        zombies[_zombieId].dna = _newDna;
    }

    function getZombiesByOwner(address _owner) external view returns(uint[] memory) {
        uint[] memory result = new uint[](ownerZombieCount[_owner]);
        uint counter = 0;
        for (uint i = 0; i < zombies.length; i++) {
            if (zombieToOwner[i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

}
