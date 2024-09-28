local M = {
  opts = {
    config = {
      close_on_select = true,
      stop_on_first_hit = false,
    },
    related = {},
  },
}

M.setup = function(opts)
  M.opts = vim.tbl_deep_extend("force", M.opts, opts)

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

  for key, ext in pairs(M.opts.related) do
    if ext.is_type == nil then
      vim.notify(
        'related_files: key: ' .. key .. ' is missing required callback is_type!',
        vim.log.levels.WARN)
    end
    if ext.get_related == nil then
      vim.notify(
        'related_files: key: ' .. key .. ' is missing required callback get_related!',
        vim.log.levels.WARN)
    end
  end
end

M.open = function()
  local file_path = vim.fn.expand('%:p')

  num_files = 0
  related_files = {}
  for key, ext in pairs(M.opts.related) do
    if ext.is_type == nil or ext.get_related == nil then
      goto continue
    end
    if ext.is_type(file_path) == true then
      ext_related_files = ext.get_related(file_path)
      for _, ext_related_file in pairs(ext_related_files) do
        table.insert(related_files, { filename = ext_related_file })
        num_files = num_files + 1
      end
      if M.opts.config.stop_on_first_hit then goto done end
    end
    ::continue::
  end
  ::done::

  if num_files == 0 then
    vim.notify(
      'related_files: no related files found for file: ' .. file_path,
      vim.log.levels.WARN)
    else
    vim.fn.setloclist(0, related_files)
    vim.cmd.lopen()
  end
end

return M
