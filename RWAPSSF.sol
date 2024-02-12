// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "./CommitReveal.sol";

contract RWAPSSF is CommitReveal {
    struct Player {
        uint choice; // 0 - Rock, 1 - Paper , 2 - Scissors, 3 - undefined
        address addr;
    }
    uint numPlayer = 0;
    uint reward = 0;
    mapping (uint => Player) private player;
    mapping (address => uint) private PlayerIndex;
    uint numInput = 0;
    uint timelimit = 10 minutes;


    function GameStatus() public view returns(uint Player_now, uint prize, uint Choice_now) {
        return(numPlayer,reward,numInput);
    }

    function reset() private{
        numPlayer = 0;
        reward = 0;
        numInput = 0;
        for(uint i=0;i<2;i++){
            PlayerIndex[player[i].addr] = 0;
            player[i].addr = address(0);
            player[i].choice = 3;
        }
    }

    function quit() public payable {
        uint idx = PlayerIndex[msg.sender];
        require(numPlayer==1 || (numPlayer==2 && numInput!=2));

        if(numPlayer==1){
            payable(player[idx].addr).transfer(reward);
        }
        else{
            payable(player[0].addr).transfer(reward/2);
            payable(player[1].addr).transfer(reward/2);
        }
        reset();
    }

    function addPlayer() public payable {
        require(numPlayer < 2);
        require(msg.value == 1 ether);
        reward += msg.value;
        player[numPlayer].addr = msg.sender;
        player[numPlayer].choice = 3;
        PlayerIndex[msg.sender] = numPlayer;
        numPlayer++;
    }

    function input(uint choice) public  {
        uint idx = PlayerIndex[msg.sender];
        require(numPlayer == 2);
        require(msg.sender == player[idx].addr);
        require(choice == 0 || choice == 1 || choice == 2);
        player[idx].choice = choice;
        numInput++;
        if (numInput == 2) {
            _checkWinnerAndPay();
        }
    }

    function _checkWinnerAndPay() private {
        uint p0Choice = player[0].choice;
        uint p1Choice = player[1].choice;
        address payable account0 = payable(player[0].addr);
        address payable account1 = payable(player[1].addr);
        if (((p0Choice + 1) % 7 == p1Choice) || ((p0Choice + 2) % 7 == p1Choice) || ((p0Choice + 3) % 7 == p1Choice)) {
            // to pay player[1]
            account1.transfer(reward);
        }
        else if (((p1Choice + 2) % 7 == p0Choice) || ((p1Choice + 2) % 7 == p0Choice) || ((p1Choice + 3) % 7 == p0Choice)) {
            // to pay player[0]
            account0.transfer(reward);    
        }
        else {
            // to split reward
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
        }
        reset();
    }
}
