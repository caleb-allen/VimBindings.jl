using Revise
using VimBindings
ENV["JULIA_DEBUG"] = "Parse,ParseClauses"
using REPL
REPL.activate(VimBindings.Parse);