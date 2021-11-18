local config = require "groupbutler.config"
local locale = require "groupbutler.languages"
local i18n = locale.translate
local null = require "groupbutler.null"
local api_err = require "groupbutler.api_errors"

local _M = {}

function _M:new(update_obj)
	local plugin_obj = {}
	setmetatable(plugin_obj, {__index = self})
	for k, v in pairs(update_obj) do
		plugin_obj[k] = v
	end
	return plugin_obj
end

function _M:onTextMessage(blocks)
	local api = self.api
	local msg = self.message
	local red = self.red
	local u = self.u
	
	if msg.chat.type == 'private' then return end
	
	if blocks[1] == 'warm' then
	
		if not msg.reply then 
			api:sendMessage(msg.chat.id, "Komenda musi być użyta jako odpowiedź (<code>reply</code>) do wiadomości.", 'html')
		else
			local who_warm, who_is_warmed = u:getnames_complete(msg)
			local hash = 'chat:'..msg.chat.id..':warms'
			red:hincrby(hash, msg.reply.from.id, 1)
			local count = red:hget(hash, msg.reply.from.id)
			if count == '1' then
				api:sendMessage(msg.chat.id, "" .. who_warm .. " <b>ogrzewa</b> " .. who_is_warmed .. " ❤ \n" .. who_is_warmed .. " <b>został ogrzany po raz pierwszy!</b>", 'html')
			else 
			 api:sendMessage(msg.chat.id, "" ..who_warm.. " <b>ogrzewa</b> " ..who_is_warmed.. "❤️ \n" ..who_is_warmed.. " <b>został ogrzany już " ..count.. " razy!</b>", 'html')
		end
	end
	end
	
	if blocks[1] == 'warmstats' then
		if not msg.reply then 
			api:sendMessage(msg.chat.id, "Komenda musi być użyta jako odpowiedź (<code>reply</code>) do wiadomości.", 'html')
		return end
		local who_warm, who_is_warmed = u:getnames_complete(msg)
		local hash = 'chat:'..msg.chat.id..':warms'
		local count = red:hget(hash, msg.reply.from.id)
		local count1 = tostring(count)
		if count1 == "userdata: (nil)" or count1 == '0' then 
			api:sendMessage(msg.chat.id, "" .. who_is_warmed.. " nie został ogrzany ani razu :(", 'html')
		else 
			if count1 == '1' then
				api:sendMessage(msg.chat.id, "" .. who_is_warmed .. " <b>został ogrzany dopiero</b> " .. count1 .. " <b>raz!</b>", 'html')
			else
				api:sendMessage(msg.chat.id, "" .. who_is_warmed .. " <b>został ogrzany już</b> " .. count1 .. " <b>razy!</b> ❤️", 'html')
			end
		end
	end

	if blocks[1] == 'warnstats' then
		if not msg.reply then 
			api:sendMessage(msg.chat.id, "Komenda musi być użyta jako odpowiedź (<code>reply</code>) do wiadomości.", 'html')
		return end
		local who_warm, who_is_warmed = u:getnames_complete(msg)
		local hash = 'chat:'..msg.chat.id..':warns'
		local count = red:hget(hash, msg.reply.from.id)
		local count1 = tostring(count)
		if count1 == "userdata: (nil)" or count1 == '0' then 
			api:sendMessage(msg.chat.id, "" .. who_is_warmed .. " ma czystą kartę! \nTrzymaj tak dalej!", 'html')
		else
			if count1 == '1' then
				api:sendMessage(msg.chat.id, "" .. who_is_warmed .. " <b>ma</b> " .. count1 .. " <b>ostrzeżenie!</b>", 'html')
			else
				api:sendMessage(msg.chat.id, "" .. who_is_warmed .. " <b>ma</b> " .. count1 .. " <b>ostrzeżenia!</b>", 'html')
			end
		end
	end
	
	if blocks[1] == 'boop' then
		if not msg.reply then 
			api:sendMessage(msg.chat.id, "Komenda musi być użyta jako odpowiedź (<code>reply</code>) do wiadomości.", 'html')
		else
			local who_warm, who_is_warmed = u:getnames_complete(msg)
			api:sendMessage(msg.chat.id, "" .. who_warm .. " <b>tycnął</b> " .. who_is_warmed .. " 💚 \n", 'html')
		end
	end	
	
	if blocks[1] == 'tyc' then
		if not msg.reply then 
			api:sendMessage(msg.chat.id, "Komenda musi być użyta jako odpowiedź (<code>reply</code>) do wiadomości.", 'html')
		else
			local who_warm, who_is_warmed = u:getnames_complete(msg)
			api:sendMessage(msg.chat.id, "" .. who_warm .. " <b>tycnął</b> " .. who_is_warmed .. " 💚 \n", 'html')
		end
	end
	
	if blocks[1] == 'nowarm' then
		if not msg.reply then return end 
		local admin, user = u:getnames_complete(msg)
		local hash = 'chat:'..msg.chat.id..':warms'
		red:hset(hash, msg.reply.from.id, 0)
		api:sendMessage(msg.chat.id, "" ..admin.. " <b>wyzerował licznik ogrzań</b> " ..user.. "", 'html')
	end
	
end

_M.triggers = {
	onTextMessage = {
		config.cmd..'(warm)$',
		config.cmd..'(nowarm)$',
		config.cmd..'(boop)$',
		config.cmd..'(tyc)$',
		config.cmd..'(warnstats)$',
		config.cmd..'(warmstats)$'
	}
}

return _M