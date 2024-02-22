if exists("g:loaded_saekpenplugin")
  finish
endif
let g:loaded_saekpenplugin = 1

let s:lua_rocks_deps_loc = expand("<sfile>:h:r") . "/../lua/saekpen/deps"
exe "lua package.path = package.path ..';" . s:lua_rocks_deps_loc . "/lua-?/init.lua'"

"command! -nargs=0 FetchTodos lua require("plugin_sample").fetch_todos()
"command! -nargs=0 InsertTodo lua require("plugin_sample").insert_todo()
"command! -nargs=0 CompleteTodo lua require("plugin_sample").complete_todo()

