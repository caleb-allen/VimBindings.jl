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
    @debug "thaw" rec
    seek(buf, rec.cursor_index)
end

struct Entry
    # line_above::Int # number of line above undo block
    # line_below::Int # number of line below undo block
    id::Int # TODO add an ID so that entries with the same content are not equivalent
    prev::Ref{Entry} # previous entry in list
    next::Ref{Entry} # next entry in list
    record::BufferRecord
end


Entry(s::String) = Entry(freeze(testbuf("|")))
# entry where both `prev` and `next` reference itself
function Entry(record::BufferRecord)
    e = Entry(1, Ref{Entry}(), Ref{Entry}(), record)
    e.prev[] = e
    e.next[] = e
    return e
end

# an entry with a reference to a previous entry, but whose `next` is itself
# for the "head" of a list (the newest entry)
function Entry(record::BufferRecord, prev::Entry)
    e = Entry(prev.id + 1, Ref{Entry}(prev), Ref{Entry}(), record)
    e.next[] = e
    return e
end

# blank entry. Both `prev` and `next` reference itself. id of 1.
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
    @debug "Recording latest entry..." record
    if record != latest[].record
        current = Entry(record, latest[])
        current.prev[] = latest[]
        latest[].next[] = current
        latest[] = current
        @debug "Recorded latest entry" record
    else
        @debug "Did not record new entry; record is equal to previous entry" record
    end
    show_full_history(latest[])
end

"""
Move from the current buffer record to the previous buffer record.
"""
function undo!(buf::IO)
    staged = latest[].prev[]
    show_full_history(staged)
    thaw!(buf, staged.record)

    latest[] = staged

    show_full_history()
    @debug "undo! to previous entry"
end

function redo!(buf::IO)
    staged = latest[].next[]
    show_full_history(staged)
    if staged === latest[]
        @debug "no newer entries. No redo."
        return
    end
    thaw!(buf, staged.record)

    latest[] = staged
    show_full_history()
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

Base.:(==)(x::Entry, y::Entry) = x.record == y.record && x.id == y.id

function show_full_history(selected::Entry=latest[])
    r = root_of(selected)
    # @debug "got root of entry" root=r entry=selected
    buf = IOBuffer()
    for entry in r
        # show(buf, entry)
        # @debug "history" entry r
        write(buf, show(buf, entry))
    end
    seek(buf, 0)
    hist_string = "\n" * read(buf, String)

    @debug hist_string
end


"""
Follow the linked list to the root and return the root.
"""
function root_of(selected::Entry)::Entry
    x = selected
    # find the root (where .prev references itself)
    while !is_first(x)
        x = x.prev[]
    end
    return x
end

"""
Whether the entry is the last in the linked list
"""
is_last(x::Entry) = x.next[] === x

"""
Whether the entry is the first in the linked list
"""
is_first(x::Entry) = x.prev[] === x

function Base.iterate(entry::Entry, state=nothing)
    # @show entry
    # @show state
    if state === nothing
        return (entry, entry)
    end
    if is_last(state)
        # last item of the list
        return nothing
    else
        return (state.next[], state.next[])
    end
end

Base.IteratorSize(::Type{Entry}) = Base.SizeUnknown()
Base.eltype(::Type{Entry}) = Entry


# function Base.show(io::IO, ::MIME"text/plain", entry::Entry)
function Base.show(io::IO, entry::Entry)
    if entry === latest[]
        write(io, "→\t")
    else
        write(io, "\t")
    end
    write(io, "Entry($(entry.id), \"" * entry.record.text * "\")\n")
end




end