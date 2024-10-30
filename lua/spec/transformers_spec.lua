local rootPath = vim.loop.cwd()

-- Closing all buffers.
local function closeAllBuffers()
	local buffers = vim.api.nvim_list_bufs()
	for _, buffer in pairs(buffers) do
		if vim.api.nvim_buf_is_loaded(buffer) and vim.api.nvim_buf_is_valid(buffer) then
			vim.api.nvim_buf_delete(buffer, { force = true })
		end
	end
end

local function runOther(filename)
	closeAllBuffers()
	vim.cmd([[
		command! -nargs=* Other lua require('other-nvim').open(<f-args>)
		command! -nargs=* OtherTabNew lua require('other-nvim').openTabNew(<f-args>)
		command! -nargs=* OtherSplit lua require('other-nvim').openSplit(<f-args>)
		command! -nargs=* OtherVSplit lua require('other-nvim').openVSplit(<f-args>)
		command! -nargs=* OtherClear lua require('other-nvim').clear(<f-args>)
	]])

	local fnInput = rootPath .. filename

	vim.api.nvim_command(":e " .. fnInput)
	vim.api.nvim_command(":Other")
end

local function checkForStringAtPos(position, string)
	local lastmatches = vim.g.other_lastmatches
	local result = nil

	if lastmatches[position] ~= nil then
		result = lastmatches[position].filename:find(string) ~= nil
	end
	if result == nil then
		print(position, string)
	end
	if result == false then
		print(position, lastmatches[position].filename, string)
	end
	return result
end

describe("transformers", function()
	it("runs a single transformer", function()
		require("other-nvim").setup({
			showMissingFiles = true,
			mappings = {
        {
          pattern = "/app/(.*)/(.*).html",
          target = {
            { target = "/app/%1/%2.rb", transformer = "pluralize", context = "test" },
          }
        }
			},
		})

		runOther("/lua/spec/fixtures/rails-minitest/app/views/user/create.html")
		assert.is_true(checkForStringAtPos(1, "app/views/users/creates.rb"))
	end)

	it("runs a different transformer on each part", function()
		require("other-nvim").setup({
			showMissingFiles = true,
			mappings = {
        {
          pattern = "/app/(%w*)/(%w*)/(.*).html",
          target = {
            { target = "/app/%1/%2/%3.rb", transformers = { "singularize" , nil, "pluralize" }, context = "test" },
          }
        }
			},
		})

		runOther("/lua/spec/fixtures/rails-minitest/app/views/user/create.html")
		assert.is_true(checkForStringAtPos(1, "app/view/user/creates.rb"))
	end)
end)
