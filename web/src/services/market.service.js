/**
 * Market Data Service
 * Fetches cryptocurrency prices and market data from CoinGecko API
 */

const COINGECKO_API_BASE = 'https://api.coingecko.com/api/v3';

// Popular cryptocurrencies to track
export const TRACKED_COINS = [
  { id: 'bitcoin', symbol: 'BTC', name: 'Bitcoin' },
  { id: 'ethereum', symbol: 'ETH', name: 'Ethereum' },
  { id: 'binancecoin', symbol: 'BNB', name: 'BNB' },
  { id: 'cardano', symbol: 'ADA', name: 'Cardano' },
  { id: 'solana', symbol: 'SOL', name: 'Solana' },
  { id: 'ripple', symbol: 'XRP', name: 'XRP' },
  { id: 'dogecoin', symbol: 'DOGE', name: 'Dogecoin' },
  { id: 'polkadot', symbol: 'DOT', name: 'Polkadot' },
  { id: 'chainlink', symbol: 'LINK', name: 'Chainlink' },
  { id: 'litecoin', symbol: 'LTC', name: 'Litecoin' }
];

/**
 * Fetch current prices for tracked coins
 */
export async function fetchCoinPrices() {
  try {
    const coinIds = TRACKED_COINS.map(coin => coin.id).join(',');
    const response = await fetch(
      `${COINGECKO_API_BASE}/simple/price?ids=${coinIds}&vs_currencies=usd&include_24hr_change=true&include_24hr_vol=true&include_market_cap=true`
    );
    
    if (!response.ok) {
      throw new Error('Failed to fetch prices');
    }
    
    const data = await response.json();
    
    // Transform data into array format
    return TRACKED_COINS.map(coin => {
      const priceData = data[coin.id];
      if (!priceData) return null;
      
      return {
        id: coin.id,
        symbol: coin.symbol,
        name: coin.name,
        price: priceData.usd || 0,
        change24h: priceData.usd_24h_change || 0,
        volume24h: priceData.usd_24h_vol || 0,
        marketCap: priceData.usd_market_cap || 0
      };
    }).filter(Boolean);
  } catch (error) {
    console.error('Error fetching coin prices:', error);
    throw error;
  }
}

/**
 * Fetch detailed market data for a specific coin
 */
export async function fetchCoinDetails(coinId) {
  try {
    const response = await fetch(
      `${COINGECKO_API_BASE}/coins/${coinId}?localization=false&tickers=false&community_data=false&developer_data=false`
    );
    
    if (!response.ok) {
      throw new Error('Failed to fetch coin details');
    }
    
    const data = await response.json();
    
    return {
      id: data.id,
      symbol: data.symbol?.toUpperCase(),
      name: data.name,
      image: data.image?.large,
      description: data.description?.en,
      price: data.market_data?.current_price?.usd || 0,
      change24h: data.market_data?.price_change_percentage_24h || 0,
      change7d: data.market_data?.price_change_percentage_7d || 0,
      change30d: data.market_data?.price_change_percentage_30d || 0,
      volume24h: data.market_data?.total_volume?.usd || 0,
      marketCap: data.market_data?.market_cap?.usd || 0,
      marketCapRank: data.market_cap_rank,
      high24h: data.market_data?.high_24h?.usd || 0,
      low24h: data.market_data?.low_24h?.usd || 0,
      circulatingSupply: data.market_data?.circulating_supply || 0,
      totalSupply: data.market_data?.total_supply || 0,
      maxSupply: data.market_data?.max_supply || null,
      ath: data.market_data?.ath?.usd || 0,
      athDate: data.market_data?.ath_date?.usd,
      atl: data.market_data?.atl?.usd || 0,
      atlDate: data.market_data?.atl_date?.usd
    };
  } catch (error) {
    console.error('Error fetching coin details:', error);
    throw error;
  }
}

/**
 * Fetch price chart data for a coin
 */
export async function fetchCoinChart(coinId, days = 7) {
  try {
    const response = await fetch(
      `${COINGECKO_API_BASE}/coins/${coinId}/market_chart?vs_currency=usd&days=${days}`
    );
    
    if (!response.ok) {
      throw new Error('Failed to fetch chart data');
    }
    
    const data = await response.json();
    
    return {
      prices: data.prices || [],
      volumes: data.total_volumes || [],
      marketCaps: data.market_caps || []
    };
  } catch (error) {
    console.error('Error fetching chart data:', error);
    throw error;
  }
}

/**
 * Search for coins
 */
export async function searchCoins(query) {
  try {
    const response = await fetch(
      `${COINGECKO_API_BASE}/search?query=${encodeURIComponent(query)}`
    );
    
    if (!response.ok) {
      throw new Error('Failed to search coins');
    }
    
    const data = await response.json();
    
    return (data.coins || []).slice(0, 10).map(coin => ({
      id: coin.id,
      symbol: coin.symbol?.toUpperCase(),
      name: coin.name,
      image: coin.thumb,
      marketCapRank: coin.market_cap_rank
    }));
  } catch (error) {
    console.error('Error searching coins:', error);
    throw error;
  }
}

/**
 * Format price with appropriate decimals
 */
export function formatPrice(price) {
  if (price >= 1000) {
    return `$${price.toLocaleString('en-US', { minimumFractionDigits: 0, maximumFractionDigits: 0 })}`;
  } else if (price >= 1) {
    return `$${price.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
  } else if (price >= 0.01) {
    return `$${price.toLocaleString('en-US', { minimumFractionDigits: 4, maximumFractionDigits: 4 })}`;
  } else {
    return `$${price.toLocaleString('en-US', { minimumFractionDigits: 6, maximumFractionDigits: 8 })}`;
  }
}

/**
 * Format large numbers (market cap, volume)
 */
export function formatLargeNumber(num) {
  if (num >= 1e12) {
    return `$${(num / 1e12).toFixed(2)}T`;
  } else if (num >= 1e9) {
    return `$${(num / 1e9).toFixed(2)}B`;
  } else if (num >= 1e6) {
    return `$${(num / 1e6).toFixed(2)}M`;
  } else if (num >= 1e3) {
    return `$${(num / 1e3).toFixed(2)}K`;
  } else {
    return `$${num.toFixed(2)}`;
  }
}

/**
 * Get color for price change
 */
export function getChangeColor(change) {
  if (change > 0) return 'text-green-400';
  if (change < 0) return 'text-red-400';
  return 'text-gray-400';
}

/**
 * Get background color for price change
 */
export function getChangeBgColor(change) {
  if (change > 0) return 'bg-green-500/10';
  if (change < 0) return 'bg-red-500/10';
  return 'bg-gray-500/10';
}
