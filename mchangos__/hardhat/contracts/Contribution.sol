//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract ContributionDapp {
    struct Group {
        address admin;
        string description;
        uint256 balance;
        address[] groupMembers;
        mapping(address => Participant) participants;
        State currentState;
    }
    
    struct Participant {
        string name;
        uint256 amountDonated;
        uint256 amountCollected;
        bool isBanned;
    }
    
    enum State { notStarted, inProgress, completed }
    
    mapping(address => Group) public groups;
    address[] public admins;

    event hasDonated(address indexed _participant, uint256 _amount);
    event fundsReleased(address indexed _participant, uint256 _amount);
    event joinedGroup(address indexed _participant, string _groupName, uint256 _time);

    modifier onlyAdmin(address _groupAdmin) {
        require(msg.sender == _groupAdmin, "Only group admin can perform this action");
        _;
    }

    function createGroup(string memory _description, address[] memory _initialMembers) external {
        require(groups[msg.sender].admin == address(0), "You are already an admin of a group");
        Group memory newGroup = Group({
            admin: msg.sender,
            description: _description,
            balance: 0,
            groupMembers: _initialMembers,
            currentState: State.notStarted
        });

        groups[msg.sender] = newGroup;
        admins.push(msg.sender);
    }

    function joinGroup(address _groupAdmin) external {
        Group storage group = groups[_groupAdmin];
        require(group.admin != address(0), "Group does not exist");
        require(group.currentState == State.notStarted, "Group is not in join state");
        require(!group.participants[msg.sender].isBanned, "You are banned from this group");

        Participant memory newParticipant = Participant({
            name: "Your Name", // Set your name here
            amountDonated: 0,
            amountCollected: 0,
            isBanned: false
        });

        group.participants[msg.sender] = newParticipant;
        emit joinedGroup(msg.sender, group.description, block.timestamp);
    }

    function donate(address _groupAdmin, uint256 _amount) external {
        Group storage group = groups[_groupAdmin];
        require(group.admin != address(0), "Group does not exist");
        require(group.currentState == State.inProgress, "Group is not in progress");
        require(!group.participants[msg.sender].isBanned, "You are banned from this group");
        
        group.participants[msg.sender].amountDonated += _amount;
        group.balance += _amount;
        emit hasDonated(msg.sender, _amount);
    }

    function startCollection(address _groupAdmin) external onlyAdmin(_groupAdmin) {
        Group storage group = groups[_groupAdmin];
        require(group.admin != address(0), "Group does not exist");
        require(group.currentState == State.notStarted, "Collection has already started");
        
        group.currentState = State.inProgress;
    }

    function releaseFunds(address _groupAdmin, uint256 _amount) external onlyAdmin(_groupAdmin) {
        Group storage group = groups[_groupAdmin];
        require(group.admin != address(0), "Group does not exist");
        require(group.currentState == State.inProgress, "Group is not in progress");
        require(group.balance >= _amount, "Insufficient funds");
        
        address[] storage members = group.groupMembers;
        for (uint256 i = 0; i < members.length; i++) {
            address participantAddress = members[i];
            Participant storage participant = group.participants[participantAddress];
            if (!participant.isBanned && participant.amountCollected == 0) {
                participant.amountCollected = _amount;
                group.balance -= _amount;
                emit fundsReleased(participantAddress, _amount);
                return;
            }
        }

        group.currentState = State.completed;
    }

    function banParticipant(address _groupAdmin, address _participant) external onlyAdmin(_groupAdmin) {
        Group storage group = groups[_groupAdmin];
        require(group.admin != address(0), "Group does not exist");
        require(group.currentState == State.notStarted, "Group is not in join state");

        group.participants[_participant].isBanned = true;
    }
}
