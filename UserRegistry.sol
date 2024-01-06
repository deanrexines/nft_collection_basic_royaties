// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";


contract UserRegistry is Ownable {
    address[] public users;
    mapping(address => address) public user_collections;

    constructor() {}

    function addUser(address user) external onlyOwner {
        users.push(user);
    }

    function updateCollectionsForUser(address user, address collection) public onlyOwner {
        user_collections[user] = collection;
    }
}
