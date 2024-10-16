// SPDX-License-Identifier: GNU LGPLv3
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./PollContract.sol";
import "./LibraryContract.sol";

contract CoreContract is AccessControl {
    bytes32 public constant COUNCIL = keccak256("COUNCIL");

    PollContract[5] public pollContracts; // Array of 5 poll contracts
    LibraryContract public libraryContract; // Incase this is necessary
    uint256 public sessionIdCounter = 0;

    constructor(address[5] memory _pollContracts, address _libraryContract) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        for (uint256 i = 0; i < 5; i++) {
            pollContracts[i] = PollContract(_pollContracts[i]);
        }
        libraryContract = LibraryContract(_libraryContract);
    }

    // Queue a batch of vote sessions
    function queueBatchVoteSessions(
        string[5] memory descriptions,
        uint256 startTime,
        uint256 endTime
    ) external onlyRole(COUNCIL) {
        for (uint256 i = 0; i < 5; i++) {
            pollContracts[i].startVoteSession(
                descriptions[i],
                startTime,
                endTime
            );
        }
        sessionIdCounter++;
        libraryContract.storeBatchSession(
            sessionIdCounter,
            descriptions,
            startTime,
            endTime
        );
    }

    function endBatchVoteSessions() external onlyRole(COUNCIL) {
        string[5] memory descriptions;
        uint256[5][5] memory votes;
        address[][5] memory voters;
        uint256[5] memory totalVotes;
        uint256 startTime;
        uint256 endTime;

        for (uint256 i = 0; i < 5; i++) {
            pollContracts[i].endSession();
            (
                descriptions[i],
                votes[i],
                voters[i],
                totalVotes[i],
                startTime,
                endTime
            ) = pollContracts[i].getSessionData();
        }
        libraryContract.updateBatchResults(
            sessionIdCounter,
            votes,
            voters,
            totalVotes,
            endTime
        );
    }
}
