local config = require "groupbutler.config"
local locale = require "groupbutler.languages"
local i18n = locale.translate
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

local function bot_version()
	if not config.commit or (config.commit):len() ~= 40 then
		return i18n("unknown")
	end
	return ("[%s](%s/commit/%s)"):format(string.sub(config.commit, 1, 7), config.source_code, config.commit)
end

local strings = {
	about = i18n([[Hej! Dziękuję, że zdecydowałeś się na poświęcenie swojego cennego czasu na zajrzenie tutaj. 
Futrzaczek powstał ponad pół roku temu (wow, jak ten czas szybko leci). Przy jego tworzeniu opierałem się w większości na projekcie [GroupButler](https://github.com/group-butler/GroupButler) z moimi własnymi modyfikacjami, rozwiązaniami dla problemów oraz tłumaczeniem. Jest to mój pierwszy duży projekt, który zyskał tak dużą popularność (na dzień dzisiejszy - 04/01/2019 - jest używany na około 30 aktywnych grupach). Dziękuję wszystkim za wsparcie oraz liczę na dalszą współpracę! :P 
]])
}

local function do_keyboard_credits(self)
	local bot = self.bot
	local keyboard = {}
	keyboard.inline_keyboard = {
		{
			{text = i18n("Kanał dyskusyjny"), url = 't.me/futrzaczekdiscussions'},
			{text = i18n("Napisz do mnie! x3"), url = 'https://telegram.me/poszko'},
		}
	}
	return keyboard
end

function _M:onTextMessage(blocks)
	local api = self.api
	local msg = self.message

	if msg.chat.type ~= 'private' then return end

	if blocks[1] == 'ping' then
		api:sendMessage(msg.from.id, i18n("Pong!"), "Markdown")
	end
	if blocks[1] == 'echo' then
		local ok, err = api:sendMessage(msg.chat.id, blocks[2], "Markdown")
		if not ok then
			api:sendMessage(msg.chat.id, api_err.trans(err), "Markdown")
		end
	end
	if blocks[1] == 'about' then
		local keyboard = do_keyboard_credits(self)
		api:sendMessage(msg.chat.id, strings.about, "Markdown", true, nil, nil, keyboard)
	end
	if blocks[1] == 'group' then
		if config.help_group and config.help_group ~= '' then
			api:sendMessage(msg.chat.id,
				i18n('You can find the list of our support groups in [this channel](%s)'):format(config.help_group), "Markdown")
		end
	end
end

function _M:onCallbackQuery(blocks)
	local api = self.api
	local msg = self.message

	if blocks[1] == 'about' then
		local keyboard = do_keyboard_credits(self)
		api:editMessageText(msg.chat.id, msg.message_id, nil, strings.about, "Markdown", true, keyboard)
	end
	if blocks[1] == 'group' then
		if config.help_group and config.help_group ~= '' then
			local markup = {inline_keyboard={{{text = i18n('🔙 back'), callback_data = 'fromhelp:about'}}}}
			api:editMessageText(msg.chat.id, msg.message_id, nil,
				i18n("You can find the list of our support groups in [this channel](%s)"):format(config.help_group),
				"Markdown", nil, markup)
		end
	end
end

_M.triggers = {
	onTextMessage = {
		config.cmd..'(ping)$',
		config.cmd..'(echo) (.*)$',
		config.cmd..'(about)$',
		config.cmd..'(group)s?$',
		'^/start (group)s$'
	},
	onCallbackQuery = {
		'^###cb:fromhelp:(about)$',
		'^###cb:private:(group)s$'
	}
}

return _M
