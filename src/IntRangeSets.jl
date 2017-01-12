module IntRangeSets

export IntRangeSet

import Base: push!, in, show

type IntRange{T<:Integer}
    lv::T
    rv::T
    lp::Nullable{IntRange{T}}
    rp::Nullable{IntRange{T}}
    lc::Nullable{IntRange{T}}
    rc::Nullable{IntRange{T}}
    IntRange(lv, rv=lv, lp=nothing, rp=nothing, lc=nothing, rc=nothing) = new(lv, rv, lp, rp, lc, rc)
end

type IntRangeSet{T<:Integer} # <: Base.AbstractSet{T}
    balanced::Bool
    root::Nullable{IntRange{T}}
    cache::Nullable{IntRange{T}}
    IntRangeSet() = new(true, nothing, nothing)
end

typealias Tree IntRangeSet
typealias Node IntRange

# NOTE: tree.cache only used and updated in `push!` methods

function push!{T}(tree::Tree{T}, x::T)
    if tree.root.isnull
        node = Node{T}(x)
        push!(tree, node)
    elseif between_parents(x, tree.cache.value)
        push!(tree, tree.cache.value, x)
    else
        push!(tree, tree.root.value, x)
    end

    tree
end

function push!{T}(tree::Tree{T}, node::Node{T})
    if tree.root.isnull
        tree.root = node
        tree.cache = node
    else
        push!(tree, tree.root.value, x)
    end

    tree
end

function push!{T}(tree::Tree{T}, node::Node{T}, x::T)
    if x == node.lv - 1
        extend_left!(tree, node, x-1)
        tree.cache = node
    elseif x == node.rv + 1
        extend_right!(tree, node, x+1)
        tree.cache = node
    elseif x < node.lv
        if node.lc.isnull
            x = Node{T}(x, x, node.lp, node)
            node.lc = x
            tree.cache = x
            tree.balanced = false
        else
            push!(tree, node.lc, x)
        end
    elseif x > node.rv
        if node.rc.isnull
            x = Node{T}(x, x, node, node.rp)
            node.rc = x
            tree.cache = x
            tree.balanced = false
        else
            push!(tree, node.rc, x)
        end
    end

    tree
end

function extend_left!{T}(tree::Tree{T}, node::Node{T}, x::T)

end

function extend_right!{T}(tree::Tree{T}, node::Node{T}, x::T)

end

#== helper ==#

function between_parents{T}(x::T, node::Node{T})
    !node.lp.isnull && x <= node.lp.value.rv && return false
    !node.rp.isnull && x >= node.rp.value.lv && return false
    true
end

function traverse{T}(f::Function, tree::Tree{T})
    traverse(f, tree, tree.root)
end

function traverse{T}(f::Function, tree::Tree{T}, node::Nullable{Node{T}})
    if !node.isnull
        node = node.value
        traverse(f, tree, node.lc)
        f(node)
        traverse(f, tree, node.rc)
    end
end

function show{T}(io::IO, tree::IntRangeSet{T})
    println(io, "IntRangeSets{$T}:")
    if tree.root.isnull
        println(io, "  (empty)")
    else
        traverse(tree) do node
            println(io, "  ", node.lv, ':', node.rv)
        end
    end
end

end # module IntRangeSets
