export IntRangeDict

import Base: push!, in, show, foreach, collect, getindex, read, write

type IntRangeSpan{K<:Integer, V}
    lv::K
    rv::K
    data::Vector{V}
end

immutable IntRangeDict{K<:Integer, V}
    data::Vector{IntRangeSpan{K, V}}
    IntRangeDict() = new([])
end

immutable IntRangeHandler{K<:Integer, V}
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

    find_within(i, j) = if i == j
        v[i] <= int ? i : i - 1
    else
        m = (i + j + 1) ÷ 2
        v[m] <= int ? find_within(m, j) :
                      find_within(i, m-1)
    end

    find_within(1, length(dict.data))
end

function getindex{K, V}(dict::IntRangeDict{K, V}, range::UnitRange{K})
    IntRangeHandler{K, V}(range.start, range.stop, dict)
end

function push!{K, V}(handle::IntRangeHandler{K, V}, v::V)
    data, lv, rv = handle.dict.data, handle.lv, handle.rv

    if lv > rv
        return handle
    end

    i = find_last(handle.dict, lv) # use last rahter than binary to make inserting incremently faster

    if i == 0 || lv > data[i].rv
        if i+1 <= length(data) && rv >= data[i+1].lv
            insert!(data, i+1, IntRangeSpan{K, V}(lv, data[i+1].lv-1, [v]))
            push_aligned_left!(handle.dict, rv, v, i+2)
        else
            insert!(data, i+1, IntRangeSpan{K, V}(lv, rv, [v]))
        end
    else
        if lv == data[i].lv
            push_aligned_left!(handle.dict, rv, v, i)
        else
            old_rv = data[i].rv
            data[i].rv = lv-1

            if rv <= old_rv
                insert!(data, i+1, IntRangeSpan{K, V}(lv, rv, [data[i].data[:]; v]))

                if rv != old_rv
                    insert!(data, i+2, IntRangeSpan{K, V}(rv+1, old_rv, data[i].data[:]))
                end
            else
                insert!(data, i+1, IntRangeSpan{K, V}(lv, old_rv, [data[i].data[:]; v]))
                push_aligned_right!(handle.dict, rv, v, i+1)
            end
        end
    end

    handle.dict
end

"push when handle.lv == handle.dict.data[i].lv"
function push_aligned_left!{K, V}(dict::IntRangeDict{K, V}, rv::K, v::V, i::Int)
    p = dict.data[i]

    if rv < p.rv
        lv = p.lv
        p.lv = rv + 1
        insert!(dict.data, i, IntRangeSpan{K, V}(lv, rv, [p.data[:]; v]))
    else
        push!(p.data, v)
        if rv > p.rv
            push_aligned_right!(dict, rv, v, i)
        end
    end
end

"push when handle.lv == handle.dict.data[i].rv+1"
function push_aligned_right!{K, V}(dict::IntRangeDict{K, V}, rv::K, v::V, i::Int)
    p = dict.data[i]
    if i+1 <= length(dict.data)
        pnext = dict.data[i+1]
        if p.rv+1 == pnext.lv
            push_aligned_left!(dict, rv, v, i+1)
        elseif rv < pnext.lv
            insert!(dict.data, i+1, IntRangeSpan{K, V}(p.rv+1, rv, [v]))
        else
            insert!(dict.data, i+1, IntRangeSpan{K, V}(p.rv+1, pnext.lv-1, [v]))
            push_aligned_left!(dict, rv, v, i+1)
        end
    else
        push!(dict.data, IntRangeSpan{K, V}(p.rv+1, rv, [v]))
    end
end

function traverse{K, V}(f::Function, dict::IntRangeDict{K, V})::Void
    for i in dict.data
        f(i.lv:i.rv, i.data)
    end
end

function show{K, V}(io::IO, dict::IntRangeDict{K, V})::Void
    println(io, "IntRangeDict{$K, $V}:")
    if isempty(dict.data)
        println(io, "  (empty)")
    else
        traverse(dict) do range, data
            println(io, "  ", range.start, '-', range.stop, ": ", join(data, ','))
        end
    end
end
