module Changes
using ..TextUtils

struct VimString <: AbstractString
    text::String
    start_column::Int
end
struct Entry
    # line_above::Int # number of line above undo block
    # line_below::Int # number of line below undo block
    record::BufferRecord
    prev::Ref{Entry} # previous entry in list
    next::Union{Entry,Nothing}

    # root entry
end


function Entry()
    record = VimBuffer("|") |> freeze
    e = Entry(record, Ref{Entry}(), nothing)
    e.prev[] = e
    e
end

function Base.:(==)(x::Entry, y::Entry)
    x.record == y.record &&
        x.start_column == y.start_column
end


const global root::Entry = Entry()
const latest::Ref{Entry} = Ref{Entry}(root)
function record(buf::VimBuffer)
    record = freeze(buf)
    if record != latest[].record
        @debug "Recording latest entry" record
        entry = Entry(record,)
        current.prev[] = latest[]
        latest[] = current
    else
        @debug "Entry is not different from previous entry. Not saving new record." record
    end
end

function previous_entry()

end

end