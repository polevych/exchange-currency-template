declare namespace NodeJS {
  export interface ProcessEnv {
    TESTNET_ALCHEMY_URL: string;
    TESTNET_PRIVATE_KEY: string;
    MAINNET_ALCHEMY_URL: string;
    MAINNET_PRIVATE_KEY: string;
    ERC20_NAME: string;
    ERC20_SYMBOL: string;
    USDC_ADDRESS: string;
    USDT_ADDRESS: string;
    ERC20_ADDRESS: string;
    ERC20_TO_USDC_RATE: string;
    MINIMUM_PURCHASE_AMOUNT: string;
    PRICE_FEED_USDC: string;
    PRICE_FEED_USDT: string;
    PRICE_FEED_MATIC: string;
  }
}
