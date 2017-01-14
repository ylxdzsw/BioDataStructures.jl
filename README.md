IntRangeSets.jl
===============

[![Build Status](https://travis-ci.org/ylxdzsw/IntRangeSets.jl.svg?branch=master)](https://travis-ci.org/ylxdzsw/IntRangeSets.jl)
[![Coverage Status](https://coveralls.io/repos/github/ylxdzsw/IntRangeSets.jl/badge.svg?branch=master)](https://coveralls.io/github/ylxdzsw/IntRangeSets.jl?branch=master)

A tree based datastructure holds Integers. Ideally for bed in NGS.

### Features

- use a cache to make inserting integer incrementally (eg. `push!(t, 2, 3, 4, 6, 8, 9)`) in O(1), even when the tree is not balanced.
- automatically balance the tree when performing quering.
- use a dense structure aiming to save high-scale, clustered integers (more specifically, bed-like data in NGS).

### Installation

```julia
Pkg.clone("https://github.com/ylxdzsw/IntRangeSets.jl")
```

### Example

```julia
using IntRangeSets

a = IntRangeSet{Int}()

push!(a, 2)
push!(a, 4:5)
show(a)

# IntRangeSets{Int64}:
#  2:2
#  4:5

push!(a, 3)
show(a)

# IntRangeSets{Int64}:
#   2:5

3 in a # true

b = IntRangeSet{Int}()
push!(b, 4:8)
push!(b, 2)
foreach(println, b)

# 2:2
# 4:8

c = union(a, b)
show(c)

# IntRangeSets{Int64}:
#   2:8

c = intersect(a, b)
show(c)

# IntRangeSets{Int64}:
#   2:2
#   4:5

collect(c)

# 2-element Array{UnitRange{Int64},1}:
#  2:2
#  4:5
```

see [test/runtests.jl](test/runtests.jl) for all usages.

### Benchmark

run [test/benchmark.jl](test/benchmark.jl) to get your local performance.
