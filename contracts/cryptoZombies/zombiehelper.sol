//SPDX-License-Identifier: GPL 3.0
pragma solidity ^0.8.34;

import {ZombieFeeding} from "./zombiefeeding.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ZombieHelper is ZombieFeeding {
    uint256 levelUpFee = 0.001 ether;

    modifier aboveLevel(uint256 _zombieId, uint256 _level) {
        require(zombies[_zombieId].level >= _level);
        _;
    }

    function levelUp(uint256 _zombieId) external payable {
        require(msg.value == levelUpFee);
        zombies[_zombieId].level++;
    }

    function withdraw() external Ownable.onlyOwner {
        address payable _owner = payable(Ownable.owner());
        (bool success,) = _owner.call{value: address(this).balance}("");
        require(success);
    }

    function changeName(uint256 _zombieId, string calldata _newName)
        external
        aboveLevel(_zombieId, 2)
        onlyOwnerOf(_zombieId)
    {
        zombies[_zombieId].name = _newName;
    }

    function changeDna(uint256 _zombieId, uint256 _newDna) external aboveLevel(_zombieId, 20) onlyOwnerOf(_zombieId) {
        zombies[_zombieId].dna = _newDna;
    }

    function getZombiesByOwner(address _owner) external view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](ownerZombieCount[_owner]);
        uint256 counter = 0;
        for (uint256 i = 0; i < zombies.length; i++) {
            if (zombieToOwner[i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }
}
