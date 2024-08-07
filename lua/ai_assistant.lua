local M = {}

-- Debug function
local function debug_print(message)
  print(vim.inspect(message))
end

-- Function to get API key from environment variable
local function get_api_key(name)
  return os.getenv(name)
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

  print(prompt)
end

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
