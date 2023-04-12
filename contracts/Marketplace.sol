// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "./IRevPass.sol";

contract Marketplace is ReentrancyGuard {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    Counters.Counter private _numRevPassListed;
    address private _marketOwner;

    // If multiple collections: mapping(address => mapping(uint256 => Listing)) private _listingMap;
    // maps token id to properties of the rental listing. Assuming there's only the RevPass collection. 
    mapping(uint256 => Listing) private _listingMap;
    // mapping are not iterable. Use EnumerableSet
    EnumerableSet.UintSet private _nftTokensListed;

    struct Listing {
        address owner; // address of token owner
        address user; // address of renter or zero if none
        uint256 ownerUIN;
        uint256 userUIN;
        address nftContract; // address of contract/collection
        uint256 tokenId; // tokenID of the listed NFT within the NFT collection
        uint256 priceToRent; // cost to rent the NFT. Prob a constant since all RevPasses are the same
        uint256 startDateUNIX; // when the nft can start being rented
        uint256 endDateUNIX; // when the nft can no longer be rented
        uint256 expires; // when the user can no longer rent it
        bool isListed;
    }
    event NFTListed(
        address owner,
        address user,
        uint256 ownerUIN,
        uint256 userUIN,
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
        uint256 ownerUIN,
        uint256 userUIN,
        address nftContract,
        uint256 tokenId,
        uint256 rentalFee, // cost to rent NFT
        uint256 startDateUNIX,
        uint256 endDateUNIX,
        uint64 expires
    );
    event NFTUnlisted(
        address unlistSender,
        address nftContract,
        uint256 tokenId,
        uint256 refund // if owner unlists the nft while it's being rented, the owner needs to refund 
    );


    address public nftcontract;
    constructor() {
        _marketOwner = msg.sender;
        nftcontract = 0xd9145CCE52D386f254917e481eB44e9943F39138;
    }

    // function to list NFT for rental
    function privateListNFT(
        address nftContract,
        uint256 tokenId,
        uint256 startDateUNIX,
        uint256 endDateUNIX,
        uint256 expires,
        address user,
        uint256 userUIN
        //uint256 ownerUIN
    ) public payable nonReentrant {
        require(isRentableNFT(nftContract), "Contract is not an ERC4907");
        require(IERC721(nftContract).ownerOf(tokenId) == msg.sender, "Not owner of nft");
        require(startDateUNIX >= block.timestamp, "Start date cannot be in the past");
        require(endDateUNIX >= startDateUNIX, "End date cannot be before the start date");
        require(_listingMap[tokenId].nftContract == address(0), "This NFT has already been listed");

        _listingMap[tokenId] = Listing(
            msg.sender,
            user,
            IRevPass(nftContract).getOwnerUIN(tokenId),
            userUIN,
            nftContract,
            tokenId,
            0,
            startDateUNIX,
            endDateUNIX,
            expires,
            true
        );

        _numRevPassListed.increment();
        EnumerableSet.add(_nftTokensListed, tokenId);
        emit NFTListed(
            IERC721(nftContract).ownerOf(tokenId),
            user,
            IRevPass(nftContract).getOwnerUIN(tokenId),
            userUIN,
            nftContract,
            tokenId,
            0,
            startDateUNIX,
            endDateUNIX,
            expires
        );
    }

        // function to list NFT for rental
    function listNFT(
        address nftContract,
        uint256 tokenId,
        uint256 priceToRent,
        uint256 startDateUNIX,
        uint256 endDateUNIX
        //uint256 ownerUIN
    ) public payable nonReentrant {
        //require owner == user otherwise throw "someone has already rented this"
        //require statment that checks if isListed=True?
        //change isListed to true
        require(_listingMap[tokenId].owner == _listingMap[tokenId].user, "Someone has already rented this pass. You cannot relist");
        require(_listingMap[tokenId].isListed == false, "This has already been listed");
        //require(isRentableNFT(nftContract), "Contract is not an ERC4907");
        require(IERC721(nftContract).ownerOf(tokenId) == msg.sender, "Not owner of nft");
        require(priceToRent > 0, "Rental price should be greater than 0");
        require(startDateUNIX >= block.timestamp, "Start date cannot be in the past");
        require(endDateUNIX >= startDateUNIX, "End date cannot be before the start date");
        require(nftcontract == 0xd9145CCE52D386f254917e481eB44e9943F39138, "You can only list RevPass NFTs");

        _listingMap[tokenId] = Listing(
            msg.sender,
            address(0),
            IRevPass(nftContract).getOwnerUIN(tokenId),
            0,
            nftContract,
            tokenId,
            priceToRent,
            startDateUNIX,
            endDateUNIX,
            0,
            true
        );

        _numRevPassListed.increment();
        EnumerableSet.add(_nftTokensListed, tokenId);
        emit NFTListed(
            IERC721(nftContract).ownerOf(tokenId),
            address(0),
            IRevPass(nftContract).getOwnerUIN(tokenId),
            0,
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
        uint64 expires,
        uint256 userUIN
    ) public payable nonReentrant {
        Listing storage listing = _listingMap[tokenId];
        require(listing.user == address(0), "NFT already rented");
        require(expires <= listing.endDateUNIX, "Rental period exceeds max date rentable");
        // Transfer rental fee
        uint256 rentalFee = listing.priceToRent;
        require(msg.value >= rentalFee, "Not enough ether to cover rental period");
        payable(listing.owner).transfer(rentalFee);
        // Update listing
        IRevPass(nftContract).setUser(tokenId, msg.sender, expires, userUIN);
        listing.user = msg.sender;
        listing.expires = expires;
        listing.isListed = false;
        emit NFTRented(
            IERC721(nftContract).ownerOf(tokenId),
            msg.sender,
            IRevPass(nftContract).getUserUIN(tokenId),
            userUIN,
            nftContract,
            tokenId,
            rentalFee,
            listing.startDateUNIX,
            listing.endDateUNIX,
            expires
        );
    }

    // function to unlist your rental, refunding the user for any lost time
    function unlistNFT(address nftContract, uint256 tokenId) public payable nonReentrant {
        Listing storage listing = _listingMap[tokenId];
        require(listing.owner != address(0), "This NFT is not listed");
        require(listing.owner == msg.sender || _marketOwner == msg.sender , "Not approved to unlist NFT");
        require(listing.user == address(0), "This NFT is not rented");
        // fee to be returned to user if unlisted before rental period is up
        uint256 refund = listing.priceToRent;
        // need to write some tests. I think priceToRent is 0 if rent period expires. Or handle case where listing.user is address(0)
        require(msg.value >= refund, "Not enough ether to cover refund");
        payable(listing.user).transfer(refund);
        // clean up data
        IRevPass(nftContract).setUser(tokenId, address(0), 0, 0);
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
        try IERC165(nftContract).supportsInterface(type(IRevPass).interfaceId) returns (bool rentable) {
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