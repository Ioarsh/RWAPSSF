// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "./CommitReveal.sol";

contract RWAPSSF is CommitReveal{
    struct Player {
        uint choice; // 0 - Rock, 1 - Fire , 2 - Scissors, 3 - Sponge, 4 - Paper, 5 - Air, 6 - Water, 7 - Undefined
        uint timestamp;
        address addr;
        bool foul;
    }
    uint internal  numPlayer = 0;
    uint internal reward = 0;
    mapping (uint => Player) private player;
    mapping (address => uint) private PlayerIndex;
    uint internal numInput = 0;
    uint internal choose_timelimit = 10 minutes;


    function GameStatus() public view returns(uint Player_now, uint prize, uint Choice_now) {
        return(numPlayer,reward,numInput);
    }

    function _reset() private{
        numPlayer = 0;
        reward = 0;
        numInput = 0;
        for(uint i=0;i<2;i++){
            PlayerIndex[player[i].addr] = 0;
            player[i].addr = address(0);
            player[i].choice = 7;
            player[i].timestamp = block.timestamp;
            player[i].foul = false;
        }
    }
    
    function quit() public payable {
        uint idx = PlayerIndex[msg.sender];
        require(numPlayer == 1 || numInput < 2);
        if (numPlayer == 1) {
            payable(player[idx].addr).transfer(reward);
        } else {
            payable(player[0].addr).transfer(reward/2);
            payable(player[1].addr).transfer(reward/2);
        }
        _reset();
    }

    function _terminate() private {
        if(player[0].foul==true){
            payable(player[1].addr).transfer(reward);
        }
        else if(player[1].foul==true){
            payable(player[0].addr).transfer(reward);
        }
        else{
            payable(player[0].addr).transfer(reward/2);
            payable(player[1].addr).transfer(reward/2);
        }
        _reset();
    }

    function addPlayer() public payable {
        require(numPlayer < 2);
        require(msg.value == 1 ether);
        reward += msg.value;
        player[numPlayer].addr = msg.sender;
        player[numPlayer].choice = 7;
        player[numPlayer].foul = false;
        PlayerIndex[msg.sender] = numPlayer;
        numPlayer++;
        if (numPlayer == 2) {
            player[0].timestamp = block.timestamp;
            player[1].timestamp = block.timestamp;
        }
    }

    function input(uint choice, uint salt) public{
        uint idx = PlayerIndex[msg.sender];
        require(numPlayer == 2);
        require(msg.sender == player[idx].addr);
        require(choice == 0 || choice == 1 || choice == 2 || choice == 3 || choice == 4 || choice == 5 || choice == 6);
        if(block.timestamp > player[idx].timestamp + choose_timelimit){
            player[idx].foul = true;
        }
        uint HashedData = uint(getSaltedHash(bytes32(choice),bytes32(salt)));
        player[idx].choice = HashedData;
        commit(bytes32(HashedData));
        numInput++;
    }

    function RevealAns(uint answer,uint saltz) public{
        require(numInput == 2);
        revealAnswer(bytes32(answer),bytes32(saltz));
        uint idx = PlayerIndex[msg.sender];
        player[idx].choice = answer;
        if(commits[player[0].addr].revealed==true && commits[player[1].addr].revealed==true){
            _checkWinnerAndPay();
        }
    }


    function _checkWinnerAndPay() private {
        uint p0Choice = player[0].choice;
        uint p1Choice = player[1].choice;
        address payable account0 = payable(player[0].addr);
        address payable account1 = payable(player[1].addr);
        if(player[0].foul == true || player[1].foul == true){
            _terminate();
            return;
        }
        if (((p0Choice + 1) % 7 == p1Choice) || ((p0Choice + 2) % 7 == p1Choice) || ((p0Choice + 3) % 7 == p1Choice)) {
            // to pay player[0]
            account0.transfer(reward);
        }
        else if (((p1Choice + 1) % 7 == p0Choice) || ((p1Choice + 2) % 7 == p0Choice) || ((p1Choice + 3) % 7 == p0Choice)) {
            // to pay player[1]
            account1.transfer(reward);    
        }
        else {
            // to split reward
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
        }
        _reset();
    }
}
