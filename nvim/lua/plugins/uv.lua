return
{
  'benomahony/uv.nvim',
  config = function()
		require('uv').setup({
			-- Auto-activate virtual environments when found
			auto_activate_venv = false,

			-- Auto commands for directory changes
			auto_commands = true,

			-- Integration with snacks picker
			picker_integration = true,

			-- Keymaps to register (set to false to disable)
			keymaps = {
				prefix = "<leader>x",  -- Main prefix for uv commands
				commands = true,       -- Show uv commands menu (<leader>x)
				run_file = true,       -- Run current file (<leader>xr)
				run_selection = true,  -- Run selected code (<leader>xs)
				run_function = true,   -- Run function (<leader>xf)
				venv = false,           -- Environment management (<leader>xe)
				init = false,           -- Initialize uv project (<leader>xi)
				add = false,            -- Add a package (<leader>xa)
				remove = false,         -- Remove a package (<leader>xd)
				sync = false,           -- Sync packages (<leader>xc)
				sync_all = false, -- uv sync --all-extras --all-groups --all-packages (<leader>xC)
			},

			-- Execution options
			execution = {
				-- Python run command template
				run_command = "uv run python",

				-- Show output in notifications
				notify_output = true,

				-- Notification timeout in ms
				notification_timeout = 10000,
			},
		})
  end,
}
