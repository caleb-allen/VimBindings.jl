
#=
LineDiff(index = 0,
         text = "")
""
->
"hello"

+LineDiff(index = 0,
         text = "hello")

"hello"
->
"he"

-LineDiff(index = 2
         text = "llo")

=#

struct LineDiff
    index :: Int64
    text :: String
end

+(x::LineDiff, y::LineDiff) = 

    function buffer(diff :: LineDiff)
end



function test_line_diff()
end


