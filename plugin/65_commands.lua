-- ============================================================================
-- User commands (plugin/65_commands.lua)
-- ============================================================================
-- General-purpose custom commands that do not fit into other categories.
-- ============================================================================

local pick_later = Config.pick_later

-- ============================================================================
-- Clipboard helpers
-- ============================================================================

local function copy_current_buffer_path_to_system_clipboard(expand_modifiers, label)
  local path = vim.fn.expand('%' .. expand_modifiers)
  if path == '' then
    vim.notify('No file associated with current buffer', vim.log.levels.WARN)
    return
  end
  vim.fn.setreg('+', path)
  vim.notify(label .. ' copied to system clipboard: ' .. path, vim.log.levels.INFO)
end

vim.api.nvim_create_user_command('MyCopyFilePath', function()
  local items = {
    { text = 'File name', expand = ':t', description = 'Current buffer file name' },
    { text = 'Relative path', expand = ':.', description = 'Current buffer relative path' },
    { text = 'Absolute path', expand = ':p', description = 'Current buffer absolute path' },
    { text = 'Relative directory', expand = ':.:h', description = 'Current buffer relative directory path' },
    { text = 'Absolute directory', expand = ':p:h', description = 'Current buffer absolute directory path' },
  }

  local source = {
    items = items,
    name = 'Copy file path',
    choose = function() end,
  }

  pick_later({ source = source }, function(chosen)
    copy_current_buffer_path_to_system_clipboard(chosen.expand, chosen.description)
  end)
end, { desc = 'Copy current buffer file path to system clipboard (with type selection)' })

-- ============================================================================
-- System file manager
-- ============================================================================

vim.api.nvim_create_user_command('MyOpenCurrentBufferFileInSystemFileManager', function()
  local file = vim.fn.expand('%:p')
  if file == '' then
    vim.notify('No file associated with current buffer', vim.log.levels.WARN)
    return
  end

  local cmd
  if vim.fn.has('mac') == 1 then
    cmd = { 'open', '-R', file }
  elseif vim.fn.has('win32') == 1 or vim.fn.has('win64') == 1 then
    cmd = { 'cmd.exe', '/c', 'explorer', '/select,' .. file }
  else
    cmd = { 'xdg-open', vim.fn.fnamemodify(file, ':h') }
  end

  vim.fn.jobstart(cmd, { detach = true })
  vim.notify('Opened in system file manager: ' .. file, vim.log.levels.INFO)
end, { desc = 'Open current buffer file in system file manager' })

-- ============================================================================
-- Buffer management
-- ============================================================================

vim.api.nvim_create_user_command('MyCloseAllOtherBuffers', function()
  local current = vim.api.nvim_get_current_buf()
  local closed = 0
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if buf ~= current and vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted then
      local ok = pcall(vim.api.nvim_buf_delete, buf, { force = false })
      if ok then
        closed = closed + 1
      end
    end
  end
  vim.notify('Closed ' .. closed .. ' other buffer(s)', vim.log.levels.INFO)
end, { desc = 'Close all other buffers except the current one' })

vim.api.nvim_create_user_command('MyCloseAllUnmodifiedBuffers', function()
  local closed = 0
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted and not vim.bo[buf].modified then
      local ok = pcall(vim.api.nvim_buf_delete, buf, { force = false })
      if ok then
        closed = closed + 1
      end
    end
  end
  vim.notify('Closed ' .. closed .. ' unmodified buffer(s)', vim.log.levels.INFO)
end, { desc = 'Close all unmodified buffers' })

-- ============================================================================
-- Window management
-- ============================================================================

local maximized_tab = nil

vim.api.nvim_create_user_command('MyToggleMaximizeCurrentWindow', function()
  if maximized_tab then
    -- Check if the maximized tab still exists (user might have closed it manually)
    local exists = false
    for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
      if tab == maximized_tab then
        exists = true
        break
      end
    end

    if exists then
      -- Switch to the maximized tab and close it. This leaves us back in the original tab.
      vim.api.nvim_set_current_tabpage(maximized_tab)
      vim.cmd('tabclose')
    end

    maximized_tab = nil
    vim.notify('Window layout restored', vim.log.levels.INFO)
  else
    -- Create a new tab with the current window. Save the NEW tab's handle so we can close it later.
    vim.cmd('tab split')
    maximized_tab = vim.api.nvim_get_current_tabpage()
    vim.notify('Current window maximized', vim.log.levels.INFO)
  end
end, { desc = 'Toggle maximize and restore the current window' })

-- ============================================================================
-- Selection statistics
-- ============================================================================

vim.api.nvim_create_user_command('MyShowSelectionCharacterAndWordCount', function()
  local visual_mode = vim.fn.visualmode()
  if visual_mode == '' or vim.fn.getpos("'<")[2] == 0 then
    vim.notify('No previous visual selection found', vim.log.levels.WARN)
    return
  end

  local ok, lines = pcall(vim.fn.getregion, vim.fn.getpos("'<"), vim.fn.getpos("'>"), { type = visual_mode })
  if not ok or not lines then
    vim.notify('Failed to get visual selection', vim.log.levels.ERROR)
    return
  end

  local text = table.concat(lines, '\n')
  local chars = vim.fn.strchars(text)
  local _, words = text:gsub('%S+', '')

  vim.notify(string.format('Selection: %d characters, %d words', chars, words), vim.log.levels.INFO)
end, { range = true, desc = 'Show character and word count of the last visual selection' })

-- ============================================================================
-- File information
-- ============================================================================

vim.api.nvim_create_user_command('MyShowCurrentBufferFileInformation', function()
  local path = vim.fn.expand('%:p')
  if path == '' then
    vim.notify('No file associated with current buffer', vim.log.levels.WARN)
    return
  end

  local size = vim.fn.getfsize(path)
  local size_str
  if size < 0 then
    size_str = 'unknown'
  elseif size < 1024 then
    size_str = size .. ' bytes'
  elseif size < 1024 * 1024 then
    size_str = string.format('%.2f KB', size / 1024)
  else
    size_str = string.format('%.2f MB', size / (1024 * 1024))
  end

  local mtime = vim.fn.getftime(path)
  local mtime_str = mtime > 0 and os.date('%Y-%m-%d %H:%M:%S', mtime) or 'unknown'

  local encoding = vim.bo.fileencoding or vim.bo.encoding or 'unknown'
  local fileformat = vim.bo.fileformat or 'unknown'

  local perm = vim.fn.getfperm(path) or 'unknown'

  local msg = string.format(
    'File: %s\nSize: %s\nModified: %s\nEncoding: %s\nFormat: %s\nPermissions: %s',
    path,
    size_str,
    mtime_str,
    encoding,
    fileformat,
    perm
  )
  vim.notify(msg, vim.log.levels.INFO)
end, { desc = 'Show current buffer file information (size, encoding, permissions, etc.)' })

-- ============================================================================
-- Selection encoding
-- ============================================================================

local function get_last_visual_selection_text()
  local visual_mode = vim.fn.visualmode()
  if visual_mode == '' or vim.fn.getpos("'<")[2] == 0 then
    return nil, 'No previous visual selection found'
  end

  local ok, lines = pcall(vim.fn.getregion, vim.fn.getpos("'<"), vim.fn.getpos("'>"), { type = visual_mode })
  if not ok or not lines then
    return nil, 'Failed to get visual selection'
  end

  return table.concat(lines, '\n'), nil
end

vim.api.nvim_create_user_command('MyUrlEncodeSelection', function()
  local text, err = get_last_visual_selection_text()
  if not text then
    vim.notify(err, vim.log.levels.WARN)
    return
  end

  local encoded = text:gsub("[^%w%-_%.!%~%*%'%(%)]", function(c)
    return string.format('%%%02X', string.byte(c))
  end)

  vim.fn.setreg('+', encoded)
  vim.notify('URL encoded selection copied to system clipboard', vim.log.levels.INFO)
end, { range = true, desc = 'URL encode the last visual selection and copy to system clipboard' })

vim.api.nvim_create_user_command('MyBase64EncodeSelection', function()
  local text, err = get_last_visual_selection_text()
  if not text then
    vim.notify(err, vim.log.levels.WARN)
    return
  end

  local ok, encoded = pcall(vim.base64.encode, text)
  if not ok then
    vim.notify('Base64 encode failed: ' .. tostring(encoded), vim.log.levels.ERROR)
    return
  end

  vim.fn.setreg('+', encoded)
  vim.notify('Base64 encoded selection copied to system clipboard', vim.log.levels.INFO)
end, { range = true, desc = 'Base64 encode the last visual selection and copy to system clipboard' })
