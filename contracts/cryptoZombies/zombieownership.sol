//SPDX-License-Identifier: GPL 3.0
pragma solidity ^0.8.35;

import {ZombieBattle} from "./zombiebattle.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/*
@title Contrato para un juego de zombies
@author Francisco Pereira
@Dev implementa el token ERC721 para la transferencia de zombies
dentro del entorno del juego.
*/
contract ZombieOwnership is ZombieBattle, ERC721 {

    constructor() ERC721("CryptoZombies", "CRZB") {}

    mapping (uint => address) zombieApprovals;

    function balanceOf(address _owner) public view override(ERC721) returns (uint256 _balance) {
        return ownerZombieCount[_owner];
    }

    function _ownerOf(uint256 _tokenId) internal view override(ERC721) returns(address _owner) {
        return zombieToOwner[_tokenId];
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal override(ERC721) {
        ownerZombieCount[_to]++;
        ownerZombieCount[_from]--;
        zombieToOwner[_tokenId] = _to;
        emit Transfer(_from, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public override(ERC721) {
        require(zombieToOwner[_tokenId] == msg.sender || zombieApprovals[_tokenId] == msg.sender);
        _transfer(_from, _to, _tokenId);
    }

    function approve(address _to, uint256 _tokenId) public override(ERC721) onlyOwnerOf(_tokenId) {
        zombieApprovals[_tokenId] = _to;
        emit Approval(msg.sender, _to, _tokenId);
    }

}
