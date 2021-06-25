//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Ticket is ERC20{

  address private _manager;
  
  constructor() ERC20("LotteryTicket", "LT") {
    _mint(msg.sender, 100);
    _manager = msg.sender;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
    require((((sender != address(0)) && (recipient == _manager)) || ((sender == _manager) && (recipient != address(0)))), 
      "ERC20: tokens are only transfered between manager and players");
    ERC20._transfer(sender, recipient, amount);
  }
}

contract Lottery {
  address payable manager;

  address payable[] winners;

  address payable[] lotteryPlayers;
}
