// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./ERC4907.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error MainPass__AboveMaxSupply();
error MainPass__TransferFailed();

/* testing pull/commit */
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
     * @dev only the owner (deployer) of the contract can mint non-fungible tokens
     */
    function mint(address to) external onlyOwner {
        if (totalSupply > s_maxSupply) {
            revert MainPass__AboveMaxSupply();
        }
        ++totalSupply;
        _mint(to, totalSupply);
    }

    function massAirdrop(address[] calldata to) external onlyOwner {
        for (uint256 i = 0; i < to.length; ++i) {
            if (totalSupply > s_maxSupply) {
                revert MainPass__AboveMaxSupply();
            }
            ++totalSupply;
            _mint(to[i], totalSupply);
        }
    }

    function setBaseUri(string calldata uri) external onlyOwner {
        s_uri = uri;
    }

    function maxSupply() public view returns (uint256) {
        return s_maxSupply;
    }

    function withdrawETH() public onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        if (!success) {
            revert MainPass__TransferFailed();
        }
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(s_uri, Strings.toString(_tokenId), ".json"));
    }

    receive() external payable {}

    fallback() external payable {}
}
