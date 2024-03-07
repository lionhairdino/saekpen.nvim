if exists("g:loaded_saekpenplugin")
   finish
endif
let g:loaded_saekpenplugin = 1
lua require'saekpen'.init()
lua require'saekpen'.setup()

command! SaekpenMode lua require'saekpen'.toggle()<CR>
"command! -nargs=1 -range ActivePen lua require'saekpen'.activePen(<list1>,<list2>,<q-args>)<CR>
"command! -range -nargs=* ActivePen call luaeval("require'saekpen'.activePen(_A)",[<line1>, <line2>, <f-args>])")
"command! -range SaekPaint call luaeval("require'saekpen'.paint(_A)",[<line1>, <line2>])")
command! SaekpenClear lua require'saekpen'.clear()<CR>
command! -nargs=1 SaekpenOutput lua require'saekpen'.output(<q-args>)<CR>
command! SaekpenInput lua require'saekpen'.input()<CR>

