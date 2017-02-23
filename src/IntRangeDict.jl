export IntRangeDict

import Base: push!, in, show, foreach, collect, getindex, read, write

type IntRangeSpan{K<:Integer, V}
    lv::K
    rv::K
    data::Vector{V}
    IntRangeSpan(x, y) = new(x, y, [])
end

type IntRangeDict{K<:Integer, V}
    data::Vector{IntRangeSpan{K, V}}
    IntRangeDict() = new([])
end

type IntRangeHandler{K<:Integer, V}
    lv::K
    rv::K
    dict::IntRangeDict{K, V}
end

function find_last{K, V}(dict::IntRangeDict{K, V}, int::K)::Int
    findlast(x->x.lv <= int, dict.data)
end

function find_binary{K, V}(dict::IntRangeDict{K, V}, int::K)::Int
    isempty(dict.data) && return 0

    v(i) = dict.data[i].lv

    _find(i, j) = if i == j
        v[i] <= int ? i : i - 1
    else
        m = (i + j + 1) ÷ 2
        v[m] <= int ? _find(m, j) : _find(i, m-1)
    end

    find_binary(1, length(dict.data))
end

function getindex{K, V}(dict::IntRangeDict{K, V}, range::UnitRange{K})::IntRangeHandler{K, V}
    IntRangeHandler{K, V}(range.start, range.stop, dict)
end
