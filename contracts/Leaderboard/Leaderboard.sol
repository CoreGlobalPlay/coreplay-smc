// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract Leaderboard is AccessControlUpgradeable, UUPSUpgradeable {
    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 private constant GAME_ROLE = keccak256("GAME_ROLE");

    //////////////
    /// Storage
    //////////////
    mapping(address => uint256) points;

    //////////////
    /// Events
    //////////////
    event NewPoint(
        uint256 gameId,
        address user,
        uint256 earnAmount,
        uint256 betAmount
    );

    //////////////
    /// Constructor
    //////////////
    function initialize() public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(GAME_ROLE, msg.sender);
    }

    function newPoint(
        uint256 gameId,
        address user,
        uint256 earnAmount,
        uint256 betAmount
    ) public onlyRole(GAME_ROLE) {
        emit NewPoint(gameId, user, earnAmount, betAmount);
    }

    function _authorizeUpgrade(
        address _newImplementation
    ) internal override onlyRole(ADMIN_ROLE) {}
}
