import { createWalletClient, createPublicClient, http, defineChain, getContract } from "viem";
import { privateKeyToAccount } from "viem/accounts";
import * as dotenv from "dotenv";

dotenv.config();

const asciiToHex = (s: string): `0x${string}` => {
  if (s.startsWith("0x")) return s as `0x${string}`;
  return ("0x" + Buffer.from(s, "ascii").toString("hex")) as `0x${string}`;
};

async function main() {
  const VAULT_ADDRESS = process.env.VAULT_ADDRESS;
  const RPC_URL = process.env.RPC_URL;
  const DEPOSIT_AMOUNT = process.env.DEPOSIT_AMOUNT;
  const PRIVATE_KEY = process.env.PRIVATE_KEY;
  const CHAIN_ID = process.env.CHAIN_ID ? parseInt(process.env.CHAIN_ID) : 5003;
  const TOKEN_ADDRESS = process.env.TOKEN_ADDRESS || "0x0000000000000000000000000000000000000000";
  const TAIL = process.env.TAIL || "";

  if (!VAULT_ADDRESS) throw new Error("VAULT_ADDRESS not set");
  if (!RPC_URL) throw new Error("RPC_URL not set");
  if (!DEPOSIT_AMOUNT) throw new Error("DEPOSIT_AMOUNT not set");
  if (!PRIVATE_KEY) throw new Error("PRIVATE_KEY not set");

  const depositAmount = BigInt(DEPOSIT_AMOUNT);
  const isNativeToken = TOKEN_ADDRESS === "0x0000000000000000000000000000000000000000";
  const tailHex = TAIL ? asciiToHex(TAIL) : "0x";

  const customChain = defineChain({
    id: CHAIN_ID,
    name: "Custom Chain",
    nativeCurrency: { name: "ETH", symbol: "ETH", decimals: 18 },
    rpcUrls: {
      default: { http: [RPC_URL] },
    },
  });

  const account = privateKeyToAccount(PRIVATE_KEY as `0x${string}`);

  const walletClient = createWalletClient({
    account,
    chain: customChain,
    transport: http(RPC_URL),
  });

  const publicClient = createPublicClient({
    chain: customChain,
    transport: http(RPC_URL),
  });

  console.log("Wallet Address:", account.address);
  console.log("Vault Address:", VAULT_ADDRESS);
  console.log("Token Address:", TOKEN_ADDRESS);
  console.log("Deposit Amount (Wei):", depositAmount.toString());
  console.log("Is Native Token:", isNativeToken);
  console.log("Tail (ASCII):", TAIL);
  console.log("Tail (Hex):", tailHex);

  const vaultAbi = [
    {
      inputs: [
        { internalType: "address", name: "token", type: "address" },
        { internalType: "uint256", name: "amount", type: "uint256" },
        { internalType: "bytes", name: "tail", type: "bytes" },
      ],
      name: "deposit",
      outputs: [],
      stateMutability: "payable",
      type: "function",
    },
  ] as const;

  const contract = getContract({
    address: VAULT_ADDRESS as `0x${string}`,
    abi: vaultAbi,
    client: { public: publicClient, wallet: walletClient },
  });

  const txHash = await contract.write.deposit(
    [TOKEN_ADDRESS as `0x${string}`, depositAmount, tailHex],
    isNativeToken ? { value: depositAmount } : {}
  );

  console.log("Transaction Hash:", txHash);

  const receipt = await publicClient.waitForTransactionReceipt({
    hash: txHash,
    timeout: 120_000,
    pollingInterval: 2_000,
  });

  console.log("Transaction Receipt:", receipt);
  console.log("Deposit successful!");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
