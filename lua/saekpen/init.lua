local M = {}
M.saekpen_mode = false
-- 키맵 백업
M.key_backup_n = {}
M.key_backup_v = {}
M.keys = { "1", "2", "3", "4", "5", "6", "7", "8" } -- saekpen이 사용하는 단축키
M.namespace = -1
M.pencolor = -1

local color_table = {
  { fg = '#FFFFFF', bg = '#555753', ctermfg = 1, ctermbg = 1 },
  { fg = '#FFFFFF', bg = '#ef2929', ctermfg = 2, ctermbg = 2 },
  { fg = '#000000', bg = '#8ae234', ctermfg = 3, ctermbg = 3 },
  { fg = '#000000', bg = '#fce94f', ctermfg = 4, ctermbg = 4 },
  { fg = '#000000', bg = '#32afff', ctermfg = 5, ctermbg = 5 },
  { fg = '#000000', bg = '#ad7fa8', ctermfg = 6, ctermbg = 6 },
  { fg = '#000000', bg = '#34e2e2', ctermfg = 7, ctermbg = 7 },
  { fg = '#000000', bg = '#ffffff', ctermfg = 8, ctermbg = 8 },
}

local prepareColor = function()
  local nid = vim.api.nvim_create_namespace('Saekpen-ANSI')
  print(nid)
  vim.api.nvim_set_hl(nid, 'ANSI40', {fg = color_table[1].fg, bg = color_table[1].bg})
  vim.api.nvim_set_hl(nid, 'ANSI41', {fg = color_table[2].fg, bg = color_table[2].bg})
  vim.api.nvim_set_hl(nid, 'ANSI42', {fg = color_table[3].fg, bg = color_table[3].bg})
  vim.api.nvim_set_hl(nid, 'ANSI43', {fg = color_table[4].fg, bg = color_table[4].bg})
  vim.api.nvim_set_hl(nid, 'ANSI44', {fg = color_table[5].fg, bg = color_table[5].bg})
  vim.api.nvim_set_hl(nid, 'ANSI45', {fg = color_table[6].fg, bg = color_table[6].bg})
  vim.api.nvim_set_hl(nid, 'ANSI46', {fg = color_table[7].fg, bg = color_table[7].bg})
  vim.api.nvim_set_hl(nid, 'ANSI47', {fg = color_table[8].fg, bg = color_table[8].bg})
  return nid
end

-- 현재 버퍼와 창 얻기
M.saek = function()
  local current_win = vim.api.nvim_get_current_win()
  local current_buf = vim.api.nvim_get_current_buf()

  -- 현재 창의 시작과 끝 위치 얻기
  --local start_pos = vim.api.nvim_win_get_cursor(current_win)

  -- 비주얼 모드에서 선택한 첫 글자로 보내기
  vim.api.nvim_command([[normal! `<]])
  local start_pos = vim.api.nvim_win_get_cursor(current_win)
  -- 비주얼 모드에서 선택한 끝 글자로 보내기
  vim.api.nvim_command([[normal! `>]])
  local end_pos = vim.api.nvim_win_get_cursor(current_win)
  -- 시작 위치와 끝 위치 출력
  print("시작 위치:", start_pos[1], start_pos[2])
  print("끝 위치:", end_pos[1], end_pos[2])
end

-- 보조 유틸
-- 내장 함수 찾으면 삭제할 것
local is_elem = function(tbl, value)
  for _, v in pairs(tbl) do
    if v == value then
      return true
    end
  end
  return false
end

local key_backup = function(mode, keys)
  local current_keymap = vim.api.nvim_buf_get_keymap(0, mode) -- 현재 버퍼
  local res = {}
  for _, one in ipairs(current_keymap) do
    if is_elem(keys, one.lhs) then
      table.insert(res, {
        mode = one.mode,
        lhs = one.lhs,
        rhs = one.rhs,
        noremap = one.noremap,
        silent = one.silent,
        expr = one.expr
      })
    end
  end
  return res
end

local key_recover = function(mode, keys, backup)
  -- 키 복원
  for _, one in ipairs(keys) do
    vim.api.nvim_buf_del_keymap(0, mode, one)
  end
  for _, one in ipairs(backup) do
    vim.api.nvim_buf_set_keymap(0
    , one.mode
    , one.lhs
    , one.rhs
    , { noremap = one.noremap, silent = one.silent, expr = one.expr }
    )
  end
end

local merge_table = function(t1, t2)
  local res = {}
  for _, v in ipairs(t1) do
    table.insert(res, v)
  end
  for _, v in ipairs(t2) do
    table.insert(res, v)
  end
  return res
end

local function popup(text)
  local width = 40
  local bufnr = vim.api.nvim_create_buf(false, true)
  local current_win = vim.api.nvim_get_current_win()
  local win_id = vim.api.nvim_open_win(bufnr, true, {
    relative = 'editor',
    width = width,
    height = 1,
    row = 1,
    col = vim.api.nvim_win_get_width(current_win) - width - 1,
    style = 'minimal',
    border = 'none',
    focusable = false,
  })

  --vim.api.nvim_buf_set_option(bufnr, 'modifiable', true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { text })
  vim.api.nvim_buf_set_option(bufnr, 'modifiable', false)
  vim.api.nvim_command('wincmd p') -- 직전 윈도우로 포커스 옮기기
  return win_id
end

local changeToVisualMode = function()
  -- n 모드만 넘어 오고 있다. 비주얼 모드에서 숫자를 누르는 순간 n모드로 바뀌는 것 같다.
  local m = vim.api.nvim_get_mode()
  -- 바뀐 highlight를 적용하기 위해
  -- 현재 비주얼 모드면 노말모드로 간 후 다시 비주얼 모드로
  print (m.mode)
  if m.mode:match('[vVsS]') ~= nil then
    -- local aid = vim.api.nvim_create_augroup('ChangeToVisualMode', { clear = true})
    -- vim.api.nvim_create_autocmd('ModeChanged', {
    --   group = 'ChangeToVisualMode',
    --   callback = function(ev)
    --     vim.api.nvim_feedkeys('v','n',true)
    --     vim.api.nvim_del_augroup_by_id(aid)
    --   end
    -- })
    --vim.api.nvim_feedkeys('','n',true)
    --vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>",true,false,true),'x',true)
    --vim.api.nvim_feedkeys('v', 'n', true)
    print ("이미 비주얼 모드")
    vim.api.nvim_input('gv')
  else
    print ("이미 비주얼 모드2")
    vim.api.nvim_feedkeys('v', 'n', true)
    vim.api.nvim_input('gv')
  end
end

M.activePen = function(args)
  --  vim.api.nvim_out_write(vim.inspect(args))
  M.pencolor = tonumber(args[3])
  print ("인자 ".. args[4])
  local preMode = args[4] -- 0: normal, 1: visual

  local coloridx = M.pencolor - 39
  local colors = { guifg = color_table[coloridx].fg
                 , guibg = color_table[coloridx].bg
                 , ctermfg = color_table[coloridx].ctermfg
                 , ctermbg = color_table[coloridx].ctermbg
                 }
  --  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>",true,false,true),'n',true)
  if colors ~= nil then
    vim.api.nvim_command(string.format(
      'highlight Visual guifg=%s guibg=%s ctermfg=%s ctermbg=%s',
      colors.guifg, colors.guibg, colors.ctermfg, colors.ctermbg))
  end
  --changeToVisualMode()
  vim.api.nvim_feedkeys('v', 'n', true)
  if preMode == '1' then vim.api.nvim_input('gv') end
  -- vim.api.nvim_feedkeys('','n',true)
  -- vim.api.nvim_feedkeys('v','n',true)
end

local paint = function(args)
  local c = M.pencolor
  local current_win = vim.api.nvim_get_current_win()
  local current_buf = vim.api.nvim_get_current_buf()
  local sp = vim.api.nvim_buf_get_mark(current_buf, '<')
  local ep = vim.api.nvim_buf_get_mark(current_buf, '>')
  --local last = string.len(vim.api.nvim_get_current_line())
  --끝 글자 얻는 방법을 아직 모른다. 일단 아래 방법으로.
  local lastch = vim.api.nvim_buf_get_text(current_buf, ep[1],ep[2],ep[1],ep[2],{})
  local ep_ = 0
  if lastch == '\r' then ep_ = ep[2] - 1 else ep_ = ep[2] end

  vim.api.nvim_buf_set_extmark(current_buf,M.namespace,sp[1]-1,sp[2],
    { end_row = ep[1] - 1, end_col = ep_, hl_eol = false, hl_group = 'ANSI'..c})
  vim.api.nvim_win_set_cursor(current_win, ep)
end

M.paint = function()
  paint(M.pencolor)
end

M.toggle = function()
  if M.saekpen_mode then
    print("SaekpenMode 종료")
    M.saekpen_mode = false
    local popup_id = M.popup_win_id
    if popup_id ~= nil then vim.api.nvim_win_close(popup_id, true) end
    -- 키맵 복원
    key_recover('n', M.keys, M.key_backup_n)
    key_recover('v', M.keys, M.key_backup_v)
  else
    M.namespace = prepareColor()
    vim.api.nvim_set_hl_ns(M.namespace)
    print("SaekpenMode 시작")
    M.saekpen_mode = true
    -- 키맵 백업
    M.key_backup_n = key_backup('n', M.keys)
    M.key_backup_n = key_backup('v', M.keys)
    -- M.key_backup = merge_table(normal_map,visual_map)
    -- 색펜 셋업
    -- <C-U>를 먼저 입력하면 range를 무효화할 수 있다.
    vim.api.nvim_buf_set_keymap(0, 'n', '1', ':ActivePen 40 0<CR>', { noremap = true, silent = false })
    vim.api.nvim_buf_set_keymap(0, 'n', '2', ':ActivePen 41 0<CR>', { noremap = true, silent = false })
    vim.api.nvim_buf_set_keymap(0, 'n', '3', ':ActivePen 42 0<CR>', { noremap = true, silent = false })
    vim.api.nvim_buf_set_keymap(0, 'n', '4', ':ActivePen 43 0<CR>', { noremap = true, silent = false })
    vim.api.nvim_buf_set_keymap(0, 'n', '5', ':ActivePen 44 0<CR>', { noremap = true, silent = false })
    vim.api.nvim_buf_set_keymap(0, 'n', '6', ':ActivePen 45 0<CR>', { noremap = true, silent = false })
    vim.api.nvim_buf_set_keymap(0, 'n', '7', ':ActivePen 46 0<CR>', { noremap = true, silent = false })
    vim.api.nvim_buf_set_keymap(0, 'n', '8', ':ActivePen 47 0<CR>', { noremap = true, silent = false })

    vim.api.nvim_buf_set_keymap(0, 'x', '1', ':ActivePen 40 1<CR>', { noremap = true, silent = false })
    vim.api.nvim_buf_set_keymap(0, 'x', '2', ':ActivePen 41 1<CR>', { noremap = true, silent = false })
    vim.api.nvim_buf_set_keymap(0, 'x', '3', ':ActivePen 42 1<CR>', { noremap = true, silent = false })
    vim.api.nvim_buf_set_keymap(0, 'x', '4', ':ActivePen 43 1<CR>', { noremap = true, silent = false })
    vim.api.nvim_buf_set_keymap(0, 'x', '5', ':ActivePen 44 1<CR>', { noremap = true, silent = false })
    vim.api.nvim_buf_set_keymap(0, 'x', '6', ':ActivePen 45 1<CR>', { noremap = true, silent = false })
    vim.api.nvim_buf_set_keymap(0, 'x', '7', ':ActivePen 46 1<CR>', { noremap = true, silent = false })
    vim.api.nvim_buf_set_keymap(0, 'x', '8', ':ActivePen 47 1<CR>', { noremap = true, silent = false })

    vim.api.nvim_buf_set_keymap(0, 'x', '<CR>', ':SaekPaint<CR>', { noremap = true,silent = false })
    -- @todo 팝업창 설정에 따라 안보이게
    M.popup_win_id = popup("Saekpen Mode")
  end
end

return M
