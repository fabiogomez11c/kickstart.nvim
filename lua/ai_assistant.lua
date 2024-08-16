local M = {}
local Job = require('plenary.job')

-- Debug function
local function debug_print(message)
  print(vim.inspect(message))
end

-- Function to make the API call
-- @prompt : prompt to be passed into the API call
-- @callback : callback function to handle the API response
function M.call_local_api_stream(prompt, on_chunk)
  local url = 'http://127.0.0.1:8000/stream'
  local data = vim.fn.json_encode({ message = prompt })

  local job = Job:new({
    command = 'curl',
    args = {
      '--no-buffer',
      '-X', 'POST',
      '-H', 'Content-Type: application/json',
      '-d', data,
      url,
    },
    on_stdout = function(_, line)
      if line then
        on_chunk(line)
      else
        debug_print('Failed to parse chunk: ' .. line)
      end
    end,
  })

  job:start()
end

-- Function to get lines until cursor
function M.get_lines_until_cursor()
  local current_buffer = vim.api.nvim_get_current_buf()
  local current_window = vim.api.nvim_get_current_win()
  local cursor_position = vim.api.nvim_win_get_cursor(current_window)
  local row = cursor_position[1]

  local lines = vim.api.nvim_buf_get_lines(current_buffer, 0, row, true)
  return table.concat(lines, '\n')
end

-- Function to get visual selection
function M.get_visual_selection()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local lines = vim.fn.getline(start_pos[2], end_pos[2])

  if #lines > 0 then
    lines[#lines] = string.sub(lines[#lines], 1, end_pos[3])
    lines[1] = string.sub(lines[1], start_pos[3])
  end

  return table.concat(lines, '\n')
end

-- Function to insert formatted response into the buffer
function M.insert_formatted_response(response_str)
  local lines = vim.split(response_str, '\n')

  vim.schedule(function()
    local current_window = vim.api.nvim_get_current_win()
    local cursor_position = vim.api.nvim_win_get_cursor(current_window)
    local row, col = cursor_position[1], cursor_position[2]

    vim.cmd('undojoin')
    vim.api.nvim_put(lines, 'l', true, true)

    local num_lines = #lines
    local last_line_length = #lines[num_lines]
    vim.api.nvim_win_set_cursor(current_window, { row + num_lines - 1, col + last_line_length })
  end)
end

-- Token streaming callback function
function M.insert_token(token)
  vim.schedule(function()
    local current_window = vim.api.nvim_get_current_win()
    local cursor_position = vim.api.nvim_win_get_cursor(current_window)
    local row, col = cursor_position[1], cursor_position[2]

    vim.api.nvim_put({ token }, 'c', false, true)

    local last_line_length = #token
    vim.api.nvim_win_set_cursor(current_window, { row, col + last_line_length })
  end)
end

-- Function to invoke the AI assistant
function M.invoke_ai_assistant(opts)
  opts = opts or {}
  local replace = opts.replace or false
  local prompt

  if vim.fn.mode() == 'v' or vim.fn.mode() == 'V' then
    prompt = M.get_visual_selection()
    if replace then
      vim.api.nvim_command('normal! d')
    else
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', false, true, true), 'nx', false)
    end
  else
    prompt = M.get_lines_until_cursor()
  end

  if #prompt == 0 then
    print("No text selected or cursor at the beginning of the file.")
    return
  end

  M.call_local_api_stream(prompt, function(data)
    M.insert_token(data)
  end)
end

return M
