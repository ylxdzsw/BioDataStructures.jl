using IntRangeSets
using Base.Test

@testset "push integers" begin
    x = IntRangeSet{Int}()
    @test push!(x, 3) == x
    @test collect(x)  == [3:3]
    @test push!(x, 3) == x
    @test collect(x)  == [3:3]
    @test push!(x, 4) == x
    @test collect(x)  == [3:4]
    @test push!(x, 4) == x
    @test collect(x)  == [3:4]
    @test push!(x, 6) == x
    @test collect(x)  == [3:4, 6:6]
    @test push!(x, 5) == x
    @test collect(x)  == [3:6]
    @test push!(x, 0) == x
    @test collect(x)  == [0:0, 3:6]
    @test push!(x, 1) == x
    @test collect(x)  == [0:1, 3:6]
    @test push!(x, 2) == x
    @test collect(x)  == [0:6]
end

@testset "push ranges" begin
    x = IntRangeSet{Int}()
    @test push!(x, 2:5) == x
    @test collect(x)  == [2:5]
    @test push!(x, 15:15) == x
    @test collect(x)  == [2:5, 15:15]
    @test push!(x, 15:14) == x
    @test collect(x)  == [2:5, 15:15]
    @test push!(x, 15:15) == x
    @test collect(x)  == [2:5, 15:15]
    @test push!(x, 1:3) == x
    @test collect(x)  == [1:5, 15:15]
    @test push!(x, 0:0) == x
    @test collect(x)  == [0:5, 15:15]
    @test push!(x, 5:8) == x
    @test collect(x)  == [0:8, 15:15]
    @test push!(x, 14:16) == x
    @test collect(x)  == [0:8, 14:16]
    @test push!(x, 3:5) == x
    @test collect(x)  == [0:8, 14:16]
    @test push!(x, 0:20) == x
    @test collect(x)  == [0:20]
end

@testset "in operator" begin
    x = IntRangeSet{Int}()
    @test (2 in x) == false
    push!(x, 2:4)
    @test (2 in x) == true
    @test (1 in x) == false
    push!(x, 6)
    @test (6 in x) == true
    @test (5 in x) == false
    push!(x, 4:6)
    @test (5 in x) == true
end

@testset "union" begin
    x = IntRangeSet{Int}()
    y = IntRangeSet{Int}()
    push!(x, 2:4)
    push!(y, 6)
    @test collect(union(x,y)) == [2:4, 6:6]
    push!(y, 5:6)
    union!(x, y)
    @test collect(x) == [2:6]
end

@testset "intersect" begin
    x = IntRangeSet{Int}()
    y = IntRangeSet{Int}()
    push!(x, 2:4)
    push!(x, 8:10)
    push!(y, 3:9)
    @test collect(intersect(x, y)) == [3:4, 8:9]
end

@testset "additional random test" begin
    a = IntSet()
    b = IntRangeSet{Int}()

    for i in 1:50_000
        data = rand(1:1_000_000)
        if rand() < .2 # range
            data = data:data+rand(1:5)^2
            foreach(x->push!(a, x), data)
            push!(b, data)
        else # singel integer
            push!(a, data)
            push!(b, data)
        end
    end

    for i in 1:200_000
        data = rand(1:1_000_025)
        @test (data in a) == (data in b)
    end
end
