// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC721C.sol";
import "./BasicRoyalties.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./CreatorRewardsEscrowManager.sol";
import "./MashCollectionMediaMetadata.sol";
import "./PayoutUtils.sol";
import "./UserRegistry.sol";


contract MashCollection is ERC721C, BasicRoyalties, Ownable, Pausable
{
    uint16 MASH_FEE = 10;
    uint32 private _token_counter;
    uint128 public mint_price;
    uint256 public max_supply;
    string public baseURI;

    address public immutable _this = address(this);
    address payable public immutable _mash_treasury_wallet = payable(0x2B6C4eFA4e6BDA96fcd0EE321e72E886256c3a2A); //arbitrary address for sample purposes
    address public immutable _user_registry = 0x2B6C4eFA4e6BDA96fcd0EE321e72E886256c3a2A; //arbitrary address for sample purposes
    address public immutable _creator_escrow;
    address public immutable _media_metadata;

    event Mint(address _from, uint256 tokenId, address collection);

    constructor(
        string memory _name,
        uint128 _mint_price,
        uint256 _max_supply,
        string memory _baseURI,
        address[] memory _payees, 
        uint256[] memory _shares,
        address royalty_receiver,
        uint96 royalty_fee_numerator
    )
        ERC721(_name, "MashCollection")
        BasicRoyalties(royalty_receiver, royalty_fee_numerator)
    {
            max_supply = _max_supply;
            mint_price = _mint_price;
            _token_counter = 0;
            baseURI = _baseURI;

            require(_payees.length == 1 && _shares.length == 1, "Solo artist royalties only");
            CreatorRewardsEscrowManager escrow_manager = new CreatorRewardsEscrowManager(_payees, _shares); 
            _creator_escrow = address(payable(escrow_manager));

            MashCollectionMediaMetadata mediaMetadata = new MashCollectionMediaMetadata(); 
            _media_metadata = address(mediaMetadata);

            setToDefaultSecurityPolicy();
    }

    function mint(address _to) external payable whenNotPaused {
        require(msg.value >= mint_price, "Not enough ETH sent; check price!");
        require(_token_counter + 1 <= max_supply);

        _safeMint(_to, _token_counter); 

        emit Mint(_to, _token_counter, _this);

        ++_token_counter;

        UserRegistry(_user_registry).updateCollectionsForUser(_to, _this);

        uint mash_platform_fee = PayoutUtils.getMintPayout(msg.value, MASH_FEE);
        _pay_creators(msg.value - mash_platform_fee);
        _process_mash_platform_fee(mash_platform_fee);
    }

    function burn(uint256 tokenId) external {
        require(msg.sender == ownerOf(tokenId), "Only owner of token can burn");
        _burn(tokenId);
    }

    function _process_mash_platform_fee(uint total_payout) private {
        (bool sent, ) = _mash_treasury_wallet.call{value: total_payout}("");
        require(sent, "Failed to send Ether");
    }

    function _pay_creators(uint total_payout) private {
        (bool sent, ) = _creator_escrow.call{value: total_payout}("");
        require(sent, "Failed to send Ether");
    }

    function _requireCallerIsContractOwner() internal view virtual override {
        _checkOwner();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721C, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    uint256[48] private __gap;
}
