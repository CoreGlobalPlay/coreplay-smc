//SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Structs} from "@switchboard-xyz/on-demand-solidity/structs/Structs.sol";
import {ISwitchboard} from "@switchboard-xyz/on-demand-solidity/ISwitchboard.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract SwResolver is Initializable {
    address private _switchboard;
    bytes32 public queue;
    mapping(bytes32 => uint256) public randomnessIdToGameId;
    mapping(uint256 => bytes32) public gameIdToRandomnessId;

    event RandomRequested(bytes32 randomnessId);
    
    // https://docs.switchboard.xyz/product-documentation/randomness/tutorials/evm
    function setupResolver(address switchboard_, bytes32 swQueue_) internal initializer {
        queue = swQueue_;
        _switchboard = switchboard_;
    }

    function requestRandomNumber(uint256 gameId) internal {
        require(gameIdToRandomnessId[gameId] == 0, "Game exists");

        bytes32 randomnessId = keccak256(abi.encodePacked(gameId, msg.sender, block.timestamp));

        ISwitchboard(_switchboard).requestRandomness(
            randomnessId,            // randomnessId (bytes32): Unique ID for the request.
            address(this),            // authority (address):  Only this contract should manage randomness. 
            queue,                    // queueId (bytes32 ): Chain selection for requesting randomness.
            1                         // minSettlementDelay (uint16): Minimum seconds to settle the request.
        );

        // Store the randomnessId number to identify the callback request
        randomnessIdToGameId[randomnessId] = gameId;
        gameIdToRandomnessId[gameId] = randomnessId;

        emit RandomRequested(randomnessId);
    }

    function resolve(
        bytes[] calldata switchboardUpdateFeeds,
        bytes32 randomnessId
    ) external {
        // invoke
        ISwitchboard(_switchboard).updateFeeds(switchboardUpdateFeeds);

        // store value for later use
        Structs.RandomnessResult memory randomness = ISwitchboard(_switchboard).getRandomness(randomnessId).result;
        require(randomness.settledAt != 0, "Randomness failed to Settle");

        handleRandomNumber(randomnessIdToGameId[randomnessId], randomness.value);
    }

    function handleRandomNumber(
        uint256 gameId,
        uint256 randomNumber
    ) internal virtual;
}