" if exists("g:loaded_saekpenplugin")
"   finish
" endif
" let g:loaded_saekpenplugin = 1
"
"
" let s:lua_rocks_deps_loc = expand("<sfile>:h:r") . "/../lua/saekpen/deps"
" exe "lua package.path = package.path ..';" . s:lua_rocks_deps_loc . "/lua-?/init.lua'"
"
"command! -nargs=0 FetchTodos lua require("plugin_sample").fetch_todos()
"command! -nargs=0 InsertTodo lua require("plugin_sample").insert_todo()
"command! -nargs=0 CompleteTodo lua require("plugin_sample").complete_todo()
"
"lua require'saekpen'.init_highlights()
"lua require'saekpen'.run_autocommands()
command! Saek lua require'saekpen'.saek()<CR>
command! SaekMode lua require'saekpen'.toggle()<CR>
"command! -nargs=1 -range ActivePen lua require'saekpen'.activePen(<list1>,<list2>,<q-args>)<CR>
command! -range -nargs=* ActivePen call luaeval("require'saekpen'.activePen(_A)",[<line1>, <line2>, <f-args>])")
command! -range SaekPaint call luaeval("require'saekpen'.paint(_A)",[<line1>, <line2>])")
