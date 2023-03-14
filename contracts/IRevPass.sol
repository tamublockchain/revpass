// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IRevPass {
    // Logged when the user of a token assigns a new user or updates expires
    /// @notice Emitted when the `user` of an NFT or the `expires` of the `user` is changed
    /// The zero address for user indicates that there is no user address
    event UpdateUser(uint256 indexed tokenId, address indexed user, uint64 expires);

    /// @notice Get the user address of an NFT
    /// @dev The zero address indicates that there is no user or the user is expired
    /// @param tokenId The NFT to get the user address for
    /// @return The user address for this NFT
    function userOf(uint256 tokenId) external view returns (address);

    /// @notice Get the user expires of an NFT
    /// @dev The zero value indicates that there is no user
    /// @param tokenId The NFT to get the user expires for
    /// @return The user expires for this NFT
    function userExpires(uint256 tokenId) external view returns (uint256);

    /**
     * @notice Set a user (renter) and an expiry date for RevPass and user UIN
     * @dev The zero address indicates there is no user
     * will revert if not an owner nor approved (setUser())
     * @param tokenId The unique id of RevPass
     * @param user The temporary user (renter) of RevPass
     * @param expires UNIX timestamp of when user access expires
     * @param _userUIN UIN of the user to be set
     */
    function setUser(uint256 tokenId, address user, uint64 expires, uint256 _userUIN) external;

    /**
     * @notice Changes owner UIN
     * @dev callable through onlyOwner (Texas A&M)
     * @param tokenId token id
     * @param newOwnerUIN UIN of the owner
     */
    function changeOwnerUIN(uint256 tokenId, uint256 newOwnerUIN) external;

    /**
     * @notice Get the owner UIN of tokenId
     * @param tokenId The unique id of RevPass
     * @return ownerUIN
     */
    function getOwnerUIN(uint256 tokenId) external view returns (uint256);

    /**
     * @notice Get the owner UIN of tokenId
     * @dev Zero indicates there is no user
     * @param tokenId The unique id of RevPass
     * @return userUIN
     */
    function getUserUIN(uint256 tokenId) external view returns (uint256);
}
