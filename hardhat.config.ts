import { HardhatUserConfig } from "hardhat/types"
import "@nomiclabs/hardhat-etherscan"
import "@nomiclabs/hardhat-ethers"
import "@nomiclabs/hardhat-waffle"
import "@openzeppelin/hardhat-upgrades"

import "solidity-coverage"

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.2",
        settings: {
          optimizer: { enabled: true, runs: 2000 },
        },
      }
    ]
  }
}

export default config
