---@diagnostic disable: no-unknown

local wezterm = require("wezterm")
local config = wezterm.config_builder()
local action = wezterm.action

-- Platform detection
local is_darwin = wezterm.target_triple:find("darwin") ~= nil
local is_linux = wezterm.target_triple:find("linux") ~= nil
local is_windows = wezterm.target_triple:find("windows") ~= nil

-- Set environment variables (platform-specific)
if is_darwin then
	config.set_environment_variables = {
		PATH = "/opt/homebrew/bin:" .. os.getenv("PATH"),
	}
elseif is_linux then
	config.set_environment_variables = {
		PATH = "/usr/local/bin:" .. os.getenv("PATH"),
	}
end

-- Set appearance
config.color_scheme = "ayu"
config.font = wezterm.font("0xProto Nerd Font")
config.font_size = 15.5
config.line_height = 1.1
config.window_decorations = "RESIZE"
config.window_background_opacity = 0.9
config.use_fancy_tab_bar = true

-- macOS-specific settings
if is_darwin then
	config.macos_window_background_blur = 30
end

config.window_frame = {
	font = wezterm.font("0xProto Nerd Font"),
	font_size = 12,
	active_titlebar_bg = "#000000",
	inactive_titlebar_bg = "#111111",
}

config.colors = {
	tab_bar = {
		active_tab = {
			bg_color = "#000000",
			fg_color = "#c0c0c0",
		},
		inactive_tab = {
			bg_color = "#212121",
			fg_color = "#808080",
		},
	},
}

-- Animation Framerate
config.animation_fps = 60
config.max_fps = 120

-- Set Key Bindings (platform-aware)
local super = is_darwin and "CMD" or "CTRL"
local alt = is_darwin and "OPT" or "ALT"

config.keys = {
	{
		-- Move left word
		key = "LeftArrow",
		mods = alt,
		action = action.SendString("\x1bb"),
	},
	{
		-- Move right word
		key = "RightArrow",
		mods = alt,
		action = action.SendString("\x1bf"),
	},
	{
		-- Delete word backwards
		key = "Backspace",
		mods = alt,
		action = action.SendKey({ mods = "CTRL", key = "w" }),
	},
	{
		-- Delete whole line
		key = "Backspace",
		mods = super,
		action = action.SendKey({ mods = "CTRL", key = "u" }),
	},
	{
		-- Open wezterm config_file
		key = ",",
		mods = "SUPER",
		action = action.SpawnCommandInNewTab({
			cwd = wezterm.home_dir,
			args = { os.getenv("SHELL"), "-l", "-i", "-c", "nvim " .. wezterm.config_file },
		}),
	},
	{
		-- Show the launcher
		key = "F3",
		mods = super,
		action = action.ShowLauncher,
	},
	{
		-- Open new split vertical pane
		key = "d",
		mods = super .. "|SHIFT",
		action = action.SplitVertical({ domain = "CurrentPaneDomain" }),
	},
	{
		-- Open new split horizontal pane
		key = "d",
		mods = super,
		action = action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	{
		-- Activate pane selection mode with the default alphabet (labels are "a", "s", "d", "f" and so on)
		key = "8",
		mods = "CTRL",
		action = action.PaneSelect,
	},
	{
		-- Activate pane selection mode with numeric labels
		key = "9",
		mods = "CTRL",
		action = action.PaneSelect({
			alphabet = "1234567890",
		}),
	},
	{
		-- Show the pane selection mode, but have it swap the active and selected panes
		key = "0",
		mods = "CTRL",
		action = action.PaneSelect({
			mode = "SwapWithActive",
		}),
	},
	{
		-- Clear scrollback buffer and viewport
		key = "k",
		mods = super,
		action = action.ClearScrollback("ScrollbackAndViewport"),
	},
	{
		-- Close the current pane with confirmation
		key = "w",
		mods = super,
		action = action.CloseCurrentPane({ confirm = true }),
	},
	{
		-- Close the current tab with confirmation
		key = "w",
		mods = super .. "|SHIFT",
		action = action.CloseCurrentTab({ confirm = true }),
	},
	{
		-- Move cursor to beginning of line
		key = "LeftArrow",
		mods = super,
		action = action.SendKey({ key = "Home" }),
	},
	{
		-- Move cursor to end of line
		key = "RightArrow",
		mods = super,
		action = action.SendKey({ key = "End" }),
	},
	{
		-- Open the command palette
		key = "p",
		mods = super .. "|SHIFT",
		action = action.ActivateCommandPalette,
	},
	{
		-- Open Shell (Domain wolf-family)
		key = "F1",
		mods = "CTRL|SHIFT",
		action = action.SpawnCommandInNewTab({
			cwd = wezterm.home_dir,
			args = { os.getenv("SHELL"), "-l", "-i", "-c", "ssh wolf-family" },
		}),
	},
	{
		-- Open Vim in current directory
		key = "e",
		mods = super .. "|" .. alt,
		action = action.SpawnCommandInNewTab({
			args = { os.getenv("SHELL"), "-l", "-i", "-c", "nvim" },
		}),
	},
}

-- Platform-specific keybindings
if is_windows then
	-- Add Windows-specific keybindings if needed
	table.insert(config.keys, {
		key = "v",
		mods = "CTRL|SHIFT",
		action = action.PasteFrom("Clipboard"),
	})
end

----------------
--- GUI Customizations

local SOLID_LEFT_ARROW = utf8.char(0xe0b2)
local SOLID_RIGHT_ARROW = utf8.char(0xe0b0)

local function merge_arrays(...)
	local result = {}
	for _, arr in ipairs({ ... }) do
		for _, v in ipairs(arr) do
			table.insert(result, v)
		end
	end
	return result
end

-- Format a section with background and foreground colors
local function format_section(text, bg, fg, is_first, prev_bg)
	local section = {}

	if not is_first then
		table.insert(section, { Background = { Color = prev_bg or "none" } })
		table.insert(section, { Foreground = { Color = bg } })
		table.insert(section, { Text = SOLID_LEFT_ARROW })
	end

	table.insert(section, { Background = { Color = bg } })
	table.insert(section, { Foreground = { Color = fg } })
	table.insert(section, { Text = " " .. text .. " " })

	return section
end

-- Get battery status (if available)
local function get_battery_info()
	for _, b in ipairs(wezterm.battery_info()) do
		return string.format("%.0f%%", b.state_of_charge * 100)
	end
	return nil
end

-- Get current working directory
local function get_cwd(pane)
	local cwd = pane:get_current_working_dir()
	if cwd then
		if type(cwd) == "userdata" then
			cwd = cwd.file_path
		end
		-- Simplify home directory
		local home = os.getenv("HOME")
		if home and cwd:find(home, 1, true) == 1 then
			cwd = "~" .. cwd:sub(#home + 1)
		end
		-- Get last two directories
		local parts = {}
		for part in string.gmatch(cwd, "[^/]+") do
			table.insert(parts, part)
		end
		if #parts > 2 then
			return ".../" .. parts[#parts - 1] .. "/" .. parts[#parts]
		end
		return cwd
	end
	return ""
end

-- Initialize status bar
wezterm.on("update-status", function(window, pane)
	local colors = window:effective_config().resolved_palette
	local sections = {}

	-- Color scheme
	local bg1 = "#1a1a1a"
	local bg2 = "#2a2a2a"
	local bg3 = "#3a3a3a"
	local fg = colors.foreground

	-- Current working directory
	local cwd = get_cwd(pane)
	if cwd and cwd ~= "" then
		local cwd_sections = format_section(cwd, bg1, fg, true, nil)
		for _, s in ipairs(cwd_sections) do
			table.insert(sections, s)
		end
	end

	-- Date and time
	local date = wezterm.strftime("%a %b %-d %H:%M")
	local time_sections = format_section(date, bg2, fg, false, bg1)
	for _, s in ipairs(time_sections) do
		table.insert(sections, s)
	end

	-- Battery info (if available)
	local battery = get_battery_info()
	if battery then
		local battery_sections = format_section(battery, bg3, fg, false, bg2)
		for _, s in ipairs(battery_sections) do
			table.insert(sections, s)
		end
	end

	-- Hostname
	local hostname_sections = format_section(wezterm.hostname(), "#000000", fg, false, bg3)
	for _, s in ipairs(hostname_sections) do
		table.insert(sections, s)
	end

	window:set_right_status(wezterm.format(sections))
end)

-- (This is where our config will go)
wezterm.log_info("Hello world! my name is " .. wezterm.hostname())

-- Returns our config to be evaluated. We must always do this at the bottom of this file
return config
