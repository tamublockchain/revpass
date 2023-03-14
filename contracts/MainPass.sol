// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./ERC4907.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// custom errors - need to document these
error MainPass__AboveMaxSupply();
error MainPass__TransferFailed();

/**
 * @title RevPass - Digital Sports Pass
 * @author Texas A&M Blockchain - tamublock@gmail.com
 * @notice A digital implementation of the Texas A&M Sports Pass based on ERC4907
 * @dev This inherits the custom ERC4907 contract and the Ownable Contract from OpenZeppelin 
 */
contract MainPass is ERC4907, Ownable {
    uint256 public totalSupply;
    uint256 private s_maxSupply;
    string private s_uri;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_
    ) ERC4907(name_, symbol_) Ownable() {
        s_maxSupply = maxSupply_;
    }

    /**
     * @notice mint a singular RevPass 
     * @dev only the owner (deployer) of the contract can send one NFT
     * @param to address of the account receiving the newly-minted token
     */
    function mint(address to) external onlyOwner {
        if (totalSupply > s_maxSupply) {
            revert MainPass__AboveMaxSupply();
        }
        ++totalSupply;
        _mint(to, totalSupply); // use _safeMint instead?
    }

    /**
     * @notice mint and send several at once
     * @dev only owner (deployer) of contract can call
     * @param to array of addresses of the accounts receiving the newly-minted tokens
     */
    function massAirdrop(address[] calldata to) external onlyOwner {
        for (uint256 i = 0; i < to.length; ++i) {
            if (totalSupply > s_maxSupply) {
                revert MainPass__AboveMaxSupply();
            }
            ++totalSupply;
            _mint(to[i], totalSupply); // use _safeMint instead?
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

    //not sure if this is needed
    function maxSupply() public view returns (uint256) {
        return s_maxSupply;
    }

    /**
     * @dev allows the owner to withdraw any Ether held in the contract
     */
    function withdrawETH() public onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        if (!success) {
            revert MainPass__TransferFailed();
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

    receive() external payable {}

    fallback() external payable {}
}

/// Questions and comments to address 
///
///
/// 1. Document the custom errors
/// 2. I dont think we should implement Ownable. Some of the functions can harm contract functionality if used wrong
///        Instead, copy the onlyOwner modifier 
/// 3. UIN for the owner needs to come from the 721 contract. This needs to be implemented
/// 4. Do we need a URI? If not, it can also be removed in the custom 721 ^
/// 5. Change the name to RevPass