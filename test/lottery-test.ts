import { ethers, upgrades } from "hardhat"

import { expect } from "chai"
import { Contract, Signer } from "ethers"
import { tokens, timeoutAppended } from "./utils/utils"
import { Lottery, TestErc20 } from "../typechain"

describe("Lottery", function() {
  let owner: Signer
  let users: Signer[]
  let token: TestErc20
  let lottery: Lottery

    beforeEach(async () => {
      ;[owner, ...users] = await ethers.getSigners()

      token = (await (await ethers.getContractFactory("TestERC20")).deploy("BUSD", "BUSD")) as TestErc20
    await token.deployed()
      for (const user of users) {
        await token.transfer(await user.getAddress(), tokens(10_000))
      }
    
      lottery = (await (await ethers.getContractFactory("Lottery")).deploy()) as Lottery
      await lottery.deployed()
    })
    
    it('Should have manager as creator', async () => {
      const manager = await lottery["getOwner()"]
      expect(manager, await(owner.getAddress())).to.be.equal
    })

    it('Lottery is not live', async () => {
      const status = await lottery.isLive()
      expect(status).to.be.false
    })

    it('Does not allow entry if lottery is not live', async () => {
      let status = lottery.buyWithBNB(1)
      await expect(status).to.be.reverted
    })

    it('Lottery is live', async () => {
      lottery.activateLottery(1, 1)
      const status = await lottery.isLive()
      await expect(status).to.be.true
    })

    it('Allows to participate in lottery with BNB', async () => {
      lottery.activateLottery(1, 1)
      let status = lottery.buyWithBNB(1, {value: 1});

      const players = await lottery.getPlayersList()

      expect(players[0], await(owner.getAddress())).to.be.equal
    });

    it('Allows to participate in lottery with BUSD', async () => {
      lottery.activateLottery(1, 1)
      let status = lottery.buyWithBUSD(1);
      await expect(status).to.be.reverted
      await token.approve(await(owner.getAddress()), 1)
      status = lottery.buyWithBUSD(1);
      await expect(status).to.be.ok
    });

    it('Requires exact amount of ether', async () => {
      lottery.activateLottery(1, 1)
      let status = lottery.buyWithBNB(2, {value: 1});
      await expect(status).to.be.reverted
    });

    it('Selects a winner', async () => {
      await lottery.activateLottery(1000000, 10)
      await lottery.buyWithBNB(2, {value: 2 * 1000000})
      await lottery.declareWinner()
      let winners = await lottery.getWinners();
      console.log("Winner: ", winners[0])
      console.log("Owner: ", await(owner.getAddress()))
      expect(winners[0], await(owner.getAddress())).to.be.equal
      await lottery.claimPrize(await(owner.getAddress()))
      const status = await lottery.isLive()
      await expect(status).to.be.false
    })
  })