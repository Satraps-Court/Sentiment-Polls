// SPDX-License-Identifier: GNU LGPLv3
pragma solidity ^0.8.18;

contract PollContract {
    string public description;
    uint256[5] public votes;
    bool public sessionActive;
    uint256 public sessionId;

    address public relayContract;

    constructor(address _relayContract) {
        relayContract = _relayContract;
    }

    modifier onlyRelay() {
        require(msg.sender == relayContract, "Only relay can call");
        _;
    }

    /* Starts a session with a single project description */
    function startSession(
        uint256 _sessionId,
        string memory _description
    ) external onlyRelay {
        require(!sessionActive, "Session already active");
        sessionId = _sessionId;
        description = _description;
        sessionActive = true;
    }

    /* (Likert scale 1-5) */
    function vote(uint256 voteValue) external {
        require(sessionActive, "No active session");
        require(voteValue >= 1 && voteValue <= 5, "Invalid vote option");

        votes[voteValue - 1] += 1;
    }

    function endSession() external onlyRelay {
        sessionActive = false;
        RelayContract(relayContract).endSession(sessionId);
    }

    function getResults() external view returns (uint256[5] memory) {
        return votes;
    }

    function getDescription() external view returns (string memory) {
        return description;
    }
}
