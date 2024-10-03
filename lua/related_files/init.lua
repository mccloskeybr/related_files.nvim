local M = {
  opts = {
    config = {
      close_on_select = true,
      stop_on_first_hit = false,
      format_func = nil,
    },
    groups = {},
  },
}

M.setup = function(opts)
  M.opts = vim.tbl_deep_extend("force", M.opts, opts)

  -- configure an autogroup that closes the location list if configured.
  if M.opts.config.close_on_select then
    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup(
        'related_files_auto_close', {clear = true}),
      pattern = 'qf',
      callback = function()
        vim.cmd([[nnoremap <buffer> <CR> <CR>:lclose<CR>]])
      end
    })
  end

  -- notify on misconfiguration once only, at startup.
  for group, ext in pairs(M.opts.groups) do
    if ext.is_in_group == nil then
      vim.notify(
        'related_files: group: ' .. group .. ' is missing required callback is_in_group!',
        vim.log.levels.WARN)
    end
    if ext.get_files_in_group == nil then
      vim.notify(
        'related_files: group: ' .. group .. ' is missing required callback get_files_in_group!',
        vim.log.levels.WARN)
    end
  end
end

M.open = function()
  local file_path = vim.fn.expand('%:p')

  -- loop through configured related files, match against callback, and add to list.
  num_files = 0
  related_files = {}
  for group, ext in pairs(M.opts.groups) do
    if ext.is_in_group == nil or ext.get_files_in_group == nil then
      goto continue
    end
    if ext.is_in_group(file_path) == true then
      ext_related_files = ext.get_files_in_group(file_path)
      for _, ext_related_file in pairs(ext_related_files) do
        -- NOTE: location list expects a certain table format: see :help setqflist.
        table.insert(related_files, ext_related_file)
        num_files = num_files + 1
      end

      -- exit on first match if configured.
      if M.opts.config.stop_on_first_hit then goto done end
    end
    ::continue::
  end
  ::done::

  if num_files == 0 then
    vim.notify(
      'related_files: no related files found for file: ' .. file_path,
      vim.log.levels.WARN)
    return
  end

  vim.fn.setloclist(0, {}, 'r', { items = related_files, quickfixtextfunc = M.opts.config.format_func })
  vim.cmd.lopen()
end

return M
