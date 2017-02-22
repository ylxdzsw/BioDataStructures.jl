using BioDataStructures
using BenchmarkTools

# 1. small-scale, non-cluster, sorted, push intenger

data = rand(1:1_000_000, 10_000) |> unique |> sort

@benchmark begin
    a = IntRangeSet{Int}()
    for i in $data
        push!(a, i)
    end
end
