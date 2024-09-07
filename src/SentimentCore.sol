// SPDX-License-Identifier: GNU LGPLv3
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract SentimentPoll is AccessControl {
    bytes32 public constant COUNCIL = keccak256("COUNCIL");

    // different session states
    enum SessionState {
        Inactive,
        Queued,
        Active,
        Ended
    }

    // representing a vote session
    struct VoteSession {
        SessionState state;
        string description;
        uint256 startTime;
        uint256 endTime;
        mapping(address => bool) hasVoted;
        mapping(address => uint256[]) votedTokenIds;
        uint256[5] votes; // Likert scale from 1 to 5
        uint256 totalVotes;
    }

    address[] public allowedCollections;
    VoteSession[] public sessionQueue;
    uint256 public currentSessionId = 0;

    // arbitrary session delay and duration
    uint256 public constant SESSION_DELAY = 12 hours;
    uint256 public constant SESSION_DURATION = 24 hours;

    event VoteSessionQueued(string description);
    event VoteSessionStarted(string description);
    event Voted(address indexed voter, uint256[] tokenIds, uint256 vote);
    event VoteSessionEnded(string description, uint256[5] voteResults);

    // Constructor arg -----------------------------------
    // input format: [0x,0x,0x,0x]
    constructor(address[] memory _collections) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        allowedCollections = _collections;
    }

    // Starts a session after a 12-hour delay - then runs for 24 hours, etc.
    // description would typically be the name of the project being polled
    function queueVoteSession(
        string memory description
    ) external onlyRole(COUNCIL) {
        VoteSession storage newSession = sessionQueue.push();
        newSession.description = description;
        newSession.state = SessionState.Queued;
        newSession.totalVotes = 0;

        emit VoteSessionQueued(description);

        // If no current session is running, will schedule the next session
        if (
            currentSessionId == 0 ||
            sessionQueue[currentSessionId - 1].state == SessionState.Ended
        ) {
            _startNextSession();
        }
    }

    // Cast a vote (Likert scale options: 1-5)
    //Option 1: Very Unsatisfied
    //Option 2: Unsatisfied
    //Option 3: Neutral
    //Option 4: Satisfied
    //Option 5: Very Satisfied
    // Still needs to implement:
    // (1) payment provision
    // (2) direct msg.value to a council treasury
    // (3) if voter holds certain nft collection tokens, then make vote free
    function vote(uint256 voteValue) external {
        require(
            voteValue >= 1 && voteValue <= 5,
            "Invalid vote option (must be between 1 and 5)"
        );
        VoteSession storage currentSession = sessionQueue[currentSessionId - 1];
        require(
            currentSession.state == SessionState.Active,
            "No active vote session"
        );
        require(!currentSession.hasVoted[msg.sender], "You have already voted");

        uint256[] memory ownedTokenIds = _getOwnedTokens(msg.sender);
        require(ownedTokenIds.length > 0, "You don't own any allowed tokens");

        currentSession.hasVoted[msg.sender] = true;
        currentSession.votedTokenIds[msg.sender] = ownedTokenIds;

        // Stores the vote (1-5 Likert scale), subtract 1 to index array from 0 to 4
        currentSession.votes[voteValue - 1] += 1;
        currentSession.totalVotes += 1;

        emit Voted(msg.sender, ownedTokenIds, voteValue);
    }

    // Internals ------------------------------------

    // Starts the next session in the queue
    function _startNextSession() internal {
        if (currentSessionId < sessionQueue.length) {
            VoteSession storage nextSession = sessionQueue[currentSessionId];
            nextSession.startTime = block.timestamp + SESSION_DELAY;
            nextSession.endTime = nextSession.startTime + SESSION_DURATION;
            nextSession.state = SessionState.Active;

            emit VoteSessionStarted(nextSession.description);

            currentSessionId++;
        }
    }

    // Ends the current session
    function _endCurrentSession() internal {
        require(currentSessionId > 0, "No session to end");
        VoteSession storage currentSession = sessionQueue[currentSessionId - 1];
        require(
            currentSession.state == SessionState.Active,
            "Session already ended"
        );

        currentSession.state = SessionState.Ended;

        emit VoteSessionEnded(currentSession.description, currentSession.votes);

        // Start the next session if one is queued
        if (
            currentSessionId < sessionQueue.length &&
            sessionQueue[currentSessionId].state == SessionState.Queued
        ) {
            _startNextSession();
        }
    }

    // Check eligibility of a voter + get their token IDs
    function _getOwnedTokens(
        address voter
    ) internal view returns (uint256[] memory) {
        uint256[] memory tokenIds;
        for (uint256 i = 0; i < allowedCollections.length; i++) {
            IERC721 collection = IERC721(allowedCollections[i]);
            uint256 balance = collection.balanceOf(voter);

            for (uint256 j = 0; j < balance; j++) {
                uint256 tokenId = collection.tokenOfOwnerByIndex(voter, j);
                tokenIds[tokenIds.length] = tokenId;
            }
        }
        return tokenIds;
    }

    // Called externally to manually trigger ending of sessions (should be done via a scheduler/ui on website that anybody can call)
    function checkAndEndSession() external {
        VoteSession storage currentSession = sessionQueue[currentSessionId - 1];
        if (
            block.timestamp >= currentSession.endTime &&
            currentSession.state == SessionState.Active
        ) {
            _endCurrentSession();
        }
    }

    // Public getters --------------------------------------

    // Get results of a voting session by ID (useful for UI)
    function getSessionResults(
        uint256 sessionId
    )
        external
        view
        returns (string memory description, uint256[5] memory voteCounts)
    {
        require(sessionId < sessionQueue.length, "Invalid sessionId");

        VoteSession storage session = sessionQueue[sessionId];
        return (session.description, session.votes);
    }

    // COUNCIL functions -------------------------
    // input format: [0x,0x,0x,0x]
    function addAllowedCollection(
        address collection
    ) external onlyRole(COUNCIL) {
        allowedCollections.push(collection);
    }

    // first check the allowedCollections array to make sure the index is valid
    function removeAllowedCollection(uint256 index) external onlyRole(COUNCIL) {
        require(index < allowedCollections.length, "Invalid index");
        allowedCollections[index] = allowedCollections[
            allowedCollections.length - 1
        ];
        allowedCollections.pop();
    }
}
