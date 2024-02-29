local M = {}

local H = require 'saekpen/history'

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
  vim.api.nvim_set_hl(nid, 'ANSI39', M.backupVisual) -- 지우개
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

function M.init()
  --제일 먼저 호출, 사용자 정의값이 필요 없는 초기화 과정은 여기
  M.saekpen_mode = false
  -- 키맵 백업
  M.key_backup_n = {}
  M.key_backup_v = {}
  -- saekpen이 사용하는 단축키, 0: 하일라이트 삭제
  M.keys = { "1", "2", "3", "4", "5", "6", "7", "8", "<CR>", "9" }
  M.namespace = -1
  M.penColor = -1
  M.backupVisual = {}
  M.popup_buf = -1
  M.history = H.init()
end

-- init 다음에 호출. 사용자 정의값은 여기서 적용
function M.setup(user_opts)
  M.config = vim.tbl_deep_extend("force", M.config, user_opts or {})
  M.backupVisual = vim.api.nvim_get_hl(0, { name = 'Visual' })
  M.namespace = prepareColor()
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
  for i, _ in ipairs(M.config.color_table) do
    hl = "ANSI" .. (39 + i)
    vim.api.nvim_buf_set_extmark(buf, M.namespace, 0, i - 1,
      { end_row = 0, end_col = i, virt_text = { { "" .. i, hl } }, virt_text_pos = 'overlay', })
  end

  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_command('wincmd p') -- 직전 윈도우로 포커스 옮기기
  return win_id
end

function M.activePen(penColor, preMode)
  --args[1],args[2]로 선택 range가 들어오지만 지금은 쓰지 않는다.
  --vim.api.nvim_out_write(vim.inspect(args))
  --M.penColor = tonumber(args[3])
  --local preMode = args[4] -- 0: normal, 1: visual
  M.penColor = penColor

  local colors

  local coloridx = M.penColor - 39
  if coloridx == 0 then
    colors = M.backupVisual
  else
    colors = {
      fg = M.config.color_table[coloridx].fg,
      bg = M.config.color_table[coloridx].bg,
      ctermfg = M.config.color_table[coloridx].ctermfg,
      ctermbg = M.config.color_table[coloridx].ctermbg
    }
  end

  if colors ~= nil then
    vim.api.nvim_set_hl(M.namespace, 'Visual', colors)
  end
  if preMode == 1 then
    vim.api.nvim_input('gv')
  else
    vim.api.nvim_feedkeys('v', 'n', true)
  end
end

function M.paint()
  local c = M.penColor
  if c == -1 then return end
  local current_win = vim.api.nvim_get_current_win()
  local current_buf = vim.api.nvim_get_current_buf()
  local sp = vim.api.nvim_buf_get_mark(current_buf, '<')
  local ep = vim.api.nvim_buf_get_mark(current_buf, '>') -- 끝 글자가 한글일 때 문제가 있다.

  -- 이유는 모르지만 커서가 튄다. 있던 자리를 기억했다 되돌린다.
  -- 비주얼 모드로 들어가서 선택 이동을 해도,
  -- 현재 위치가 아니라 비주얼 모드를 시작했던 위치를 돌려준다.
  --local curpos = vim.api.nvim_win_get_cursor(current_win)

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
    -- extmark는 {시작점과 {끝점}}을 가지고 있다.
    -- 기준은 시작점이다. 끝점은 부가적인 정보다.
    -- 끝점이 현재 선택 영역에 포함되어도 지워지지 않는다.
    --
    -- @todo
    -- 만일 지우고 싶다면, 끝점과 extmark id를 연결하는 별도
    -- 테이블을 만들어서 현재 영역에 포함되는지 순회해야 한다.
    local emarks = vim.api.nvim_buf_get_extmarks(current_buf, M.namespace, { sp[1] - 1, sp[2] }, { ep[1] - 1, ep__ },
      { details = true })
    for _, em in ipairs(emarks) do
      vim.api.nvim_buf_del_extmark(current_buf, M.namespace, em[1])
      local v = { -1, em[2], em[3], em[4].end_row, em[4].end_col, em[4].hl_group }
      H.add(M.history, v)
    end
  else
    hl = 'ANSI' .. c
    vim.api.nvim_buf_set_extmark(current_buf, M.namespace, sp[1] - 1, sp[2],
      { end_row = ep[1] - 1, end_col = ep__, hl_eol = false, hl_group = hl, priority = 9999, hl_mode = "blend" })
    H.add(M.history, { 1, sp[1] - 1, sp[2], ep[1] - 1, ep__, hl }) -- 첫 번째 1:추가 -1:삭제
    M.penColor = -1
    --vim.api.nvim_set_hl(M.namespace,'Visual', M.backupVisual)
    -- nvim_set_hl 은 아예 대체하는 거고, :highlight는 있는 걸 업데이트할 수 있다고 한다.
    vim.api.nvim_win_set_cursor(current_win, ep)
    vim.api.nvim_set_hl(M.namespace, 'Visual', M.backupVisual)
    --vim.api.nvim_feedkeys('v', 'n', true) -- Visual 모드 끝내는 v
  end
  H.reset_redo(M.history)
end

local function undo_redo(doit) -- doit: H.redo 혹은 H.undo
  local current_win = vim.api.nvim_get_current_win()
  local current_buf = vim.api.nvim_get_current_buf()
  local last = doit(M.history)
  if last == nil then return end
  if (last[1] == 1) then -- 1 : 추가 -1: 삭제
    local emark = vim.api.nvim_buf_get_extmarks(current_buf, M.namespace, { last[2], last[3] }, { last[4], last[5] }, {})
    vim.api.nvim_buf_del_extmark(current_buf, M.namespace, emark[1][1])
    vim.api.nvim_win_set_cursor(current_win, { last[2] + 1, last[3] })
  else
    vim.api.nvim_buf_set_extmark(current_buf, M.namespace, last[2], last[3],
      { end_row = last[4], end_col = last[5], hl_eol = false, hl_group = last[6], priority = 9999, hl_mode = "blend" })
    vim.api.nvim_win_set_cursor(current_win, { last[4] + 1, last[5] })
  end
end

function M.undo()
  undo_redo(H.undo)
end

function M.redo()
  undo_redo(H.redo)
end

local function get_all_extmark()
  local current_buf = vim.api.nvim_get_current_buf()
  local all = vim.api.nvim_buf_get_extmarks(current_buf, M.namespace, 0, -1, { details = true })
  local res = ""
  for _, one in ipairs(all) do
    local str = string.format(';%s,%s,%s,%s,%s', one[2], one[3], one[4].end_row, one[4].end_col, one[4].hl_group)
    res = res .. str
  end
  return res
end

function M.output()
  vim.api.nvim_put({ "/Saekpen" .. get_all_extmark() }, '', false, true)
end

local function read_extmarks_str(s, e)
  local current_buf = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(current_buf, s, e, false)
  for _, line in ipairs(lines) do
    local matched = string.find(line, '/Saekpen;', 1, false)
    if matched ~= nil then
      return string.sub(line,matched+9, #line) -- /Saekpen 문자열 날리기
    end
  end
  return nil
end

function M.input()
  local current_win = vim.api.nvim_get_current_win()
  local current_buf = vim.api.nvim_get_current_buf()
  local em_str = read_extmarks_str(-5, -1)
  if em_str ~= nil then
    for em in string.gmatch(em_str, "[^;]+") do
      local props = {}
      local i = 1
      for p in string.gmatch(em, "[^,]+") do
        props[i] = p
        i = i + 1
      end
      if props ~= nil then
        local e1 = tonumber(props[1])
        local e2 = tonumber(props[2])
        local e3 = tonumber(props[3])
        local e4 = tonumber(props[4])
        vim.api.nvim_buf_set_extmark(current_buf, M.namespace, e1, e2,
          { end_row = e3, end_col = e4, hl_eol = false, hl_group = props[5], priority = 9999, hl_mode = "blend" })
        vim.api.nvim_win_set_cursor(current_win, { e3 + 1, e4 }) -- 1,0 인덱스
      end
    end
  end
end

function M.clear()
  local current_buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(current_buf, M.namespace, 0, -1)
  M.history = H.init()
end

function M.toggle()
  if M.saekpen_mode then
    M.saekpen_mode = false
    if M.popup_win_id ~= nil then vim.api.nvim_win_close(M.popup_win_id, true) end
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
    -- 무효화 시키면 nvim_buf_get_mark로도 얻을 수 없다.
    local activePenCmd = ":lua require'saekpen'.activePen(%d,%d)<CR>"
    vim.api.nvim_buf_set_keymap(0, 'n', '1', string.format(activePenCmd, 40, 0), { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, 'n', '2', string.format(activePenCmd, 41, 0), { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, 'n', '3', string.format(activePenCmd, 42, 0), { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, 'n', '4', string.format(activePenCmd, 43, 0), { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, 'n', '5', string.format(activePenCmd, 44, 0), { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, 'n', '6', string.format(activePenCmd, 45, 0), { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, 'n', '7', string.format(activePenCmd, 46, 0), { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, 'n', '8', string.format(activePenCmd, 47, 0), { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, 'n', '9', string.format(activePenCmd, 39, 0), { noremap = true, silent = true })

    vim.api.nvim_buf_set_keymap(0, 'x', '1', string.format(activePenCmd, 40, 1), { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, 'x', '2', string.format(activePenCmd, 41, 1), { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, 'x', '3', string.format(activePenCmd, 42, 1), { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, 'x', '4', string.format(activePenCmd, 43, 1), { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, 'x', '5', string.format(activePenCmd, 44, 1), { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, 'x', '6', string.format(activePenCmd, 45, 1), { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, 'x', '7', string.format(activePenCmd, 46, 1), { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, 'x', '8', string.format(activePenCmd, 47, 1), { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, 'x', '9', string.format(activePenCmd, 39, 1), { noremap = true, silent = true })

    vim.api.nvim_buf_set_keymap(0, 'x', '<CR>', ":lua require'saekpen'.paint()<CR>",
      { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, 'n', '<CR>', ":lua require'saekpen'.paint()<CR>",
      { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, 'x', 'U', ":lua require'saekpen'.undo()<CR>",
      { noremap = true, silent = true, desc = 'Saekpen UnDo' })
    vim.api.nvim_buf_set_keymap(0, 'n', 'U', ":lua require'saekpen'.undo()<CR>",
      { noremap = true, silent = true, desc = 'Saekpen UnDo' })
    vim.api.nvim_buf_set_keymap(0, 'x', 'R', ":lua require'saekpen'.redo()<CR>",
      { noremap = true, silent = true, desc = 'Saekpen ReDo' })
    vim.api.nvim_buf_set_keymap(0, 'n', 'R', ":lua require'saekpen'.redo()<CR>",
      { noremap = true, silent = true, desc = 'Saekpen ReDo' })


    -- 굳이 없어도 되지만 오류를 막기 위해

    -- @todo 팝업창 설정에 따라 안보이게
    M.popup_win_id = popup()
  end
end

return M

-- /Saekpen;65,0,65,78,ANSI46;73,8,73,29,ANSI42;88,1,88,30,ANSI44;93,18,93,67,ANSI40
