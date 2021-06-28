//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface Token {
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract Ticket is ERC20{
    // Lottery contract
    address private _manager;

    constructor() ERC20("LotteryTicket", "LT") {
        _manager = msg.sender;
    }

    function printTickets(address recepient, uint ticketsAmount) public {
        if(msg.sender == _manager) {
            _mint(recepient, ticketsAmount);
        }
    }

    function returnTickets(address recepient, uint ticketsAmount) public {
        if(msg.sender == _manager) {
            _burn(recepient, ticketsAmount);
        }
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        require((((sender != address(0)) && (recipient == _manager)) || ((sender == _manager) && (recipient != address(0)))), 
            "Ticket: tickets are only transfered between manager and players");
        ERC20._transfer(sender, recipient, amount);
    }
}

contract Lottery {

    // Creator of the lottery contract
    address public owner;

    // Variables for players
    struct Player {
        uint entryCount;
        uint index;
    }
    address[] public addressIndexes;
    mapping(address => Player) players;
    address[] public lotteryBag;

    // Variables for lottery information
    Ticket public tickets;
    address[] public winners;
    bool public isLotteryLive;
    uint public BNBToParticipate;
    uint public BUSDToParticipate;
    address constant BUSDAddr = 0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee;

    // constructor
    constructor() {
        owner = msg.sender;
        tickets = new Ticket();
        BNBToParticipate = 1;
        BUSDToParticipate = 1;
        isLotteryLive = false;
    }

    function buyWithBNB(uint ticketsAmount) public payable {
        require(isLotteryLive);
        require(msg.value == BNBToParticipate * ticketsAmount);

        if (isNewPlayer(msg.sender)) {
            players[msg.sender].entryCount = ticketsAmount;
            addressIndexes.push(msg.sender);
            players[msg.sender].index = addressIndexes.length - 1;
            lotteryBag.push(msg.sender);
        } else {
            players[msg.sender].entryCount += ticketsAmount;
        }
        tickets.printTickets(msg.sender, ticketsAmount);

        // event
        emit PlayerParticipated(msg.sender);
    }

    function buyWithBUSD(uint ticketsAmount) public {
        require(isLotteryLive);
        require(Token(BUSDAddr).allowance(msg.sender, address(this)) >= ticketsAmount * BUSDToParticipate);
        Token(BUSDAddr).transferFrom(msg.sender, address(this), ticketsAmount * BUSDToParticipate);
        if (isNewPlayer(msg.sender)) {
            players[msg.sender].entryCount = ticketsAmount;
            addressIndexes.push(msg.sender);
            players[msg.sender].index = addressIndexes.length - 1;
            lotteryBag.push(msg.sender);
        } else {
            players[msg.sender].entryCount += ticketsAmount;
        }
        tickets.printTickets(msg.sender, ticketsAmount);

        // event
        emit PlayerParticipated(msg.sender);
    }

    function activateLottery(uint BNBRequired, uint BUSDRequired) public restricted {
        isLotteryLive = true;
        BNBToParticipate = BNBRequired == 0 ? 1 : BNBRequired;
        BUSDToParticipate = BUSDRequired == 0 ? 1 : BUSDRequired;
        winners = new address[](0);
    }

    function getPlayersList() public view returns (address [] memory) {
        return addressIndexes;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function isLive() public view returns (bool) {
        return isLotteryLive;
    }
    
    function declareWinner() public restricted {
        require(lotteryBag.length > 0);

        isLotteryLive = false;
        uint winnersAmount = generateRandomNumber() % lotteryBag.length + 1;
        for(uint i = 0; i < winnersAmount; i++) {
            uint index = generateRandomNumber() % lotteryBag.length;
            if(lotteryBag[index] != address(0)) {
                winners.push(lotteryBag[index]);
                lotteryBag[index] = address(0);
            } else i--;
        }

        // empty the lottery bag and indexAddresses
        lotteryBag = new address[](0);
        addressIndexes = new address[](0);

        // event
        emit WinnerDeclared(winners);
    }

    function getWinners() public view returns (address [] memory) {
        return winners;
    }

    function claimPrize(address payable player) public returns(bool) {
        bool isWinner = false;
        uint totalTicketsWon = 0;
        for(uint i = 0; i < winners.length; i++) {
            totalTicketsWon += players[winners[i]].entryCount;
            if(winners[i] == player) {
                isWinner = true;
            }
        }
        if(isWinner) {
            uint winnerTickets = players[player].entryCount;
            console.log("Balance before payment: ", address(this).balance);
            console.log("Payment size: ", (address(this).balance / totalTicketsWon * winnerTickets));
            player.transfer((address(this).balance / totalTicketsWon * winnerTickets));
            console.log("Balance after payment: ", address(this).balance);
            tickets.returnTickets(player, winnerTickets);
        }
        return isWinner;
    }


    // Private functions
    function isNewPlayer(address playerAddress) private view returns(bool) {
        if (addressIndexes.length == 0) {
            return true;
        }
        return (addressIndexes[players[playerAddress].index] != playerAddress);
    }

    function generateRandomNumber() private view returns(uint) {
        return uint(sha256(abi.encodePacked(blockhash(0))));
    }

    // Modifiers
    modifier restricted() {
        require(msg.sender == owner);
        _;
    }

    // Events
    event WinnerDeclared(address[] winners);
    event PlayerParticipated(address playerAddress);
}
