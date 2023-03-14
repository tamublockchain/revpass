// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./IERC4907.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @title ERC4907 Rentable NFT specifications based on EIP4907
 * @author Texas A&M Blockchain - tamublock@gmail.com
 * @notice A custom ERC4907 contract based on the Texas A&M Sports Pass
 * @dev This inherits the ERC721 and the IERC4907 standards 
 */
contract ERC4907 is ERC721, IERC4907 {
    //We need to include the following data in this nft
    //not sure how much of it will/can be on/off chain
    /** 
     * nftID - identifier that connects UIN on TAMU side
     * ownerUIN - UIN of owner that is set when NFT is sent
     * ownerAddr - address of owner wallet
     * userAddr - address of user
     * userUIN - UIN of user that is set at 
     * expiryDate - unix timestamp of expiry date
    */
    struct UserInfo {
        address user; // address of user role
        uint64 expires; // unix timestamp, user expires
    }

    //list of all NFTs minted. why is this needed?
    //probably add this to main pass
    mapping(uint256 => UserInfo) internal _users;

    //not sure about this one
    //i dont think this constructor is needed. Symbol and name should be constants
    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    /**
     * @notice Set a user (renter) and an expiry date for RevPass
     * @dev The zero address indicates there is no user
     * @param tokenId The unique id of RevPass
     * @param user The temporary user (renter) of RevPass
     * @param expires UNIX timestamp of when user access expires
     */
    function setUser(uint256 tokenId, address user, uint64 expires) public virtual {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        UserInfo storage info = _users[tokenId];
        info.user = user;
        info.expires = expires;
        emit UpdateUser(tokenId, user, expires);
    }

    /**
     * @notice Get the user (renter) address of an NFT
     * @dev The zero address indicates that there is no user or the user (renter) is expired
     * @param tokenId The unique id of RevPass
     * @return The user (renter) address for this NFT
     */
    function userOf(uint256 tokenId) public view virtual returns (address) {
        if (block.timestamp <= uint256(_users[tokenId].expires)) {
            return _users[tokenId].user;
        } else {
            return address(0);
        }
    }

    /**
     * @notice Get the expiry date for a RevPass
     * @dev The zero value indicates that there is no user
     * @param tokenId The unique id of RevPass 
     * @return The expiry date of the user (renter)
     */
    function userExpires(uint256 tokenId) public view virtual returns (uint256) {
        return _users[tokenId].expires;
    }

    /**
     * @notice Checking to see if this contract supports the 4907 interface
     * @dev See {IERC165-supportsInterface} for more details
     * @param interfaceId The interface ID of 4907
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC4907).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Hook function called by the ERC1155 token contract before a batch of tokens is transferred from one address to another.
     * @param from The address from which the tokens are being transferred.
     * @param to The address to which the tokens are being transferred.
     * @param tokenId The ID of the token being transferred.
     * @param batchSize The number of tokens being transferred.
     * Emits an `UpdateUser` event if the user record associated with the `tokenId` is deleted due to the transfer.
     * Requirements:
     * - This function must be called from within the ERC1155 token contract.
     * - The `_users` mapping must contain a user record for the given `tokenId`.
     * - If `from` and `to` are the same address, no user record should be deleted.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override {
        // Call the parent implementation of this function to ensure any necessary checks are performed.
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    
        // If the token is being transferred to a different address and has a user record, delete the user record.
        if (from != to && _users[tokenId].user != address(0)) {
            delete _users[tokenId];
            // Emit event from IERC4907 indicating that the user record has been updated to reflect the transfer.
            emit UpdateUser(tokenId, address(0), 0);
        }
    }
}

/// Questions and comments to address 
///
///
/// 1. See notes in UserInfo struct
/// 2. What is the purpose of the mapping? Do we need that in this contract?
/// 3. I don't think the constuctor is needed. It will be a constant 
/// 4. Should we change user -> renter for clarity on our end. 2 actors: a `renter` and an `owner`