# BinanceHistoricalData.jl
Julia package for downloading binance historical data using Julia.
See function docstrings and [the binance public data repo](https://github.com/binance/binance-public-data) for more information.

### Install
```julia 
import Pkg; Pkg.add("https://github.com/p-casgrain/BinanceHistoricalData.jl")
```
### Example
```julia
using BinanceHistoricalData
using CSV, ZipFile, DataFrames, DataFramesMeta, Dates

# Choose some path to download to
my_path = "./binance_data/zip/"
mkpath(my_path)

# Download the zip file
zip_path = 
    download_klines( 
        :BTCUSDT,
        Date(2022,01,12),
        my_path;
        agg_level="daily",
        sym_type="spot")

# Read the zipped csv, format timestamps
zf = ZipFile.Reader(zip_path)
kline_dataframe = CSV.File(read(zf.files[1]),header=BinanceHistoricalData.tbl_colnames_klines) |> DataFrame
@transform!( kline_dataframe, @byrow :OpenTime = DateTime(1970) + :OpenTime*Millisecond(1) )
@transform!( kline_dataframe, @byrow :CloseTime = DateTime(1970) + :CloseTime*Millisecond(1) )

```