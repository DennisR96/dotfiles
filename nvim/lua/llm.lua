local M = {}

local chat_history = {
  { role = "system", content = "You are a helpful coding assistant." }
}

-- Append messages to the chat buffer
local function append_to_chat(buf, role, content)
  local prefix = (role == "user") and "🧑 You: " or "🤖 Assistant: "
  local lines = vim.split(content, "\n", { plain = true })
  lines[1] = prefix .. lines[1]
  table.insert(lines, 1, "")
  vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
end

-- Send message to OpenAI
local function send_message(chat_buf, input_buf)
  local user_input = vim.api.nvim_buf_get_lines(input_buf, 0, -1, false)
  user_input = table.concat(user_input, "\n"):gsub("^%s+", ""):gsub("%s+$", "")
  if user_input == "" then return end

  table.insert(chat_history, { role = "user", content = user_input })
  append_to_chat(chat_buf, "user", user_input)

  local api_url = "https://openrouter.ai/api/v1/chat/completions"
  local api_key = os.getenv("OPENROUTER_API_KEY")
  if not api_key then
    vim.api.nvim_err_writeln("OPENAI_API_KEY not set in environment")
    return
  end

  local payload = vim.fn.json_encode({
    model = "deepseek/deepseek-chat-v3-0324:free",
    messages = chat_history,
    temperature = 0
  })

  append_to_chat(chat_buf, "assistant", "⏳ Thinking...")

  vim.system({
    "curl", "-s", api_url,
    "-H", "Content-Type: application/json",
    "-H", "Authorization: Bearer " .. api_key,
    "-d", payload
  }, { text = true }, function(obj)
    vim.schedule(function()
      vim.api.nvim_buf_set_lines(chat_buf, -2, -1, false, {}) -- remove "Thinking..."

      if obj.code ~= 0 then
        append_to_chat(chat_buf, "assistant", "❌ API request failed (exit code " .. obj.code .. ")")
        return
      end

      local ok, data = pcall(vim.fn.json_decode, obj.stdout)
      if not ok or not data or not data.choices or not data.choices[1] then
        append_to_chat(chat_buf, "assistant", "⚠️ Invalid response from API")
        return
      end

      local response = data.choices[1].message.content or "No response received"
      table.insert(chat_history, { role = "assistant", content = response })
      append_to_chat(chat_buf, "assistant", response)

      -- Clear input buffer
      vim.api.nvim_buf_set_lines(input_buf, 0, -1, false, {})
      vim.api.nvim_buf_call(input_buf, function()
        vim.cmd("startinsert")
      end)
    end)
  end)
end

-- Chat UI
function M.chat()
  -- Chat buffer
  local chat_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(chat_buf, 'filetype', 'markdown')
  vim.api.nvim_buf_set_lines(chat_buf, 0, -1, false, { "💬 LLM Chat (press q to quit)", "" })

  local width = math.floor(vim.o.columns * 0.4)
  local height = math.floor(vim.o.lines * 1)
  local row = 0
  local col = vim.o.columns - width

  local chat_win = vim.api.nvim_open_win(chat_buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded"
  })

  -- Input buffer
  local input_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(input_buf, 'filetype', 'markdown')
  vim.api.nvim_buf_set_lines(input_buf, 0, -1, false, {})

  local input_height = 5
  local input_row = row + height + 1

  local input_win = vim.api.nvim_open_win(input_buf, true, {
    relative = "editor",
    width = width,
    height = input_height,
    row = input_row,
    col = col,
    style = "minimal",
    border = "single"
  })

  -- Keymaps
  vim.api.nvim_buf_set_keymap(input_buf, 'n', '<Tab>', '<C-w>k', { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(chat_buf, 'n', '<Tab>', '<C-w>j', { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(chat_buf, 'n', 'q', '<cmd>bd!<CR>', { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(input_buf, 'i', '<CR>', '<Esc><cmd>lua require("llm")._send_chat()<CR>', { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(input_buf, 'n', '<CR>', '<cmd>lua require("llm")._send_chat()<CR>', { noremap = true, silent = true })

  M._send_chat = function()
    send_message(chat_buf, input_buf)
  end

  -- Start in insert mode
  vim.api.nvim_set_current_win(input_win)
  vim.cmd("startinsert")
end

-- Explain: same as before
function M.explain()
  local api_url = "https://openrouter.ai/api/v1/chat/completions"
  local api_key = os.getenv("OPENROUTER_API_KEY")
  if not api_key then
    vim.api.nvim_err_writeln("OPENAI_API_KEY not set in environment")
    return
  end
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local lines = vim.fn.getline(start_pos[2], end_pos[2])
  if #lines == 0 then
    vim.api.nvim_err_writeln("No text selected")
    return
  end
  local selected_text = table.concat(lines, "\n"):gsub("^%s+", ""):gsub("%s+$", "")
  local payload = vim.fn.json_encode({
  model = "deepseek/deepseek-chat-v3-0324:free",
  messages = {
    { role = "system", content = "You are a helpful assistant that explains code." },
    { role = "user", content = "Please explain what happens here:\n\n" .. selected_text }
  },
  temperature = 0
})  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "⌛ Requesting explanation from OpenAI..." })
  vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')
  local width = math.floor(vim.o.columns * 0.4)
  local height = vim.o.lines
  local opts = {
    relative = "editor",
    width = width,
    height = height,
    row = 0,
    col = vim.o.columns - width,
    style = "minimal",
    border = "rounded"
  }
  vim.api.nvim_open_win(buf, true, opts)
  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '<cmd>bd!<CR>', { noremap = true, silent = true })
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.system({
    "curl", "-s", api_url,
    "-H", "Content-Type: application/json",
    "-H", "Authorization: Bearer " .. api_key,
    "-d", payload
  }, { text = true }, function(obj)
    vim.schedule(function()
      if obj.code ~= 0 then
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "❌ API request failed (exit code " .. obj.code .. ")" })
        return
      end
      local ok, data = pcall(vim.fn.json_decode, obj.stdout)
      if not ok or not data or not data.choices or not data.choices[1] then
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "⚠️ Invalid response from API" })
        return
      end
      local response = data.choices[1].message["content"] or "No response received"
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(response, "\n"))
    end)
  end)
end

-- Setup keymaps
function M.setup_keymaps()
  vim.keymap.set('v', '<leader>le', ":lua require('llm').explain()<CR>", { noremap = true, silent = true, desc = "LLM: Explain" })
  vim.keymap.set('n', '<leader>lc', ":lua require('llm').chat()<CR>", { noremap = true, silent = true, desc = "LLM: Chat" })
end

return M

