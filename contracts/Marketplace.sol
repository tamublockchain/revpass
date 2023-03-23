// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "./IERC4907.sol";

contract Marketplace is ReentrancyGuard {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    Counters.Counter private _numRevPassListed;
    address private _marketOwner;
    uint256 private _listingFee = .0001 ether; // cost to list a RevPass onto the marketplace

    // If multiple collections: mapping(address => mapping(uint256 => Listing)) private _listingMap;
    // maps token id to properties of the rental listing. Assuming there's only the RevPass collection. 
    mapping(uint256 => Listing) private _listingMap;
    // mapping are not iterable. Use EnumerableSet
    EnumerableSet.UintSet private _nftTokensListed;

    struct Listing {
        address owner; // address of token owner
        address user; // address of renter or zero if none
        address nftContract; // address of contract/collection
        uint256 tokenId; // tokenID of the listed NFT within the NFT collection
        uint256 priceToRent; // cost to rent the NFT. Prob a constant since all RevPasses are the same
        uint256 startDateUNIX; // when the nft can start being rented
        uint256 endDateUNIX; // when the nft can no longer be rented
        uint256 expires; // when the user can no longer rent it
    }
    event NFTListed(
        address owner,
        address user,
        address nftContract,
        uint256 tokenId,
        uint256 priceToRent,
        uint256 startDateUNIX,
        uint256 endDateUNIX,
        uint256 expires
    );
    event NFTRented(
        address owner,
        address user,
        address nftContract,
        uint256 tokenId,
        uint256 startDateUNIX,
        uint256 endDateUNIX,
        uint64 expires,
        uint256 rentalFee // cost to rent NFT
    );
    event NFTUnlisted(
        address unlistSender,
        address nftContract,
        uint256 tokenId,
        uint256 refund // if owner unlists the nft while it's being rented, the owner needs to refund 
    );


    constructor() public {
        _marketOwner = msg.sender;
    }

    // function to list NFT for rental
    function listNFT(
        address nftContract,
        uint256 tokenId,
        uint256 priceToRent,
        uint256 startDateUNIX,
        uint256 endDateUNIX
    ) public payable nonReentrant {
        require(isRentableNFT(nftContract), "Contract is not an ERC4907");
        require(IERC721(nftContract).ownerOf(tokenId) == msg.sender, "Not owner of nft");
        require(msg.value == _listingFee, "Not enough ether for listing fee");
        require(priceToRent > 0, "Rental price should be greater than 0");
        require(startDateUNIX >= block.timestamp, "Start date cannot be in the past");
        require(endDateUNIX >= startDateUNIX, "End date cannot be before the start date");
        require(_listingMap[tokenId].nftContract == address(0), "This NFT has already been listed");

        payable(_marketOwner).transfer(_listingFee);
        _listingMap[tokenId] = Listing(
            msg.sender,
            address(0),
            nftContract,
            tokenId,
            priceToRent,
            startDateUNIX,
            endDateUNIX,
            0
        );

        _numRevPassListed.increment();
        EnumerableSet.add(_nftTokensListed, tokenId);
        emit NFTListed(
            IERC721(nftContract).ownerOf(tokenId),
            address(0),
            nftContract,
            tokenId,
            priceToRent,
            startDateUNIX,
            endDateUNIX,
            0
        );
    }

    // function to rent an NFT
    function rentNFT(
        address nftContract,
        uint256 tokenId,
        uint64 expires
    ) public payable nonReentrant {
        Listing storage listing = _listingMap[tokenId];
        require(listing.user == address(0), "NFT already rented");
        require(expires <= listing.endDateUNIX, "Rental period exceeds max date rentable");
        // Transfer rental fee
        uint256 rentalFee = listing.priceToRent;
        require(msg.value >= rentalFee, "Not enough ether to cover rental period");
        payable(listing.owner).transfer(rentalFee);
        // Update listing
        IERC4907(nftContract).setUser(tokenId, msg.sender, expires);
        listing.user = msg.sender;
        listing.expires = expires;

        // TODO: Maybe take the RevPass off the marketplace after it has been rented? 
        emit NFTRented(
            IERC721(nftContract).ownerOf(tokenId),
            msg.sender,
            nftContract,
            tokenId,
            listing.startDateUNIX,
            listing.endDateUNIX,
            expires,
            rentalFee
        );
    }

    // function to unlist your rental, refunding the user for any lost time
    function unlistNFT(address nftContract, uint256 tokenId) public payable nonReentrant {
        Listing storage listing = _listingMap[tokenId];
        require(listing.owner != address(0), "This NFT is not listed");
        require(listing.owner == msg.sender || _marketOwner == msg.sender , "Not approved to unlist NFT");
        // fee to be returned to user if unlisted before rental period is up
        uint256 refund = listing.priceToRent;
        // need to write some tests. I think priceToRent is 0 if rent period expires. Or handle case where listing.user is address(0)
        require(msg.value >= refund, "Not enough ether to cover refund");
        payable(listing.user).transfer(refund);
        // clean up data
        IERC4907(nftContract).setUser(tokenId, address(0), 0);
        EnumerableSet.remove(_nftTokensListed, tokenId);
        delete _listingMap[tokenId];
        _numRevPassListed.decrement();

        emit NFTUnlisted(
            msg.sender,
            nftContract,
            tokenId,
            refund
        );
    }

    /* 
    * function to get all listings
    *
    * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
    * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
    * this function has an unbounded cost, and using it as part of a state-changing function may render the function
    * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
    */
    function getAllListings() public view returns (Listing[] memory) {
        Listing[] memory listings = new Listing[](_numRevPassListed.current());
        uint256[] memory tokens = EnumerableSet.values(_nftTokensListed);
        uint256 listingsIndex = 0;
        for (uint j = 0; j < tokens.length; j++) {
            listings[listingsIndex] = _listingMap[tokens[j]];
            listingsIndex++;
        }
        return listings;
    }


    function isRentableNFT(address nftContract) public view returns (bool) {
        bool _isRentable = false;
        bool _isNFT = false;
        try IERC165(nftContract).supportsInterface(type(IERC4907).interfaceId) returns (bool rentable) {
            _isRentable = rentable;
        } catch {
            return false;
        }
        try IERC165(nftContract).supportsInterface(type(IERC721).interfaceId) returns (bool nft) {
            _isNFT = nft;
        } catch {
            return false;
        }
        return _isRentable && _isNFT;
    }
}