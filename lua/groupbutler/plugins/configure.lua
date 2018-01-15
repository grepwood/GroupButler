local config = require "groupbutler.config"
local u = require "groupbutler.utilities"
local api = require "telegram-bot-api.methods".init(config.telegram.token)
local db = require "groupbutler.database"
local locale = require "groupbutler.languages"
local i18n = locale.translate

local plugin = {}

local function cache_chat_title(chat_id, title)
	print('caching title...')
	local key = 'chat:'..chat_id..':title'
	db:set(key, title)
	db:expire(key, config.bot_settings.cache_time.chat_titles)

	return title
end

local function get_chat_title(chat_id)
	local cached_title = db:get('chat:'..chat_id..':title')
	if not cached_title then
		local chat_object = api.getChat(chat_id)
		if chat_object then
			return cache_chat_title(chat_id, chat_object.title)
		end
	else
		return cached_title
	end
end

local function do_keyboard_config(chat_id, user_id) -- is_admin
	local keyboard = {
		inline_keyboard = {
			{{text = i18n("🛠 Menu"), callback_data = 'config:menu:'..chat_id}},
			{{text = i18n("⚡️ Antiflood"), callback_data = 'config:antiflood:'..chat_id}},
			{{text = i18n("🌈 Media"), callback_data = 'config:media:'..chat_id}},
			{{text = i18n("🚫 Antispam"), callback_data = 'config:antispam:'..chat_id}},
			{{text = i18n("📥 Log channel"), callback_data = 'config:logchannel:'..chat_id}}
		}
	}

	if u.can(chat_id, user_id, "can_restrict_members") then
		table.insert(keyboard.inline_keyboard,
			{{text = i18n("⛔️ Default permissions"), callback_data = 'config:defpermissions:'..chat_id}})
	end

	return keyboard
end

function plugin.onTextMessage(msg)
	if msg.chat.type ~= 'private' then
		if u.is_allowed('config', msg.chat.id, msg.from) then
			local chat_id = msg.chat.id
			local keyboard = do_keyboard_config(chat_id, msg.from.id)
			if not db:get('chat:'..chat_id..':title') then cache_chat_title(chat_id, msg.chat.title) end
			local res = api.sendMessage(msg.from.id,
				i18n("<b>%s</b>\n<i>Change the settings of your group</i>"):format(msg.chat.title:escape_html()), 'html',
					nil, nil, nil, keyboard)
			if not u.is_silentmode_on(msg.chat.id) then --send the responde in the group only if the silent mode is off
				if res then
					api.sendMessage(msg.chat.id, i18n("_I've sent you the keyboard via private message_"), "Markdown")
				else
					u.sendStartMe(msg)
				end
			end
		end
	end
end

function plugin.onCallbackQuery(msg)
	local chat_id = msg.target_id
	local keyboard = do_keyboard_config(chat_id, msg.from.id, msg.from.admin)
	local text = i18n("<i>Change the settings of your group</i>")
	local chat_title = get_chat_title(chat_id)
	if chat_title then
		text = ("<b>%s</b>\n"):format(chat_title:escape_html())..text
	end
	api.editMessageText(msg.chat.id, msg.message_id, nil, text, 'html', nil, keyboard)
end

plugin.triggers = {
	onTextMessage = {
		config.cmd..'config$',
		config.cmd..'settings$',
	},
	onCallbackQuery = {
		'^###cb:config:back:'
	}
}

return plugin
