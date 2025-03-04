type NetworkConfig = {
  ShinchanName: string;
  ShinchanSymbol: string;
};

export const networkConfig: Record<string, NetworkConfig> = {
  hardhat: {
    ShinchanName: "Shi",
    ShinchanSymbol: "SH",
  },
  bscTestnet: {
    ShinchanName: "Shi",
    ShinchanSymbol: "SH",
  },
  berachain: {
    ShinchanName: "🐻 Shincha: The Chilling Bear Around 🐻",
    ShinchanSymbol: "SHINCHAN",
  },
};
