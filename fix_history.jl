#!/usr/bin/env julia
#
# Find any Julia history entries with control sequences that corrupt the REPL state.
# By default, print the lines which are corrupted.
#
# usage: ./fix_history.jl [--delete_corrupted, --escape_corrupted]
#
# --delete_corrupted: remove entries which are corrupted from history.
#
# --escape_corrupted: sanitize the entries which are corrupted so that the corrupted
# entries are still in history but can be safely displayed on the terminal.
#
# using  will copy the contents of `repl_history.jl` with the corrupted
# entries removed. A backup file will be created at `repl_history_backup.jl`
# prior to any modifications.

history_file = joinpath(homedir(), ".julia/logs/repl_history.jl")
delete_entries = false
if "--delete_corrupted" in ARGS
    delete_entries = true
end
escape_entries = false
if "--escape_corrupted" in ARGS
    escape_entries = true
end

if escape_entries && delete_entries
    println("Invalid parameters. Only use 1 of --escape_corrupted and --delete_corrupted")
    exit(2)
end

struct HistoryEntry
    time::String
    mode::String
    content::String
end

function is_hist_metadata(line::AbstractString)::Bool
    rx = r"# (time|mode): .*"
    match(rx, line) !== nothing
end
"""
Find the lines that make up the history entry at `starting_line`, including commented lines for time and mode.
"""
function entry_lines(lines, starting_line::Int)::UnitRange
    i = starting_line
    metadata_entries = 0
    while metadata_entries < 2
        i -= 1
        if is_hist_metadata(lines[i])
            metadata_entries += 1
        end
    end
    start = i

    i = starting_line
    metadata_entries = 0
    while metadata_entries == 0
        i += 1
        if is_hist_metadata(lines[i])
            metadata_entries += 1
        end
    end
    endd = i
    return start:endd
end

function is_corrupted(entry::HistoryEntry)::Bool
    bad_char = '\e'
    return bad_char in entry.content
end

corrupted(entries::Vector{HistoryEntry})::Vector{HistoryEntry} = filter(is_corrupted, entries)
uncorrupted(entries::Vector{HistoryEntry})::Vector{HistoryEntry} = filter(!is_corrupted, entries)

function entries()::Vector{HistoryEntry}
    entries = []
    metadata_lines = 0

    time = nothing
    mode = nothing
    content = []
    for line in eachline(history_file)
        if is_hist_metadata(line)
            if metadata_lines == 0
                if time !== nothing && mode !== nothing
                    # create an entry value if necessary
                    push!(entries,
                        HistoryEntry(time, mode, join(content, "\n")))
                end
                # reset for a new entry
                time = line
                mode = nothing
                content = []
            elseif metadata_lines == 1
                mode = line
            end
            metadata_lines += 1
        else
            metadata_lines = 0
            push!(content, line)
        end
    end
    entries
end

function write_history(entries::Vector{HistoryEntry})
    backup_file = joinpath(homedir(), ".julia/logs/repl_history_backup.jl")
    cp(history_file, backup_file)
    println("copied $history_file to $backup_file")

    out_file = history_file
    rm(history_file)
    touch(history_file)
    open(out_file, "w") do io
        for entry in entries
            write(io, entry)
            write(io, "\n")
        end
    end
    return out_file
end

function Base.write(io::IO, e::HistoryEntry)
    if is_corrupted(e)
        print(io, e.time * "\n" * e.mode * "\n\t" * escape_string(e.content[2:end])) # exclude tab char
    else
        print(io, e.time * "\n" * e.mode * "\n" * e.content)
    end
end
function Base.show(io::IO, e::HistoryEntry)
    if is_corrupted(e)
        println(io, "\t" * e.time * "\n\t" * e.mode * "\n\t\t" * escape_string(e.content))
    else
        println(io, "\t" * e.time * "\n\t" * e.mode * "\n\t" * e.content)
    end
end

function fix_history(; delete_entries=false, escape_entries=false)
    es = entries()
    corrupt = corrupted(es)
    if isempty(corrupt)
        println("No corrupt entries found.")
        return
    end
    println("Found $(length(corrupt)) corrupted entries!")

    es = if delete_entries
        uncorrupted(entries())
    elseif escape_entries
        entries()
    else
        println(
            """
            run 
               `./fix_history.jl --delete_entries`
            or
               `./fix_history.jl --escape_entries`
            to fix and overwrite $history_file.""")
        return
    end

    out_file = write_history(es)
    println("Wrote history at $out_file")
end

fix_history(; delete_entries, escape_entries)

