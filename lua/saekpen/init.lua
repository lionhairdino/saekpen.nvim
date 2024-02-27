local M = {}
M.saekpen_mode = false
-- 키맵 백업
M.key_backup_n = {}
M.key_backup_v = {}

-- saekpen이 사용하는 단축키, 0: 하일라이트 삭제
M.keys = { "1", "2", "3", "4", "5", "6", "7", "8", "<CR>", "9" }

M.namespace = -1
M.pencolor = -1
M.backupVisual = {}
M.popup_buf = -1

M.config = {
  color_table = {
    { fg = '#FFFFFF', bg = '#cf494c', ctermfg = 15, ctermbg = 0 },
    { fg = '#000000', bg = '#60b442', ctermfg = 15, ctermbg = 4 },
    { fg = '#000000', bg = '#db9c11', ctermfg = 0,  ctermbg = 10 },
    { fg = '#000000', bg = '#fce94f', ctermfg = 0,  ctermbg = 14 },
    { fg = '#FFFFFF', bg = '#0575d8', ctermfg = 0,  ctermbg = 9 },
    { fg = '#000000', bg = '#ad5ed2', ctermfg = 0,  ctermbg = 5 },
    { fg = '#000000', bg = '#1db6bb', ctermfg = 0,  ctermbg = 11 },
    { fg = '#000000', bg = '#bab7b6', ctermfg = 0,  ctermbg = 15 },
  }
}

local prepareColor = function()
  local nid = vim.api.nvim_create_namespace('Saekpen-ANSI')
  vim.api.nvim_set_hl(nid, 'ANSI39', M.backupVisual)           -- 지우개
  vim.api.nvim_set_hl(nid, 'ANSI40', { fg = M.config.color_table[1].fg, bg = M.config.color_table[1].bg })
  vim.api.nvim_set_hl(nid, 'ANSI41', { fg = M.config.color_table[2].fg, bg = M.config.color_table[2].bg })
  vim.api.nvim_set_hl(nid, 'ANSI42', { fg = M.config.color_table[3].fg, bg = M.config.color_table[3].bg })
  vim.api.nvim_set_hl(nid, 'ANSI43', { fg = M.config.color_table[4].fg, bg = M.config.color_table[4].bg })
  vim.api.nvim_set_hl(nid, 'ANSI44', { fg = M.config.color_table[5].fg, bg = M.config.color_table[5].bg })
  vim.api.nvim_set_hl(nid, 'ANSI45', { fg = M.config.color_table[6].fg, bg = M.config.color_table[6].bg })
  vim.api.nvim_set_hl(nid, 'ANSI46', { fg = M.config.color_table[7].fg, bg = M.config.color_table[7].bg })
  vim.api.nvim_set_hl(nid, 'ANSI47', { fg = M.config.color_table[8].fg, bg = M.config.color_table[8].bg })
  return nid
end

M.init = function()
  M.backupVisual = vim.api.nvim_get_hl(0, { name = 'Visual' })
  M.namespace = prepareColor()
end

-- Lazy 패키지 매니저가 자동으로 실행한다.
M.setup = function(user_opts)
  M.config = vim.tbl_deep_extend("force", M.config, user_opts or {})
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
    -- 기존 없는 매핑이면 무시한다는데, 오류가 난다.
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

local function popup()
  local buf = M.popup_buf
  buf = vim.api.nvim_create_buf(false, true)
  local width = 16
  local current_win = vim.api.nvim_get_current_win()
  local win_id = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = 1,
    row = 1,
    col = vim.api.nvim_win_get_width(current_win) - width - 1,
    style = 'minimal',
    border = 'none',
    focusable = false,
  })

  vim.api.nvim_win_set_hl_ns(win_id, M.namespace)
  --vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "123456789 Sakpen" })
  local hl
  for i, _ in ipairs(color_table) do
    hl = "ANSI" .. (39 + i)
    vim.api.nvim_buf_set_extmark(buf, M.namespace, 0, i - 1,
      { end_row = 0, end_col = i, virt_text = { { "" .. i, hl } }, virt_text_pos = 'overlay', })
  end

  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_command('wincmd p') -- 직전 윈도우로 포커스 옮기기
  return win_id
end

M.activePen = function(args)
  --  vim.api.nvim_out_write(vim.inspect(args))
  M.pencolor = tonumber(args[3])
  local preMode = args[4] -- 0: normal, 1: visual
  local colors

  local coloridx = M.pencolor - 39
  if coloridx == 0 then
    colors = M.backupVisual
  else
    colors = {
      fg = color_table[coloridx].fg,
      bg = color_table[coloridx].bg,
      ctermfg = color_table[coloridx].ctermfg,
      ctermbg = color_table[coloridx].ctermbg
    }
  end

  if colors ~= nil then
    vim.api.nvim_set_hl(M.namespace, 'Visual', colors)
  end
  vim.api.nvim_feedkeys('v', 'n', true)
  if preMode == '1' then vim.api.nvim_input('gv') end
end

local paint = function(args)
  local c = M.pencolor
  if c == -1 then return end
  local current_win = vim.api.nvim_get_current_win()
  local current_buf = vim.api.nvim_get_current_buf()
  local sp = vim.api.nvim_buf_get_mark(current_buf, '<')
  local ep = vim.api.nvim_buf_get_mark(current_buf, '>') -- 끝 글자가 한글일 때 문제가 있다.

  -- 이유는 모르지만 커서가 튄다. 있던 자리를 기억했다 되돌린다.
  -- 비주얼 모드로 들어가서 선택 이동을 해도,
  -- 현재 위치가 아니라 비주얼 모드를 시작했던 위치를 돌려준다.
  --local curpos = vim.api.nvim_win_get_cursor(current_win)
  --print(vim.inspect(curpos))

  --  extmark는 row를 0부터 시작. mark는 1부터
  --  f o o b a r      line contents
  --  0 1 2 3 4 5      character positions (0-based)
  -- 0 1 2 3 4 5 6     extmark positions (0-based)
  -- extmark는 이렇게 글자 사이 위치를 나타내며, 바bar 커서와 비슷한 위치다.
  -- "한글과한글자기호.", "한글" 두 경우 모두 strdisplaywidth의 결과가 4다
  local lastrow = vim.fn.getline(ep[1])
  local lastch = lastrow:sub(ep[2] + 1, ep[2] + 1)
  local ep_ = 0
  local lastch_len = vim.fn.strdisplaywidth(lastch)
  local lastrow_len = string.len(lastrow)
  if lastch_len > 1 then ep_ = ep[2] + lastch_len - 1 else ep_ = ep[2] + 1 end
  local ep__ = ep_ > lastrow_len and lastrow_len or ep_ -- 줄의 마지막 위치를 넘지 않게

  local hl = nil
  if (c == 39) then
    -- 현재 영역에 있는 모든 extmark를 찾아서 삭제한다.
    -- @todo
    -- extmark는 {시작점과 {끝점}}을 가지고 있다.
    -- 기준은 시작점이다. 끝점은 부가적인 정보다.
    -- 끝점이 현재 선택 영역에 포함되도 지워지지 않는다.
    -- 만일 지우고 싶다면, 끝점과 extmark id를 연결하는 별도
    -- 테이블을 만들어서 현재 영역에 포함되는지 순회해야 한다.
    local emarks = vim.api.nvim_buf_get_extmarks(current_buf, M.namespace, { sp[1] - 1, sp[2] }, { ep[1] - 1, ep__ }, {})
    print(vim.inspect(emarks))
    for _, em in ipairs(emarks) do
      vim.api.nvim_buf_del_extmark(current_buf, M.namespace, em[1])
    end
  else
    hl = 'ANSI' .. c
    vim.api.nvim_buf_set_extmark(current_buf, M.namespace, sp[1] - 1, sp[2],
      { end_row = ep[1] - 1, end_col = ep__, hl_eol = false, hl_group = hl, priority = 9999, hl_mode = "blend" })
    M.pencolor = -1
    --vim.api.nvim_set_hl(M.namespace,'Visual', M.backupVisual)
    -- nvim_set_hl 은 아예 대체하는 거고, :highlight는 있는 걸 업데이트할 수 있다고 한다.
    vim.api.nvim_set_hl(M.namespace, 'Visual', M.backupVisual)
    vim.api.nvim_win_set_cursor(current_win, ep)
  end
end

M.paint = function()
  paint(M.pencolor)
end

M.clear = function()
  local current_buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(current_buf, M.namespace, 0, -1)
end


M.toggle = function()
  if M.saekpen_mode then
    M.saekpen_mode = false
    local popup_id = M.popup_win_id
    if popup_id ~= nil then vim.api.nvim_win_close(popup_id, true) end
    -- 키맵 복원
    key_recover('n', M.keys, M.key_backup_n)
    key_recover('x', M.keys, M.key_backup_v)
  else
    vim.api.nvim_set_hl_ns(M.namespace)
    M.saekpen_mode = true
    -- 키맵 백업
    M.key_backup_n = key_backup('n', M.keys)
    M.key_backup_v = key_backup('x', M.keys)
    -- 색펜 셋업 (<C-U>를 먼저 입력하면 range를 무효화할 수 있다.)
    vim.api.nvim_buf_set_keymap(0, 'n', '1', ':ActivePen 40 0<CR>', { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, 'n', '2', ':ActivePen 41 0<CR>', { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, 'n', '3', ':ActivePen 42 0<CR>', { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, 'n', '4', ':ActivePen 43 0<CR>', { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, 'n', '5', ':ActivePen 44 0<CR>', { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, 'n', '6', ':ActivePen 45 0<CR>', { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, 'n', '7', ':ActivePen 46 0<CR>', { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, 'n', '8', ':ActivePen 47 0<CR>', { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, 'n', '9', ':ActivePen 39 0<CR>', { noremap = true, silent = true })

    vim.api.nvim_buf_set_keymap(0, 'x', '1', ':ActivePen 40 1<CR>', { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, 'x', '2', ':ActivePen 41 1<CR>', { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, 'x', '3', ':ActivePen 42 1<CR>', { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, 'x', '4', ':ActivePen 43 1<CR>', { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, 'x', '5', ':ActivePen 44 1<CR>', { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, 'x', '6', ':ActivePen 45 1<CR>', { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, 'x', '7', ':ActivePen 46 1<CR>', { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, 'x', '8', ':ActivePen 47 1<CR>', { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, 'x', '9', ':ActivePen 39 1<CR>', { noremap = true, silent = true })

    vim.api.nvim_buf_set_keymap(0, 'x', '<CR>', ':SaekPaint<CR>', { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, 'n', '<CR>', ':SaekPaint<CR>', { noremap = true, silent = true })
    -- 굳이 없어도 되지만 오류를 막기 위해

    -- @todo 팝업창 설정에 따라 안보이게
    M.popup_win_id = popup()
  end
end

return M
