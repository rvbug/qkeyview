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
                desc = map.desc or ""
            })
        end
    end
    
    return keymaps
end

-- Function to create content for the buffer
local function create_content()
    local keymaps = get_keymaps()
    local content = {}
    
    table.insert(content, "Keymaps:")
    table.insert(content, "--------")
    table.insert(content, "")
    
    for _, map in ipairs(keymaps) do
        local desc = map.desc ~= "" and map.desc or map.rhs
        local line = string.format("[%s] %s → %s", map.mode, map.lhs, desc)
        table.insert(content, line)
    end
    
    return content
end

-- Function to create the floating window
local function create_window()
    -- Calculate window size
    local width = math.floor(vim.o.columns * M.config.window.width)
    local height = math.floor(vim.o.lines * M.config.window.height)
    local col = math.floor((vim.o.columns - width) / 2)
    local row = math.floor((vim.o.lines - height) / 2)

    -- Create buffer
    buf_id = vim.api.nvim_create_buf(false, true)
    
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
    
    -- Set buffer content first
    vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, create_content())
    
    -- Then set buffer options
    vim.api.nvim_buf_set_option(buf_id, 'modifiable', false)
    vim.api.nvim_buf_set_option(buf_id, 'buftype', 'nofile')
    
    -- Set buffer keymaps
    vim.api.nvim_buf_set_keymap(buf_id, 'n', 'q', ':lua require("qkeyviewer").close()<CR>', {
        noremap = true,
        silent = true,
        nowait = true
    })
    
    -- Set buffer local options
    vim.api.nvim_win_set_option(win_id, 'wrap', false)
    vim.api.nvim_win_set_option(win_id, 'cursorline', true)
    vim.api.nvim_win_set_option(win_id, 'winhl', 'Normal:Normal,FloatBorder:FloatBorder')
end

-- Function to open the viewer
function M.open()
    if win_id and vim.api.nvim_win_is_valid(win_id) then
        return
    end
    create_window()
end

-- Function to close the viewer
function M.close()
    if win_id and vim.api.nvim_win_is_valid(win_id) then
        vim.api.nvim_win_close(win_id, true)
        win_id = nil
    end
    if buf_id and vim.api.nvim_buf_is_valid(buf_id) then
        vim.api.nvim_buf_delete(buf_id, { force = true })
        buf_id = nil
    end
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
