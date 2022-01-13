if isinteractive()
    using Dates, DataFrames, Plots
    using ZipFile, CSV
    using DataFrames, Chain, DataFramesMeta
    using Base.Iterators: take, zip, enumerate
    using BinanceHistoricalData

    # Get list of desired symbols
    full_sym_df_raw = BinanceHistoricalData.symbol_info() |> DataFrame
    grab_coins = [:BTC,:ETH,:SOL,:ADA,:XRP,:DOT,:AVAX,:LUNA,:USDT,:USDC]
    grab_coins_pairs_regex = Regex("($(join(grab_coins,"|")))($(join(grab_coins,"|")))")
    
    sym_df = @chain full_sym_df_raw begin
        select(
            :symbol,
            :status,
            :isSpotTradingAllowed => :spottrading,
            :isMarginTradingAllowed => :margintrading 
            ; renamecols = false
            )
        @subset( @byrow (:status == "TRADING") && occursin(grab_coins_pairs_regex,:symbol)  )
        # second bit lists out all spot and futures pairs
        stack([:spottrading,:margintrading],variable_name=:sym_type)
        @subset(@byrow :value == true)
        select(Not(:value))
        @transform( @byrow :sym_type = ( occursin("spot",:sym_type) ? "spot" : "futures") )
    end

    base_dl_path = "/Users/pcasgrain/Desktop/binance_data/zip/"

    fetch_monthly = Date(2018,01,01):Month(1):(floor(today(),Month)-Month(1)) # full months
    fetch_daily = floor(today(),Month):Day(1):(today()-1) # remaining days

    date_df = vcat( 
        DataFrame(date=fetch_monthly,agg="monthly"), 
        DataFrame(date=fetch_daily,agg="daily")
    )

    @sync for (sym,status,sym_type) in take( eachrow(sym_df) , 1 )
        @async for (dt,agg) in eachrow(date_df)
            try
                BinanceHistoricalData.download_klines(sym,dt,joinpath(base_dl_path,"kline/");agg_level=agg,sym_type=sym_type,verbose=false)
                @info "kline $sym_type|$sym|$dt|$agg - Download Succeeded"
            catch e
                @info "kline $sym_type|$sym|$dt|$agg - Download Failed" error=e
            end
            try
                BinanceHistoricalData.download_aggtrades(sym,dt,joinpath(base_dl_path,"aggtrade/");agg_level=agg,sym_type=sym_type,verbose=false)
                @info "aggtrade $sym_type|$sym|$dt|$agg - Download Succeeded"
            catch e
                @info "aggtrade $sym_type|$sym|$dt|$agg - Download Failed" error=e
            end

        end
    end


    master_df = DataFrame()
    df_list = DataFrame[]
    sizehint!(df_list,length(readdir(base_dl_path)))
    for fname in base_dl_path.*readdir(base_dl_path)
        println(fname)
        # arrange zip file names, unzip into temp directory
        tmp_dir_root = "/tmp/zips"
        zip_root, file_endname = @chain split(fname,'/') (join(_[1:end-1],'/'),_[end])
        tmp_folder_name = split(file_endname,'.')[1]
        full_tmp_dir = tmp_dir_root*'/'*tmp_folder_name
        isdir(tmp_dir_root) || mkpath(tmp_dir_root)
        run(`unzip -o $fname -d $full_tmp_dir`)
        # get csv file name and load csv file
        csv_file_name = readdir(full_tmp_dir)[1]
        df = CSV.File(
            full_tmp_dir*'/'*csv_file_name,
            header=BinanceHistoricalData.tbl_header_klines ) |> DataFrame
        master_df = vcat(master_df,df)
        # cleanup temp files
        run(`rm -rf $full_tmp_dir`)
    end
    # Add symbol column and write to disk as parquet
    # CSV.write(master_df,)

end