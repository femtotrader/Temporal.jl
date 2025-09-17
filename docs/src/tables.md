# Tables.jl Integration

Temporal.jl implements the [Tables.jl](https://github.com/JuliaData/Tables.jl) interface, providing seamless integration with the broader Julia data ecosystem. This makes `TS` objects compatible with packages like DataFrames.jl, CSV.jl, Arrow.jl, and many others that support the Tables.jl interface.

## Interface Implementation

The `TS` type implements the following Tables.jl interface methods:

- `Tables.istable(::Type{<:TS})` - Indicates that `TS` is a table
- `Tables.rowaccess(::Type{<:TS})` - Indicates that `TS` supports row-based access
- `Tables.columnaccess(::Type{<:TS})` - Indicates that `TS` supports column-based access
- `Tables.schema(ts::TS)` - Provides schema information including column names and types
- `Tables.rows(ts::TS)` - Returns an iterator over table rows
- `Tables.columns(ts::TS)` - Returns columns as a NamedTuple

## Schema Information

The schema includes all time series data columns plus the index:

```julia
using Temporal, Tables, Dates

# Create a time series with Date index
ts = TS([1.0 2.0; 3.0 4.0], [Date(2020,1,1), Date(2020,1,2)], [:A, :B])

# Get schema information
schema = Tables.schema(ts)
println(schema.names)  # (:index, :A, :B)
println(schema.types)  # (Date, Float64, Float64)
```

## Column Access

Access time series data as columns through the Tables.jl interface:

```julia
# Get all columns as a NamedTuple
cols = Tables.columns(ts)
println(cols.index)  # [Date(2020,1,1), Date(2020,1,2)]
println(cols.A)      # [1.0, 3.0]
println(cols.B)      # [2.0, 4.0]

# Columns can be accessed by name or index
for name in propertynames(cols)
    println("$name: $(getproperty(cols, name))")
end
```

## Row Access

Iterate over time series data row by row:

```julia
# Iterate over all rows
for row in Tables.rows(ts)
    println("Date: $(row.index), A: $(row.A), B: $(row.B)")
end

# Get specific row
first_row = first(Tables.rows(ts))
println(first_row.index)  # Date(2020,1,1)
println(first_row.A)      # 1.0
```

## Integration Examples

### Converting to DataFrame

```julia
using DataFrames

# Convert TS to DataFrame
df = DataFrame(ts)
println(df)
```

### Working with CSV

```julia
using CSV

# Write time series to CSV
CSV.write("timeseries.csv", ts)

# Read back from CSV (requires date parsing for index)
df_from_csv = CSV.read("timeseries.csv", DataFrame)
```

### Using with other Tables.jl packages

```julia
# Convert to column table format
ct = Tables.columntable(ts)

# Convert to row table format
rt = Tables.rowtable(ts)

# These can then be used with any Tables.jl compatible package
```

## Special Cases

### Empty Time Series

The Tables.jl interface handles empty time series gracefully:

```julia
empty_ts = TS(Matrix{Float64}(undef, 0, 2), Date[], [:A, :B])

# Schema information is still available
schema = Tables.schema(empty_ts)
println(schema.names)  # (:index, :A, :B)

# Column and row access return empty collections
cols = Tables.columns(empty_ts)
rows = collect(Tables.rows(empty_ts))
println(length(rows))  # 0
```

### Different Index Types

The Tables.jl interface works with any index type supported by `TS`:

```julia
using Dates

# DateTime index
dt_ts = TS([1.0 2.0], [DateTime(2020,1,1,12,0,0)], [:Value])
schema_dt = Tables.schema(dt_ts)
println(schema_dt.types[1])  # DateTime

# Integer index
int_ts = TS([1.0 2.0], [1, 2], [:Value])
schema_int = Tables.schema(int_ts)
println(schema_int.types[1])  # Int64
```

## Performance Considerations

The Tables.jl implementation is designed to be efficient:

- Column access returns views where possible to avoid copying data
- Row iteration is lazy and doesn't materialize all rows at once
- Schema information is computed on demand

This makes the interface suitable for large time series datasets while maintaining compatibility with the broader Julia data ecosystem.