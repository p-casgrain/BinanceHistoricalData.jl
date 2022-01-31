module BinanceHistoricalData
    using Dates, HTTP, JSON3
    export download_klines_spot, download_aggtrades_spot, symbol_info

    const FREQS = ["1m","5m","15m","30m","1h","2h","4h","6h","8h","12h","1d","3d","1w","1mo"]
    const AGGLEVELS = ["monthly","daily"]
    const SYMTYPE = ["spot","futures"]

    const tbl_colnames_klines = ["OpenTime","OpenPrice","HighPrice","LowPrice","ClosePrice","Volume","CloseTime","QuoteVolume","NTrades","TakerBuyBaseVolume","TakerBuyQuoteVolume","IgnoreFlag"]
    const tbl_colnames_aggtrades = ["AggTradeId","Price","Quantity","FirstTradeId","LastTradeId","Timestamp","IsMarketMakerBuyer","IsTradeBestPriceMatch"]

    """
        download_klines_spot(sym,date::Date,write_dir;freq="1m",agg_level="monthly",verbose=true)

    Download historical klines data starting on `date` for symbol `sym` to directory `write_dir`.
    
    Other argument descriptions:
     - Data frequency `freq`. (See `BinanceHistoricalData.FREQS` for possible values )
     - Data aggregation level `agg_level`. (See `BinanceHistoricalData.AGGLEVELS` for possible values )
    
    Downloads zipped CSV with column names `BinanceHistoricalData.tbl_colnames_klines`. 
    See [this link](https://github.com/binance/binance-public-data) for more details
    on the CSV file's contents.

    """
    function download_klines_spot(sym,date::Date,write_dir;freq="1m",agg_level="monthly",verbose=true)
        # Check arguments
        (agg_level ∈ AGGLEVELS) || error("must have agg_level ∈ $AGGLEVELS")
        (freq ∈ FREQS) || error("must have freq ∈ $FREQS")
        # Format information into strings
        sym_str = uppercase(String(sym))
        date_str = (agg_level == "monthly") ? Dates.format(Date(date),"yyyy-mm") : Dates.format(Date(date),"yyyy-mm-dd") 
        # Put together full data url
        sym_type = "spot"
        data_url = "https://data.binance.vision/data/$sym_type/$agg_level/klines/$sym/$freq/$sym_str-$freq-$date_str.zip"
        # Download the data
        verbose && @info "[$(now())] - Fetching binance historical kline data" sym, date, freq, sym_type, agg_level
        return download(data_url,joinpath(write_dir,"kline-$sym_type-$sym_str-$freq-$date_str.zip"))
    end
      
    """
        download_aggtrades_spot(sym,date::Date,write_dir::AbstractString;sym_type="spot",agg_level="monthly",verbose=true)

    Download historical aggregate trade data starting on `date` for symbol `sym` to directory `write_dir`.
    
    Other argument descriptions:
     - Data frequency `freq`. (See `BinanceHistoricalData.FREQS` for possible values )
     - Data aggregation level `agg_level`. (See `BinanceHistoricalData.AGGLEVELS` for possible values )
    
    Downloads zipped CSV with column names `BinanceHistoricalData.tbl_colnames_aggtrades`. 
    See [this link](https://github.com/binance/binance-public-data) for more details
    on the CSV file's contents.    
    """
    function download_aggtrades_spot(sym,date::Date,write_dir::AbstractString; sym_type="spot",agg_level="monthly",verbose=true)
        # Check arguments
        (agg_level ∈ AGGLEVELS) || error("must have agg_level ∈ $AGGLEVELS")
        # Format information into strings
        sym_str = String(sym)
        date_str = (agg_level == "monthly") ? Dates.format(Date(date),"yyyy-mm") : Dates.format(Date(date),"yyyy-mm-dd") 
        # Put together full data url
        data_url = "https://data.binance.vision/data/spot/$agg_level/aggTrades/$sym_str/$sym_str-aggTrades-$date_str.zip"
        # Download the data
        verbose && @info "[$(now())] - Fetching binance historical aggtrade data" sym, date, sym_type, agg_level
        return download(data_url,joinpath(write_dir,"aggTrades-$sym_type-$sym_str-$date_str.zip"))
    end

    """
        symbol_info()
    
    Get table of all available symbols on the Binance and some of their properties.
    """
    function symbol_info()
        resp = HTTP.get("https://api.binance.com/api/v3/exchangeInfo")
        js_tmp = JSON3.read(resp.body)
        return js_tmp.symbols
    end

end

