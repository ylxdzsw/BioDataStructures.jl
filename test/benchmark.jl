using IntRangeSets
using BenchmarkTools

function total_size(x::IntRangeSet)::Int
    n = sizeof(x)
    IntRangeSets.traverse(x) do node
        n += sizeof(node)
    end
    n
end

function total_size(x::Set)::Int
    n = sizeof(x)
    n += sizeof(x.dict)
    n += sizeof(x.dict.slots)
    n += sizeof(x.dict.keys)
    n += sizeof(x.dict.vals)
    n
end

function total_size(x::IntSet)::Int
    n = sizeof(x)
    n += sizeof(x.bits)
    n
end

# 1. small-scale, non-cluster, sorted, push intenger

data = rand(1:1_000_000, 10_000) |> unique |> sort

@benchmark begin
    a = IntRangeSet{Int}()
    for i in $data
        push!(a, i)
    end
end
