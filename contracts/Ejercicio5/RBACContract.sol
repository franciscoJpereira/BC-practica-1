//SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract RBACContract is ERC1155 {

    using EnumerableSet for EnumerableSet.UintSet;

    uint256 ADMIN_ROLE = 0;
    //Role does exist
    mapping(uint256 => bool) public roles;
    //Role assignation approvals
    mapping(uint256 => EnumerableSet.UintSet) rApprovals;
    uint256[] public existingRoles;

    constructor(string memory _uri) ERC1155(_uri) {
        _mint(msg.sender, ADMIN_ROLE, 1, "");
        roles[ADMIN_ROLE] = true;
        rApprovals[ADMIN_ROLE].add(ADMIN_ROLE);
    }

    modifier roleExists(uint256 _roleId) {
        require(roles[_roleId], "Role does not exist");
        _;
    }

    //Checks if role _from can assign role _to
    modifier canAssign(uint256 _from, uint256 _to) {
        require(rApprovals[_to].contains(_from), "Role can't be assigned using the given role");
        _;
    }

    //Verifies the sender has the admin role
    modifier onlyAdmin() {
        require(hasRole(msg.sender, ADMIN_ROLE), "User is not an admin");
        _;
    }

    function hasRole(address _user, uint256 _roleId) public view roleExists(_roleId) returns(bool) {
        return balanceOf(_user, _roleId) > 0;
    }

    function createRole(uint256 _roleId) public onlyAdmin {
        require(!roles[_roleId], "Role already exists");
        roles[_roleId] = true;
        rApprovals[_roleId].add(ADMIN_ROLE);
    }

    function assignApproval(uint256 _from, uint256 _to) public  onlyAdmin {
        rApprovals[_to].add(_from);
    }

    function removeApproval(uint256 _from, uint256 _to) public  roleExists(_from) roleExists(_to) onlyAdmin {
        rApprovals[_to].remove(_from);
    }

    function assignRole(address _to, uint256 _usedRole, uint256 _roleId) public canAssign(_usedRole, _roleId) {
        require(hasRole(msg.sender, _usedRole), "Assigner does not have the specified role");
        require(!hasRole(_to, _roleId), "User already has role");
        _mint(_to, _roleId, 1, "");
    }

    //Checks if msg.sender has any of the given roles
    function hasRoles(uint256[] calldata _roles) public view returns(uint256[] memory) {
        address[] memory user = new address[](_roles.length);
        for (uint256 i = 0; i < _roles.length; i++) {
            user[i] = msg.sender;
        }
        return balanceOfBatch(user, _roles);
    }

    //Returns the roles allowed to assign another role
    function getApprovalsFor(uint256 _roleId) public view roleExists(_roleId) returns(uint256[] memory){
        return rApprovals[_roleId].values();
    }

    function removeRoleApproval(address _to, uint256 _usedRole, uint256 _roleId) public canAssign(_usedRole, _roleId)  {
        require(hasRole(_to, _roleId), "User does not have role");
        _burn(_to, _roleId, 1);
    }

}
