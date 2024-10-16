// SPDX-License-Identifier: GNU LGPLv3
pragma solidity ^0.8.18;

import "./PollContract.sol";

contract RelayContract {
    PollContract[5] public pollContracts;
    string[] public sessionQueue;
    uint256 public currentSessionId = 0;
    uint256 public constant MAX_PARALLEL_SESSIONS = 5;

    address[] public allowedCollections;

    constructor(address[5] memory _pollContracts) {
        for (uint256 i = 0; i < MAX_PARALLEL_SESSIONS; i++) {
            pollContracts[i] = PollContract(_pollContracts[i]);
        }
    }

    // Queue new vote session descriptions
    function queueVoteSession(string memory description) external {
        sessionQueue.push(description);
    }

    // Start the next batch of 5 sessions (if available)
    function startNextSession() external {
        require(sessionQueue.length > currentSessionId, "No sessions in queue");
        uint256 batchSize = (sessionQueue.length - currentSessionId >
            MAX_PARALLEL_SESSIONS)
            ? MAX_PARALLEL_SESSIONS
            : sessionQueue.length - currentSessionId;

        for (uint256 i = 0; i < batchSize; i++) {
            pollContracts[i].startSession(
                currentSessionId,
                sessionQueue[currentSessionId]
            );
            emit VoteSessionStarted(
                currentSessionId,
                sessionQueue[currentSessionId]
            );
            currentSessionId++;
        }
    }

    // End all current sessions
    function endCurrentSession() external {
        for (uint256 i = 0; i < MAX_PARALLEL_SESSIONS; i++) {
            pollContracts[i].endSession();
            string memory description = pollContracts[i].getDescription();
            uint256[5] memory results = pollContracts[i].getResults();
            emit VoteSessionEnded(currentSessionId, description, results);
        }
    }

    function addAllowedCollection(address collection) external {
        allowedCollections.push(collection);
    }
}
