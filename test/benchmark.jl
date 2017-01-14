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
