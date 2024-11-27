// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.18;

import "./SentimentPoll.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title SentimentPollFactory
 * @dev Factory contract to deploy SentimentPolls
 * @author Clavi @clavi.satrap
 */
contract SentimentPollFactory is AccessControl {
    bytes32 public constant NOBLE = keccak256("NOBLE");
    address public immutable voteMinter;
    address public immutable consensus;
    mapping(string => address) private pollAddressById;

    event SentimentPollLaunch(
        address indexed contractOwner,
        string pollSessionId,
        address indexed contractAddress
    );

    // Modifiers ----------------------------------

    modifier onlyNoble() {
        require(hasRole(NOBLE, msg.sender), "Caller is not a Noble");
        _;
    }

    modifier onlyClavi() {
        require(msg.sender == clavi, "Only Clavi can call this function");
        _;
    }

    // Constructors -------------------------------

    /**
     * @param admin The address to be granted the default admin role
     */
    constructor(
        address admin,
        address voteMinterAddress,
        address consensusAddress
    ) {
        require(voteMinterAddress != address(0), "Invalid voteMinter address");
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(NOBLE, admin);
        grantRole(DEFAULT_ADMIN_ROLE, voteMinterAddress);
        grantRole(DEFAULT_ADMIN_ROLE, consensusAddress);
        voteMinter = voteMinterAddress;
        consensus = consensusAddress;
    }

    // Public functions ---------------------------

    /**
     * @notice Retrieves the address of a SentimentPoll contract by its unique ID
     * @param pollSessionId The unique ID associated with the SentimentPoll
     * @return Address of the SentimentPoll contract
     */
    function getPollAddressById(
        string memory pollSessionId
    ) external view returns (address) {
        return pollAddressById[pollSessionId];
    }

    /**
     * @notice Checks if a unique ID is available for a new SentimentPoll contract
     * @param pollSessionId The unique ID to check
     * @return True if the ID is available, false otherwise
     */
    function isPollSessionIdAvailable(
        string memory pollSessionId
    ) public view returns (bool) {
        return pollAddressById[pollSessionId] == address(0);
    }

    // Launch functions ---------------------------

    /**
     * @notice Deploys a new SentimentPoll contract
     * @param pollSessionId The unique ID for the new SentimentPoll
     * @return The address of the newly deployed SentimentPoll contract
     */
    function launchPoll(
        string calldata pollSessionId,
        string calldata pollName,
        string calldata pollDescription
    ) external onlyNoble returns (address) {
        require(
            isPollSessionIdAvailable(pollSessionId),
            "Unique ID is not available"
        );

        bytes32 saltedHash = keccak256(
            abi.encodePacked(msg.sender, block.timestamp, pollSessionId)
        );
        SentimentPoll poll = new SentimentPoll{salt: saltedHash}(
            pollName,
            pollDescription,
            erc721Address
        );

        pollAddressById[pollSessionId] = address(poll);
        poll.transferOwnership(msg.sender);

        emit SentimentPollLaunch(msg.sender, pollSessionId, address(poll));

        return address(poll);
    }

    // Access control functions -------------------
    /**
     * @notice Grants the NOBLE role to a specific address
     * @dev Can only be called by the voteMinter contract
     * @param account The address to grant the NOBLE role
     */
    function grantNobleRole(address account) external {
        require(msg.sender == voteMinter, "Caller is not the voteMinter");
        require(account != address(0), "Invalid account address");

        _grantRole(NOBLE, account);
        emit NobleRoleGranted(account);
    }

    function revokeNobleRole(address account) external {
        require(msg.sender == consensus, "Caller is not the Consensus");
        _revokeRole(NOBLE, account);
        emit NobleRoleRevoked(account);
    }

    // Clavi functions ----------------------------

    function setVoteMinter(address _voteMinter) external onlyClavi {
        voteMinter = _voteMinter;
        emit VoteMinterUpdated(_voteMinter);
    }

    function setConsensus(address _consensus) external onlyClavi {
        consensus = _consensus;
        emit ConsensusUpdated(_consensus);
    }
}
