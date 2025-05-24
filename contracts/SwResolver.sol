//SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Structs} from "@switchboard-xyz/on-demand-solidity/structs/Structs.sol";
import {ISwitchboard} from "@switchboard-xyz/on-demand-solidity/ISwitchboard.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

abstract contract SwResolver is Initializable, AccessControlUpgradeable {
    // Contants
    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Storages
    address private _switchboard;
    bytes32 public queue;
    uint256 public sequence;
    uint256 public solvedSeq;
    mapping(uint256 => uint256) public seq2GameId;
    bool public vrfEnable;

    // Events
    event RandomRequested(uint256 sequence);

    // https://docs.switchboard.xyz/product-documentation/randomness/tutorials/evm
    function setupResolver(address switchboard_, bytes32 swQueue_) internal initializer {
        queue = swQueue_;
        _switchboard = switchboard_;
    }

    function requestRandomNumber(uint256 gameId) internal {
        if (!vrfEnable) {
            handleRandomNumber(gameId, uint256(
                keccak256(abi.encodePacked(block.number, gameId, msg.sender))
            ));
            return;
        }
        require(seq2GameId[gameId] == 0, "Game exists");

        sequence += 1;
        ISwitchboard(_switchboard).requestRandomness(
            bytes32(sequence),        // randomnessId (bytes32): Unique ID for the request.
            address(this),            // authority (address):  Only this contract should manage randomness. 
            queue,                    // queueId (bytes32 ): Chain selection for requesting randomness.
            1                         // minSettlementDelay (uint16): Minimum seconds to settle the request.
        );

        // Store the number to identify the callback request
        seq2GameId[sequence] = gameId;

        emit RandomRequested(sequence);
    }

    function resolve(
        bytes[] calldata switchboardUpdateFeeds,
        uint256 seq
    ) external {
        uint256 gameId = seq2GameId[seq];

        require(seq == solvedSeq + 1 && gameId != 0, "invalid seq");
        solvedSeq = seq;

        // invoke
        ISwitchboard(_switchboard).updateFeeds(switchboardUpdateFeeds);

        Structs.RandomnessResult memory randomness = ISwitchboard(_switchboard).getRandomness(bytes32(solvedSeq)).result;
        require(randomness.settledAt != 0, "Randomness failed to Settle");

        handleRandomNumber(gameId, randomness.value);
    }

    function handleRandomNumber(
        uint256 gameId,
        uint256 randomNumber
    ) internal virtual;

    function setVrf(bool enabled) external onlyRole(ADMIN_ROLE) {
        vrfEnable = enabled;
    }
}