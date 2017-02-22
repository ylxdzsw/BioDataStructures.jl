export IntRangeSet

import Base: push!, in, show, foreach, collect, union, union!, intersect

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
        tree.root = node
        tree.cache = node
    elseif between_parents(x, tree.cache.value)
        push!(tree, tree.cache.value, x)
    else
        push!(tree, tree.root.value, x)
    end

    tree
end

function push!{T}(tree::Tree{T}, x::UnitRange{T})::Tree{T}
    x.start <= x.stop || return tree
    if tree.root.isnull
        node = Node{T}(x.start, x.stop)
        tree.root = node
        tree.cache = node
    elseif between_parents(x, tree.cache.value)
        push!(tree, tree.cache.value, x)
    else
        push!(tree, tree.root.value, x)
    end

    tree
end

function push!{T}(tree::Tree{T}, node::Node{T}, x::T)::Tree{T}
    if x == node.lv - 1
        extend_left!(tree, node, x)
        tree.cache = node
    elseif x == node.rv + 1
        extend_right!(tree, node, x)
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

"""
six position relations:
+-------------------+
     3333333333
    2222    5555
1111     44     6666
       ******
+-------------------+
1: insert to left child
2: extend left
3: extend both side
4: just ingnore
5: extend right
6: insert to right child
"""
function push!{T}(tree::Tree{T}, node::Node{T}, x::UnitRange{T})::Tree{T}
    if x.start < node.lv
        if x.stop < node.lv - 1
            if node.lc.isnull
                x = Node{T}(x.start, x.stop, node.lp, node)
                node.lc = x
                tree.cache = x
                tree.balanced = false
            else
                push!(tree, node.lc.value, x)
            end
        else
            extend_left!(tree, node, x.start)
            if x.stop > node.rv
                extend_right!(tree, node, x.stop)
            end
            tree.cache = node
        end
    elseif x.stop > node.rv
        if x.start <= node.rv + 1
            extend_right!(tree, node, x.stop)
            tree.cache = node
        else
            if node.rc.isnull
                x = Node{T}(x.start, x.stop, node, node.rp)
                node.rc = x
                tree.cache = x
                tree.balanced = false
            else
                push!(tree, node.rc.value, x)
            end
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
    else
        node.rv = x
    end

    x > node.rv ? extend_right!(tree, node, x) : node
end

# left subtree will be lost, as they are covered by the fused node
function fuse_lp!{T}(tree::Tree{T}, node::Node{T})::Node{T}
    # 1. hoist right child to the position of node
    if node.lp.value.rc.value == node # linked to lp directly
        node.lp.value.rc = node.rc
    else
        node.rp.value.lc = node.rc
    end
    # 2. inherit lp
    p = node.rc
    while !p.isnull
        p.value.lp = node.lp
        p = p.value.lc
    end
    # 3. adjust lp range
    node.lp.value.rv = node.rv
    # 4. track balanced property
    tree.balanced = false
    node.lp.value
end

function fuse_rp!{T}(tree::Tree{T}, node::Node{T})::Node{T}
    if node.rp.value.lc.value == node
        node.rp.value.lc = node.lc
    else
        node.lp.value.rc = node.lc
    end
    p = node.lc
    while !p.isnull
        p.value.rp = node.rp
        p = p.value.rc
    end
    node.rp.value.lv = node.lv
    tree.balanced = false
    node.rp.value
end

function swap_lc!{T}(tree::Tree{T}, node::Node{T})::Node{T}
    # 1. preserve a pointer to the right subtree
    temp = node.lc.value.rc
    # 2. hoist left child to the position of node
    if !node.lp.isnull && node.lp.value.rc.value == node
        node.lp.value.rc = node.lc
    elseif !node.rp.isnull
        node.rp.value.lc = node.lc
    else # root
        tree.root = node.lc
    end
    # 3. inherit
    node.lc.value.rc = node
    node.lc.value.rp = node.rp
    # 4. setup node itself
    node.lp = node.lc
    node.lc = temp
    # 5. return the node in the origin position
    node.lp.value
end

function swap_rc!{T}(tree::Tree{T}, node::Node{T})::Node{T}
    temp = node.rc.value.lc
    if !node.rp.isnull && node.rp.value.lc.value == node
        node.rp.value.lc = node.rc
    elseif !node.lp.isnull
        node.lp.value.rc = node.rc
    else
        tree.root = node.rc
    end
    node.rc.value.lc = node
    node.rc.value.lp = node.lp
    node.rp = node.rc
    node.rc = temp
    node.rp.value
end

function rebalance!{T}(tree::Tree{T})::Int
    depth = tree.root.isnull ? 0 : rebalance!(tree, tree.root.value)
    tree.balanced = true
    depth
end

# TODO: this is O(n) operation. Maybe we should store balance factor in each node?
function rebalance!{T}(tree::Tree{T}, node::Node{T})::Int
    ld = node.lc.isnull ? 0 : rebalance!(tree, node.lc.value)
    rd = node.rc.isnull ? 0 : rebalance!(tree, node.rc.value)
    if ld - rd > 1
        swap_lc!(tree, node)
        ld
    elseif rd - ld > 1
        swap_rc!(tree, node)
        rd
    else # already balance
        max(ld, rd) + 1
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

function union{T}(t1::Tree{T}, t2::Tree{T})::Tree{T}
    tree = Tree{T}()
    union!(tree, t1)
    union!(tree, t2)
    tree
end

function union{T}(ts::Tree{T}...)::Tree{T}
    tree = Tree{T}()
    for t in ts
        union!(tree, t)
    end
    tree
end

function union!{T}(t1::Tree{T}, t2)::Tree{T}
    t1.balanced || rebalance!(t1)
    foreach(x->push!(t1, x), t2)
    t1
end

function intersect{T}(t1::Tree{T}, t2::Tree{T})::Tree{T}
    tree = Tree{T}()
    a, b = collect(t1), collect(t2)
    i, j = 1, 1

    while true
        if i > length(a) || j > length(b)
            break
        end

        start = max(a[i].start, b[j].start)

        if a[i].stop < b[j].stop
            push!(tree, start:a[i].stop)
            i += 1
        else
            push!(tree, start:b[j].stop)
            j += 1
        end
    end

    tree
end

# TODO: intersect all in one pass
function intersect{T}(ts::Tree{T}...)::Tree{T}
    reduce(intersect, ts)
end

function in{T}(x::T, tree::Tree{T})::Bool
    tree.balanced || rebalance!(tree)
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

function between_parents{T}(x::T, node::Node{T})::Bool
    !node.lp.isnull && x <= node.lp.value.rv + 1 && return false
    !node.rp.isnull && x >= node.rp.value.lv - 1 && return false
    true
end

function between_parents{T}(x::UnitRange{T}, node::Node{T})::Bool
    !node.lp.isnull && x.start <= node.lp.value.rv + 1 && return false
    !node.rp.isnull && x.stop  >= node.rp.value.lv - 1 && return false
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
