// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GroupStudyIncentives {
    struct StudySession {
        uint256 sessionId;
        string topic;
        address[] participants;
        uint256 reward;
        bool isCompleted;
    }

    address public admin;
    uint256 public nextSessionId;
    mapping(uint256 => StudySession) public studySessions;
    mapping(address => uint256) public balances;

    event SessionCreated(uint256 sessionId, string topic, uint256 reward);
    event ParticipantJoined(uint256 sessionId, address participant);
    event SessionCompleted(uint256 sessionId);
    event RewardClaimed(address participant, uint256 amount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier validSession(uint256 sessionId) {
        require(sessionId < nextSessionId, "Invalid session ID");
        _;
    }

    constructor() {
        admin = msg.sender;
        nextSessionId = 0;
    }

    function createStudySession(string memory topic, uint256 reward) public onlyAdmin {
        require(reward > 0, "Reward must be greater than 0");

        StudySession storage newSession = studySessions[nextSessionId];
        newSession.sessionId = nextSessionId;
        newSession.topic = topic;
        newSession.reward = reward;
        newSession.isCompleted = false;

        emit SessionCreated(nextSessionId, topic, reward);

        nextSessionId++;
    }

    function joinStudySession(uint256 sessionId) public validSession(sessionId) {
        StudySession storage session = studySessions[sessionId];
        require(!session.isCompleted, "Session is already completed");

        for (uint256 i = 0; i < session.participants.length; i++) {
            require(session.participants[i] != msg.sender, "You are already part of this session");
        }

        session.participants.push(msg.sender);
        emit ParticipantJoined(sessionId, msg.sender);
    }

    function completeStudySession(uint256 sessionId) public onlyAdmin validSession(sessionId) {
        StudySession storage session = studySessions[sessionId];
        require(!session.isCompleted, "Session is already completed");
        require(session.participants.length > 0, "No participants in the session");

        uint256 rewardPerParticipant = session.reward / session.participants.length;
        for (uint256 i = 0; i < session.participants.length; i++) {
            balances[session.participants[i]] += rewardPerParticipant;
        }

        session.isCompleted = true;
        emit SessionCompleted(sessionId);
    }

    function claimReward() public {
        uint256 reward = balances[msg.sender];
        require(reward > 0, "No reward to claim");

        balances[msg.sender] = 0;
        payable(msg.sender).transfer(reward);

        emit RewardClaimed(msg.sender, reward);
    }

    function fundContract() public payable onlyAdmin {
        require(msg.value > 0, "Funding amount must be greater than 0");
    }

    function getSessionParticipants(uint256 sessionId) public view validSession(sessionId) returns (address[] memory) {
        return studySessions[sessionId].participants;
    }
}
