local M = {}
local Job = require 'plenary.job'

-- Debug function
local function debug_print(message)
  print(vim.inspect(message))
end

-- Function to get API key from environment variable
-- local function get_api_key(name)
--   return os.getenv(name)
-- end

-- Function to make the api call
-- @prompt : prompt to be passed into the api call
-- @callback : callback function to handle the api response
function M.call_local_api_stream(prompt, on_chunk)
  local url = 'http://127.0.0.1:8000/stream'
  local data = vim.fn.json_encode { message = prompt }

  local job
  job = Job:new {
    command = 'curl',
    args = {
      '--no-buffer',
      '-X',
      'POST',
      '-H',
      'Content-Type: application/json',
      '-d',
      data,
      url,
    },
    on_stdout = function(_, line)
      -- `line` receives each chunk of the streaming response
      debug_print(line)
      if line then
        on_chunk(line)
      else
        debug_print('Failed to parse chunk: ' .. line)
      end
    end,
  }

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
  -- Save the current selection marks
  local start_pos = vim.fn.getpos "'<" -- {0, 67, 1, 0} -> gets the start of the visual selection coordinates
  local end_pos = vim.fn.getpos "'>" -- {0. 74, 214..., 0} -> gets the end of the visual selection coordinates

  -- Get the lines of the selection
  local lines = vim.fn.getline(start_pos[2], end_pos[2])

  -- Adjust the last line to only include up to the column of the end mark
  if #lines > 0 then
    lines[#lines] = string.sub(lines[#lines], 1, end_pos[3])
  end

  -- Adjust the first line to start from the column of the start mark
  if #lines > 0 then
    lines[1] = string.sub(lines[1], start_pos[3])
  end

  -- Join the lines and return the result
  return table.concat(lines, '\n')
end

-- Function to insert formatted response into the buffer
function M.insert_formatted_response(response_str)
  -- Remove the outer quotes and unescape inner quotes
  local unescaped = response_str:gsub('^"', ''):gsub('"$', ''):gsub('\\"', '"')
  local lines = vim.split(response_str, '\n')

  -- Schedule the insertion to occur in the main Neovim event loop
  vim.schedule(function()
    -- Get the current cursor position
    -- local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local current_window = vim.api.nvim_get_current_win()
    local cursor_position = vim.api.nvim_win_get_cursor(current_window)
    local row, col = cursor_position[1], cursor_position[2]

    vim.cmd 'undojoin'
    -- debug_print(lines)
    vim.api.nvim_put(lines, 'l', true, true)

    local num_lines = #lines
    local last_line_length = #lines[num_lines]
    vim.api.nvim_win_set_cursor(current_window, { row + num_lines - 1, col + last_line_length })
  end)
end

-- Token streaming callback function
-- Token by token insertion at the cursor position
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
  local replace = opts.replace
  local prompt = M.get_visual_selection()
  if #prompt > 0 then
    if replace then
      vim.api.nvim_command 'normal! d'
      vim.api.nvim_command 'normal! k'
    else
      -- the objective of this is to tell neovim to act as if the Escape key was pressed by user
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', false, true, true), 'nx', false)
    end
  else
    prompt = M.get_lines_until_cursor()
  end

  prompt = 'create a python function to sum two numbers'

  M.call_local_api_stream(prompt, function(data)
    M.insert_token(data)
  end)
end

-- M.call_local_api('write a python function to create random numbers', function(result)
--   -- Parse the JSON result
--   local success, parsed = pcall(vim.json.decode, result)
--   if success then
--     -- Assuming the PAI returns a 'response' field
--     local response = parsed.response
--     if response then
--       -- Insert the response at the cursor position
--       M.insert_formatted_response(response)
--     else
--       print 'API doesnt contain response field'
--     end
--   else
--     print('Failed to parse API response: ' .. result)
--   end
-- end)
--
M.invoke_ai_assistant {}

return M
-- [[
-- there are several thing pending to be inplemente
-- 1. when there isn't any selection - visual mode, the context for the LLM should be the lines till the cursor,
-- -- 1.1 What to do if the file is too big?
-- this should be based on structured outputs, the return of this interaction must be code and zero chat, so there is not need to parse anything
-- 2. in visual mode, the idea is to modify - like inline instruction, a diff visualization will be great, for the short term I can use just git
-- 3. for the chat part, there should be several options:
-- -- 3.1 Select a file and chat based on that
-- -- 3.2 Do not select a file
-- -- 3.3 Use a documentation
-- -- -- 3.3.1 For this I will need a way to handle the documentations, probably a vector database, very simple to use.
-- in this case, we should use chat mode, since it is acceptable to have code and text at the same time
-- ]]
