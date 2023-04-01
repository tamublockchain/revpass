// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./ERC4907.sol";

// custom errors - need to document these
error RevPass__AboveMaxSupply();
error RevPass__TransferFailed();

/**
 * @title RevPass - Digital Sports Pass
 * @author Texas A&M Blockchain - tamublock@gmail.com
 * @notice A digital implementation of the Texas A&M Sports Pass based on ERC4907 and ERC721
 */
contract RevPass is ERC4907 {
    struct UINData {
        uint256 ownerUIN;
        uint256 userUIN;
    }

    mapping(uint256 => UINData) private dataUIN;

    uint256 public totalSupply;
    uint256 private s_maxSupply;
    string private s_uri;
    address private _owner;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_
    ) ERC4907(name_, symbol_) {
        s_maxSupply = maxSupply_;
        _owner = msg.sender;
    }

    /**
     * @notice mint a singular RevPass
     * @dev only the owner (deployer) of the contract can send one NFT
     * @param to address of the account receiving the newly-minted token
     */
    function mint(address to, uint256 ownerUIN) external onlyOwner {
        if (totalSupply > s_maxSupply) {
            revert RevPass__AboveMaxSupply();
        }
        ++totalSupply;
        setOwnerUIN(totalSupply, ownerUIN);
        _mint(to, totalSupply);
    }

    /**
     * @notice mint and send several at once
     * @dev only owner (deployer) of contract can call
     * @param to array of addresses of the accounts receiving the newly-minted tokens
     */
    function massAirdrop(address[] calldata to, uint256[] calldata ownerUIN) external onlyOwner {
        for (uint256 i = 0; i < to.length; ++i) {
            if (totalSupply > s_maxSupply) {
                revert RevPass__AboveMaxSupply();
            }
            ++totalSupply;
            setOwnerUIN(totalSupply, ownerUIN[i]);
            _mint(to[i], totalSupply);
        }
    }

    /**
     * @notice set base token metadata URI
     * @dev allows the owner to set the base URI for the token metadata
     * @param uri string representing the new base URI
     */
    function setBaseUri(string calldata uri) external onlyOwner {
        s_uri = uri;
    }

    /**
     * @notice sets the maximum supply of the tokens to avoid
     * over-allocation by mistake during the season
     */
    function maxSupply() public view returns (uint256) {
        return s_maxSupply;
    }

    /**
     * @dev allows the owner to withdraw any Ether held in the contract
     */
    function withdrawETH() public onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        if (!success) {
            revert RevPass__TransferFailed();
        }
    }

    /**
     * @notice generates a uri for a token
     * @param _tokenId uint256 ID of the token to query
     * @return json style uri consisting of the uri and tokenId
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(s_uri, Strings.toString(_tokenId), ".json"));
    }

    /**
     * @notice Set a user (renter) and an expiry date for RevPass and user UIN
     * @dev The zero address indicates there is no user
     * will revert if not an owner nor approved (setUser())
     * @param tokenId The unique id of RevPass
     * @param user The temporary user (renter) of RevPass
     * @param expires UNIX timestamp of when user access expires
     * @param _userUIN UIN of the user to be set
     */
    function setUser(uint256 tokenId, address user, uint64 expires, uint256 _userUIN) external {
        setUser(tokenId, user, expires);
        UINData storage data = dataUIN[tokenId];
        data.userUIN = _userUIN;
    }

    /**
     * @notice Sets owner UIN
     * @dev callable only from mint functions
     * @param tokenId token id
     * @param _ownerUIN UIN of the owner
     */
    function setOwnerUIN(uint256 tokenId, uint256 _ownerUIN) private {
        UINData storage data = dataUIN[tokenId];
        data.ownerUIN = _ownerUIN;
    }

    /**
     * @notice Changes owner UIN
     * @dev callable through onlyOwner (Texas A&M)
     * @param tokenId token id
     * @param newOwnerUIN UIN of the owner
     */
    function changeOwnerUIN(uint256 tokenId, uint256 newOwnerUIN) external onlyOwner {
        UINData storage data = dataUIN[tokenId];
        data.ownerUIN = newOwnerUIN;
    }

    /**
     * @notice Get the owner UIN of tokenId
     * @param tokenId The unique id of RevPass
     * @return ownerUIN
     */
    function getOwnerUIN(uint256 tokenId) public view returns (uint256) {
        return dataUIN[tokenId].ownerUIN;
    }

    /**
     * @notice Get the owner UIN of tokenId
     * @dev Zero indicates there is no user
     * @param tokenId The unique id of RevPass
     * @return userUIN
     */
    function getUserUIN(uint256 tokenId) public view returns (uint256) {
        if (block.timestamp <= uint256(_users[tokenId].expires)) {
            return dataUIN[tokenId].userUIN;
        } else {
            return getOwnerUIN(tokenId);
        }
    }

    /**
     * @notice Get the user (renter) address of an NFT
     * @dev The zero address indicates that there is no user or the user (renter) is expired
     * @param tokenId The unique id of RevPass
     * @return The user (renter) address for this NFT
     */
    function userOf(uint256 tokenId) public view override returns (address) {
        if (block.timestamp <= uint256(_users[tokenId].expires)) {
            return _users[tokenId].user;
        } else {
            return ownerOf(tokenId);
        }
    }

    receive() external payable {}

    fallback() external payable {}

    //Access Control

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }
}
