-- ============================================================================
-- User commands (plugin/65_commands.lua)
-- ============================================================================
-- General-purpose custom commands that do not fit into other categories.
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

vim.api.nvim_create_user_command('CopyCurrentBufferFileNameToSystemClipboard', function()
  copy_current_buffer_path_to_system_clipboard(':t', 'Current buffer file name')
end, { desc = 'Copy current buffer file name to system clipboard' })

vim.api.nvim_create_user_command('CopyCurrentBufferRelativePathToSystemClipboard', function()
  copy_current_buffer_path_to_system_clipboard(':.', 'Current buffer relative path')
end, { desc = 'Copy current buffer relative path to system clipboard' })

vim.api.nvim_create_user_command('CopyCurrentBufferAbsolutePathToSystemClipboard', function()
  copy_current_buffer_path_to_system_clipboard(':p', 'Current buffer absolute path')
end, { desc = 'Copy current buffer absolute path to system clipboard' })

vim.api.nvim_create_user_command('CopyCurrentBufferRelativeDirectoryPathToSystemClipboard', function()
  copy_current_buffer_path_to_system_clipboard(':.:h', 'Current buffer relative directory path')
end, { desc = 'Copy current buffer relative directory path to system clipboard' })

vim.api.nvim_create_user_command('CopyCurrentBufferAbsoluteDirectoryPathToSystemClipboard', function()
  copy_current_buffer_path_to_system_clipboard(':p:h', 'Current buffer absolute directory path')
end, { desc = 'Copy current buffer absolute directory path to system clipboard' })
