module IntRangeSets

export IntRangeSet

import Base: push!, in, show, foreach, collect

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

function push!{T}(tree::Tree{T}, x::T)::Tree{T}
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

function push!{T}(tree::Tree{T}, node::Node{T})::Tree{T}
    if tree.root.isnull
        tree.root = node
        tree.cache = node
    else
        push!(tree, tree.root.value, x)
    end

    tree
end

function push!{T}(tree::Tree{T}, node::Node{T}, x::T)::Tree{T}
    if x == node.lv - 1
        node = extend_left!(tree, node, x)
        tree.cache = node
    elseif x == node.rv + 1
        node = extend_right!(tree, node, x)
        tree.cache = node
    elseif x < node.lv
        if node.lc.isnull
            x = Node{T}(x, x, node.lp, node)
            node.lc = x
            tree.cache = x
            tree.balanced = false
        else
            push!(tree, node.lc.value, x)
        end
    elseif x > node.rv
        if node.rc.isnull
            x = Node{T}(x, x, node, node.rp)
            node.rc = x
            tree.cache = x
            tree.balanced = false
        else
            push!(tree, node.rc.value, x)
        end
    end

    tree
end

function extend_left!{T}(tree::Tree{T}, node::Node{T}, x::T)::Node{T}
    if !node.lc.isnull
        rmlc = right_most(tree, node.lc.value) # here can be optimized: stop at the first node that rv + 1 >= x
        if x <= rmlc.rv + 1
            fuse_rp!(tree, rmlc)
        else
            node.lv = x
        end
    elseif !node.lp.isnull && x <= node.lp.value.rv + 1
        node = fuse_lp!(tree, node)
    else
        node.lv = x
    end

    x < node.lv ? extend_left!(tree, node, x) : node
end

function extend_right!{T}(tree::Tree{T}, node::Node{T}, x::T)::Node{T}
    if !node.rc.isnull
        lmrc = left_most(tree, node.rc.value)
        if x >= lmrc.lv - 1
            fuse_lp!(tree, lmrc)
        else
            node.rv = x
        end
    elseif !node.rp.isnull && x >= node.rp.value.lv - 1
        node = fuse_rp!(tree, node)
    else
        node.rv = x
    end

    x > node.rv ? extend_right!(tree, node, x) : node
end

function fuse_lp!{T}(tree::Tree{T}, node::Node{T})::Node{T}
    # 1. delete left subtree, as they all lie in the range of fused node
    node.lc = nothing
    # 2. hoist right child to the position of node
    if node.lp.value.rc.value == node # linked to lp directly
        node.lp.value.rc = node.rc
    else
        node.rp.value.lc = node.rc
    end
    node.rc.isnull || (node.rc.value.lp = node.lp)
    # 3. adjust lp range
    node.lp.value.rv = node.rv
    # 4. track balanced property
    tree.balanced = false
    node.lp.value
end

function fuse_rp!{T}(tree::Tree{T}, node::Node{T})::Node{T}
    node.rc = nothing
    if node.rp.value.lc.value == node
        node.rp.value.lc = node.lc
    else
        node.lp.value.rc = node.lc
    end
    node.lc.isnull || (node.lc.value.rp = node.rp)
    node.rp.value.lv = node.lv
    tree.balanced = false
    node.rp.value
end

function rebalance!{T}(tree::Tree{T}, node::Node{T})::Int
    ld = node.lc.isnull ? 0 : rebalance!(node.lc.value) + 1
    rd = node.rc.isnull ? 0 : rebalance!(node.rc.value) + 1
    if ld - rd > 1

    elseif rd - ld > 1

    else # balance

    end

end

"apply f to each UnitRange in IntRangeSet, order is guaranteed"
function foreach{T}(f::Function, tree::Tree{T})::Void
    traverse(tree) do node
        f(node.lv:node.rv)
    end
end

"get a list of UnitRange that is in IntRangeSet, order is guaranteed"
function collect{T}(tree::Tree{T})::Vector{UnitRange{T}}
    list = UnitRange{T}[]
    foreach(x->push!(list, x), tree)
    list
end

function in{T}(x::T, tree::Tree{T})::Bool
    tree.root.isnull ? false : in(tree, tree.root.value, x)
end

function in{T}(tree::Tree{T}, node::Node{T}, x::T)::Bool
    if x < node.lv
        node.lc.isnull ? false : in(tree, node.lc.value, x)
    elseif x > node.rv
        node.rc.isnull ? false : in(tree, node.rc.value, x)
    else
        true
    end
end

#== helper ==#

function between_parents{T}(x::T, node::Node{T})::Bool
    !node.lp.isnull && x <= node.lp.value.rv + 1 && return false
    !node.rp.isnull && x >= node.rp.value.lv - 1 && return false
    true
end

function traverse{T}(f::Function, tree::Tree{T})::Void
    traverse(f, tree, tree.root)
end

function traverse{T}(f::Function, tree::Tree{T}, node::Nullable{Node{T}})::Void
    if !node.isnull
        node = node.value
        traverse(f, tree, node.lc)
        f(node)
        traverse(f, tree, node.rc)
    end
end

function left_most{T}(tree::Tree{T}, node::Node{T})::Node{T}
    while !node.lc.isnull
        node = node.lc.value
    end
    node
end

function right_most{T}(tree::Tree{T}, node::Node{T})::Node{T}
    while !node.rc.isnull
        node = node.rc.value
    end
    node
end

function show{T}(io::IO, tree::Tree{T})::Void
    println(io, "IntRangeSets{$T}:")
    if tree.root.isnull
        println(io, "  (empty)")
    else
        traverse(tree) do node
            println(io, "  ", node.lv, ':', node.rv)
        end
    end
end

function total_size(tree::Tree)::Int
    n = sizeof(tree)
    traverse(tree) do node
        n += sizeof(node)
    end
    n
end

end # module IntRangeSets
