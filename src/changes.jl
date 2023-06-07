module Changes
using ..TextUtils

export record, undo!, redo!

struct VimString <: AbstractString
    text::String
    start_column::Int
end

struct BufferRecord
    text::String
    cursor_index::Int
end

Base.:(==)(x::BufferRecord, y::BufferRecord) =
    x.text == y.text


function freeze(buf::IO)::BufferRecord
    pos = position(buf)
    seek(buf, 0)
    s = read(buf, String)
    seek(buf, pos)
    return BufferRecord(s, pos)
end

"""
Restore `buf` to the state recorded by `BufferRecord`
"""
function thaw!(buf::IO, rec::BufferRecord)
    truncate(buf, 0)
    write(buf, rec.text)
    # buf.mode = normal_mode
    seek(buf, rec.cursor_index)
end

struct Entry
    # line_above::Int # number of line above undo block
    # line_below::Int # number of line below undo block
    record::BufferRecord
    prev::Ref{Entry} # previous entry in list
    next::Ref{Entry} # next entry in list
end

# entry where both `prev` and `next` reference itself
function Entry(record::BufferRecord)
    e = Entry(record, Ref{Entry}(), Ref{Entry}())
    e.prev[] = e
    e.next[] = e
    return e
end

# an entry with a reference to a previous entry, but whose `next` is itself
# for the "head" of a list (the newest entry)
function Entry(record::BufferRecord, prev::Entry)
    e = Entry(record, Ref{Entry}(prev), Ref{Entry}())
    e.next[] = e
    return e
end

# blank entry. Both `prev` and `next` reference itself.
# for the root of a list (the first entry)
function Entry()
    record = VimBuffer("|") |> freeze
    return Entry(record)
end

const global root = Entry()
const latest = Ref{Entry}(root)

"""
Record the state of `buf` and save it to history.
"""
function record(buf::IO)
    record = freeze(buf)
    if record != latest[].record
        current = Entry(record)
        current.prev[] = latest[]
        latest[].next[] = current
        latest[] = current
        @debug "Recorded latest entry" record
    else
        @debug "Did not record new entry; record is equal to previous entry" record
    end
end

"""
Move from the current buffer record to the previous buffer record.
"""
function undo!(buf::IO)
    staged = latest[].prev[]
    thaw!(buf, staged.record)

    staged.prev[].next[] = staged
    latest[] = staged
    @debug "undo! to previous entry"
end

function redo!(buf::IO)
    staged = latest[].next[] 
    thaw!(buf, staged.record)
    
    staged.next[].prev[] = staged
    latest[] = staged
    @debug "redo! to next entry"
end

"""
reset the `root` and `latest` entries to initial conditions
"""
function reset!()
    root.next[] = root
    root.prev[] = root
    
    latest[] = root
end

function Base.:(==)(x::Entry, y::Entry)
    x.record == y.record &&
        x.start_column == y.start_column
end

end
