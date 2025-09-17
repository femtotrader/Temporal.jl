import Tables

Tables.istable(::Type{<:TS}) = true
Tables.rowaccess(::Type{<:TS}) = true
Tables.columnaccess(::Type{<:TS}) = true

function Tables.schema(ts::TS{V,T}) where {V,T}
    names = [:index; ts.fields]
    types = [T; fill(V, length(ts.fields))]
    return Tables.Schema(names, types)
end

function Tables.rows(ts::TS{V,T}) where {V,T}
    return TSRowIterator{V,T}(ts)
end

function Tables.columns(ts::TS)
    cols = []
    push!(cols, ts.index)
    for i in 1:size(ts.values, 2)
        push!(cols, view(ts.values, :, i))
    end
    names = [:index; ts.fields]
    return NamedTuple{Tuple(names)}(Tuple(cols))
end

struct TSRowIterator{V,T}
    ts::TS{V,T}
end

function Base.iterate(iter::TSRowIterator)
    isempty(iter.ts) && return nothing
    return iterate(iter, 1)
end

function Base.iterate(iter::TSRowIterator, state::Int)
    state > length(iter.ts.index) && return nothing

    row_values = []
    push!(row_values, iter.ts.index[state])
    for i in 1:size(iter.ts.values, 2)
        push!(row_values, iter.ts.values[state, i])
    end

    names = [:index; iter.ts.fields]
    row = NamedTuple{Tuple(names)}(Tuple(row_values))

    return (row, state + 1)
end

Base.length(iter::TSRowIterator) = length(iter.ts.index)
Base.eltype(::Type{TSRowIterator{V,T}}) where {V,T} = NamedTuple

Tables.getcolumn(row::NamedTuple, i::Int) = row[i]
Tables.getcolumn(row::NamedTuple, nm::Symbol) = getproperty(row, nm)
Tables.columnnames(row::NamedTuple) = keys(row)