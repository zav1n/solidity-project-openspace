export interface NFTListing {
  tokenId: string;
  price: string;
  seller: string;
}

export interface SignatureData {
  v: number;
  r: string;
  s: string;
  deadline: number;
  nonce: number;
}

export interface MarketplaceConfig {
  address: string;
  abi: unknown[];
}
