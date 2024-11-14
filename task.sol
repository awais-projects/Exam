// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Staking {

    address public owner;                              // owner of contract
    uint public rewardBalance;                         // variable to store the balance for the rewards

    // Struct to store the staker information
    struct Staker {
        uint balance;
        uint lastRewardTime;
        bool isStaker;
    }

    // mapping 
    mapping (address => Staker) public stakers;

    // events used in the contract
    event Deposit (address indexed sender, address indexed contractAddress, uint amount);
    event Withdraw (address indexed contractAddress, address indexed receiver, uint amount);
    event ClaimRewards (address staker, uint amount);

    //constructor to set the owner
    constructor() {
        owner = msg.sender;
    }

    //modifier for the owner to restrict functions only accessible by the owner 
    modifier onlyOwner() {
        require(msg.sender == owner,"Only the owner can perform this action");
        _;
    }

    //deposit function for the staker
    function deposit () public payable  {
        require(msg.value > 0,"The amount must be greater than 0.");

        Staker storage staker = stakers[msg.sender];
        staker.balance += msg.value;
        staker.lastRewardTime = block.timestamp;
        staker.isStaker = true;

        emit Deposit(msg.sender, address(this), msg.value);
    }

    //deposit function to add reward balance in the contract
    function depositReward() public payable onlyOwner {
        require(msg.value > 0,"The amount must be greater than 0.");
        rewardBalance += msg.value;
    }

    // withdraw function for the owner
    function withdraw(uint _amount) public {
        Staker storage staker = stakers[msg.sender];
        require(staker.isStaker,"Only the staker can call this function.");
        require(_amount > 0,"The amount must be greater than 0.");
        require(_amount <= staker.balance,"Issuficient amount.");
        staker.balance -= _amount;
        
        if (staker.balance > 0) {
            staker.isStaker = true;
        } else {
            staker.isStaker = false;
        }

        payable(msg.sender).transfer(_amount);

        emit Withdraw(address(this), msg.sender, _amount);
    }

    // function for rewards calculation
    function rewardCal() public view returns(uint) {
        Staker storage staker = stakers[msg.sender];
        require(block.timestamp >= staker.lastRewardTime + 7 days,"No reward is available.");
        uint weeksPassed =(block.timestamp - staker.lastRewardTime) / 7 days;
        uint reward = (staker.balance * 5 /100) * weeksPassed / 365;
        return reward;
    }

    //function to claim rewards by the staker
    function claimReward() public {
        Staker storage staker = stakers[msg.sender];
        uint reward = rewardCal();
        require(staker.isStaker,"Only the staker can call this function.");
        require(reward > 0,"No rewards are available.");
        staker.lastRewardTime = block.timestamp;
        staker.balance += reward;
        rewardBalance -= reward;

        emit ClaimRewards(msg.sender, reward);

    } 
    
}



contract Slashing is Staking {

    uint public slashingBalance;                       


    event panelty (address indexed stakerAddress, uint amount);
    function slashing(address _address, uint _amount) public onlyOwner {
        Staker storage staker = stakers[_address];
        require(staker.isStaker,"Enter the correct staker's address.");
        require(_amount <= (staker.balance)/2,"More than 50% palenty is not allowed");
        staker.balance -= _amount;
        slashingBalance += _amount;


        emit panelty(_address, _amount);
    }
}