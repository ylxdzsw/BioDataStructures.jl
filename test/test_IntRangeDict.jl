@testset "IntRangeDict_basic" begin
    x = IntRangeDict{Int, Int}()
    @test x[2] == []

    push!(x[3:5], 1)
    @test x[2] == []
    @test x[3] == [1]
    @test x[4] == [1]
    @test x[5] == [1]
    @test x[6] == []

    push!(x[7:7], 2)
    @test x[5] == [1]
    @test x[6] == []
    @test x[7] == [2]
    @test x[8] == []

    push!(x[1:2], 3)
    @test x[0] == []
    @test x[1] == [3]
    @test x[2] == [3]
    @test x[3] == [1]

    push!(x[1:7], 4)
    @test x[1] == [3, 4]
    @test x[3] == [1, 4]
    @test x[6] == [4]
    @test x[8] == []
end

@testset "IntRangeDict_save_and_load" begin
    x = IntRangeDict{Int, Int}()

    push!(x[4:5], 1)
    push!(x[7:8], 2)
    buf = save(x)

    y = IntRangeDict{Int, Int}(IOBuffer(buf))
    @test y[3] == []
    @test y[5] == [1]
    @test y[6] == []
    @test y[7] == [2]
    @test y[9] == []
end
