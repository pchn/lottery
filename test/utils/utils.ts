import { BigNumber, utils, ethers } from "ethers"

export const tokens = (value: number, decimals = 18) => BigNumber.from(value).mul(BigNumber.from(10).pow(decimals))

export async function now(provider: ethers.providers.JsonRpcProvider) {
  return provider.getBlock("latest").then((b) => b.timestamp)
}

export const timeoutAppended = async (provider: ethers.providers.JsonRpcProvider, seconds: number) => (await now(provider)) + seconds
