//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./Shincha.sol";

contract ShinchaFactory is
    UUPSUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable
{
    // Constants
    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 private constant WITHDRAWER = keccak256("WITHDRAWER");

    // Storages
    Shincha private _shincha;
    bytes32 private _root;
    mapping(address => uint256) private lastBlockNumberCalled;
    uint256 private _claimedCount;
    mapping(address => bool) public claimed;

    function initialize(address shincha_) public initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
        __Pausable_init_unchained();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(ADMIN_ROLE, _msgSender());

        _shincha = Shincha(shincha_);
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() external onlyRole(ADMIN_ROLE) whenNotPaused {
        _pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() external onlyRole(ADMIN_ROLE) whenPaused {
        _unpause();
    }

    function setRoot(bytes32 root_) external onlyRole(ADMIN_ROLE) {
        _root = root_;
    }

    function root() external view returns (bytes32) {
        return _root;
    }

    function claim(
        bytes32[] calldata _merkleProof
    ) external whenNotPaused returns (uint256) {
        require(!claimed[_msgSender()], "already claimed");
        require(_checkValidity(_merkleProof), "invalid proof");

        claimed[_msgSender()] = true;
        _claimedCount += 1;

        return _shincha.safeMint(_msgSender());
    }

    function _checkValidity(
        bytes32[] calldata _merkleProof
    ) internal view returns (bool) {
        bytes32 leafToCheck = keccak256(abi.encodePacked(_msgSender()));
        return MerkleProof.verify(_merkleProof, _root, leafToCheck);
    }

    //////////////
    /// Modifiers
    //////////////
    function _authorizeUpgrade(
        address
    ) internal override onlyRole(ADMIN_ROLE) {}
}
