IntRangeSets.jl
===============

[![Build Status](https://travis-ci.org/ylxdzsw/IntRangeSets.jl.svg?branch=master)](https://travis-ci.org/ylxdzsw/IntRangeSets.jl)
[![Coverage Status](https://coveralls.io/repos/github/ylxdzsw/IntRangeSets.jl/badge.svg?branch=master)](https://coveralls.io/github/ylxdzsw/IntRangeSets.jl?branch=master)

A tree based datastructure holds Integers. Ideally for bed in NGS.

### Feature

- use a cache to make inserting integer incrementally (eg. `push!(t, 2, 3, 4, 6, 8, 9)`) in O(1), even when the tree is not balanced.
- automatically balance the tree when quering or performing set operations like `intersect`.
- use a dense structure aiming to save high-scale, clustered integers (more specifically, bed-like data in NGS).

### Installation

```julia
Pkg.clone("https://github.com/ylxdzsw/IntRangeSets.jl")
```

### Benchmark

run [test/benchmark.jl](blob/master/test/benchmark.jl) to get your local performance.

### Example

see [test/runtests.jl](blob/master/test/runtests.jl) for all usages.


