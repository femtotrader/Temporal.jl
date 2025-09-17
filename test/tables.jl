@testset "Tables.jl Interface" begin
    using Tables, Dates

    # Create test data
    N = 10
    K = 4
    data = cumsum(randn(N,K), dims=1)
    dates = today()-Day(N-1):Day(1):today()
    times = DateTime(dates[1]):Hour(1):DateTime(dates[1])+Hour(N-1)
    X = TS(data, dates)
    Y = TS(data, times)

    @testset "Basic interface methods" begin
        @test Tables.istable(TS) == true
        @test Tables.istable(typeof(X)) == true
        @test Tables.rowaccess(typeof(X)) == true
        @test Tables.columnaccess(typeof(X)) == true
    end

    @testset "Schema" begin
        schema = Tables.schema(X)
        @test schema isa Tables.Schema
        @test length(schema.names) == length(X.fields) + 1  # +1 for index
        @test schema.names[1] == :index
        @test collect(schema.names[2:end]) == X.fields
        @test schema.types[1] == eltype(X.index)
        @test all(t -> t == eltype(X.values), schema.types[2:end])
    end

    @testset "Column access" begin
        cols = Tables.columns(X)
        @test cols isa NamedTuple
        @test length(cols) == length(X.fields) + 1
        @test haskey(cols, :index)
        @test cols.index == X.index

        for (i, field) in enumerate(X.fields)
            @test haskey(cols, field)
            @test cols[field] == X.values[:, i]
        end
    end

    @testset "Row access" begin
        rows = Tables.rows(X)
        @test length(rows) == size(X, 1)

        # Test first row
        first_row = first(rows)
        @test first_row isa NamedTuple
        @test haskey(first_row, :index)
        @test first_row.index == X.index[1]

        for (i, field) in enumerate(X.fields)
            @test haskey(first_row, field)
            @test first_row[field] == X.values[1, i]
        end

        # Test iteration over all rows
        row_count = 0
        for (i, row) in enumerate(rows)
            row_count += 1
            @test row.index == X.index[i]
            for (j, field) in enumerate(X.fields)
                @test row[field] == X.values[i, j]
            end
        end
        @test row_count == length(X.index)
    end

    @testset "Integration with other packages" begin
        # Test conversion to DataFrame-like structure
        # This tests the actual Tables.jl interface integration
        cols = Tables.columns(X)
        @test length(cols) > 0

        # Test that we can convert back and forth
        rows = collect(Tables.rows(X))
        @test length(rows) == size(X, 1)

        # Test Tables.columntable functionality
        ct = Tables.columntable(X)
        @test ct isa NamedTuple
        @test length(ct) == length(X.fields) + 1
    end

    @testset "Empty TS" begin
        empty_ts = TS(Matrix{Float64}(undef, 0, 2), Date[], [:A, :B])
        @test Tables.istable(typeof(empty_ts)) == true

        schema = Tables.schema(empty_ts)
        @test length(schema.names) == 3
        @test collect(schema.names) == [:index, :A, :B]

        cols = Tables.columns(empty_ts)
        @test length(cols.index) == 0

        rows = collect(Tables.rows(empty_ts))
        @test length(rows) == 0
    end

    @testset "DateTime index" begin
        schema_y = Tables.schema(Y)
        @test schema_y.types[1] == DateTime

        cols_y = Tables.columns(Y)
        @test cols_y.index == Y.index

        first_row_y = first(Tables.rows(Y))
        @test first_row_y.index isa DateTime
    end
end