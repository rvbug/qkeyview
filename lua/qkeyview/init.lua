local M = {}

-- Default configuration
M.config = {
    window = {
        width = 0.8,        -- 80% of screen width
        height = 0.8,       -- 80% of screen height
        border = "rounded", -- Border style
        title = " Keymap Viewer ",
    },
}

-- Store the buffer ID of our viewer
local buf_id = nil
-- Store the window ID of our viewer
local win_id = nil

-- Function to get all keymaps
local function get_keymaps()
    local modes = {'n', 'i', 'v', 'x', 's', 'o', '!', 'ic', 'l', 'c', 't'}
    local keymaps = {}
    
    for _, mode in ipairs(modes) do
        local mode_maps = vim.api.nvim_get_keymap(mode)
        for _, map in ipairs(mode_maps) do
            table.insert(keymaps, {
                mode = mode,
                lhs = map.lhs,
                rhs = map.rhs or "",
                desc = map.desc or "",
                silent = map.silent,
                noremap = map.noremap,
                expr = map.expr,
                buffer = map.buffer,
            })
        end
    end
    return keymaps
end

-- Function to create content for the buffer
local function create_content()
    local keymaps = get_keymaps()
    local content = {}
    local title = "Keymap Viewer"
    local width = vim.api.nvim_win_get_width(0)
    local pad_width = math.floor((width - #title) / 2)
    
    -- Center the title
    table.insert(content, string.rep(" ", pad_width) .. title)
    table.insert(content, string.rep("─", width))
    table.insert(content, "")
    
    for _, map in ipairs(keymaps) do
        local desc = map.desc ~= "" and map.desc or map.rhs
        local line = string.format("[%s] %s →→→ %s", map.mode, map.lhs, desc)
        table.insert(content, line)
    end
    
    return content
end

-- Telescope integration
local function telescope_keymaps(opts)
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    
    opts = opts or {}
    
    local keymaps = get_keymaps()
    local keymap_entries = {}
    
    for _, map in ipairs(keymaps) do
        local desc = map.desc ~= "" and map.desc or map.rhs
        table.insert(keymap_entries, {
            display = string.format("%-6s %-30s %s", "[" .. map.mode .. "]", map.lhs, desc),
            mode = map.mode,
            lhs = map.lhs,
            rhs = map.rhs or "",
            desc = desc,
            silent = map.silent and "yes" or "no",
            noremap = map.noremap and "yes" or "no",
            expr = map.expr and "yes" or "no",
            buffer = map.buffer or "global"
        })
    end
    
    pickers.new(opts, {
        prompt_title = "Keymaps",
        finder = finders.new_table {
            results = keymap_entries,
            entry_maker = function(entry)
                return {
                    value = entry,
                    display = entry.display,
                    ordinal = string.format("%s %s %s", entry.mode, entry.lhs, entry.desc),
                    preview_command = function(entry, bufnr)
                        local lines = {
                            "Details for Keymap:",
                            string.rep("─", 50),
                            "",
                            "Mode:      " .. entry.value.mode,
                            "Key:       " .. entry.value.lhs,
                            "Action:    " .. entry.value.rhs,
                            "Description: " .. entry.value.desc,
                            "",
                            "Properties:",
                            string.rep("─", 50),
                            "",
                            "Silent:    " .. entry.value.silent,
                            "NoRemap:   " .. entry.value.noremap,
                            "Expr:      " .. entry.value.expr,
                            "Scope:     " .. entry.value.buffer,
                        }
                        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
                    end,
                }
            end,
        },
        sorter = conf.generic_sorter(opts),
        previewer = require("telescope.previewers").new_buffer_previewer({
            define_preview = function(self, entry, status)
                entry.preview_command(entry, self.state.bufnr)
                -- Set some buffer options for the preview
                vim.api.nvim_buf_set_option(self.state.bufnr, 'filetype', 'markdown')
                vim.api.nvim_buf_set_option(self.state.bufnr, 'buftype', 'nofile')
            end
        }),
        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                -- You can add custom action here when a keymap is selected
                print(selection.value.display)
            end)
            return true
        end,
        layout_config = {
            width = 0.9,
            height = 0.8,
            preview_width = 0.5
        }
    }):find()
end

-- Function to create the floating window (legacy version)
local function create_window()
    -- Calculate window size
    local width = math.floor(vim.o.columns * M.config.window.width)
    local height = math.floor(vim.o.lines * M.config.window.height)
    local col = math.floor((vim.o.columns - width) / 2)
    local row = math.floor((vim.o.lines - height) / 2)

    -- Create buffer
    buf_id = vim.api.nvim_create_buf(false, true)
    
    -- Set buffer options first
    vim.api.nvim_buf_set_option(buf_id, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(buf_id, 'modifiable', true)
    
    -- Set buffer content
    vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, create_content())
    
    -- Now make it non-modifiable
    vim.api.nvim_buf_set_option(buf_id, 'modifiable', false)
    
    -- Window options
    local opts = {
        relative = "editor",
        width = width,
        height = height,
        col = col,
        row = row,
        style = "minimal",
        border = M.config.window.border,
        title = M.config.window.title,
    }
    
    -- Create window
    win_id = vim.api.nvim_open_win(buf_id, true, opts)
    
    -- Set buffer keymaps
    vim.api.nvim_buf_set_keymap(buf_id, 'n', 'q', '', {
        noremap = true,
        silent = true,
        nowait = true,
        callback = function()
            M.close()
        end
    })
    
    -- Set buffer local options
    vim.api.nvim_win_set_option(win_id, 'wrap', false)
    vim.api.nvim_win_set_option(win_id, 'cursorline', true)
    vim.api.nvim_win_set_option(win_id, 'winhl', 'Normal:Normal,FloatBorder:FloatBorder')
end

-- Function to open the viewer (now using Telescope)
function M.open()
    -- Check if telescope is available
    local has_telescope, _ = pcall(require, 'telescope')
    if has_telescope then
        telescope_keymaps()
    else
        -- Fallback to legacy floating window
        if win_id and vim.api.nvim_win_is_valid(win_id) then
            return
        end
        create_window()
    end
end

-- Function to close the viewer
function M.close()
    if win_id and vim.api.nvim_win_is_valid(win_id) then
        vim.api.nvim_win_close(win_id, true)
    end
    if buf_id and vim.api.nvim_buf_is_valid(buf_id) then
        vim.api.nvim_buf_delete(buf_id, { force = true })
    end
    win_id = nil
    buf_id = nil
end

-- Setup function
function M.setup(opts)
    M.config = vim.tbl_deep_extend("force", M.config, opts or {})
    
    -- Create the keymap
    vim.keymap.set('n', '<Space><Space>', M.open, {
        noremap = true,
        silent = true,
        desc = "Open Keymap Viewer"
    })
end

return M
