// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";

contract Shincha is AccessControl, ERC721Royalty {
    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint96 private constant ROYALTY_PERCENTAGE = 500;

    string public baseURI;
    uint256 private _totalSupply;

    constructor(
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_) {
        _setDefaultRoyalty(msg.sender, ROYALTY_PERCENTAGE);
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /// @notice public function for admin set base URI for NFT token.
    function setBaseURI(string memory _uri) external onlyRole(ADMIN_ROLE) {
        baseURI = _uri;
    }

    function safeMint(
        address to
    ) external onlyRole(MINTER_ROLE) returns (uint256 nftId) {
        nftId = _totalSupply + 1;
        _safeMint(to, nftId);
        _totalSupply += 1;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    // @dev See {IERC165-supportsInterface}.
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721Royalty, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
