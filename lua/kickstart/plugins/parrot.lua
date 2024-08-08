return {
  'frankroeder/parrot.nvim',
  tag = 'v0.4.1',
  dependencies = { 'ibhagwan/fzf-lua', 'nvim-lua/plenary.nvim' },
  -- optionally include "rcarriga/nvim-notify" for beautiful notifications
  config = function()
    require('parrot').setup {
      -- Providers must be explicitly added to make them available.
      providers = {
        -- pplx = {
        --   api_key = os.getenv 'PERPLEXITY_API_KEY',
        --   -- OPTIONAL
        --   -- gpg command
        --   -- api_key = { "gpg", "--decrypt", vim.fn.expand("$HOME") .. "/pplx_api_key.txt.gpg"  },
        --   -- macOS security tool
        --   -- api_key = { "/usr/bin/security", "find-generic-password", "-s pplx-api-key", "-w" },
        -- },
        openai = {
          api_key = os.getenv 'OPENAI_API_KEY',
        },
        anthropic = {
          api_key = os.getenv 'ANTHROPIC_API_KEY',
        },
        -- mistral = {
        --   api_key = os.getenv 'MISTRAL_API_KEY',
        -- },
        -- gemini = {
        --   api_key = os.getenv 'GEMINI_API_KEY',
        -- },
        -- groq = {
        --   api_key = os.getenv 'GROQ_API_KEY',
        -- },
        ollama = {}, -- provide an empty list to make provider available
      },
    }
  end,
  -- chat history
  -- .local/share/nvim/parrot/chats
}
