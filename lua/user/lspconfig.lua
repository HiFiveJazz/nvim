local M = {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
}
local servers = {
	"armls",
	"clangd",
	"lua_ls",
	"harper_ls",
	"pyright",
	"cssls",
	"html",
	"bashls",
	"texlab",
	"vale_ls",
	"gopls",
}



local function install_return_q(dest_buf, origin_buf)
	vim.b[dest_buf].gd_return_buf = origin_buf

	vim.keymap.set("n", "<leader>q", function()
		local ret = vim.b.gd_return_buf
		local cur = vim.api.nvim_get_current_buf()

		if type(ret) == "number" and vim.api.nvim_buf_is_valid(ret) then
			vim.cmd("buffer " .. ret)
		else
			vim.cmd("bprevious")
		end

		local ok, bd = pcall(require, "bufdelete")
		if ok then
			bd.bufdelete(cur, false)
		else
			pcall(vim.api.nvim_buf_delete, cur, { force = false })
		end
	end, {
		buffer = dest_buf,
		silent = true,
		desc = "Close definition buffer and return",
	})
end

local function lsp_keymaps(bufnr)
	local opts = { noremap = true, silent = true, buffer = bufnr }

	vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)

	vim.keymap.set("n", "gd", function()
		local origin_buf = vim.api.nvim_get_current_buf()
		local origin_win = vim.api.nvim_get_current_win()

		vim.lsp.buf.definition()

		local tries = 0
		local max_tries = 25
		local delay_ms = 20

		local function poll()
			tries = tries + 1
			if not vim.api.nvim_win_is_valid(origin_win) then
				return
			end

			local dest_buf = vim.api.nvim_win_get_buf(origin_win)
			if dest_buf ~= origin_buf then
				install_return_q(dest_buf, origin_buf)
				return
			end

			if tries < max_tries then
				vim.defer_fn(poll, delay_ms)
			end
		end

		vim.defer_fn(poll, 0)
	end, opts)

	vim.keymap.set("n", "gI", vim.lsp.buf.implementation, opts)
	vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)

	vim.keymap.set("n", "<CR>", function()
		vim.lsp.buf.signature_help({ border = "rounded" })
	end, opts)

	vim.keymap.set("n", "gl", function()
		vim.diagnostic.open_float({ border = "rounded" })
	end, opts)

	vim.keymap.set("n", "K", function()
		local ok, ufo = pcall(require, "ufo")
		if ok then
			local winid = ufo.peekFoldedLinesUnderCursor()
			if winid then
				return
			end
		end
		vim.lsp.buf.hover({ border = "rounded" })
	end, opts)

	vim.keymap.set("n", "<leader>oi", function()
		vim.lsp.buf.code_action({
			context = { only = { "source.organizeImports" } },
			apply = true,
		})
	end, { desc = "Organize Imports", buffer = bufnr, silent = true })
end

local function organize_imports(bufnr)
	local client = vim.lsp.get_clients({ bufnr = bufnr, name = "gopls" })[1]
	if not client then
		return
	end

	local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
	params.context = { only = { "source.organizeImports" } }

	local result = vim.lsp.buf_request_sync(bufnr, "textDocument/codeAction", params, 1000)
	for _, res in pairs(result or {}) do
		for _, action in pairs(res.result or {}) do
			if action.edit then
				vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
			elseif action.command then
				vim.lsp.buf.execute_command(action.command)
			end
		end
	end
end

function M.toggle_lsp()
	local enabled = vim.lsp.is_enabled(servers[1])

	vim.lsp.enable(servers, not enabled)

	vim.notify(
		"LSP " .. (enabled and "Disabled" or "Enabled"),
		vim.log.levels.INFO
	)
end

M.on_attach = function(client, bufnr)
	lsp_keymaps(bufnr)

	if client:supports_method("textDocument/inlayHint") then
		vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
	end

	if client.name == "gopls" then
		local group = vim.api.nvim_create_augroup("GoImports_" .. bufnr, { clear = true })

		vim.api.nvim_create_autocmd("BufWritePre", {
			group = group,
			buffer = bufnr,
			callback = function(args)
				organize_imports(args.buf)
				vim.lsp.buf.format({ bufnr = args.buf })
			end,
			desc = "Go: organize imports + format on save",
		})
	end
end

M.toggle_inlay_hints = function()
	vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }), { bufnr = 0 })
end

vim.api.nvim_create_autocmd("BufEnter", {
	group = vim.api.nvim_create_augroup("InitLuaSmartGd", { clear = true }),
	pattern = "*/nvim/init.lua",
	callback = function(ev)
		local function open_module_under_cursor_same_window()
			local s = vim.fn.expand("<cfile>")
			if not s or s == "" then
				return false
			end

			s = s:gsub([[^['"]+]], ""):gsub([[['"]+$]], "")

			if not s:match("^user%.") then
				return false
			end

			local rel1 = "lua/" .. s:gsub("%.", "/") .. ".lua"
			local rel2 = "lua/" .. s:gsub("%.", "/") .. "/init.lua"
			local found = vim.api.nvim_get_runtime_file(rel1, false)[1] or vim.api.nvim_get_runtime_file(rel2, false)[1]

			if not found or found == "" then
				return false
			end

			vim.cmd("normal! m'")

			local origin_buf = ev.buf
			local origin_win = vim.api.nvim_get_current_win()

			vim.cmd("edit " .. vim.fn.fnameescape(found))

			local dest_buf = vim.api.nvim_win_get_buf(origin_win)
			install_return_q(dest_buf, origin_buf)

			return true
		end

		vim.keymap.set("n", "gd", function()
			if not open_module_under_cursor_same_window() then
				vim.lsp.buf.definition()
			end
		end, {
			buffer = ev.buf,
			silent = true,
			desc = "init.lua: open module buffer / LSP definition",
		})
	end,
})

function M.common_capabilities()
	local ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
	if ok then
		local caps = cmp_nvim_lsp.default_capabilities()
		caps.textDocument.foldingRange = {
			dynamicRegistration = false,
			lineFoldingOnly = true,
		}
		return caps
	end

	local capabilities = vim.lsp.protocol.make_client_capabilities()
	capabilities.textDocument.completion.completionItem.snippetSupport = true
	capabilities.textDocument.completion.completionItem.resolveSupport = {
		properties = { "documentation", "detail", "additionalTextEdits" },
	}
	capabilities.textDocument.foldingRange = {
		dynamicRegistration = false,
		lineFoldingOnly = true,
	}
	return capabilities
end

function M.config()
	vim.o.winborder = "rounded"

	-- rustaceanvim owns rust_analyzer
	vim.lsp.enable("rust_analyzer", false)

	local wk = require("which-key")
	wk.add({
		{ "<leader>la", "<cmd>lua vim.lsp.buf.code_action()<cr>", desc = "Code Action" },
		{
			"<leader>lf",
			"<cmd>lua vim.lsp.buf.format({ async = true, filter = function(client) return client.name ~= 'typescript-tools' end })<cr>",
			desc = "Format",
		},
		{
			"<leader>lh",
			"<cmd>lua require('user.lspconfig').toggle_inlay_hints()<cr>",
			desc = "Hints",
			icon = { icon = "󰛨 ", color = "blue" },
		},
		{ "<leader>li", "<cmd>LspInfo<cr>", desc = "Info", icon = { icon = "󰋽 ", color = "blue" } },
		{
			"<leader>lj",
			"<cmd>lua vim.diagnostic.goto_next()<cr>",
			desc = "Next Diagnostic",
			icon = { icon = "󰮰 ", color = "blue" },
		},
		{
			"<leader>lk",
			"<cmd>lua vim.diagnostic.goto_prev()<cr>",
			desc = "Prev Diagnostic",
			icon = { icon = "󰮲 ", color = "blue" },
		},
		{
			"<leader>ll",
			"<cmd>lua vim.lsp.codelens.run()<cr>",
			desc = "CodeLens Action",
			icon = { icon = " ", color = "blue" },
		},
		{
			"<leader>lq",
			"<cmd>lua vim.diagnostic.setloclist()<cr>",
			desc = "Quickfix",
			icon = { icon = "󰁨 ", color = "blue" },
		},
		{
			"<leader>lr",
			"<cmd>lua vim.lsp.buf.rename()<cr>",
			desc = "Rename",
			icon = { icon = "󰟵 ", color = "blue" },
		},
		{
			"<leader>lt",
			"<cmd>lua require('user.lspconfig').toggle_lsp()<cr>",
			desc = "Toggle LSP",
			icon = { icon = "󰒍 ", color = "blue" },
		},
	})

	wk.add({
		{ "<leader>la", group = "LSP" },
		{ "<leader>laa", "<cmd>lua vim.lsp.buf.code_action()<cr>", desc = "Code Action", mode = "v" },
	})


	vim.diagnostic.config({
		signs = true,
		virtual_text = true,
		update_in_insert = false,
		underline = true,
		severity_sort = true,
		float = {
			focusable = true,
			style = "minimal",
			border = "rounded",
			header = "",
			prefix = "",
		},
	})

	for _, server in ipairs(servers) do
		local opts = {
			on_attach = M.on_attach,
			capabilities = M.common_capabilities(),
		}

		local ok, settings = pcall(require, "user.lspsettings." .. server)
		if ok then
			opts = vim.tbl_deep_extend("force", opts, settings)
		end

		vim.lsp.config(server, opts)
	end

	vim.lsp.enable(servers)
end

return M
