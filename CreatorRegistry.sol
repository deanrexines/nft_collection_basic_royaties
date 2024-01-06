// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";


contract CreatorRegistry is Ownable {
    Creator[] public creators;
    mapping(address => Collection[]) public creator_collections;

    enum CreatorType { VISUAL, AUDIO }

    struct Creator {
        address creator_address;
        string creator_name;
        CreatorType creator_type;
    }

    struct Collection {
        uint256 id;
        address collection_address;
        uint256 max_supply;
        uint128 mint_price;
        string title;
        string description;
        string thumbnail_url;
    }

    constructor() {}

    function addCreator(bytes calldata creator) external onlyOwner {
        (
            string memory _creator_name,
            string memory _creator_type_str,
            address _creator_address
        ) = abi.decode(creator, (string, string, address));

        CreatorType _creator_type = (keccak256(abi.encodePacked(_creator_type_str)) == keccak256(abi.encodePacked("VISUAL"))) 
                                        ? CreatorType.VISUAL : CreatorType.AUDIO;
        
        creators.push(Creator({
            creator_name: _creator_name,
            creator_type: _creator_type,
            creator_address: _creator_address
        }));
    }

    function updateCollectionsForCreator(address creator, bytes calldata collection) public onlyOwner {
        (
            uint256 _id,
            address _collection_address,
            uint256 _max_supply,
            uint128 _mint_price,
            string memory _title,
            string memory _description,
            string memory _thumbnail_url
        ) = abi.decode(collection, (uint256, address, uint256, uint128, string, string, string));

        creator_collections[creator].push(Collection({
            id: _id,
            collection_address: _collection_address,
            max_supply: _max_supply,
            mint_price: _mint_price,
            title: _title,
            description: _description,
            thumbnail_url: _thumbnail_url
        }));
    }
}
