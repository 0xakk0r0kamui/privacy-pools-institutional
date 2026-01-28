import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import fs from "node:fs";
import path from "node:path";

function readFoundrySettings() {
  const foundryPath = path.join(__dirname, "foundry.toml");
  const content = fs.readFileSync(foundryPath, "utf8");

  const solcMatch = content.match(/solc_version\s*=\s*['"]([^'"]+)['"]/);
  if (!solcMatch) {
    throw new Error("solc_version not found in foundry.toml");
  }

  const optimizerEnabledMatch = content.match(/optimizer\s*=\s*(true|false)/);
  if (!optimizerEnabledMatch) {
    throw new Error("optimizer not found in foundry.toml");
  }

  const optimizerRunsMatch = content.match(/optimizer_runs\s*=\s*([0-9_]+)/);
  if (!optimizerRunsMatch) {
    throw new Error("optimizer_runs not found in foundry.toml");
  }

  const optimizerRuns = Number(optimizerRunsMatch[1].replace(/_/g, ""));
  if (!Number.isFinite(optimizerRuns)) {
    throw new Error("optimizer_runs is not a valid number in foundry.toml");
  }

  const optimizerEnabled = optimizerEnabledMatch[1] === "true";

  return { solcVersion: solcMatch[1], optimizerRuns, optimizerEnabled };
}

const { solcVersion, optimizerRuns, optimizerEnabled } = readFoundrySettings();

const config: HardhatUserConfig = {
  solidity: {
    version: solcVersion,
    settings: {
      optimizer: {
        enabled: optimizerEnabled,
        runs: optimizerRuns,
      },
    },
  },
  paths: {
    sources: "./src",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  typechain: {
    outDir: "exports/types",
    target: "ethers-v6",
  },
};

export default config;
