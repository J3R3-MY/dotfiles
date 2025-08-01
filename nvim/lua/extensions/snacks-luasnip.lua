-- Snacks.nvim LuaSnip integration
-- Provides a picker interface for browsing and inserting LuaSnip snippets

local M = {}

--- Extracts and formats a description from a LuaSnip snippet object
---@param snippet table LuaSnip snippet object containing name and description fields
---@return string description Formatted description or fallback

local function get_snippet_description(snippet)
  local description = ''

  if snippet.description and #snippet.description > 1 then
    -- Multi-line descriptions: concatenate with spaces
    for _, line in ipairs(snippet.description) do
      description = description .. line .. ' '
    end
    description = description:gsub('%s+$', '')
  elseif snippet.name and snippet.description and snippet.description[1] ~= snippet.name then
    -- Single description that differs from name
    description = snippet.description[1] or ''
  end

  return description
end

--- Get snippet preview content (docstring)
--- Searches through loaded LuaSnip snippets to find a matching snippet
--- and extract its docstring for preview display
---@param snippet table LuaSnip snippet object with name and trigger fields
---@param ft string Filetype for snippet lookup (empty string uses current buffer filetype)
---@return string preview_text Formatted preview content or fallback message
local function get_snippet_preview(snippet, ft)
  local luasnip = require('luasnip')
  local preview_text = "No preview available"

  -- Find matching snippet in loaded snippets to get docstring
  local snips_for_ft = luasnip.get_snippets(ft == '' and vim.bo.filetype or ft)
  if snips_for_ft then
    for _, s in pairs(snips_for_ft) do
      if snippet.name == s.name and snippet.trigger == s.trigger then
        local raw_docstring = s:get_docstring()
        -- Handle different docstring formats
        if raw_docstring then
          if type(raw_docstring) == "string" then
            preview_text = raw_docstring
          elseif type(raw_docstring) == "table" then
            preview_text = table.concat(raw_docstring, '\n')
          end
        end
        break
      end
    end
  end

  return preview_text
end

--- Get sort priority for filetype ordering
---@param ft string Filetype
---@param current_ft string Current buffer filetype
---@return number priority Lower numbers = higher priority
local function get_filetype_priority(ft, current_ft)
  if ft == current_ft then
    return 1 -- Current filetype first
  elseif ft == '' then
    return 3 -- "all" filetype last
  else
    return 2 -- Other filetypes in the middle
  end
end

--- Collect all available LuaSnip snippets
---@return table items Formatted picker items
local function get_luasnip_items()
  local items = {}
  local has_luasnip, luasnip = pcall(require, 'luasnip')

  if not has_luasnip then
    vim.notify('LuaSnip not available', vim.log.levels.WARN)
    return items
  end

  -- Get current buffer filetype for priority sorting
  local current_ft = vim.bo.filetype
  local available = luasnip.available()

  for ft, file in pairs(available) do
    for _, snippet in ipairs(file) do
      local description = get_snippet_description(snippet)
      local preview_text = get_snippet_preview(snippet, ft)

      -- Get filetype icon using Snacks utilities
      local display_ft = ft == '' and 'all' or ft
      local icon, icon_hl = Snacks.util.icon(display_ft, "filetype")

      -- Create searchable text for the matcher
      local searchable_text = string.format("%s %s %s %s",
        display_ft,
        snippet.trigger,
        snippet.name or "",
        description
      )

      -- Get priority for sorting
      local priority = get_filetype_priority(ft, current_ft)

      -- Build table for snacks.picker
      table.insert(items, {
        snippet = snippet,
        ft = ft,
        trigger = snippet.trigger,
        name = snippet.name,
        description = description,
        preview_text = preview_text,
        icon = icon,
        icon_hl = icon_hl,
        display_ft = display_ft,
        text = searchable_text, -- This is what the matcher will search
        ft_priority = priority
      })
    end
  end

  -- Sort items by filetype priority, then by trigger
  table.sort(items, function(a, b)
    if a.ft_priority ~= b.ft_priority then
      return a.ft_priority < b.ft_priority
    end
    return a.trigger < b.trigger
  end)

  return items
end

--- Expand selected snippet
---@param item table Picker item containing snippet data
local function expand_snippet(item)
  local has_luasnip, luasnip = pcall(require, 'luasnip')
  if not has_luasnip then
    vim.notify('LuaSnip not available', vim.log.levels.ERROR)
    return
  end

  -- Primary method: find snippet using luasnip.available
  local snippets_to_expand = {}
  luasnip.available(function(snippet)
    if snippet.trigger == item.trigger and snippet.name == item.name then
      table.insert(snippets_to_expand, snippet)
    end
    return nil
  end)

  -- Expand snippet with slight delay for insert mode
  if #snippets_to_expand > 0 then
    vim.cmd(':startinsert!')
    vim.defer_fn(function()
      luasnip.snip_expand(snippets_to_expand[1])
    end, 50)
  else
    -- Fallback: try stored snippet object
    if item.snippet then
      vim.cmd(':startinsert!')
      vim.defer_fn(function()
        luasnip.snip_expand(item.snippet)
      end, 50)
    else
      vim.notify(
        string.format("No snippets found for trigger '%s'", item.trigger),
        vim.log.levels.WARN
      )
    end
  end
end

--- Open LuaSnip snippet picker
function M.open()
  local items = get_luasnip_items()

  if #items == 0 then
    vim.notify('No LuaSnip snippets available', vim.log.levels.INFO)
    return
  end

  Snacks.picker.pick({
    source = "luasnip",
    items = items,

    -- Format picker display with icons and structured layout
    format = function(item)
      return {
        { item.icon .. " ",                                                                         item.icon_hl },
        { item.display_ft .. " | " },
        { (item.description ~= '' and item.description or (item.name or 'No description')) .. " | " },
        { item.trigger }
      }
    end,

    -- Preview window showing snippet expansion
    preview = function(ctx)
      ctx.preview:reset()

      local lines = vim.split(ctx.item.preview_text, "\n")
      ctx.preview:set_lines(lines)

      -- Apply syntax highlighting based on filetype
      local ft = ctx.item.ft ~= '' and ctx.item.ft or vim.bo.filetype
      if ft then
        ctx.preview:highlight({ ft = ft })
      end
    end,

    layout = {
      preset = "telescope",
    },

    -- Expand selected snippet
    confirm = function(picker, item)
      picker:close()
      expand_snippet(item)
    end,
  })
end

return M
