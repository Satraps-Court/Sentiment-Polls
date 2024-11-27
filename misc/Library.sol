// SPDX-License-Identifier: GNU LGPLv3
pragma solidity ^0.8.18;

contract LibraryContract {
    enum SessionState { Inactive, Queued, Active, Ended }

    struct BatchSession {
        string[5] descriptions; 
        uint256[5][5] votes; 
        address[][5] voters; 
        uint256[5] totalVotes; 
        uint256 startTime;
        uint256 endTime;
        SessionState state;
    }

    mapping(uint256 => BatchSession) public sessionData;

    function storeBatchSession(uint256 sessionId, string[5] memory descriptions, uint256 startTime, uint256 endTime) external {
        sessionData[sessionId] = BatchSession({
            descriptions: descriptions,
            votes: [[0, 0, 0, 0, 0], [0, 0, 0, 0, 0], [0, 0, 0, 0, 0], [0, 0, 0, 0, 0], [0, 0, 0, 0, 0]],
            voters:  , new address , new address , new address , new address ],
            totalVotes: [0, 0, 0, 0, 0],
            startTime: startTime,
            endTime: endTime,
            state: SessionState.Active
        });
    }

    /* Update results */
    function updateBatchResults(uint256 sessionId, uint256[5][5] memory votes, address[][5] memory voters, uint256[5] memory totalVotes, uint256 endTime) external {
        BatchSession storage session = sessionData[sessionId];
        session.votes = votes;
        session.voters = voters;
        session.totalVotes = totalVotes;
        session.endTime = endTime;
        session.state = SessionState.Ended;
    }

    function getBatchSession(uint256 sessionId) external view returns (
        string[5] memory descriptions, 
        uint256[5][5] memory votes, 
        address[][5] memory voters, 
        uint256[5] memory totalVotes, 
        uint256 startTime, 
        uint256 endTime
    ) {
        BatchSession storage session = sessionData[sessionId];
        return (
            session.descriptions,
            session.votes,
            session.voters,
            session.totalVotes,
            session.startTime,
            session.endTime
        );
    }
}
