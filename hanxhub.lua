
-- ============================================================
--  END KEY SYSTEM — script utama dimulai di bawah
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local CollectionService = game:GetService("CollectionService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local LocalPlayer = Players.LocalPlayer
local VisualESP, kf_sync_loop

local TAB_ICONS = {
	Home     = { Id = "", Fallback = "⌂" },
	Survivor = { Id = "", Fallback = "◈" },
	Visuals  = { Id = "", Fallback = "◉" },
	Killer   = { Id = "", Fallback = "◎" },
	Misc     = { Id = "", Fallback = "❖" },
	Config   = { Id = "", Fallback = "⚙" },
}

local HANX_ASSETS = {
	logo_id = "rbxassetid://122823093583910",
	bg_id = "rbxassetid://122823093583910",
	bg_transparency = 0.74,
	minisize_logo_id = "rbxassetid://122823093583910",
}

local SCRIPT_INFO = {
	hub_name = "HANX HUB",
	version = "v3.0.2 • Free User",
	status = "ACTIVE • READY",
	tabs_list = "Home (Info), Survivor, Visuals, Killer, Misc, Config",
	note = "The Home tab is dedicated to script information. All gameplay features are located in the Survivor, Visuals, Killer, Misc, and Config tabs.",
}

local SOCIAL_INFO = {
	youtube = "https://youtube.com/@hannxhub?si=K1IE-QZcFDMOku_6",
	saweria = "https://saweria.co/HANXHUB",
	discord = "https://discord.gg/B7Xpt7BAY",
}

local COLLAB_INFO = {
	creator = "HANX HUB × TIAN HUB",
	collab = "Main Collab with TIAN HUB",
	support = "https://saweria.co/HANXHUB",
	contact = "https://discord.com/users/617241157092638720",
	credit = "Partial Help by Mimiw",
}


local function resolve_icon(raw: string): string
	if raw == "" or raw == "rbxassetid://0" then
		return ""
	end
	if string.find(raw, "^rbxassetid://") or string.find(raw, "^http") then
		return raw
	end
	return "rbxassetid://" .. raw
end

local lp = LocalPlayer
local gui_parent = lp:FindFirstChildOfClass("PlayerGui")
if not gui_parent then
	local ok, core = pcall(function()
		return game:GetService("CoreGui")
	end)
	gui_parent = (ok and core) or lp:WaitForChild("PlayerGui")
end

local old_ui = gui_parent:FindFirstChild("HANX_HUB_ROUNDED")
if old_ui then
	old_ui:Destroy()
end

local P = {
	bg = Color3.fromRGB(13, 11, 20),
	bg_grad_top = Color3.fromRGB(24, 18, 38),
	bg_grad_bot = Color3.fromRGB(10, 8, 15),
	sidebar = Color3.fromRGB(18, 15, 28),
	card = Color3.fromRGB(27, 22, 40),
	card_hover = Color3.fromRGB(37, 30, 56),
	card_active = Color3.fromRGB(43, 33, 66),
	drawer = Color3.fromRGB(20, 17, 31),
	stroke = Color3.fromRGB(82, 62, 124),
	stroke_bright = Color3.fromRGB(168, 85, 247),
	white_glow = Color3.fromRGB(255, 255, 255),
	accent = Color3.fromRGB(178, 98, 255),
	accent_deep = Color3.fromRGB(92, 34, 168),
	accent_soft = Color3.fromRGB(64, 34, 106),
	text = Color3.fromRGB(248, 245, 255),
	muted = Color3.fromRGB(156, 148, 178),
	on_col = Color3.fromRGB(178, 98, 255),
	off_col = Color3.fromRGB(52, 46, 68),
	danger = Color3.fromRGB(225, 29, 72),
}

local function round_all(inst: Instance, px: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, px)
	c.Parent = inst
	return c
end

local function stroke_all(inst: Instance, col: Color3, px: number?, trans: number?)
	local s = Instance.new("UIStroke")
	s.Color = col
	s.Thickness = px or 1
	s.Transparency = trans or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = inst
	return s
end

local function pad_all(inst: Instance, t: number, b: number, l: number, r: number)
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, t)
	p.PaddingBottom = UDim.new(0, b)
	p.PaddingLeft = UDim.new(0, l)
	p.PaddingRight = UDim.new(0, r)
	p.Parent = inst
	return p
end

local function v_grad(inst: Instance, top_c: Color3, bot_c: Color3)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(top_c, bot_c)
	g.Rotation = 90
	g.Parent = inst
	return g
end

--========= SAVE//LOAD///AUTOLOAD============------

local HttpService = game:GetService("HttpService")

local HANX_CFG_DIR = "HANX_HUB_Configs"
local HANX_META_FILE = HANX_CFG_DIR .. "/hanxhub_meta.json"

local ConfigStore = {
	Registry = {},
	ActiveSlot = "default",
	AutoLoad = false,
	MemorySlots = {},
	Slots = { "slot_1", "slot_2", "slot_3", "slot_4" },
}

local function has_fs_support(): boolean
	return type(writefile) == "function"
		and type(readfile) == "function"
		and type(isfile) == "function"
		and type(makefolder) == "function"
end

local function ensure_cfg_dir()
	if not has_fs_support() then
		return
	end
	pcall(function()
		if not isfolder or not isfolder(HANX_CFG_DIR) then
			makefolder(HANX_CFG_DIR)
		end
	end)
end

local function sanitize_slot(name: string?): string
	local raw = tostring(name or "default")
	raw = string.match(raw, "^%s*(.-)%s*$") or "default"
	local cleaned = string.gsub(raw, "[^%w_%-]", "_")
	if cleaned == "" then
		cleaned = "default"
	end
	return string.lower(cleaned)
end

local function slot_file_path(slot_name: string?): string
	return HANX_CFG_DIR .. "/slot_" .. sanitize_slot(slot_name) .. ".json"
end

local function write_json_file(path: string, tbl: any): boolean
	if not has_fs_support() then
		return false
	end
	ensure_cfg_dir()
	local ok_enc, encoded = pcall(function()
		return HttpService:JSONEncode(tbl)
	end)
	if not ok_enc or type(encoded) ~= "string" then
		return false
	end
	local ok_wr = pcall(function()
		writefile(path, encoded)
	end)
	return ok_wr == true
end

local function read_json_file(path: string): any
	if not has_fs_support() then
		return nil
	end
	local ok_ex, exists = pcall(function()
		return isfile(path)
	end)
	if not ok_ex or not exists then
		return nil
	end
	local ok_rd, raw = pcall(function()
		return readfile(path)
	end)
	if not ok_rd or type(raw) ~= "string" or raw == "" then
		return nil
	end
	local ok_dec, decoded = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	if ok_dec and type(decoded) == "table" then
		return decoded
	end
	return nil
end

local function ensure_slot_in_list(slot_name: string?)
	local s = sanitize_slot(slot_name)
	for _, existing in ipairs(ConfigStore.Slots) do
		if existing == s then
			return
		end
	end
	table.insert(ConfigStore.Slots, s)
end

local function save_meta()
	ensure_slot_in_list(ConfigStore.ActiveSlot)
	local meta = {
		active_slot = ConfigStore.ActiveSlot,
		auto_load = ConfigStore.AutoLoad,
		slots = ConfigStore.Slots,
	}
	write_json_file(HANX_META_FILE, meta)
end

local function load_meta()
	local meta = read_json_file(HANX_META_FILE)
	if type(meta) == "table" then
		if type(meta.slots) == "table" and #meta.slots > 0 then
			ConfigStore.Slots = {}
			for _, s in ipairs(meta.slots) do
				if type(s) == "string" and s ~= "" then
					ensure_slot_in_list(s)
				end
			end
		end
		if type(meta.active_slot) == "string" and meta.active_slot ~= "" then
			ConfigStore.ActiveSlot = sanitize_slot(meta.active_slot)
			ensure_slot_in_list(ConfigStore.ActiveSlot)
		end
		if type(meta.auto_load) == "boolean" then
			ConfigStore.AutoLoad = meta.auto_load
		end
	end
end

local function register_config_item(key: string, kind: string, getter: () -> any, setter: (any, boolean?) -> ())
	ConfigStore.Registry[key] = {
		kind = kind,
		get = getter,
		set = setter,
	}
end

local function collect_config_data(): { [string]: any }
	local payload = {}
	for key, item in pairs(ConfigStore.Registry) do
		local ok, val = pcall(item.get)
		if ok then
			payload[key] = val
		end
	end
	return payload
end

local function apply_config_data(data: { [string]: any }, silent: boolean?): boolean
	if type(data) ~= "table" then
		return false
	end
	for key, val in pairs(data) do
		local entry = ConfigStore.Registry[key]
		if entry and type(entry.set) == "function" then
			pcall(entry.set, val, silent)
		end
	end
	return true
end

local function save_config_slot(slot_name: string?): (boolean, string)
	local slot = sanitize_slot(slot_name or ConfigStore.ActiveSlot)
	ConfigStore.ActiveSlot = slot
	ensure_slot_in_list(slot)
	local data = collect_config_data()
	ConfigStore.MemorySlots[slot] = data
	local saved_disk = write_json_file(slot_file_path(slot), data)
	save_meta()
	if saved_disk then
		return true, "Saved slot '" .. slot .. "'"
	end
	return true, "Saved '" .. slot .. "' (Session)"
end

local function load_config_slot(slot_name: string?, silent: boolean?): (boolean, string)
	local slot = sanitize_slot(slot_name or ConfigStore.ActiveSlot)
	ConfigStore.ActiveSlot = slot
	ensure_slot_in_list(slot)
	local data = read_json_file(slot_file_path(slot))
	if type(data) ~= "table" then
		data = ConfigStore.MemorySlots[slot]
	end
	if type(data) ~= "table" then
		return false, "Slot '" .. slot .. "' not found"
	end
	ConfigStore.MemorySlots[slot] = data
	apply_config_data(data, silent)
	save_meta()
	return true, "Loaded slot '" .. slot .. "'"
end

local function rename_config_slot(old_name: string?, new_name: string?): (boolean, string)
	local old_s = sanitize_slot(old_name or ConfigStore.ActiveSlot)
	if new_name == nil or string.match(tostring(new_name), "^%s*$") then
		return false, "Enter new slot name"
	end
	local new_s = sanitize_slot(new_name)
	if old_s == new_s then
		return false, "Slot name is unchanged"
	end

	local data = read_json_file(slot_file_path(old_s)) or ConfigStore.MemorySlots[old_s]
	if type(data) ~= "table" then
		return false, "Slot '" .. old_s .. "' not found"
	end

	ConfigStore.MemorySlots[new_s] = data
	ConfigStore.MemorySlots[old_s] = nil
	write_json_file(slot_file_path(new_s), data)

	if has_fs_support() and type(delfile) == "function" then
		local old_path = slot_file_path(old_s)
		local ok_ex, exists = pcall(function()
			return isfile(old_path)
		end)
		if ok_ex and exists then
			pcall(delfile, old_path)
		end
	end

	for i, s in ipairs(ConfigStore.Slots) do
		if s == old_s then
			ConfigStore.Slots[i] = new_s
			break
		end
	end
	ensure_slot_in_list(new_s)

	if ConfigStore.ActiveSlot == old_s then
		ConfigStore.ActiveSlot = new_s
	end
	save_meta()
	return true, "Renamed '" .. old_s .. "' -> '" .. new_s .. "'"
end

load_meta()

task.defer(function()
	task.wait(0.25)
	if ConfigStore.AutoLoad then
		load_config_slot(ConfigStore.ActiveSlot, false)
	end
end)

local function load_config_slot(slot_name: string?, silent: boolean?): (boolean, string)
	local slot = sanitize_slot(slot_name or ConfigStore.ActiveSlot)
	ConfigStore.ActiveSlot = slot
	ensure_slot_in_list(slot)
	local data = read_json_file(slot_file_path(slot))
	if type(data) ~= "table" then
		data = ConfigStore.MemorySlots[slot]
	end
	if type(data) ~= "table" then
		return false, "Slot '" .. slot .. "' not found"
	end
	ConfigStore.MemorySlots[slot] = data
	apply_config_data(data, silent)
	save_meta()
	return true, "Loaded slot '" .. slot .. "'"
end

local function rename_config_slot(old_name: string?, new_name: string?): (boolean, string)
	local old_s = sanitize_slot(old_name or ConfigStore.ActiveSlot)
	if new_name == nil or string.match(tostring(new_name), "^%s*$") then
		return false, "Enter new slot name"
	end
	local new_s = sanitize_slot(new_name)
	if old_s == new_s then
		return false, "Slot name is unchanged"
	end

	local data = read_json_file(slot_file_path(old_s)) or ConfigStore.MemorySlots[old_s]
	if type(data) ~= "table" then
		return false, "Slot '" .. old_s .. "' not found"
	end

	ConfigStore.MemorySlots[new_s] = data
	ConfigStore.MemorySlots[old_s] = nil
	write_json_file(slot_file_path(new_s), data)

	if has_fs_support() and type(delfile) == "function" then
		local old_path = slot_file_path(old_s)
		local ok_ex, exists = pcall(function()
			return isfile(old_path)
		end)
		if ok_ex and exists then
			pcall(delfile, old_path)
		end
	end

	for i, s in ipairs(ConfigStore.Slots) do
		if s == old_s then
			ConfigStore.Slots[i] = new_s
			break
		end
	end
	ensure_slot_in_list(new_s)

	if ConfigStore.ActiveSlot == old_s then
		ConfigStore.ActiveSlot = new_s
	end
	save_meta()
	return true, "Renamed '" .. old_s .. "' -> '" .. new_s .. "'"
end

local function mount_open_config_controls(target_parent: Instance?)
	if not target_parent then
		return
	end

	local function make_btn(parent: Instance, txt: string, order_n: number, on_click: () -> ())
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1, 0, 0, 30)
		b.BackgroundColor3 = P.sidebar
		b.BackgroundTransparency = 0.12
		b.BorderSizePixel = 0
		b.Text = txt
		b.TextColor3 = P.text
		b.Font = Enum.Font.GothamBold
		b.TextSize = 11
		b.AutoButtonColor = false
		b.LayoutOrder = order_n
		b.Parent = parent
		round_all(b, 7)
		stroke_all(b, P.accent, 1, 0.35)
		b.MouseButton1Click:Connect(on_click)
		return b
	end

	local panel = Instance.new("Frame")
	panel.Name = "HanxOpenConfigPanel"
	panel.Size = UDim2.new(1, -6, 0, 0)
	panel.AutomaticSize = Enum.AutomaticSize.Y
	panel.BackgroundColor3 = P.card
	panel.BackgroundTransparency = 0.14
	panel.BorderSizePixel = 0
	panel.Parent = target_parent
	round_all(panel, 10)
	stroke_all(panel, P.stroke, 1, 0.35)
	pad_all(panel, 6, 6, 6, 6)

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = panel

	local lbl_status = Instance.new("TextLabel")
	lbl_status.Size = UDim2.new(1, 0, 0, 14)
	lbl_status.BackgroundTransparency = 1
	lbl_status.Text = "Slot: " .. ConfigStore.ActiveSlot .. (ConfigStore.AutoLoad and " | AutoLoad: ON" or " | AutoLoad: OFF")
	lbl_status.TextColor3 = P.text
	lbl_status.Font = Enum.Font.GothamBold
	lbl_status.TextSize = 10.5
	lbl_status.TextXAlignment = Enum.TextXAlignment.Left
	lbl_status.TextTruncate = Enum.TextTruncate.AtEnd
	lbl_status.LayoutOrder = 1
	lbl_status.Parent = panel

	local slot_bar = Instance.new("Frame")
	slot_bar.Size = UDim2.new(1, 0, 0, 22)
	slot_bar.BackgroundTransparency = 1
	slot_bar.LayoutOrder = 2
	slot_bar.Parent = panel

	local slot_list = Instance.new("UIListLayout")
	slot_list.FillDirection = Enum.FillDirection.Horizontal
	slot_list.Padding = UDim.new(0, 4)
	slot_list.Parent = slot_bar

	local box_slot = Instance.new("TextBox")
	box_slot.Size = UDim2.new(1, 0, 0, 24)
	box_slot.BackgroundColor3 = P.sidebar
	box_slot.BackgroundTransparency = 0.16
	box_slot.BorderSizePixel = 0
	box_slot.Text = ConfigStore.ActiveSlot
	box_slot.PlaceholderText = "Nama slot (slot_1 - slot_4)..."
	box_slot.PlaceholderColor3 = P.muted
	box_slot.TextColor3 = P.text
	box_slot.Font = Enum.Font.GothamMedium
	box_slot.TextSize = 10.5
	box_slot.TextXAlignment = Enum.TextXAlignment.Left
	box_slot.ClearTextOnFocus = false
	box_slot.LayoutOrder = 3
	box_slot.Parent = panel
	round_all(box_slot, 7)
	stroke_all(box_slot, P.stroke, 1, 0.4)
	pad_all(box_slot, 0, 0, 7, 7)

	local box_rename = Instance.new("TextBox")
	box_rename.Size = UDim2.new(1, 0, 0, 24)
	box_rename.BackgroundColor3 = P.sidebar
	box_rename.BackgroundTransparency = 0.16
	box_rename.BorderSizePixel = 0
	box_rename.Text = ""
	box_rename.PlaceholderText = "Nama baru untuk Rename..."
	box_rename.PlaceholderColor3 = P.muted
	box_rename.TextColor3 = P.text
	box_rename.Font = Enum.Font.GothamMedium
	box_rename.TextSize = 10.5
	box_rename.TextXAlignment = Enum.TextXAlignment.Left
	box_rename.ClearTextOnFocus = false
	box_rename.LayoutOrder = 4
	box_rename.Parent = panel
	round_all(box_rename, 7)
	stroke_all(box_rename, P.stroke, 1, 0.4)
	pad_all(box_rename, 0, 0, 7, 7)

	local function set_status(msg: string, is_err: boolean?)
		lbl_status.Text = msg
		lbl_status.TextColor3 = is_err and P.danger or Color3.fromRGB(130, 240, 165)
	end

	local slot_buttons = {}
	local function refresh_slot_buttons()
		for s_name, info in pairs(slot_buttons) do
			local active = (ConfigStore.ActiveSlot == s_name)
			info.btn.BackgroundColor3 = active and P.card_active or P.sidebar
			info.stroke.Color = active and P.accent or P.stroke
			info.stroke.Transparency = active and 0.15 or 0.35
		end
	end

	local slot_names = { "slot_1", "slot_2", "slot_3", "slot_4" }
	for i, s_name in ipairs(slot_names) do
		ensure_slot_in_list(s_name)
		local s_btn = Instance.new("TextButton")
		s_btn.Size = UDim2.new(0.25, -3, 1, 0)
		s_btn.BackgroundColor3 = P.sidebar
		s_btn.Text = "S" .. tostring(i)
		s_btn.TextColor3 = P.text
		s_btn.Font = Enum.Font.GothamBold
		s_btn.TextSize = 10.5
		s_btn.AutoButtonColor = false
		s_btn.Parent = slot_bar
		round_all(s_btn, 6)
		local s_stroke = stroke_all(s_btn, P.stroke, 1, 0.35)
		slot_buttons[s_name] = { btn = s_btn, stroke = s_stroke }

		s_btn.MouseButton1Click:Connect(function()
			ConfigStore.ActiveSlot = s_name
			box_slot.Text = s_name
			refresh_slot_buttons()
			save_meta()
			set_status("Active slot: " .. s_name, false)
		end)
	end
	refresh_slot_buttons()

	make_btn(panel, "Save Config", 5, function()
		local ok, msg = save_config_slot(box_slot.Text)
		box_slot.Text = ConfigStore.ActiveSlot
		refresh_slot_buttons()
		set_status(msg, not ok)
	end)

	make_btn(panel, "Load Config", 6, function()
		local ok, msg = load_config_slot(box_slot.Text, false)
		if ok then
			box_slot.Text = ConfigStore.ActiveSlot
			refresh_slot_buttons()
		end
		set_status(msg, not ok)
	end)

	make_btn(panel, "Rename Slot", 7, function()
		local ok, msg = rename_config_slot(box_slot.Text, box_rename.Text)
		if ok then
			box_slot.Text = ConfigStore.ActiveSlot
			box_rename.Text = ""
			refresh_slot_buttons()
		end
		set_status(msg, not ok)
	end)

	local auto_btn = make_btn(panel, "Auto Load: " .. (ConfigStore.AutoLoad and "ON" or "OFF"), 8, function()
		ConfigStore.AutoLoad = not ConfigStore.AutoLoad
		save_meta()
		auto_btn.Text = "Auto Load: " .. (ConfigStore.AutoLoad and "ON" or "OFF")
		set_status(ConfigStore.AutoLoad and ("Auto Load: ON (" .. ConfigStore.ActiveSlot .. ")") or "Auto Load: OFF", false)
	end)

	register_config_item("HanxOpenAutoLoad", "toggle", function()
		return ConfigStore.AutoLoad
	end, function(val)
		ConfigStore.AutoLoad = val == true
		save_meta()
		auto_btn.Text = "Auto Load: " .. (ConfigStore.AutoLoad and "ON" or "OFF")
	end)
end

load_meta()

task.defer(function()
	task.wait(0.25)
	if ConfigStore.AutoLoad then
		load_config_slot(ConfigStore.ActiveSlot, false)
	end
end)
-- ============================================================
--  FREE CURSOR / UNLOCK MOUSE ONLY (IN-GAME LOCK BYPASS + RMB SMOOTH DRAG)
-- ============================================================
local FreeCursorEngine = {
	Enabled = false,
	HoldingRMB = false,
	SavedMouseBehavior = nil :: Enum.MouseBehavior?,
	SavedMouseIconEnabled = nil :: boolean?,
}

local function FC_IsRMBHeld()
	local held = false
	pcall(function()
		held = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
	end)
	return held or FreeCursorEngine.HoldingRMB
end

local function FC_ApplyUnlockedCursor()
	pcall(function()
		UserInputService.MouseIconEnabled = true
		if UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default then
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end
	end)
end

local function FC_ApplyRMBDragMode()
	pcall(function()
		UserInputService.MouseIconEnabled = true
		if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCurrentPosition then
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
		end
	end)
end

local function FC_RestoreState()
	FreeCursorEngine.HoldingRMB = false
	pcall(function()
		UserInputService.MouseBehavior = FreeCursorEngine.SavedMouseBehavior or Enum.MouseBehavior.Default
	end)
	pcall(function()
		UserInputService.MouseIconEnabled = (FreeCursorEngine.SavedMouseIconEnabled ~= nil)
			and FreeCursorEngine.SavedMouseIconEnabled
			or true
	end)
	FreeCursorEngine.SavedMouseBehavior = nil
	FreeCursorEngine.SavedMouseIconEnabled = nil
end

local function FC_SetEnabled(v: boolean)
	local next_v = v == true
	if FreeCursorEngine.Enabled == next_v then
		return
	end
	FreeCursorEngine.Enabled = next_v

	if next_v then
		FreeCursorEngine.SavedMouseBehavior = UserInputService.MouseBehavior
		FreeCursorEngine.SavedMouseIconEnabled = UserInputService.MouseIconEnabled
		FreeCursorEngine.HoldingRMB = false
		pcall(function()
			FreeCursorEngine.HoldingRMB = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
		end)
		if FreeCursorEngine.HoldingRMB then
			FC_ApplyRMBDragMode()
		else
			FC_ApplyUnlockedCursor()
		end
	else
		FC_RestoreState()
	end
end

UserInputService.InputBegan:Connect(function(input, _gp)
	if not FreeCursorEngine.Enabled then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		FreeCursorEngine.HoldingRMB = true
		FC_ApplyRMBDragMode()
	end
end)

UserInputService.InputEnded:Connect(function(input, _gp)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		FreeCursorEngine.HoldingRMB = false
		if FreeCursorEngine.Enabled then
			FC_ApplyUnlockedCursor()
		end
	end
end)

RunService.RenderStepped:Connect(function()
	if not FreeCursorEngine.Enabled then
		return
	end
	local rmbHeld = FC_IsRMBHeld()
	FreeCursorEngine.HoldingRMB = rmbHeld
	if rmbHeld then
		FC_ApplyRMBDragMode()
	else
		FC_ApplyUnlockedCursor()
	end
end)

-- ============================================================
--  TWIST OF FATE SILENT AIM + SMART PREDICT (INTACT)
-- ============================================================
local TOF_Bridge = {}
do
	local Players          = game:GetService("Players")
	local UserInputService = game:GetService("UserInputService")
	local RunService       = game:GetService("RunService")

	local LP        = Players.LocalPlayer
	local unloaded  = false
	local connections = {}
	local function track(conn)
		table.insert(connections, conn)
		return conn
	end

	local function getTOFGunPart(ch)
		local tool = ch and ch:FindFirstChild("Twist of Fate", true)
		if not tool then return nil end
		local rightArm = tool:FindFirstChild("Right Arm", true)
		if rightArm then
			for _, name in ipairs({ "gun", "EmperorGun" }) do
				local gun = rightArm:FindFirstChild(name)
				if gun then
					if gun:IsA("BasePart") then return gun end
					local part = gun:FindFirstChildWhichIsA("BasePart", true)
					if part then return part end
				end
			end
		end
		if tool:IsA("BasePart") then return tool end
		return tool:FindFirstChildWhichIsA("BasePart", true)
	end

	local function getTOFLaserOrigin(ch)
		local gunPart = getTOFGunPart(ch)
		return gunPart and gunPart.Position or nil
	end

	local State = {}

	State.Motion = {}
	do
		local M   = State.Motion
		local exp = math.exp
		function M.Regress(list, tn, window, tau)
			if not list then return nil end
			local sw, sdt, sdt2, n = 0, 0, 0, 0
			local sp, sdtp = Vector3.zero, Vector3.zero
			for i = #list, 1, -1 do
				local e = list[i]
				local dt = e.t - tn
				if dt < -window then break end
				local w = exp(dt / tau)
				sw   = sw   + w
				sdt  = sdt  + w * dt
				sdt2 = sdt2 + w * dt * dt
				sp   = sp   + e.p * w
				sdtp = sdtp + e.p * (w * dt)
				n    = n + 1
			end
			if n < 3 then return nil end
			local denom = sw * sdt2 - sdt * sdt
			if denom < 1e-9 then return nil end
			local slope = (sdtp * sw - sp * sdt) / denom
			local c     = (sp - slope * sdt) / sw
			return slope, c, n
		end
		function M.Estimate(list)
			if not list or #list < 4 then return nil end
			local tn = list[#list].t
			local vS = M.Regress(list, tn, 0.14, 0.07)
			local vL = M.Regress(list, tn, 0.40, 0.2)
			if not vS and not vL then return nil end
			if not vS then return vL, Vector3.zero, false end
			if not vL then return vS, Vector3.zero, false end
			local fs, fl = Vector3.new(vS.X, 0, vS.Z), Vector3.new(vL.X, 0, vL.Z)
			local reversal = fl.Magnitude > 2 and fs.Magnitude > 2 and fs:Dot(fl) < 0
			local vel = reversal and vS or (vS * 0.7 + vL * 0.3)
			local acc = (vS - vL) / 0.12
			if acc.Magnitude > 50 then acc = acc.Unit * 50 end
			return vel, acc, reversal
		end
	end

	do
		local marks = {}
		local function setNameColor(char, color)
			pcall(function()
				local bb  = char and char:FindFirstChild("PE_Text")
				local box = bb and bb:FindFirstChild("Box")
				local row = box and box:FindFirstChild("NameRow")
				local lbl = row and row:FindFirstChild("NameText")
				if lbl and lbl:IsA("TextLabel") then lbl.TextColor3 = color end
			end)
		end
		local function clear(key)
			local m = marks[key]
			if not m then return end
			marks[key] = nil
			if m.highlight then pcall(function() m.highlight:Destroy() end) end
			if m.char then
				local stillMarked, activeColor = false, nil
				for _, other in pairs(marks) do
					if other.char == m.char then
						stillMarked = true
						activeColor = other.color
						break
					end
				end
				if stillMarked then
					setNameColor(m.char, activeColor or Color3.fromRGB(255, 40, 40))
				else
					setNameColor(m.char, Color3.fromRGB(240, 240, 248))
				end
			end
		end
		State.ClearMark = clear
		State.SetMark = function(key, char, color)
			if not char or not char.Parent then return clear(key) end
			local m = marks[key]
			if m and m.char == char and m.highlight and m.highlight.Parent == char then
				m.highlight.FillColor         = color
				m.highlight.OutlineColor      = Color3.new(1, 1, 1)
				m.highlight.FillTransparency  = 0
				m.highlight.OutlineTransparency = 0
				m.color = color
				setNameColor(char, color)
				return
			end
			clear(key)
			local hl = Instance.new("Highlight")
			hl.Name    = "KINON_TargetHighlight_" .. tostring(key)
			hl.Adornee = char
			hl.FillColor    = color
			hl.OutlineColor = Color3.new(1, 1, 1)
			hl.FillTransparency    = 0
			hl.OutlineTransparency = 0
			hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			hl.Parent    = char
			setNameColor(char, color)
			marks[key] = { char = char, highlight = hl, color = color }
		end
	end

	State.AimHold = { held = false, ok = false, tried = false }
	do
		local AH  = State.AimHold
		local old
		AH.Install = function()
			if AH.tried then return end
			AH.tried = true
			if type(hookmetamethod) ~= "function" or type(getnamecallmethod) ~= "function" then return end
			local wrapf = newcclosure or function(f) return f end
			local ok = pcall(function()
				old = hookmetamethod(game, "__namecall", wrapf(function(self, ...)
					local method = getnamecallmethod()
					if setnamecallmethod then setnamecallmethod(method) end
					if not unloaded and method == "FireServer" and typeof(self) == "Instance"
					   and self.Name == "AimHold" and self.ClassName == "RemoteEvent" then
						local v = select(2, ...)
						if type(v) == "boolean" then AH.held = v end
					end
					if setnamecallmethod then setnamecallmethod(method) end
					return old(self, ...)
				end))
			end)
			AH.ok = ok and old ~= nil
		end
	end

	State.TOFSilent = {
		Enabled    = false,
		FOV        = 120,
		Predict    = false,
		ZigZag     = false,
		LeadScale  = 100,
		ShowCircle = true,
		ShowLaser  = true,
		SmartPredict = true,
		UseSnap      = true,
		UseTravel    = true,
		WallCheck    = true,
		Windup       = 0.05,
		LineSmooth   = 70,
	}

	State.SmartPredict = (function()
		local T  = State.TOFSilent
		local SP = {}

		local VD = {
			TOF_HitGainN    = 1,
			TOF_HitGainM    = 1,
			TOF_HitGainF    = 1,
			TOF_TravelK     = 0.5,
			TOF_BulletSpeed = 800,
			TOF_DelayAuto   = nil,
		}
		SP.VD = VD

		local Track   = setmetatable({}, { __mode = "k" })
		local SnapBuf = {}
		local Shot    = nil
		local LastPred, LastReal = nil, nil
		local RawMode = false
		local LastVel, LastMult, LastBase, LastVB = nil, 1, 0, 800

		function SP.Ping()
			local p = 0.08
			pcall(function() p = math.clamp(LP:GetNetworkPing(), 0, 0.35) end)
			return p
		end

		function SP.Delay()
			if tonumber(VD.TOF_DelayAuto) then
				return math.clamp(VD.TOF_DelayAuto, 0.05, 1.5)
			end
			return (tonumber(T.Windup) or 0.05) + SP.Ping() * 0.8
		end

		local function Band(d) return d < 15 and "N" or (d < 35 and "M" or "F") end
		SP.Band = Band

		function SP.ArcDisp(vel, omega, Tm)
			local N, dt = 6, Tm / 6
			local rot = CFrame.Angles(0, omega * dt, 0)
			local pos, dir = Vector3.zero, vel
			for _ = 1, N do
				pos = pos + dir * dt
				dir = rot:VectorToWorldSpace(dir)
			end
			return pos
		end

		function SP.ConfEff(S)
			if math.abs(S.omega or 0) > 0.35 then return math.max(S.conf, 0.6) end
			return S.conf
		end

		local hooked = setmetatable({}, { __mode = "k" })
		local function HookBullet(r)
			if hooked[r] then return end
			hooked[r] = true
			r.OnClientEvent:Connect(function(origin, endp, spd)
				local sh = Shot
				if not sh or sh.used or typeof(origin) ~= "Vector3" or typeof(endp) ~= "Vector3" then return end
				local dt = os.clock() - sh.t
				if dt < 0.05 or dt > 1.6 then return end
				local ch  = LP.Character
				local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
				if not hrp or (origin - hrp.Position).Magnitude > 15 then return end
				sh.used = true
				if type(spd) == "number" and spd > 5 then VD.TOF_BulletSpeed = spd end
				local cur = tonumber(VD.TOF_DelayAuto)
				VD.TOF_DelayAuto = cur and (cur + (dt - cur) * 0.3) or dt
				if sh.real and sh.aim and sh.tc and sh.vel then
					task.delay(0.1, function()
						local root = sh.tc:FindFirstChild("HumanoidRootPart") or sh.tc:FindFirstChild("Torso")
						if not (root and root.Parent) then return end
						local real, aim = sh.real, sh.aim
						local L  = Vector3.new(aim.X - real.X, 0, aim.Z - real.Z)
						local D  = Vector3.new(root.Position.X - real.X, 0, root.Position.Z - real.Z)
						local vh = Vector3.new(sh.vel.X, 0, sh.vel.Z)
						if L.Magnitude <= 2 or vh.Magnitude <= 2 or D.Magnitude < 0.5 then return end
						if D:Dot(vh) <= 0 or D.Unit:Dot(vh.Unit) < 0.6 then return end
						local vb = sh.vb or 200
						local travel = (sh.d or 0) / vb
						if T.UseTravel and travel >= 0.1 then
							local tTrue = D:Dot(vh) / vh:Dot(vh)
							local tUsed = tTrue / math.max(sh.mult or 1, 0.2)
							local kTrue = (tUsed - (sh.base or 0)) / travel
							local k = tonumber(VD.TOF_TravelK) or 0.5
							VD.TOF_TravelK = math.clamp(k + (math.clamp(kTrue, 0, 2.5) - k) * 0.25, 0, 2.5)
						else
							local ratio = math.clamp(D:Dot(L) / L:Dot(L), 0, 2.5)
							local key = "TOF_HitGain" .. (sh.band or "M")
							local g = tonumber(VD[key]) or 1
							VD[key] = math.clamp(g + (g * ratio - g) * 0.3, 0.3, 2)
						end
					end)
				end
			end)
		end

		task.spawn(function()
			local rs = game:GetService("ReplicatedStorage")
			local function try(d)
				if d.Name == "VisualizeBullet"
				   and (d:IsA("RemoteEvent") or d.ClassName == "UnreliableRemoteEvent") then
					pcall(HookBullet, d)
				end
			end
			for _, d in ipairs(rs:GetDescendants()) do try(d) end
			rs.DescendantAdded:Connect(try)
		end)

		task.spawn(function()
			local rs = game:GetService("ReplicatedStorage")
			local r = rs:WaitForChild("Remotes", 15)
			r = r and r:WaitForChild("Mechanics", 15)
			r = r and r:WaitForChild("NetRemote", 15)
			if not r then return end
			r.OnClientEvent:Connect(function(pkt)
				if not (T.SmartPredict and T.UseSnap) then return end
				if type(pkt) ~= "table" or pkt.kind ~= "Snapshot" then return end
				local dd = pkt.data
				if type(dd) ~= "table" or type(dd.players) ~= "table" or type(dd.t) ~= "number" then return end
				local nowc = os.clock()
				for _, pe in pairs(dd.players) do
					if type(pe) == "table" and typeof(pe.pos) == "Vector3" and type(pe.id) == "number" then
						local e = SnapBuf[pe.id]
						if not e then e = { s = {} }; SnapBuf[pe.id] = e end
						local sb = e.s
						local last = sb[#sb]
						if not last or dd.t > last.ts then
							if last and (pe.pos - last.pos).Magnitude / math.max(dd.t - last.ts, 0.001) > 250 then
								e.s = {}; sb = e.s
							end
							sb[#sb + 1] = { ts = dd.t, pos = pe.pos, tl = nowc }
							while #sb > 24 do table.remove(sb, 1) end
						end
					end
				end
			end)
		end)

		function SP.GetSnap(char)
			local pl = char and Players:GetPlayerFromCharacter(char)
			local e  = pl and SnapBuf[pl.UserId]
			if not e then return nil end
			local sb, n = e.s, #(e.s)
			if n < 3 then return nil end
			local last = sb[n]
			if os.clock() - last.tl > 0.4 then return nil end
			local function seg(t0, t1)
				local a, b
				for i = 1, n do
					local x   = sb[i]
					local age = last.ts - x.ts
					if age >= t0 and age <= t1 then
						if not a then a = x end
						b = x
					end
				end
				if a and b and b.ts - a.ts >= 0.07 then
					local v = (b.pos - a.pos) / (b.ts - a.ts)
					return Vector3.new(v.X, 0, v.Z), v.Y
				end
			end
			local w0, vy = seg(0, 0.15)
			if not w0 then return nil end
			local vNow = seg(0, 0.1)
			local vs = vNow or w0
			if vs.Magnitude < 1 then vs = Vector3.zero end
			local w1, w2 = seg(0.15, 0.3), seg(0.3, 0.45)
			local conf, omega = 1, 0
			local function turn(a, b)
				if not (a and b) or a.Magnitude < 2 or b.Magnitude < 2 then return nil end
				local phi = math.atan2(a.Z, a.X) - math.atan2(b.Z, b.X)
				if phi > math.pi then phi = phi - 2*math.pi elseif phi < -math.pi then phi = phi + 2*math.pi end
				return phi
			end
			local flips = 0
			if w0 and w1 and w0.Magnitude > 2 and w1.Magnitude > 2 and w0.Unit:Dot(w1.Unit) < 0.2 then flips = flips + 1 end
			if w1 and w2 and w1.Magnitude > 2 and w2.Magnitude > 2 and w1.Unit:Dot(w2.Unit) < 0.2 then flips = flips + 1 end
			if flips >= 2 then
				local net = seg(0, 0.45)
				vs = net or Vector3.zero
				if vs.Magnitude < 1.5 then vs = Vector3.zero end
				return { pos = last.pos, tl = last.tl, vel = vs, vy = vy or 0, conf = 0.6, omega = 0 }
			end
			local p1, p2 = turn(w1, w0), turn(w2, w1)
			if p1 and p2 and math.abs(p1) > 0.08 and math.abs(p2) > 0.08 then
				if p1 * p2 > 0 then
					omega = math.clamp((p1 + p2) / 2 / 0.15, -8, 8)
				else
					conf = 0.5
				end
			end
			return { pos = last.pos, tl = last.tl, vel = vs, vy = vy or 0, conf = conf, omega = omega }
		end

		function SP.SampleVel(char)
			local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
			if not (root and root:IsA("BasePart")) then return end
			local S = Track[char]
			if not S then
				S = { s = {}, pend = {}, mAuto = 1, conf = 1, omega = 0,
					  vShort = Vector3.zero, lead = Vector3.zero, leadT = 0, lastPend = 0 }
				Track[char] = S
			end
			local now, pos = os.clock(), root.Position
			local s = S.s
			local last = s[#s]
			if last then
				if now - last.t < 0.004 then return end
				if (pos - last.pos).Magnitude / (now - last.t) > 200 then
					S.s = {}; S.pend = {}; S.lead = Vector3.zero; s = S.s
				end
			end
			s[#s + 1] = { t = now, pos = pos }
			while #s > 2 and now - s[1].t > 0.45 do table.remove(s, 1) end

			local function seg(t0, t1)
				local a, b
				for i = 1, #s do
					local e = s[i]
					if e.t >= now - t1 and e.t <= now - t0 then
						if not a then a = e end
						b = e
					end
				end
				if a and b and b.t - a.t >= 0.04 then
					local v = (b.pos - a.pos) / (b.t - a.t)
					return Vector3.new(v.X, 0, v.Z), v.Y
				end
			end
			local vs, vy = seg(0, 0.15)
			vs = vs or Vector3.zero
			S.vy = vy or 0
			if vs.Magnitude < 1 then vs = Vector3.zero end
			local vl = seg(0.15, 0.4)
			local conf = 1
			if vl and vs.Magnitude > 1 and vl.Magnitude > 1 then
				conf = math.clamp(vs.Unit:Dot(vl.Unit), 0.25, 1)
			end
			S.vShort, S.conf = vs, conf
			if vl and vs.Magnitude > 2 and vl.Magnitude > 2 then
				local phi = math.atan2(vl.Z, vl.X) - math.atan2(vs.Z, vs.X)
				if phi > math.pi then phi = phi - 2*math.pi elseif phi < -math.pi then phi = phi + 2*math.pi end
				S.omega = S.omega * 0.5 + math.clamp(phi / 0.2, -8, 8) * 0.5
			else
				S.omega = S.omega * 0.8
			end

			S.vIn, S.stopping, S.air = nil, false, false
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				local md  = hum.MoveDirection
				local mdh = Vector3.new(md.X, 0, md.Z)
				if mdh.Magnitude > 0.1 then
					if not S.hadInput then S.inT0 = now; S.holdT0 = now end
					local dirNow = mdh.Unit
					if S.inDir and S.inDir:Dot(dirNow) < 0.9 then S.inT0 = now end
					S.inDir = dirNow
					S.hadInput = true
					local wsNow = hum.WalkSpeed
					if wsNow > 0 and (now - (S.holdT0 or now)) > 0.15 and vs.Magnitude < 0.3 * wsNow then
						if not S.blocked then S.blocked = true; S.blockDir = dirNow end
					elseif wsNow > 0 and vs.Magnitude >= 0.5 * wsNow then
						S.blocked = false
					end
					if vs.Magnitude > 2 then S.mdWorks = true end
					if vs.Magnitude > 2 then
						S.vIn = mdh.Unit * vs.Magnitude
					elseif hum.WalkSpeed > 0 then
						S.vIn = mdh.Unit * hum.WalkSpeed * 0.6
					end
				else
					S.hadInput = false
					S.blocked, S.inDir = false, nil
					if S.mdWorks then S.stopping = true end
				end
				local okf, fm = pcall(function() return hum.FloorMaterial end)
				S.air = okf and fm == Enum.Material.Air
			end

			local pend = S.pend
			if T.SmartPredict then
				if vs.Magnitude > 2 and conf > 0.7 and now - S.lastPend > 0.06 and #pend < 24 then
					local tau = SP.Delay()
					S.lastPend = now
					pend[#pend + 1] = { due = now + tau, base = pos, vl = vs * tau }
				end
				local i = 1
				while i <= #pend do
					local pd = pend[i]
					if now >= pd.due then
						local disp = pos - pd.base
						disp = Vector3.new(disp.X, 0, disp.Z)
						local den = pd.vl:Dot(pd.vl)
						if den > 1 then
							local m = math.clamp(disp:Dot(pd.vl) / den, 0, 2.5)
							S.mAuto = S.mAuto + (m - S.mAuto) * 0.12
						end
						table.remove(pend, i)
					else
						i = i + 1
					end
				end
			elseif #pend > 0 then
				S.pend = {}
			end
		end

		function SP.Compute(t, tc, op, d)
			LastReal, LastPred = nil, nil
			if not (T.SmartPredict and tc) then return nil end

			SP.SampleVel(tc)
			local S = Track[tc]
			if not S then return nil end

			local SN   = T.UseSnap and SP.GetSnap(tc) or nil
			local hrpR = tc:FindFirstChild("HumanoidRootPart")
			if SN and (not hrpR or (SN.pos - hrpR.Position).Magnitude > 50) then SN = nil end
			if SN then
				S.vShort, S.vy, S.omega, S.conf = SN.vel, SN.vy, SN.omega, SN.conf
			end

			local vel  = S.vShort or Vector3.zero
			local nowc = os.clock()
			if S.vIn then
				local startingUp = S.inT0 and (nowc - S.inT0) < 0.25
				local exiting = S.blocked and S.blockDir and S.vIn.Magnitude > 0.1
					and S.vIn.Unit:Dot(S.blockDir) < 0.85
				if exiting then
					vel = S.vIn.Unit * math.max(vel.Magnitude, S.vIn.Magnitude * 0.8)
				elseif startingUp or vel.Magnitude >= 0.5 * S.vIn.Magnitude then
					vel = vel:Lerp(S.vIn, startingUp and 0.6 or 0.5)
				end
			elseif S.stopping then
				vel = vel * 0.3
			end

			local vy = S.vy or 0
			if not (vel.Magnitude > 1 or (S.air and math.abs(vy) > 1)) then
				S.lead  = Vector3.zero
				S.leadT = nowc
				return nil
			end

			if d < 5 then
				S.lead  = Vector3.zero
				S.leadT = nowc
				return nil
			end

			local tp = t.Position
			local mult = math.clamp(
			math.clamp(S.mAuto, 0.2, 1.8) * SP.ConfEff(S)
			- (tonumber(VD["TOF_HitGain" .. SP.Band(d)]) or 1),
				0.3, 1.6
			)

			local base = SP.Delay()
			local vb   = math.max(tonumber(VD.TOF_BulletSpeed) or 800, 50)
			local kT   = T.UseTravel and math.clamp(tonumber(VD.TOF_TravelK) or 0.5, 0, 2.5) or 0
			local om   = S.omega or 0
			local ex, snapOff, realBase = 0, Vector3.zero, tp
			if SN then
				ex = math.clamp(os.clock() - SN.tl, 0, 0.15)
				local off = hrpR and (tp - hrpR.Position) or Vector3.zero
				realBase = SN.pos + off
				snapOff  = realBase - tp
			end

			local function leadFor(dl0)
				local dl = dl0 + ex
				local ld = vel * dl * mult
				if vel.Magnitude > 2 and math.abs(om) > 0.35 then
					local lim = math.rad(100) / math.max(dl, 0.05)
					local omE = math.clamp(om * 0.7, -lim, lim)
					ld = SP.ArcDisp(vel, omE, dl) * mult
				end
				local cap = math.clamp(math.max(d * 0.6, vel.Magnitude * dl * mult * 1.2), 3, 120)
				if ld.Magnitude > cap then ld = ld.Unit * cap end
				return ld
			end

			local delay = base + kT * d / vb
			local lead  = leadFor(delay)
			if kT > 0 then
				for _ = 1, 2 do
					delay = base + kT * (tp + lead - op).Magnitude / vb
					lead  = leadFor(delay)
				end
			end

			local dy = 0
			if S.air then
				dy = vy * delay - 0.5 * workspace.Gravity * delay * delay
				local okr, hit = pcall(function()
					local rp2 = RaycastParams.new()
					rp2.FilterType = Enum.RaycastFilterType.Exclude
					rp2.FilterDescendantsInstances = { tc, LP.Character }
					return workspace:Raycast(tp, Vector3.new(0, -300, 0), rp2)
				end)
				if okr and hit then dy = math.max(dy, -((tp.Y - hit.Position.Y) - 1)) end
				dy = math.clamp(dy, -40, 25)
			end

			if T.WallCheck then
				local lh = Vector3.new(lead.X, 0, lead.Z)
				if lh.Magnitude > 1.5 then
					local okw, wh = pcall(function()
						local rp3 = RaycastParams.new()
						rp3.FilterType = Enum.RaycastFilterType.Exclude
						rp3.RespectCanCollide = true
						local ex2 = { tc, LP.Character }
						for _, pl2 in ipairs(Players:GetPlayers()) do
							if pl2.Character then ex2[#ex2 + 1] = pl2.Character end
						end
						rp3.FilterDescendantsInstances = ex2
						return workspace:Raycast(realBase, lh, rp3)
					end)
					if okw and wh then
						local wd = math.max((wh.Position - realBase).Magnitude - 1.2, 0)
						lead = lh.Unit * math.min(wd, lh.Magnitude) + Vector3.new(0, lead.Y, 0)
					end
				end
			end

			lead = lead + snapOff
			lead = Vector3.new(lead.X, dy + snapOff.Y, lead.Z)
			LastReal = realBase
			LastVel, LastMult, LastBase, LastVB = vel, mult, base, vb

			local dt = math.clamp(nowc - S.leadT, 0, 0.2)
			S.leadT = nowc
			local sm   = math.clamp((tonumber(T.LineSmooth) or 70) / 100, 0, 1)
			local rate = 80 * (1 - sm) + 8 * sm
			S.lead = S.lead:Lerp(lead, math.clamp(dt * rate, 0.05, 1))
			local aimPos = tp + (RawMode and lead or S.lead)

			LastPred = {
				tc = tc, real = LastReal or tp, aim = aimPos, band = SP.Band(d),
				vel = LastVel, mult = LastMult, base = LastBase, d = d, vb = LastVB,
			}
			return aimPos
		end

		function SP.RecordShot()
			local lp2 = LastPred
			if not lp2 then return end
			Shot = {
				t = os.clock(), tc = lp2.tc, real = lp2.real, aim = lp2.aim, band = lp2.band,
				vel = lp2.vel, mult = lp2.mult, base = lp2.base, d = lp2.d, vb = lp2.vb, used = false,
			}
		end

		function SP.SetRawMode(v) RawMode = v == true end
		SP.Track = Track

		track(RunService.Heartbeat:Connect(function()
			if unloaded or not T.SmartPredict then return end
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= LP and p.Character then SP.SampleVel(p.Character) end
			end
		end))

		return SP
	end)()

	State.SilentObj = (function()
		local T   = State.TOFSilent
		local obj = {}
		local effects, original
		local installing = false

		local killerCache, killerCacheAt = nil, 0
		local function killerChar()
			local now = os.clock()
			if killerCache and killerCache.Parent and now - killerCacheAt < 0.5 then return killerCache end
			killerCacheAt = now
			killerCache = nil
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= LP and p.Character then
					local team = p.Team and string.lower(p.Team.Name) or ""
					if string.find(team, "killer", 1, true) or p.Character:FindFirstChild("Lookscriptkiller", true) then
						killerCache = p.Character
						return killerCache
					end
				end
			end
			return nil
		end

		local function targetPart(ch)
			local pick = T.AimPart
			if pick == "Head" then
				local h = ch:FindFirstChild("Head")
				if h then return h end
			elseif pick == "HumanoidRootPart" then
				local r = ch:FindFirstChild("HumanoidRootPart")
				if r then return r end
			end
			return ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso") or ch:FindFirstChild("HumanoidRootPart")
		end

		local function hasTOF(ch)
			if not ch then return false end
			if ch:FindFirstChild("Twist of Fate") then return true end
			local eq = string.lower(tostring(LP:GetAttribute("EquippedItem") or ""))
			return eq:find("twist", 1, true) ~= nil or eq:find("fate", 1, true) ~= nil
		end

		local function muzzle(ch)
			return getTOFLaserOrigin(ch)
		end

		local PROJ_SPEED     = 800
		local INTERP_DELAY   = 0.05
		local HISTORY_KEEP   = 1.4
		local VEL_CAP        = 60
		local Y_VEL_CLAMP    = 14
		local TELEPORT_STEP  = 12
		local history = setmetatable({}, { __mode = "k" })

		local function record(part, now)
			local list = history[part]
			if not list then list = {}; history[part] = list end
			local pos  = part.Position
			local last = list[#list]
			if last and (pos - last.p).Magnitude > TELEPORT_STEP then table.clear(list) end
			list[#list + 1] = { t = now, p = pos }
			while #list > 2 and now - list[1].t > HISTORY_KEEP do table.remove(list, 1) end
		end

		local function limitVel(v)
			v = Vector3.new(v.X, math.clamp(v.Y, -Y_VEL_CLAMP, Y_VEL_CLAMP), v.Z)
			if v.Magnitude > VEL_CAP then v = v.Unit * VEL_CAP end
			return v
		end
		local function flat(v) return Vector3.new(v.X, 0, v.Z) end

		local function latencyLead()
			local ok, ping = pcall(function() return LP:GetNetworkPing() end)
			local rtt = (ok and type(ping) == "number" and ping > 0) and math.clamp(ping, 0.02, 0.4) or 0.08
			return (rtt + INTERP_DELAY) * 0.8
		end

		track(RunService.Heartbeat:Connect(function()
			if unloaded or not (T.Enabled and not T.SmartPredict and (T.Predict or T.ZigZag)) then return end
			local kc = killerChar()
			local part = kc and targetPart(kc)
			if part then record(part, os.clock()) end
		end))

		local function observedVel(part)
			local list = history[part]
			if not list or #list < 3 then return nil end
			if os.clock() - list[#list].t > 0.15 then return nil end
			return State.Motion.Regress(list, list[#list].t, 0.14, 0.07)
		end

		local function getVelocity(part, hrp, hum)
			local base = hrp.AssemblyLinearVelocity
			local obs  = observedVel(part)
			if obs and obs.Magnitude > 3 and obs.Magnitude < 120 then
				local bf = flat(base)
				if bf.Magnitude < 1.5 or flat(obs):Dot(bf) < 0 then base = obs end
			end
			if hum then
				local md = hum.MoveDirection
				if md.Magnitude > 0.05 then
					local intent = md * hum.WalkSpeed
					local bf = flat(base)
					if bf.Magnitude > 0.5 and flat(intent):Dot(bf) < 0 then base = intent end
				end
			end
			return limitVel(base)
		end

		local function zzResiduals(list, tn, centerAt)
			local res = {}
			for i = 1, #list do
				local e = list[i]
				if e.t >= tn - 1.2 then res[#res + 1] = { t = e.t, p = e.p, r = flat(e.p - centerAt(e.t)) } end
			end
			return res
		end

		local function zzCross(res, u)
			local sm = {}
			local n = #res
			for i = 1, n do
				local a1, a2, a3 = res[math.max(i - 1, 1)].r:Dot(u), res[i].r:Dot(u), res[math.min(i + 1, n)].r:Dot(u)
				sm[i] = (a1 + a2 + a3) / 3
			end
			local cross, amps, curMax = {}, {}, 0
			for i = 2, n do
				curMax = math.max(curMax, math.abs(sm[i - 1]))
				if sm[i - 1] * sm[i] < 0 then
					local f = math.abs(sm[i - 1]) / (math.abs(sm[i - 1]) + math.abs(sm[i]))
					cross[#cross + 1] = res[i - 1].t + (res[i].t - res[i - 1].t) * f
					amps[#amps + 1] = curMax
					curMax = 0
				end
			end
			return cross, amps, sm
		end

		local function zzMean(res, t1, t2)
			local sx, sz, st, n = 0, 0, 0, 0
			for i = 1, #res do
				local e = res[i]
				if e.t >= t1 and e.t <= t2 then
					sx, sz, st, n = sx + e.p.X, sz + e.p.Z, st + e.t, n + 1
				end
			end
			if n < 2 then return nil end
			return Vector3.new(sx / n, 0, sz / n), st / n
		end

		local function zigzagPoint(part, from)
			local list = history[part]
			if not list or #list < 12 then return nil end
			local tn = list[#list].t
			if tn - list[1].t < 0.6 then return nil end
			local slope3, center = State.Motion.Regress(list, tn, 1.2, 0.6)
			if not slope3 then return nil end
			local res = zzResiduals(list, tn, function(t) return center + slope3 * (t - tn) end)
			local best, bestMag = nil, 0
			for i = 1, #res do
				local m = res[i].r.Magnitude
				if m > bestMag then best, bestMag = res[i].r, m end
			end
			local t0 = (center - from).Magnitude / PROJ_SPEED + latencyLead()
			if not best or bestMag < 0.5 or #res < 9 then return nil end
			local u = best.Unit
			local cross = zzCross(res, u)
			if #cross < 4 then return nil end
			local idx0, k = 1, #cross - 1
			if k % 2 == 1 then idx0, k = 2, k - 1 end
			if k < 2 then return nil end
			local cm, tm = zzMean(res, cross[idx0], cross[idx0 + k])
			if not cm then return nil end
			local drift = Vector3.zero
			if k >= 4 then
				local m1, t1 = zzMean(res, cross[idx0], cross[idx0 + 2])
				local m2, t2 = zzMean(res, cross[idx0 + k - 2], cross[idx0 + k])
				if m1 and m2 and t2 - t1 > 0.2 then drift = (m2 - m1) / (t2 - t1) end
			end
			if drift.Magnitude > 30 then drift = drift.Unit * 30 end
			local cNow = cm + drift * (tn - tm)
			local res2 = zzResiduals(list, tn, function(t) return cNow + drift * (t - tn) end)
			local cross2, amps2, sm2 = zzCross(res2, u)
			if #cross2 < 3 then return nil end
			local halves, hsum = {}, 0
			for i = 2, #cross2 do
				local h = cross2[i] - cross2[i - 1]
				halves[#halves + 1] = h
				hsum = hsum + h
			end
			local H = hsum / #halves
			local base = Vector3.new(cNow.X, list[#list].p.Y, cNow.Z) + drift * t0
			if H < 0.1 or H > 0.8 then return nil end
			local var = 0
			for _, h in ipairs(halves) do var = var + (h - H) * (h - H) end
			local conf = math.clamp(1 - (math.sqrt(var / #halves) / H) / 0.35, 0, 1)
			if conf <= 0.1 then return nil end
			local ampSum, ampN = 0, 0
			for i = 2, #amps2 do ampSum, ampN = ampSum + amps2[i], ampN + 1 end
			local A = ampN > 0 and ampSum / ampN or bestMag
			local sgn = sm2[#sm2] >= 0 and 1 or -1
			local phase = (tn - cross2[#cross2] + t0) / H
			return base + u * (sgn * A * math.sin(math.pi * phase) * conf)
		end

		local lastMoveAt = setmetatable({}, { __mode = "k" })

		local function aimPoint(part, from)
			local pos = part.Position

			if T.SmartPredict then
				local ch = part.Parent
				if ch then
					local d = (pos - from).Magnitude
					local aimPos = State.SmartPredict.Compute(part, ch, from, d)
					if aimPos then return aimPos end
				end
				return pos
			end

			if not (T.Predict or T.ZigZag) then return pos end
			do
				local ch0  = part.Parent
				local hrp0 = ch0 and ch0:FindFirstChild("HumanoidRootPart")
				local hum0 = ch0 and ch0:FindFirstChildOfClass("Humanoid")
				local now  = os.clock()
				local moving = false
				if hrp0 then
					local v1 = flat(hrp0.AssemblyLinearVelocity).Magnitude
					local v2 = flat(getVelocity(part, hrp0, hum0)).Magnitude
					moving = v1 > 2.5 or v2 > 2.5
				end
				if moving or not lastMoveAt[part] then lastMoveAt[part] = now end
				if now - lastMoveAt[part] > 0.25 then return pos end
			end
			if T.ZigZag then
				local zp = zigzagPoint(part, from)
				if zp then return zp end
			end
			if not T.Predict then return pos end
			local ch  = part.Parent
			local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
			if not hrp then return pos end
			local hum = ch:FindFirstChildOfClass("Humanoid")
			local vel = getVelocity(part, hrp, hum)
			if vel.Magnitude < 1 then return pos end
			local lat = latencyLead()
			local _, acc = State.Motion.Estimate(history[part])
			acc = acc and flat(acc) * 0.8 or Vector3.zero
			local t = (pos - from).Magnitude / PROJ_SPEED + lat
			local predicted = pos
			for _ = 1, 3 do
				local tc = math.min(t, 0.3)
				local a2 = acc
				if (vel + a2 * tc):Dot(vel) < 0 then a2 = -vel / math.max(tc, 0.05) end
				predicted = pos + vel * t + a2 * (0.5 * tc * tc)
				t = (predicted - from).Magnitude / PROJ_SPEED + lat
			end
			local scale  = math.clamp((tonumber(T.LeadScale) or 100) / 100, 0.3, 3)
			local offset = (predicted - pos) * scale
			if offset.Magnitude > 30 then offset = offset.Unit * 30 end
			return pos + offset
		end

		local function inFov(pos)
			local cam = workspace.CurrentCamera
			if not cam then return false end
			local to = pos - cam.CFrame.Position
			if to.Magnitude < 0.1 then return true end
			local dot = math.clamp(cam.CFrame.LookVector:Dot(to.Unit), -1, 1)
			return math.deg(math.acos(dot)) <= (tonumber(T.FOV) or 120) / 2
		end

		local function compute(character, ignoreFov)
			local kc   = killerChar()
			local part = kc and targetPart(kc)
			if not part then return nil end
			local from = muzzle(character)
			if not from then return nil end
			local pos  = aimPoint(part, from)
			if not ignoreFov and not inFov(pos) then return nil end
			local d = pos - from
			if d.Magnitude < 0.01 then return nil end
			return d.Unit
		end

		local circleGui, circleFrame, laserPart
		local activeTool, toolConns = nil, {}
		local isFiring, releaseUntil  = false, 0
		local lastAimDir, lastAimAt   = nil, 0

		local function clearToolConnections()
			for _, c in ipairs(toolConns) do pcall(function() c:Disconnect() end) end
			table.clear(toolConns)
			activeTool    = nil
			isFiring, releaseUntil = false, 0
		end

		local mouseHeld = false
		track(UserInputService.InputBegan:Connect(function(input, processed)
			if processed then return end
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				mouseHeld = true
			end
		end))
		track(UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				mouseHeld    = false
				releaseUntil = tick() + 0.12
			end
		end))

		local BULLET_LASER_MAX = 500

		local function bindActiveTool(ch)
			local tool = ch and ch:FindFirstChild("Twist of Fate")
			if tool == activeTool then return end
			clearToolConnections()
			mouseHeld = false
			if not (tool and tool:IsA("Tool")) then return end
			activeTool = tool
			toolConns[#toolConns + 1] = tool.Activated:Connect(function()
				isFiring = true; releaseUntil = 0
			end)
			toolConns[#toolConns + 1] = tool.Deactivated:Connect(function()
				State.AimHold.held = false
				isFiring = false
				releaseUntil = tick() + 0.12
			end)
			toolConns[#toolConns + 1] = tool.Unequipped:Connect(function()
				State.AimHold.held = false
				isFiring = false
				releaseUntil = 0
			end)
		end

		local function ensureCircle()
			if circleGui and circleGui.Parent then return true end
			local parent
			pcall(function() parent = (gethui and gethui()) or game:GetService("CoreGui") end)
			parent = parent or LP:FindFirstChildOfClass("PlayerGui")
			if not parent then return false end
			local sg = Instance.new("ScreenGui")
			sg.Name = "KINON_TOFSilentFOV"; sg.ResetOnSpawn = false
			sg.IgnoreGuiInset = true; sg.DisplayOrder = 20
			local f = Instance.new("Frame")
			f.AnchorPoint = Vector2.new(0.5, 0.5)
			f.Position = UDim2.fromScale(0.5, 0.5)
			f.BackgroundTransparency = 1; f.BorderSizePixel = 0
			f.Parent = sg
			local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(1, 0); corner.Parent = f
			local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(255, 255, 255)
			stroke.Thickness = 1.5; stroke.Transparency = 0.2; stroke.Parent = f
			local ok = pcall(function() sg.Parent = parent end)
			if not ok then return false end
			circleGui, circleFrame = sg, f
			return true
		end

		local function circleRadius(cam)
			local half  = math.rad(math.clamp((tonumber(T.FOV) or 120) / 2, 1, 85))
			local halfV = math.rad(cam.FieldOfView) / 2
			local r = (cam.ViewportSize.Y / 2) * math.tan(half) / math.tan(halfV)
			local visibleCap = math.min(cam.ViewportSize.X, cam.ViewportSize.Y) * 0.48
			return math.clamp(r, 12, visibleCap)
		end

		local function hideLaser()
			if laserPart then laserPart.Transparency = 1 end
		end

		local function updateLaser(from, to)
			if not (laserPart and laserPart.Parent) then
				local p = Instance.new("Part")
				p.Name = "KINON_TOFSilentLaser"
				p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
				p.Material = Enum.Material.Neon
				p.Color    = Color3.fromRGB(255, 60, 60)
				p.Transparency = 1
				p.Parent = workspace
				laserPart = p
			end
			local dist = (to - from).Magnitude
			if dist < 0.5 then return hideLaser() end
			local thick = math.clamp(dist * 0.0015, 0.12, 0.3)
			laserPart.Size  = Vector3.new(thick, thick, dist)
			laserPart.CFrame = CFrame.new((from + to) / 2, to)
			laserPart.Transparency = 0
		end

		local aimRay = RaycastParams.new()
		aimRay.FilterType = Enum.RaycastFilterType.Exclude
		aimRay.RespectCanCollide = true

		local function drawAimLaser(ch, from, dir)
			aimRay.FilterDescendantsInstances = { ch }
			local res = workspace:Raycast(from, dir * BULLET_LASER_MAX, aimRay)
			updateLaser(from, res and res.Position or (from + dir * BULLET_LASER_MAX))
		end

		local renderBindName = "KINON_TOFSilentLaser_" .. tostring(LP.UserId)
		pcall(function() RunService:UnbindFromRenderStep(renderBindName) end)
		RunService:BindToRenderStep(renderBindName, Enum.RenderPriority.Last.Value, function()
			local active = T.Enabled and not unloaded
			local cam = workspace.CurrentCamera
			if active and T.ShowCircle and cam and ensureCircle() then
				circleGui.Enabled = true
				local r = circleRadius(cam)
				circleFrame.Size = UDim2.fromOffset(r * 2, r * 2)
			elseif circleGui then
				circleGui.Enabled = false
			end

			if not active or not T.ShowLaser then return hideLaser() end
			local ch = LP.Character
			bindActiveTool(ch)
			if not hasTOF(ch) then State.AimHold.held = false; return hideLaser() end
			if State.AimHold.ok and not State.AimHold.held then return hideLaser() end
			local from = muzzle(ch)
			if not from then return hideLaser() end
			local good, dir = pcall(compute, ch, true)
			if not (good and typeof(dir) == "Vector3") then
				dir = nil
				if cam then
					aimRay.FilterDescendantsInstances = { ch }
					local hit = workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * BULLET_LASER_MAX, aimRay)
					local target = hit and hit.Position or (cam.CFrame.Position + cam.CFrame.LookVector * BULLET_LASER_MAX)
					local d = target - from
					dir = d.Magnitude > 0.5 and d.Unit or cam.CFrame.LookVector
				end
			end
			if not dir then return hideLaser() end
			pcall(drawAimLaser, ch, from, dir)
		end)

		local function restore()
			if effects and original then
				pcall(function() effects.aimDirection = original end)
			end
		end

		local function install()
			if original or installing then return end
			installing = true
			task.spawn(function()
				local ok = pcall(function()
					local rs = game:GetService("ReplicatedStorage")
					local m  = rs:WaitForChild("Modules", 10):WaitForChild("Items", 10):WaitForChild("TwistOfFate", 10):WaitForChild("TwistoffateEffects", 10)
					local e  = require(m)
					local orig = e.aimDirection
					if type(orig) ~= "function" then error("no aimDirection") end
					e.aimDirection = function(character, camCF)
						if unloaded or not T.Enabled then return orig(character, camCF) end
						if T.SmartPredict then State.SmartPredict.SetRawMode(true) end
						local good, dir = pcall(compute, character)
						if T.SmartPredict then State.SmartPredict.SetRawMode(false) end
						if good and dir then
							lastAimDir, lastAimAt = dir, tick()
							if T.SmartPredict then State.SmartPredict.RecordShot() end
							return dir
						end
						local res = orig(character, camCF)
						if typeof(res) == "Vector3" then lastAimDir, lastAimAt = res, tick() end
						return res
					end
					effects, original = e, orig
				end)
				installing = false
				if ok and unloaded then restore() end
			end)
		end

		function obj:Refresh()
			if T.Enabled then State.AimHold.Install(); install() end
		end

		function obj:Destroy()
			T.Enabled = false
			pcall(function() RunService:UnbindFromRenderStep(renderBindName) end)
			clearToolConnections()
			mouseHeld = false
			restore()
			if circleGui then pcall(function() circleGui:Destroy() end) end
			if laserPart then pcall(function() laserPart:Destroy() end) end
		end

		return obj
	end)()

	local function SetTOFSilent(enabled)
		State.TOFSilent.Enabled = enabled == true
		State.SilentObj:Refresh()
	end

	SetTOFSilent(false)

	getgenv().KinonTOFSilent = {
		State = State,
		Set   = SetTOFSilent,
	}

	TOF_Bridge.State = State
	TOF_Bridge.Set = SetTOFSilent
	TOF_Bridge.Cleanup = function()
		unloaded = true
		for _, c in ipairs(connections) do
			pcall(function() c:Disconnect() end)
		end
		table.clear(connections)
		pcall(function() State.SilentObj:Destroy() end)
	end
end

-- ============================================================
--  AUTO PARRY (HANXHUB V3 - FULL ANTI-JUKE + COMBO HITBOX + ANTI-MISS + ANTI-FAKE HIT + ANTI-BYPASS PING)
-- ============================================================
local ToggleRegistry = ToggleRegistry or {}
local TianHubState = getgenv().TianHubState or {}
getgenv().TianHubState = TianHubState
TianHubState.AutoParry = false

local AP
do
	local W = getgenv()
	local rawSpawn = task.spawn
	local Stats = game:GetService("Stats")

	AP = {
		Enabled = false,
		Range = 14,
		DelayMs = 0,
		FaceSensitivity = 10,
		AggressiveMode = false,
		CircleVisible = false,
		AntiFakeHit = false,
		AntiBypassPing = false,
		CurrentPingMs = 0,
		RangeColor = Color3.fromRGB(255, 255, 255),
		Distance = 15,
		FaceBias = 10,
	}
	W.TianHub_AutoParry = AP

	local AttackSkip = {
		["106871536134254"] = false,
		["117070354890871"] = false,
		["73681849513551"]  = false,
		["100014992013740"] = false,
	}
	AP.AttackSkip = AttackSkip

	-- Tambahkan ID animasi serangan baru di sini kapan saja:
	local CUSTOM_NEW_IDS = {
		-- ["123456789012345"] = true,
	}

	local LUNGE_IDS = {}
	for _, id in ipairs({
		"71008020992570","72742711718023","72908958549833","73923929500477","74968262036854",
		"75857500533792","76385865186777","76503974441748","77081789642514","78432063483146",
		"78935059863801","79935565590141","79965656177566","80411309607666","82666958311998",
		"83873880822918","84525330720658","85030641905220","89185525343404","92125118598365",
		"92362656727126","92554564590253","96839438835309","99472251587670","102055678391920",
		"104689417033027","105374834496520","109402730355822","111920872708571","112166042383605",
		"112633191985365","112840768179724","113255068724446","115244153053858","117042998468241",
		"117207742458428","118907603246885","119752564209631","121216847022485","121571390309073",
		"122812055447896","123047897844134","123812278891591","124706657239027","124735239320776",
		"125224839697689","126081405469607","126497551689502","126527634689050","126626340093785",
		"126751859125353","128241974219045","129784271201071","130012819736632","130585295123651",
		"130593238885843","132817836308238","133002120549396","133881825716964","133963973694098",
		"134838390519433","135002183282873","135403091566760","135727476735024","136365031119137",
		"137504605181913","137688077908355","137795837089724","137846825408335","138045669415653",
		"138720291317243","117187218825161","105221485497534","86868198964957","134758728973154",
		"132636403911470","125350153877085","2874840706","110850539331763","72042024",
		"139369275981139","113691709436161","129626174716003","75618342544502","93902163029544",
		"79310600168078","104540716539347","101636125032002","125430111937587","81963230963908",
		"84926129581106","83333467665074","127417297154354",
		-- Batch ID baru update terbaru
		"139845102938471","139912847561029","140028374651920","140192837465102","140384756192837",
		"140519283746512","140692837461523","140847561928340","141029384756192","141283746519284",
	}) do
		LUNGE_IDS[id] = true
	end

	for id, flag in pairs(CUSTOM_NEW_IDS) do
		if flag then
			LUNGE_IDS[tostring(id)] = true
		end
	end

	local SKIP_IDS = {}
	for _, id in ipairs({
		"86266790353635","84093948968516","102746205979822","99210996402874","121108316060822",
		"109928123357793","110466971021611","110355011987939","135181748009911","77210283630654",
		"108211560927158","104192089592095","109257644640676","98163597193511","111223305405046",
		"75258958842388","93136435416899","92098503722633","117886494230451",
	}) do
		SKIP_IDS[id] = true
	end

	local SPECIAL_NAMES = {
		["101443662521580"] = "Veil Spear Throw 1",
		["127622545856523"] = "Veil Spear Throw 2",
		["76744850905644"]  = "Myers Grab",
		["71001061734896"]  = "Take Out Spear",
		["129669521834246"] = "Put Away Spear",
	}
	local DEFAULT_ATTACKS = {
		["106871536134254"] = {Name = "Masked Alex Attack", Default = true},
		["117070354890871"] = {Name = "Masked Alex Lunge",  Default = true},
		["73681849513551"]  = {Name = "Hidden Dash",        Default = true},
		["100014992013740"] = {Name = "Abysswalker Slash",  Default = true},
	}

	local BODY_PART_NAMES = {
		"HumanoidRootPart", "UpperTorso", "Torso", "LowerTorso", "Head",
	}

	-- Hitbox badan diperbesar penuh untuk menangkap serangan menyamping, gocek & combo cepat
	local BODY_HITBOX_EXPAND = Vector3.new(2.6, 2.8, 2.6)
	local BASE_MAX_TIMEPOS = 0.52
	local BASE_MAX_DURATION = 0.58

	local state = {
		LastAttempt = 0,
		LastSuccess = 0,
		ParryBusyUntil = 0,
		AutoRotateLockedUntil = 0,
		SeenAnimators = setmetatable({}, {__mode = "k"}),
		SeenModels = setmetatable({}, {__mode = "k"}),
		ActiveClient = nil,
		ClientModule = nil,
		ClientHooked = false,
		LastGcScan = 0,
	}
	local Connections = {}
	local function addConn(c) table.insert(Connections, c); return c end

	-- ============================================================
	--  ANTI-BYPASS PING: BACA PING SERVER REAL-TIME (MS -> DETIK)
	-- ============================================================
	function AP.GetPingMs()
		local pingMs = 0
		pcall(function()
			local net = Stats:FindFirstChild("Network")
			local srv = net and net:FindFirstChild("ServerStatsItem")
			local dataPing = srv and srv:FindFirstChild("Data Ping")
			if dataPing then
				pingMs = tonumber(dataPing:GetValue()) or 0
			end
		end)
		if pingMs <= 0 then
			pcall(function()
				pingMs = (LocalPlayer:GetNetworkPing() or 0) * 1000
			end)
		end
		pingMs = math.clamp(math.floor(pingMs + 0.5), 0, 999)
		AP.CurrentPingMs = pingMs
		return pingMs
	end

	local function getNetworkPingSec()
		if AP.AntiBypassPing ~= true then
			return 0
		end
		return math.clamp(AP.GetPingMs(), 0, 500) / 1000
	end

	local prompt = { HoldingPrompt = false, HoldSince = 0, UntilTime = 0 }
	addConn(ProximityPromptService.PromptButtonHoldBegan:Connect(function(_, plr)
		if plr == LocalPlayer then prompt.HoldingPrompt = true; prompt.HoldSince = tick() end
	end))
	addConn(ProximityPromptService.PromptButtonHoldEnded:Connect(function(_, plr)
		if plr == LocalPlayer then
			prompt.HoldingPrompt = false
			prompt.UntilTime = math.max(prompt.UntilTime, tick() + 0.35)
		end
	end))
	addConn(ProximityPromptService.PromptTriggered:Connect(function(_, plr)
		if plr == LocalPlayer then
			prompt.HoldingPrompt = false
			prompt.UntilTime = tick() + 1.2
		end
	end))

	local function getBodyDist(myChar, targetPos)
		local minDist = math.huge
		for _, name in ipairs(BODY_PART_NAMES) do
			local bPart = myChar:FindFirstChild(name)
			if bPart and bPart:IsA("BasePart") then
				local half = (bPart.Size + BODY_HITBOX_EXPAND) * 0.5
				local lp = bPart.CFrame:PointToObjectSpace(targetPos)
				local clamped = Vector3.new(
					math.clamp(lp.X, -half.X, half.X),
					math.clamp(lp.Y, -half.Y, half.Y),
					math.clamp(lp.Z, -half.Z, half.Z)
				)
				local closestWorld = bPart.CFrame:PointToWorldSpace(clamped)
				local d = (targetPos - closestWorld).Magnitude
				if d < minDist then
					minDist = d
				end
			end
		end
		return minDist
	end

	local function segmentHitsRealBody(myChar, segStart, segEnd, radius)
		local steps = 14
		for i = 0, steps do
			local alpha = i / steps
			local samplePos = segStart:Lerp(segEnd, alpha)
			if getBodyDist(myChar, samplePos) <= radius then
				return true
			end
		end
		return false
	end

	local function checkFace(killerHRP, myHRP)
		if not killerHRP or not myHRP then return false end
		local toMe = myHRP.Position - killerHRP.Position
		local flatToMe = Vector3.new(toMe.X, 0, toMe.Z)
		local flatLook = Vector3.new(killerHRP.CFrame.LookVector.X, 0, killerHRP.CFrame.LookVector.Z)
		if flatToMe.Magnitude <= 0.05 or flatLook.Magnitude <= 0.01 then return true end

		local forwardDot = flatLook.Unit:Dot(flatToMe.Unit)
		local sens = math.clamp(tonumber(AP.FaceSensitivity) or 10, 0, 10)
		local minDot = AP.AggressiveMode and 0.22 or (0.55 - (sens / 10) * 0.35)
		return forwardDot >= minDot
	end

	-- ============================================================
	--  ANTI-FAKE HIT + ANTI-BYPASS PING + ANTI-MISS + ANTI-JUKE
	-- ============================================================
	local function checkRange(killerHRP, myHRP, tPos, vel, killerChar, track)
		if not killerHRP or not myHRP then return false end
		if not checkFace(killerHRP, myHRP) then
			return false
		end

		local pingSec = getNetworkPingSec()
		local kVel = vel or killerHRP.AssemblyLinearVelocity
		local myVel = myHRP.AssemblyLinearVelocity

		local predictedKillerPos = (tPos or killerHRP.Position) + (kVel * (pingSec * 0.75))
		local predictedMyPos = myHRP.Position + (myVel * (pingSec * 0.18))

		local myChar = LocalPlayer.Character
		local baseRange = math.clamp(tonumber(AP.Range) or 14, 5, 35)
		local pingBonusRange = math.clamp(pingSec * 16.0, 0, 5.0)
		local effectiveRange = baseRange + pingBonusRange

		local dist = (predictedKillerPos - predictedMyPos).Magnitude
		local rawDist = (killerHRP.Position - myHRP.Position).Magnitude
		if math.min(dist, rawDist) > effectiveRange + 5.0 then
			return false
		end

		if AP.AntiFakeHit and track then
			local tp, spd = 0, 1
			pcall(function()
				tp = track.TimePosition or 0
				spd = track.Speed or 1
			end)
			if spd <= 0.05 then
				return false
			end
			local relVelTowardMe = 0
			local dirToMe = (predictedMyPos - predictedKillerPos)
			if dirToMe.Magnitude > 0.05 then
				relVelTowardMe = kVel:Dot(dirToMe.Unit)
			end
			if math.min(dist, rawDist) > (baseRange * 0.82) and relVelTowardMe < 2.0 and tp < 0.04 then
				return false
			end
		end

		if not myChar then
			return math.min(dist, rawDist) <= effectiveRange
		end

		-- Anti-Miss Combo & Gocek: sapuan jangkauan lebih panjang + radius deteksi lebar
		local reach = math.clamp(effectiveRange * 1.18, 10.0, 28.0)
		if kVel.Magnitude > 1.5 then
			reach = reach + math.clamp(kVel.Magnitude * (0.18 + pingSec * 0.45), 0, 6.0)
		end

		local hitRadius = 3.45 + math.clamp(pingSec * 3.0, 0, 1.0)
		local origin = predictedKillerPos - killerHRP.CFrame.LookVector * 0.75
		local tip = predictedKillerPos + killerHRP.CFrame.LookVector * reach
		if segmentHitsRealBody(myChar, origin, tip, hitRadius) then
			return true
		end

		-- Cek tambahan jarak langsung (anti-miss untuk combo beruntun & gocek jarak rapat)
		if math.min(dist, rawDist) <= (effectiveRange * 0.90) then
			return true
		end

		if killerChar then
			for _, wName in ipairs({"RightHand", "Right Arm", "LeftHand", "Left Arm"}) do
				local wp = killerChar:FindFirstChild(wName)
				if wp and wp:IsA("BasePart") then
					local wpPred = wp.Position + (kVel * (pingSec * 0.75))
					local relZ = killerHRP.CFrame:PointToObjectSpace(wpPred).Z
					if relZ <= 0.65 and getBodyDist(myChar, wpPred) <= (3.75 + pingSec * 2.5) then
						return true
					end
				end
			end
		end

		return false
	end

	local function getParryTool()
		local char = LocalPlayer.Character
		local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
		if char then
			for _, child in ipairs(char:GetChildren()) do
				if child:IsA("Tool") then
					local n = child.Name:lower()
					if n:find("parry") or n:find("dagger") then return child end
				end
			end
		end
		if backpack then
			for _, child in ipairs(backpack:GetChildren()) do
				if child:IsA("Tool") then
					local n = child.Name:lower()
					if n:find("parry") or n:find("dagger") then return child end
				end
			end
		end
		local equipped = tostring(LocalPlayer:GetAttribute("EquippedItem") or ""):lower()
		if equipped:find("parry") or equipped:find("dagger") then
			return true
		end
		return nil
	end

	local function isToolOwnedByMe(tool)
		if typeof(tool) ~= "Instance" then return false end
		local char = LocalPlayer.Character
		local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
		return (char and tool:IsDescendantOf(char)) or (backpack and tool:IsDescendantOf(backpack))
	end

	local function getClient(forceRescan)
		local char = LocalPlayer.Character
		local function isValid(c)
			if type(c) ~= "table" or type(c.Parry) ~= "function" then return false end
			if not c.tool or not isToolOwnedByMe(c.tool) then return false end
			return true
		end

		if not forceRescan then
			if isValid(state.ActiveClient) then
				return state.ActiveClient
			end
			if isValid(_G.TianHub_ActiveParryClient) then
				state.ActiveClient = _G.TianHub_ActiveParryClient
				return state.ActiveClient
			end
		end

		if not state.ClientModule then
			pcall(function()
				local M = ReplicatedStorage:FindFirstChild("Modules")
				local I = M and M:FindFirstChild("Items")
				local P = I and I:FindFirstChild("ParryingDagger")
				local PC = P and P:FindFirstChild("ParryClient")
				if PC then state.ClientModule = require(PC) end
			end)
		end

		if type(state.ClientModule) == "table" and not state.ClientHooked then
			state.ClientHooked = true
			pcall(function()
				local origNew = state.ClientModule.new
				if type(origNew) == "function" then
					state.ClientModule.new = function(...)
						local c = origNew(...)
						state.ActiveClient = c
						_G.TianHub_ActiveParryClient = c
						return c
					end
				end
			end)
		end

		if typeof(getgc) == "function" and (forceRescan or tick() - state.LastGcScan > 0.6) then
			state.LastGcScan = tick()
			local ok, gc = pcall(getgc, true)
			if ok and type(gc) == "table" then
				local matched = nil
				for _, c in ipairs(gc) do
					if isValid(c) and (getmetatable(c) == state.ClientModule or rawget(c, "parryEvent") or rawget(c, "daggerFolder") or rawget(c, "tool")) then
						matched = c
						if char and c.character == char then
							state.ActiveClient = c
							_G.TianHub_ActiveParryClient = c
							return c
						end
					end
				end
				if matched then
					state.ActiveClient = matched
					_G.TianHub_ActiveParryClient = matched
					return matched
				end
			end
		end

		if isValid(state.ActiveClient) then return state.ActiveClient end
		return nil
	end

	local function doFallback()
		local fired = false
		pcall(function()
			local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
			local mob = pg and (pg:FindFirstChild("Survivor-mob") or pg:FindFirstChild("Survivor"))
			local ctrl = mob and mob:FindFirstChild("Controls")
			local btn = ctrl and (ctrl:FindFirstChild("Gui-mob") or ctrl:FindFirstChild("action"))
			if btn then
				if typeof(firesignal) == "function" then
					pcall(function() firesignal(btn.MouseButton1Down) end)
					task.defer(function() pcall(function() firesignal(btn.MouseButton1Up) end) end)
					fired = true
				end
				if typeof(getconnections) == "function" then
					local ok, conns = pcall(function() return getconnections(btn.MouseButton1Down) end)
					if ok and type(conns) == "table" then
						for _, c in ipairs(conns) do pcall(function() c:Fire(); fired = true end) end
					end
					local ok1, conns1 = pcall(function() return getconnections(btn.MouseButton1Up) end)
					if ok1 and type(conns1) == "table" then
						task.defer(function() for _, c in ipairs(conns1) do pcall(function() c:Fire() end) end end)
					end
				end
			end
		end)
		local tool = getParryTool()
		if typeof(tool) == "Instance" and tool:IsA("Tool") then
			pcall(function() tool:Activate(); fired = true end)
		end
		return fired
	end
	AP.DoFallback = doFallback

	local function lockFaceToKillerBriefly(killerChar)
		local char = LocalPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local myHRP = char and char:FindFirstChild("HumanoidRootPart")
		if not hum or not myHRP then return end

		state.AutoRotateLockedUntil = tick() + 0.08
		pcall(function() hum.AutoRotate = false end)

		if killerChar and killerChar.Parent then
			local kHRP = killerChar:FindFirstChild("HumanoidRootPart")
			if kHRP then
				local lookPos = Vector3.new(kHRP.Position.X, myHRP.Position.Y, kHRP.Position.Z)
				if (lookPos - myHRP.Position).Magnitude > 0.2 then
					pcall(function()
						myHRP.CFrame = CFrame.lookAt(myHRP.Position, lookPos)
					end)
				end
			end
		end

		task.delay(0.085, function()
			if tick() >= state.AutoRotateLockedUntil and hum and hum.Parent then
				pcall(function() hum.AutoRotate = true end)
			end
		end)
	end

	local ACTION_KEYWORDS = {"repair","generator","unhook","hooking","rescu","gate","vault","pallet","dropping","interact","opening"}
	local ANIM_KEYWORDS   = {"repair","generator","unhook","rescue","hook","gate","exit","vault","window","pallet","drop"}

	local function hasBlockingAttr(inst)
		local ok, attrs = pcall(function() return inst:GetAttributes() end)
		if not ok or type(attrs) ~= "table" then return false end
		for k, v in pairs(attrs) do
			if v == true then
				local n = string.lower(tostring(k))
				if not (n:find("^can") or n:find("^has") or n:find("^allow")) then
					for _, kw in ipairs(ACTION_KEYWORDS) do
						if n:find(kw, 1, true) then return true end
					end
				end
			end
		end
		return false
	end

	local function isDoingAction()
		local t = tick()
		if t < prompt.UntilTime then return true end
		if prompt.HoldingPrompt and t - prompt.HoldSince < 15 then return true end
		local char = LocalPlayer.Character
		if not char then return false end
		if hasBlockingAttr(char) or hasBlockingAttr(LocalPlayer) then return true end
		local hum = char:FindFirstChildOfClass("Humanoid")
		local animator = hum and hum:FindFirstChildOfClass("Animator")
		if animator then
			local ok, tracks = pcall(function() return animator:GetPlayingAnimationTracks() end)
			if ok and tracks then
				for _, track in ipairs(tracks) do
					local s = ""
					pcall(function()
						local p = track.Priority
						if p == Enum.AnimationPriority.Action or p == Enum.AnimationPriority.Action2
							or p == Enum.AnimationPriority.Action3 or p == Enum.AnimationPriority.Action4 then
							s = string.lower(tostring(track.Name) .. " " .. tostring(track.Animation and track.Animation.Name or ""))
						end
					end)
					if s ~= "" and not s:find("parry", 1, true) and not s:find("dagger", 1, true) then
						for _, kw in ipairs(ANIM_KEYWORDS) do
							if s:find(kw, 1, true) then return true end
						end
					end
				end
			end
		end
		return false
	end

	local function executeParryNow(reason, killerChar)
		if AP.Enabled ~= true then return false end
		local now = tick()
		if now < state.ParryBusyUntil then return false end
		if now - state.LastAttempt < 0.005 then return false end
		if now - state.LastSuccess < 0.065 then return false end

		local tool = getParryTool()
		if not tool then return false end
		if isDoingAction() then return false end

		local char = LocalPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not char or not hum or hum.Health <= 0 then return false end
		if char:GetAttribute("Knocked") or LocalPlayer:GetAttribute("Knocked")
			or char:GetAttribute("IsHooked") or LocalPlayer:GetAttribute("IsHooked")
			or char:GetAttribute("IsCarried") or LocalPlayer:GetAttribute("IsCarried")
			or char:GetAttribute("IsDead") or LocalPlayer:GetAttribute("IsDead") then return false end

		state.LastAttempt = now
		state.ParryBusyUntil = now + 0.085
		lockFaceToKillerBriefly(killerChar)

		local client = getClient(false)
		if client then
			local ok, result = pcall(function()
				if client.character ~= char and type(client._bindCharacter) == "function" then
					pcall(function() client:_bindCharacter(char) end)
				end
				return client:Parry()
			end)
			if ok and result ~= false then
				state.LastSuccess = tick()
				return true
			end

			local freshClient = getClient(true)
			if freshClient and freshClient ~= client then
				local ok2, res2 = pcall(function()
					if freshClient.character ~= char and type(freshClient._bindCharacter) == "function" then
						pcall(function() freshClient:_bindCharacter(char) end)
					end
					return freshClient:Parry()
				end)
				if ok2 and res2 ~= false then
					state.LastSuccess = tick()
					return true
				end
			end
		end

		local okFb, resFb = pcall(doFallback)
		if okFb and resFb then
			state.LastSuccess = tick()
			return true
		end

		return false
	end

	local function triggerParryWithDelay(reason, killerChar, track)
		if AP.Enabled ~= true then return false end
		local rawDelaySec = math.clamp(tonumber(AP.DelayMs) or 0, 0, 350) / 1000
		local pingCompSec = (AP.AntiBypassPing == true) and (getNetworkPingSec() * 0.55) or 0
		local effectiveDelay = math.max(0, rawDelaySec - pingCompSec)

		if effectiveDelay <= 0.002 then
			return executeParryNow(reason, killerChar)
		end

		task.delay(effectiveDelay, function()
			if AP.Enabled ~= true then return end
			if track and not track.IsPlaying then
				return
			end
			if killerChar and killerChar.Parent then
				local myChar = LocalPlayer.Character
				local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
				local kHRP = killerChar:FindFirstChild("HumanoidRootPart")
				if not myHRP or not kHRP then return end
				if not checkRange(kHRP, myHRP, nil, kHRP.AssemblyLinearVelocity, killerChar, track) then
					return
				end
			end
			executeParryNow(reason .. ":delayed", killerChar)
		end)
		return true
	end

	local function isKnownAttackId(id)
		if SKIP_IDS[id] or SPECIAL_NAMES[id] then return false end
		local def = DEFAULT_ATTACKS[id]
		if def and AttackSkip[id] == true then return false end
		if LUNGE_IDS[id] == true or CUSTOM_NEW_IDS[id] == true then
			return true
		end
		if def and def.Default == true then
			return true
		end
		return false
	end

	local function handleAnim(track, char)
		if not AP.Enabled or not track or not char or not char.Parent then return end
		local id = ""
		pcall(function() id = tostring(track.Animation.AnimationId):match("%d+") or "" end)
		if id == "" then return end
		if SKIP_IDS[id] or SPECIAL_NAMES[id] then return end

		if string.lower(tostring(char.Name or "")):find("veil", 1, true) then
			local n1, n2 = "", ""
			pcall(function() n1 = string.lower(tostring(track.Name or "")) end)
			pcall(function() n2 = string.lower(tostring(track.Animation and track.Animation.Name or "")) end)
			local s = n1 .. " " .. n2
			if s:find("spear", 1, true) or s:find("throw", 1, true) or s:find("charge", 1, true) then return end
		end

		if not isKnownAttackId(id) then
			return
		end

		local pingSec = getNetworkPingSec()
		local maxTimePos = BASE_MAX_TIMEPOS + (pingSec * 0.35)
		local maxDur = BASE_MAX_DURATION + (pingSec * 0.35)

		local ok, timePos = pcall(function() return track.TimePosition or 0 end)
		if ok and timePos > maxTimePos then return end

		local confirmFrames = 0
		local myChar0 = LocalPlayer.Character
		local myHRP0 = myChar0 and myChar0:FindFirstChild("HumanoidRootPart")
		local kHRP0 = char:FindFirstChild("HumanoidRootPart")
		if myHRP0 and kHRP0 and checkRange(kHRP0, myHRP0, nil, kHRP0.AssemblyLinearVelocity, char, track) then
			local closeDist = (kHRP0.Position - myHRP0.Position).Magnitude
			if not AP.AntiFakeHit or closeDist <= 10.5 then
				if triggerParryWithDelay("instant:" .. id, char, track) then return end
			else
				confirmFrames = 1
			end
		end

		rawSpawn(function()
			local startT = tick()
			local lastPos, lastT, velEst
			while AP.Enabled and track.IsPlaying do
				local tp = 0
				pcall(function() tp = track.TimePosition or 0 end)
				if tp > maxTimePos then break end
				if tick() - startT >= maxDur then break end

				local myChar = LocalPlayer.Character
				local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
				local kHRP = char:FindFirstChild("HumanoidRootPart")
				if kHRP then
					local now = tick()
					local pos = kHRP.Position
					if lastPos and now > lastT then
						local v = (pos - lastPos) / (now - lastT)
						velEst = velEst and velEst * 0.5 + v * 0.5 or v
					else
						velEst = kHRP.AssemblyLinearVelocity
					end
					lastPos, lastT = pos, now
				end

				if myHRP and kHRP and checkRange(kHRP, myHRP, nil, velEst, char, track) then
					confirmFrames += 1
					local reqFrames = (AP.AntiFakeHit and ((kHRP.Position - myHRP.Position).Magnitude > 11.0)) and 2 or 1
					if confirmFrames >= reqFrames then
						if triggerParryWithDelay("anim:" .. id, char, track) then return end
					end
				else
					confirmFrames = 0
				end
				RunService.Heartbeat:Wait()
			end
		end)
	end

	local function hookAnimator(animator, char)
		if not animator or state.SeenAnimators[animator] then return end
		state.SeenAnimators[animator] = true
		local ok, conn = pcall(function()
			return animator.AnimationPlayed:Connect(function(track)
				pcall(handleAnim, track, char)
			end)
		end)
		if ok and conn then addConn(conn) end
		pcall(function()
			for _, t in ipairs(animator:GetPlayingAnimationTracks()) do
				handleAnim(t, char)
			end
		end)
	end

	local function hookCharacter(char)
		if not char or state.SeenModels[char] then return end
		state.SeenModels[char] = true
		local function bind(inst)
			if inst:IsA("Humanoid") then
				local animator = inst:FindFirstChildOfClass("Animator")
				if animator then hookAnimator(animator, char) end
				addConn(inst.ChildAdded:Connect(function(c)
					if c:IsA("Animator") then hookAnimator(c, char) end
				end))
			end
		end
		for _, c in ipairs(char:GetChildren()) do pcall(bind, c) end
		addConn(char.ChildAdded:Connect(function(c) pcall(bind, c) end))
	end

	local function isLobbyOrSurvivor(plr, char)
		if plr and plr.Team then
			local t = plr.Team.Name:lower()
			if t:find("survivor", 1, true) or t:find("lobby", 1, true) or t:find("spectat", 1, true) or t:find("none", 1, true) then
				return true
			end
		end
		local function chkNonKiller(inst)
			if not inst then return false end
			local role = tostring(inst:GetAttribute("Role") or ""):lower()
			if role == "survivor" or role == "lobby" or role == "spectator" then
				return true
			end
			if inst:GetAttribute("InLobby") == true or inst:GetAttribute("IsSurvivor") == true then
				return true
			end
			return false
		end
		return chkNonKiller(plr) or chkNonKiller(char)
	end

	local function isKillerChar(char)
		if not char or not char:IsA("Model") or char == LocalPlayer.Character then return false end
		if not char:FindFirstChildOfClass("Humanoid") or not char:FindFirstChild("HumanoidRootPart") then return false end

		if isLobbyOrSurvivor(LocalPlayer, LocalPlayer.Character) then
			local myTeam = LocalPlayer.Team and LocalPlayer.Team.Name:lower() or ""
			if not myTeam:find("survivor", 1, true) then
				return false
			end
		end

		local plr = Players:GetPlayerFromCharacter(char)
		if plr == LocalPlayer then return false end

		if isLobbyOrSurvivor(plr, char) then
			return false
		end

		local function chkKillerAttr(inst)
			if not inst then return false end
			local role = tostring(inst:GetAttribute("Role") or ""):lower()
			return role == "killer" or inst:GetAttribute("IsKiller") == true
		end
		if chkKillerAttr(char) or chkKillerAttr(plr) then
			return true
		end

		if plr and plr.Team then
			local t = plr.Team.Name:lower()
			if t:find("killer", 1, true) or t:find("slasher", 1, true) or t:find("hunter", 1, true) or t:find("monster", 1, true) then
				return true
			end
		end

		local K = workspace:FindFirstChild("Killers")
		if K and char:IsDescendantOf(K) then
			return true
		end

		if not plr then
			local n = char.Name:lower()
			for _, kw in ipairs({"zombie","slasher","monster","killer","veil","stalker","masked","abysswalker","hunter"}) do
				if n:find(kw, 1, true) then
					return true
				end
			end
		end

		return false
	end

	local function getAllKillers()
		local list, seen = {}, {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer then
				local c = p.Character
				if c and not seen[c] and isKillerChar(c) then
					seen[c] = true
					table.insert(list, c)
				end
			end
		end
		local K = workspace:FindFirstChild("Killers")
		if K then
			for _, d in ipairs(K:GetDescendants()) do
				if d:IsA("Model") and not seen[d] and isKillerChar(d) then
					seen[d] = true
					table.insert(list, d)
				end
			end
		end
		for _, c in ipairs(workspace:GetChildren()) do
			if c:IsA("Model") and not seen[c] and isKillerChar(c) then
				seen[c] = true
				table.insert(list, c)
			end
		end
		return list
	end

	addConn(task.spawn(function()
		while true do
			if AP.Enabled then
				for _, k in ipairs(getAllKillers()) do pcall(hookCharacter, k) end
				if getParryTool() then
					pcall(getClient, false)
				end
				task.wait(0.08)
			else
				task.wait(0.35)
			end
		end
	end))

	addConn(Players.PlayerAdded:Connect(function(player)
		if player == LocalPlayer then return end
		addConn(player.CharacterAdded:Connect(function(char)
			task.defer(function()
				if char and isKillerChar(char) then hookCharacter(char) end
			end)
		end))
	end))

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			addConn(p.CharacterAdded:Connect(function(char)
				task.defer(function()
					if char and isKillerChar(char) then hookCharacter(char) end
				end)
			end))
		end
	end

	local ringFolder
	local ringSegments = {}
	local RING_SEGMENTS = 96
	local RING_ALPHA = 0.2
	local RING_THICK = 0.3
	local RING_HEIGHT = 0.1

	local function cleanupRing()
		for _, segment in ipairs(ringSegments) do
			pcall(function() segment:Destroy() end)
		end
		ringSegments = {}
		if ringFolder then
			pcall(function() ringFolder:Destroy() end)
			ringFolder = nil
		end
	end

	local function ensureRing()
		if #ringSegments == RING_SEGMENTS and ringFolder and ringFolder.Parent then return end
		cleanupRing()
		ringFolder = Instance.new("Folder")
		ringFolder.Name = "TIANHUB_ParryCircleVisual"
		ringFolder.Parent = workspace

		for i = 1, RING_SEGMENTS do
			local segment = Instance.new("Part")
			segment.Name = "ParryRingSegment" .. i
			segment.Anchored = true
			segment.CanCollide = false
			segment.CanTouch = false
			segment.CanQuery = false
			segment.CastShadow = false
			segment.Material = Enum.Material.Neon
			segment.Color = Color3.fromRGB(168, 85, 247)
			segment.Transparency = RING_ALPHA
			segment.Size = Vector3.new(RING_THICK, RING_HEIGHT, 1)
			segment.Parent = ringFolder
			ringSegments[i] = segment
		end
	end

	local function updateRing(center, range)
		local segmentLength = (2 * math.pi * range / RING_SEGMENTS) * 1.05
		for i, segment in ipairs(ringSegments) do
			local theta = (i - 1) / RING_SEGMENTS * math.pi * 2
			segment.Size = Vector3.new(RING_THICK, RING_HEIGHT, segmentLength)
			segment.CFrame = CFrame.new(center) * CFrame.Angles(0, theta, 0) * CFrame.new(range, 0, 0)
		end
	end

	addConn(RunService.Heartbeat:Connect(function()
		local myChar = LocalPlayer.Character
		local hum = myChar and myChar:FindFirstChildOfClass("Humanoid")
		if hum and hum.AutoRotate == false and tick() > state.AutoRotateLockedUntil then
			pcall(function() hum.AutoRotate = true end)
		end

		local hrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
		if not AP.Enabled or not AP.CircleVisible or not hrp then
			cleanupRing()
			return
		end

		ensureRing()
		local range = math.clamp(tonumber(AP.Range) or 14, 5, 35)
		local center = hrp.Position + Vector3.new(0, -2.8, 0)
		updateRing(center, range)
	end))

	function AP.AddAttackId(id)
		local clean = tostring(id):match("%d+")
		if clean then
			CUSTOM_NEW_IDS[clean] = true
			LUNGE_IDS[clean] = true
		end
	end

	function AP.SetEnabled(value)
		AP.Enabled = value == true
		TianHubState.AutoParry = AP.Enabled
		state.ParryBusyUntil = 0
		if AP.Enabled then
			pcall(getClient, true)
		else
			local char = LocalPlayer.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum then pcall(function() hum.AutoRotate = true end) end
		end
	end
	function AP.SetRange(value)
		AP.Range = math.clamp(tonumber(value) or 14, 5, 35)
	end
	function AP.SetDelay(value)
		AP.DelayMs = math.clamp(tonumber(value) or 0, 0, 350)
	end
	function AP.SetRangeESP(value)
		AP.CircleVisible = value == true
	end
	function AP.SetFaceSensitivity(value)
		AP.FaceSensitivity = math.clamp(tonumber(value) or 10, 0, 10)
	end
	function AP.SetAggressiveMode(value)
		AP.AggressiveMode = value == true
	end
	function AP.SetAntiFakeHit(value)
		AP.AntiFakeHit = value == true
	end
	function AP.SetAntiBypassPing(value)
		AP.AntiBypassPing = value == true
	end

	function AP.ResetClientCache()
		state.ActiveClient = nil
		_G.TianHub_ActiveParryClient = nil
		state.LastGcScan = 0
		state.ParryBusyUntil = 0
		state.LastAttempt = 0
		state.LastSuccess = 0
		local char = LocalPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then pcall(function() hum.AutoRotate = true end) end
	end
end

do
	local function isParryRelatedTool(inst)
		if not inst or not inst:IsA("Tool") then return false end
		local n = string.lower(inst.Name or "")
		return n:find("parry", 1, true) ~= nil or n:find("dagger", 1, true) ~= nil
	end

	local function watchCharacter(character)
		if not character then return end
		AP.ResetClientCache()
		character.ChildAdded:Connect(function(child)
			if isParryRelatedTool(child) then AP.ResetClientCache() end
		end)
		character.ChildRemoved:Connect(function(child)
			if isParryRelatedTool(child) then AP.ResetClientCache() end
		end)
	end

	if LocalPlayer.Character then
		watchCharacter(LocalPlayer.Character)
	end
	LocalPlayer.CharacterAdded:Connect(function(character)
		watchCharacter(character)
	end)
	LocalPlayer.CharacterRemoving:Connect(function()
		AP.ResetClientCache()
	end)

	local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
	if backpack then
		backpack.ChildAdded:Connect(function(child)
			if isParryRelatedTool(child) then AP.ResetClientCache() end
		end)
		backpack.ChildRemoved:Connect(function(child)
			if isParryRelatedTool(child) then AP.ResetClientCache() end
		end)
	end
	LocalPlayer.ChildAdded:Connect(function(child)
		if child:IsA("Backpack") then
			child.ChildAdded:Connect(function(tool)
				if isParryRelatedTool(tool) then AP.ResetClientCache() end
			end)
			child.ChildRemoved:Connect(function(tool)
				if isParryRelatedTool(tool) then AP.ResetClientCache() end
			end)
		end
	end)
end

-- ============================================================
--  TIAN HUB FULL SKILLCHECK GENERATOR & TRAPS ENGINE
-- ============================================================
local AS_ApplySpeed, AS_Reset, AutoSkill, TH_ClearHighlightMap, TH_SyncGenESP, TrapEngine
do
local PGui2 = lp:WaitForChild("PlayerGui")
local isMob2 = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local genCache = { t = 0, list = {} }
TianHubState.NearestGenProgress = function()
	local ch = LocalPlayer.Character
	local root = ch and ch:FindFirstChild("HumanoidRootPart")
	if not root then return 0 end
	local now = os.clock()
	if now - genCache.t > 3 then
		genCache.t = now
		genCache.list = {}
		local map = workspace:FindFirstChild("Map")
		if map then
			for _, o in ipairs(map:GetDescendants()) do
				if o:IsA("Model") and (o:GetAttribute("RepairProgress") ~= nil or o:GetAttribute("ProgressRepair") ~= nil) then
					genCache.list[#genCache.list + 1] = o
				end
			end
		end
	end
	local best, bd = 0, 15
	for _, g in ipairs(genCache.list) do
		if g.Parent then
			local part = g.PrimaryPart or g:FindFirstChildWhichIsA("BasePart", true)
			if part then
				local d = (part.Position - root.Position).Magnitude
				if d < bd then
					bd = d
					best = g:GetAttribute("RepairProgress") or g:GetAttribute("ProgressRepair") or 0
				end
			end
		end
	end
	return best
end

AutoSkill = {
	Mode = "Normal",
	Active = false,
	Speed = 1,
	SpeedCharacter = nil,
	SpeedOriginal = nil,
	LastGR = nil,
	HasClicked = false,
	LastLR = nil,
	LastTick = nil,
	WasActive = false,
	PerfLastGR = nil,
	PerfHasClicked = false,
	PerfLastLR = nil,
	PerfLastTick = nil,
	PerfWasActive = false,
}

local function AS_PressSkill()
	if isMob2 then
		local btn = PGui2:FindFirstChild("check", true)
		if btn and btn:IsA("GuiObject") and btn.Visible then
			local pos, size = btn.AbsolutePosition, btn.AbsoluteSize
			local ins = GuiService:GetGuiInset()
			local x = pos.X + size.X / 2 + ins.X
			local y = pos.Y + size.Y / 2 + ins.Y
			pcall(function()
				VirtualInputManager:SendTouchEvent(8822, Enum.UserInputState.Begin.Value, x, y)
				task.wait(0.01)
				VirtualInputManager:SendTouchEvent(8822, Enum.UserInputState.End.Value, x, y)
			end)
			if firesignal and btn:IsA("GuiButton") then
				pcall(function() firesignal(btn.MouseButton1Click) end)
			end
			return true
		end
	end
	return pcall(function()
		VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
		task.wait(0.01)
		VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
	end)
end

local function AS_GetActiveCheck()
	for _, gn in ipairs({ "SkillCheckPromptGui", "SkillCheckPromptGui-con" }) do
		local root = PGui2:FindFirstChild(gn, true)
		if root then
			for _, obj in ipairs(root:GetDescendants()) do
				if obj.Name == "Check" and obj:IsA("GuiObject") and obj.Visible then
					local tp = obj:FindFirstChild("TrapPerfect", true)
					local tg = obj:FindFirstChild("TrapGoal", true)
					if (tp and tp:IsA("GuiObject") and tp.Visible) or (tg and tg:IsA("GuiObject") and tg.Visible) then
						return nil
					end
					local l = obj:FindFirstChild("Line", true)
					local g = obj:FindFirstChild("Goal", true)
					if l and g and l:IsA("GuiObject") and g:IsA("GuiObject") then
						return obj, l, g
					end
				end
			end
		end
	end
	return nil
end

local function AS_GetSC()
	local _, l, g = AS_GetActiveCheck()
	if l and g then
		return l, g
	end
end

local function AS_Delta(a, b)
	local d = b - a
	if d > 180 then d = d - 360 end
	if d < -180 then d = d + 360 end
	return d
end

local function AS_Crossed(prev, now, sp, ep)
	local function inside(r)
		if sp > ep then return r >= sp or r <= ep end
		return r >= sp and r <= ep
	end
	if inside(now) then return true end
	if prev == nil then return false end
	local d = AS_Delta(prev, now)
	local steps = math.abs(math.floor(d))
	if steps < 2 then return false end
	local step = d / steps
	for i = 1, steps do
		if inside((prev + step * i) % 360) then return true end
	end
	return false
end

function AS_Reset()
	AutoSkill.LastGR, AutoSkill.LastLR, AutoSkill.LastTick = nil, nil, nil
	AutoSkill.HasClicked, AutoSkill.WasActive = false, false
	AutoSkill.PerfLastGR, AutoSkill.PerfLastLR, AutoSkill.PerfLastTick = nil, nil, nil
	AutoSkill.PerfHasClicked, AutoSkill.PerfWasActive = false, false
end

local function AS_SelectMode(modeName: string)
	if modeName == "Normal" or modeName == "Perfect" then
		AutoSkill.Mode = modeName
		AS_Reset()
	end
end

local function AS_Normal()
	local l, g = AS_GetSC()
	if not (l and g) then AutoSkill.WasActive = false return end
	local lr, gr, nw = l.Rotation % 360, g.Rotation % 360, os.clock()
	if not AutoSkill.WasActive then
		AutoSkill.WasActive = true; AutoSkill.HasClicked = false
		AutoSkill.LastGR = gr; AutoSkill.LastLR = lr; AutoSkill.LastTick = nw
		return
	end
	if AutoSkill.LastGR and math.abs(AS_Delta(AutoSkill.LastGR, gr)) > 5 then
		AutoSkill.HasClicked = false; AutoSkill.LastLR = nil; AutoSkill.LastTick = nil
	end
	AutoSkill.LastGR = gr
	if AutoSkill.HasClicked then AutoSkill.LastLR = lr; AutoSkill.LastTick = nw; return end
	if AutoSkill.LastLR and AutoSkill.LastTick then
		local dt = nw - AutoSkill.LastTick
		if dt > 0 then
			local ls = AS_Delta(AutoSkill.LastLR, lr) / dt
			local pr = (lr + ls * dt * 0) % 360
			if AS_Crossed(AutoSkill.LastLR, pr, (gr + 104) % 360, (gr + 109) % 360) then
				AutoSkill.HasClicked = true
				task.spawn(function() task.wait(0.03); AS_PressSkill() end)
			end
		end
	end
	AutoSkill.LastLR, AutoSkill.LastTick = lr, nw
end

local function AS_Perfect()
	local l, g = AS_GetSC()
	if not (l and g) then AutoSkill.PerfWasActive = false return end
	local lr, gr, nw = l.Rotation % 360, g.Rotation % 360, os.clock()
	if not AutoSkill.PerfWasActive then
		AutoSkill.PerfWasActive = true; AutoSkill.PerfHasClicked = false
		AutoSkill.PerfLastGR = gr; AutoSkill.PerfLastLR = lr; AutoSkill.PerfLastTick = nw
		return
	end
	if AutoSkill.PerfLastGR and math.abs(AS_Delta(AutoSkill.PerfLastGR, gr)) > 5 then
		AutoSkill.PerfHasClicked = false; AutoSkill.PerfLastLR = nil; AutoSkill.PerfLastTick = nil
	end
	AutoSkill.PerfLastGR = gr
	if AutoSkill.PerfHasClicked then AutoSkill.PerfLastLR = lr; AutoSkill.PerfLastTick = nw; return end
	if AutoSkill.PerfLastLR and AutoSkill.PerfLastTick then
		local dt = nw - AutoSkill.PerfLastTick
		if dt > 0 then
			local ls = AS_Delta(AutoSkill.PerfLastLR, lr) / dt
			local pr = (lr + ls * dt * 0) % 360
			if AS_Crossed(AutoSkill.PerfLastLR, pr, (gr + 104) % 360, (gr + 108) % 360) then
				AutoSkill.PerfHasClicked = true
				AS_PressSkill()
			end
		end
	end
	AutoSkill.PerfLastLR, AutoSkill.PerfLastTick = lr, nw
end

function AS_ApplySpeed(enabled)
	local char = LocalPlayer.Character
	if enabled and char then
		if AutoSkill.SpeedCharacter ~= char then
			if AutoSkill.SpeedCharacter and AutoSkill.SpeedOriginal then
				pcall(function()
					AutoSkill.SpeedCharacter:SetAttribute("skillcheckspeed", AutoSkill.SpeedOriginal.lower)
					AutoSkill.SpeedCharacter:SetAttribute("SkillCheckSpeed", AutoSkill.SpeedOriginal.upper)
				end)
			end
			AutoSkill.SpeedCharacter = char
			AutoSkill.SpeedOriginal = {
				lower = char:GetAttribute("skillcheckspeed"),
				upper = char:GetAttribute("SkillCheckSpeed"),
			}
		end
		local speed = math.clamp(tonumber(AutoSkill.Speed) or 1, 0.1, 3)
		if char:GetAttribute("skillcheckspeed") ~= speed then
			pcall(function() char:SetAttribute("skillcheckspeed", speed) end)
		end
		if char:GetAttribute("SkillCheckSpeed") ~= speed then
			pcall(function() char:SetAttribute("SkillCheckSpeed", speed) end)
		end
	elseif AutoSkill.SpeedCharacter then
		local oldChar, oldValues = AutoSkill.SpeedCharacter, AutoSkill.SpeedOriginal
		pcall(function()
			oldChar:SetAttribute("skillcheckspeed", oldValues and oldValues.lower)
			oldChar:SetAttribute("SkillCheckSpeed", oldValues and oldValues.upper)
		end)
		AutoSkill.SpeedCharacter, AutoSkill.SpeedOriginal = nil, nil
	end
end

RunService.RenderStepped:Connect(function()
	AS_ApplySpeed(AutoSkill.Active)
	if AutoSkill.Active then
		if AutoSkill.Mode == "Perfect" then
			AS_Perfect()
		else
			AS_Normal()
		end
	else
		AS_Reset()
	end
end)

getgenv().TianHub_AutoSkillAPI = {
	State = AutoSkill,
	SetActive = function(v: boolean)
		AutoSkill.Active = v == true
		if not AutoSkill.Active then
			AS_Reset()
			AS_ApplySpeed(false)
		end
	end,
	SelectMode = AS_SelectMode,
	SetMode = AS_SelectMode,
	SetSpeed = function(spd: number)
		AutoSkill.Speed = math.clamp(tonumber(spd) or 1, 0.1, 3)
		if AutoSkill.Active then
			AS_ApplySpeed(true)
		end
	end,
	PressSkill = AS_PressSkill,
	Reset = AS_Reset,
}
end

-- ============================================================
--  TIAN HUB TRAP AUTO-SKILLCHECK + TRAP ESP + ESP HIGHLIGHTS
-- ============================================================
TrapEngine = {
	AutoTrapSC = false,
	TrapESP = false,
	GenESP = false,
	SurvivorESP = false,
	TrapMode = "Legit",
	TrapBusy = false,
	TrapLastLine = nil,
	TrapLastPress = 0,
	TrapHighlights = {},
	GenHighlights = {},
	SurvivorHighlights = {},
}

-- Cached trap skillcheck references: avoid recursive GUI scans every frame.
local TrapGuiCache = {
	Check = nil,
	Line = nil,
	Target = nil,
	NextScan = 0,
}

local function TH_FindTrapSkillCheck()
	local now = os.clock()
	local check = TrapGuiCache.Check
	local line = TrapGuiCache.Line
	local target = TrapGuiCache.Target

	-- Reuse cached instances while they are still valid.
	if check and line and target
		and check.Parent and line.Parent and target.Parent
		and check.Visible and target.Visible then
		return check, line, target
	end

	-- Recursive discovery is throttled; never performed every Heartbeat.
	if now < TrapGuiCache.NextScan then
		return nil, nil, nil
	end
	TrapGuiCache.NextScan = now + 0.20

	TrapGuiCache.Check = nil
	TrapGuiCache.Line = nil
	TrapGuiCache.Target = nil

	local root = PGui2:FindFirstChild("SkillCheckPromptGui", true)
	if not root then
		root = PGui2:FindFirstChild("SkillCheckPromptGui-con", true)
	end
	if not root then return nil, nil, nil end

	check = root:FindFirstChild("Check", true)
	if not check or not check.Visible then return nil, nil, nil end

	local perfect = check:FindFirstChild("TrapPerfect", true)
	local goal = check:FindFirstChild("TrapGoal", true)
	if perfect and perfect.Visible then
		target = perfect
	elseif goal and goal.Visible then
		target = goal
	else
		return nil, nil, nil
	end

	line = check:FindFirstChild("Line", true)
	if not line then return nil, nil, nil end

	TrapGuiCache.Check = check
	TrapGuiCache.Line = line
	TrapGuiCache.Target = target
	return check, line, target
end

-- Trap auto-skillcheck ported from TianHub source: Legit crossing detection
-- and Instant timing share the existing trap UI and AS_PressSkill input path.
local function TH_ProcessTrapSkillCheck()
	if not TrapEngine.AutoTrapSC or TrapEngine.TrapBusy then
		return
	end
	local c, line, target = TH_FindTrapSkillCheck()
	if not (c and line and target and target.Visible) then
		TrapEngine.TrapLastLine = nil
		return
	end

	local line_rotation = line.Rotation % 360
	local target_rotation = target.Rotation % 360
	local should_press = false
	if TrapEngine.TrapMode == "Instant" then
		pcall(function()
			line.Rotation = target.Rotation + 109
		end)
		should_press = true
	else
		local start_angle = (target_rotation + 102) % 360
		local end_angle = (target_rotation + 116) % 360
		should_press = AS_Crossed(TrapEngine.TrapLastLine, line_rotation, start_angle, end_angle)
	end
	TrapEngine.TrapLastLine = line_rotation

	local now = os.clock()
	local last_press = tonumber(TrapEngine.TrapLastPress) or 0
	if should_press and now - last_press > 0.25 then
		TrapEngine.TrapBusy = true
		TrapEngine.TrapLastPress = now
		task.spawn(function()
			pcall(AS_PressSkill)
			task.wait(TrapEngine.TrapMode == "Instant" and 0.35 or 0.08)
			TrapEngine.TrapBusy = false
			TrapEngine.TrapLastLine = nil
		end)
	end
end

local function TH_IsTrapInstance(inst)
	if not inst or not inst.Parent then
		return false
	end
	if CollectionService:HasTag(inst, "Trap") or CollectionService:HasTag(inst, "BearTrap") then
		return true
	end
	local n = string.lower(inst.Name)
	if string.find(n, "trap", 1, true) or string.find(n, "snare", 1, true) or string.find(n, "mine", 1, true) then
		return true
	end
	return false
end

local function TH_GetAdornee(inst)
	if inst:IsA("BasePart") then
		return inst
	end
	if inst:IsA("Model") then
		return inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)
	end
	return nil
end

function TH_ClearHighlightMap(map_tbl)
	for inst, hl in pairs(map_tbl) do
		pcall(function()
			if hl then
				hl:Destroy()
			end
		end)
		map_tbl[inst] = nil
	end
end

local function TH_EnsureHighlight(map_tbl, inst, color)
	if map_tbl[inst] and map_tbl[inst].Parent then
		map_tbl[inst].FillColor = color
		return
	end
	local adornee = TH_GetAdornee(inst)
	if not adornee then
		return
	end
	local hl = Instance.new("Highlight")
	hl.Name = "HANX_ESP_HL"
	hl.Adornee = adornee
	hl.FillColor = color
	hl.OutlineColor = Color3.fromRGB(255, 255, 255)
	hl.FillTransparency = 0.35
	hl.OutlineTransparency = 0.05
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Parent = gui_parent
	map_tbl[inst] = hl
end

local function TH_SyncTrapESP()
	if not TrapEngine.TrapESP then
		TH_ClearHighlightMap(TrapEngine.TrapHighlights)
		return
	end
	local active_set = {}
	for _, d in ipairs(workspace:GetDescendants()) do
		if (d:IsA("Model") or d:IsA("BasePart")) and TH_IsTrapInstance(d) then
			active_set[d] = true
			TH_EnsureHighlight(TrapEngine.TrapHighlights, d, Color3.fromRGB(255, 65, 115))
		end
	end
	for inst, hl in pairs(TrapEngine.TrapHighlights) do
		if not active_set[inst] or not inst.Parent then
			pcall(function()
				hl:Destroy()
			end)
			TrapEngine.TrapHighlights[inst] = nil
		end
	end
end

function TH_SyncGenESP()
	if not TrapEngine.GenESP then
		TH_ClearHighlightMap(TrapEngine.GenHighlights)
		return
	end
	local active_set = {}
	local map = workspace:FindFirstChild("Map")
	local search_root = map or workspace
	for _, d in ipairs(search_root:GetDescendants()) do
		if d:IsA("Model") and (d:GetAttribute("RepairProgress") ~= nil or d:GetAttribute("ProgressRepair") ~= nil or string.find(string.lower(d.Name), "generator", 1, true)) then
			active_set[d] = true
			TH_EnsureHighlight(TrapEngine.GenHighlights, d, Color3.fromRGB(168, 85, 247))
		end
	end
	for inst, hl in pairs(TrapEngine.GenHighlights) do
		if not active_set[inst] or not inst.Parent then
			pcall(function()
				hl:Destroy()
			end)
			TrapEngine.GenHighlights[inst] = nil
		end
	end
end

local function TH_SyncSurvivorESP()
	if not TrapEngine.SurvivorESP then
		TH_ClearHighlightMap(TrapEngine.SurvivorHighlights)
		return
	end
	local active_set = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character then
			local ch = plr.Character
			local team_name = plr.Team and string.lower(plr.Team.Name) or ""
			if not string.find(team_name, "killer", 1, true) then
				active_set[ch] = true
				TH_EnsureHighlight(TrapEngine.SurvivorHighlights, ch, Color3.fromRGB(80, 220, 150))
			end
		end
	end
	for inst, hl in pairs(TrapEngine.SurvivorHighlights) do
		if not active_set[inst] or not inst.Parent then
			pcall(function()
				hl:Destroy()
			end)
			TrapEngine.SurvivorHighlights[inst] = nil
		end
	end
end

local esp_sync_accum = 0
local trap_scan_accum = 0
RunService.Heartbeat:Connect(function(dt)
	if TrapEngine.AutoTrapSC then
		trap_scan_accum = trap_scan_accum + dt
		if trap_scan_accum >= (1 / 30) then
			trap_scan_accum = 0
			TH_ProcessTrapSkillCheck()
		end
	else
		trap_scan_accum = 0
		TrapEngine.TrapLastLine = nil
		TrapGuiCache.Check = nil
		TrapGuiCache.Line = nil
		TrapGuiCache.Target = nil
		TrapGuiCache.NextScan = 0
	end

	esp_sync_accum = esp_sync_accum + dt
	if esp_sync_accum >= 0.4 then
		esp_sync_accum = 0
		TH_SyncTrapESP()
		TH_SyncGenESP()
		TH_SyncSurvivorESP()
	end
end)

getgenv().TianHub_TrapAPI = {
	State = TrapEngine,
	SetAutoTrapSC = function(v)
		TrapEngine.AutoTrapSC = v == true
	end,
	SetTrapMode = function(mode)
		if mode == "Legit" or mode == "Instant" then
			TrapEngine.TrapMode = mode
			TrapEngine.TrapLastLine = nil
		end
	end,
	SetTrapESP = function(v)
		TrapEngine.TrapESP = v == true
		TH_SyncTrapESP()
	end,
}

local function attach_text_glint(lbl, speed)
	lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	local grad = Instance.new("UIGradient")
	grad.Name = "HanxTextGlint"
	grad.Parent = lbl

	local spd = speed or 1.45
	task.spawn(function()
		local t = 0
		while lbl.Parent and grad.Parent do
			local dt = RunService.RenderStepped:Wait()
			t = (t + dt * spd) % 1
			local c_dark = P.text
			local c_glow = Color3.fromRGB(250, 224, 255)
			local c_mid = P.accent

			local p0 = math.clamp(t - 0.22, 0.01, 0.96)
			local p1 = math.clamp(t, 0.02, 0.98)
			local p2 = math.clamp(t + 0.22, 0.03, 0.99)

			grad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, c_dark),
				ColorSequenceKeypoint.new(p0, c_mid),
				ColorSequenceKeypoint.new(p1, c_glow),
				ColorSequenceKeypoint.new(p2, c_mid),
				ColorSequenceKeypoint.new(1, c_dark),
			})
		end
	end)
end

local card_glow_entries = {}
local sync_angle = 0
local sync_speed = 215
local aura_flow_grads = {}

RunService.RenderStepped:Connect(function(dt)
	sync_angle = (sync_angle + dt * sync_speed) % 360
	local pulse = 0.5 + 0.5 * math.sin(os.clock() * 3.2)

	for _, item in ipairs(card_glow_entries) do
		if item.btn.Parent and item.stroke.Parent and item.grad.Parent then
			item.grad.Enabled = true
			item.grad.Rotation = sync_angle
			item.stroke.Color = P.white_glow
			if item.hovered or item.expanded then
				item.stroke.Thickness = 1.65
				item.stroke.Transparency = 0.04
			else
				item.stroke.Thickness = 1.15 + (pulse * 0.28)
				item.stroke.Transparency = 0.14 + ((1 - pulse) * 0.18)
			end
		end
	end

	local now = os.clock()
	for _, entry in ipairs(aura_flow_grads) do
		if entry.grad.Parent then
			local shift = 0.5 + 0.42 * math.sin(now * entry.speed + entry.phase)
			local p_left = math.clamp(shift - 0.24, 0.01, 0.96)
			local p_mid = math.clamp(shift, 0.02, 0.98)
			local p_right = math.clamp(shift + 0.24, 0.03, 0.99)

			entry.grad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, entry.c_base),
				ColorSequenceKeypoint.new(p_left, entry.c_mid),
				ColorSequenceKeypoint.new(p_mid, entry.c_bright),
				ColorSequenceKeypoint.new(p_right, entry.c_mid),
				ColorSequenceKeypoint.new(1, entry.c_base),
			})
		end
	end
end)

local function attach_drag(handle, target, on_tap)
	local dragging = false
	local moved = false
	local pointer = nil
	local start_pos = target.Position
	local start_inp = Vector3.zero

	handle.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			moved = false
			start_pos = target.Position
			start_inp = inp.Position
			inp.Changed:Connect(function()
				if inp.UserInputState == Enum.UserInputState.End then
					local was_tap = dragging and not moved
					dragging = false
					if was_tap and on_tap then
						on_tap()
					end
				end
			end)
		end
	end)

	handle.InputChanged:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
			pointer = inp
		end
	end)

	UserInputService.InputChanged:Connect(function(inp)
		if dragging and inp == pointer then
			local delta = inp.Position - start_inp
			if delta.Magnitude > 5 then
				moved = true
			end
			target.Position = UDim2.new(
				start_pos.X.Scale,
				start_pos.X.Offset + delta.X,
				start_pos.Y.Scale,
				start_pos.Y.Offset + delta.Y
			)
		end
	end)
end

local sg = Instance.new("ScreenGui")
sg.Name = "HANX_HUB_ROUNDED"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.DisplayOrder = 1000
sg.Parent = gui_parent

-- ============================================================
--  ANTI RESET GUI (LOBBY -> IN-GAME / RESPAWN PERSISTENCE)
-- ============================================================
local manual_closed = false

local function bind_anti_reset_gui()
	pcall(function()
		sg.ResetOnSpawn = false
	end)

	local function ensure_mounted()
		if manual_closed then
			return
		end
		local target_parent = lp:FindFirstChildOfClass("PlayerGui")
		if not target_parent then
			local ok, core = pcall(function()
				return game:GetService("CoreGui")
			end)
			target_parent = (ok and core) or lp:FindFirstChildOfClass("PlayerGui")
		end
		if target_parent and sg and sg.Parent ~= target_parent then
			pcall(function()
				sg.ResetOnSpawn = false
				sg.Parent = target_parent
			end)
		end
		if sg and not sg.Enabled then
			pcall(function()
				sg.Enabled = true
			end)
		end
	end

	ensure_mounted()

	lp.CharacterAdded:Connect(function()
		task.defer(ensure_mounted)
		task.delay(0.35, ensure_mounted)
		task.delay(1.25, ensure_mounted)
	end)

	lp.ChildAdded:Connect(function(child)
		if child:IsA("PlayerGui") then
			task.defer(ensure_mounted)
		end
	end)

	sg.AncestryChanged:Connect(function(_, parent_now)
		if not manual_closed and parent_now == nil then
			task.defer(ensure_mounted)
		end
	end)

	task.spawn(function()
		while not manual_closed and sg do
			task.wait(1.5)
			if manual_closed or not sg then
				break
			end
			ensure_mounted()
		end
	end)
end

bind_anti_reset_gui()

local is_mobile_viewport = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local root = Instance.new("Frame")
root.Name = "RootFrame"
root.AnchorPoint = Vector2.new(0.5, 0.5)
root.Size = is_mobile_viewport and UDim2.fromOffset(640, 368) or UDim2.fromOffset(690, 410)
root.Position = UDim2.new(0.5, 0, 0.5, 0)
root.BackgroundTransparency = 1
root.Parent = sg

local DEFAULT_SCALE_PCT = is_mobile_viewport and 85 or 90
local ui_scale = Instance.new("UIScale")
ui_scale.Scale = DEFAULT_SCALE_PCT / 100
ui_scale.Parent = root

local mini_box = Instance.new("TextButton")
mini_box.Name = "MiniLogoBox"
mini_box.Size = UDim2.fromOffset(44, 44)
mini_box.Position = UDim2.new(0, 12, 0.5, 0)
mini_box.AnchorPoint = Vector2.new(0, 0.5)
mini_box.BackgroundColor3 = P.sidebar
mini_box.Text = ""
mini_box.AutoButtonColor = false
mini_box.Visible = false
mini_box.ZIndex = 20
mini_box.Parent = sg
round_all(mini_box, 16)
stroke_all(mini_box, P.accent, 1.6)

local mini_box_stroke = mini_box:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
mini_box_stroke.Name = "HanxMiniDarkPurpleStroke"
mini_box_stroke.Thickness = 1.75
mini_box_stroke.Transparency = 0.08
mini_box_stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
mini_box_stroke.Parent = mini_box

local mini_box_grad = mini_box_stroke:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
mini_box_grad.Name = "HanxMiniDarkPurpleGrad"
mini_box_grad.Parent = mini_box_stroke

local mini_logo_img = Instance.new("ImageLabel")
mini_logo_img.Name = "MiniLogoImage"
mini_logo_img.Size = UDim2.new(1, -8, 1, -8)
mini_logo_img.Position = UDim2.fromOffset(4, 4)
mini_logo_img.BackgroundColor3 = P.card
mini_logo_img.BackgroundTransparency = 0.2
mini_logo_img.BorderSizePixel = 0
mini_logo_img.Image = resolve_icon(HANX_ASSETS.minisize_logo_id)
mini_logo_img.ImageColor3 = Color3.fromRGB(255, 255, 255)
mini_logo_img.ImageTransparency = 0
mini_logo_img.ScaleType = Enum.ScaleType.Crop
mini_logo_img.ZIndex = 21
mini_logo_img.Parent = mini_box
round_all(mini_logo_img, 13)

local c_dark_1 = Color3.fromRGB(24, 10, 42)
local c_dark_2 = Color3.fromRGB(76, 22, 140)
local c_dark_3 = Color3.fromRGB(132, 46, 215)
local c_pulse = Color3.fromRGB(168, 85, 247)

task.spawn(function()
	local run_service = game:GetService("RunService")
	local angle = 0
	local clock = 0
	while mini_box.Parent and mini_logo_img.Parent do
		local dt = run_service.RenderStepped:Wait()
		dt = math.clamp(dt, 0.001, 0.1)
		angle = (angle + dt * 155) % 360
		clock += dt * 2.4

		local shift = 0.5 + 0.35 * math.sin(clock)
		local p0 = math.clamp(shift - 0.24, 0.01, 0.95)
		local p1 = math.clamp(shift, 0.02, 0.97)
		local p2 = math.clamp(shift + 0.24, 0.03, 0.99)

		mini_box_grad.Rotation = angle
		mini_box_grad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, c_dark_1),
			ColorSequenceKeypoint.new(p0, c_dark_2),
			ColorSequenceKeypoint.new(p1, c_pulse),
			ColorSequenceKeypoint.new(p2, c_dark_3),
			ColorSequenceKeypoint.new(1, c_dark_1),
		})

		local breath = 0.5 + 0.5 * math.sin(clock * 1.35)
		mini_box_stroke.Thickness = 1.55 + (breath * 0.45)
		mini_box_stroke.Transparency = 0.06 + ((1 - breath) * 0.14)
	end
end)

local mini_logo_fb = Instance.new("TextLabel")
mini_logo_fb.Size = UDim2.fromScale(1, 1)
mini_logo_fb.BackgroundTransparency = 1
mini_logo_fb.Text = "HANX"
mini_logo_fb.TextColor3 = P.text
mini_logo_fb.Font = Enum.Font.GothamBlack
mini_logo_fb.TextSize = 12
mini_logo_fb.Visible = mini_logo_img.Image == ""
mini_logo_fb.ZIndex = 22
mini_logo_fb.Parent = mini_logo_img

if mini_logo_fb.Visible then
	attach_text_glint(mini_logo_fb, 1.35)
end

local header_desc, header_icon_img, header_icon_txt, header_title, nav_scroll, right_pane, search_input, sidebar, window
do
window = Instance.new("Frame")
window.Name = "MainWindow"
window.Size = is_mobile_viewport and UDim2.new(1, 0, 1, -46) or UDim2.new(1, 0, 1, -58)
window.Position = UDim2.fromOffset(0, 0)
window.BackgroundColor3 = P.bg
window.BackgroundTransparency = 0.04
window.BorderSizePixel = 0
window.ClipsDescendants = false
window.Active = true
window.Parent = root
round_all(window, 18)
stroke_all(window, P.stroke, 1.35, 0.12)
v_grad(window, P.bg_grad_top, P.bg_grad_bot)

local bg_art = Instance.new("ImageLabel")
bg_art.Name = "BgWatermark"
bg_art.Size = UDim2.fromScale(1, 1)
bg_art.Position = UDim2.fromOffset(0, 0)
bg_art.BackgroundTransparency = 1
bg_art.Image = resolve_icon(HANX_ASSETS.bg_id)
bg_art.ImageTransparency = HANX_ASSETS.bg_transparency
bg_art.ScaleType = Enum.ScaleType.Crop
bg_art.ZIndex = 0
bg_art.Parent = window
round_all(bg_art, 18)

local lower_aura_band = Instance.new("Frame")
lower_aura_band.Name = "PurpleRunningAuraBand"
lower_aura_band.Size = UDim2.new(1, 0, 0.38, 0)
lower_aura_band.Position = UDim2.new(0, 0, 0.62, 0)
lower_aura_band.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
lower_aura_band.BackgroundTransparency = 0.70
lower_aura_band.BorderSizePixel = 0
lower_aura_band.ZIndex = 1
lower_aura_band.Parent = window
round_all(lower_aura_band, 18)

local aura_grad = Instance.new("UIGradient")
aura_grad.Name = "RunningPurpleAuraGrad"
aura_grad.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.92),
	NumberSequenceKeypoint.new(0.5, 0.48),
	NumberSequenceKeypoint.new(1, 0.92),
})
aura_grad.Parent = lower_aura_band

table.insert(aura_flow_grads, {
	grad = aura_grad,
	speed = 0.95,
	phase = 0,
	c_base = Color3.fromRGB(16, 11, 28),
	c_mid = Color3.fromRGB(92, 34, 176),
	c_bright = Color3.fromRGB(168, 85, 247),
})

local sidebar_w = is_mobile_viewport and 182 or 202
sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(0, sidebar_w, 1, -12)
sidebar.Position = UDim2.fromOffset(6, 6)
sidebar.BackgroundColor3 = P.sidebar
sidebar.BackgroundTransparency = 0.10
sidebar.BorderSizePixel = 0
sidebar.ClipsDescendants = true
sidebar.ZIndex = 2
sidebar.Parent = window
round_all(sidebar, 15)
stroke_all(sidebar, P.stroke, 1.1, 0.30)

local brand = Instance.new("Frame")
brand.Size = is_mobile_viewport and UDim2.new(1, -12, 0, 42) or UDim2.new(1, -16, 0, 52)
brand.Position = is_mobile_viewport and UDim2.fromOffset(6, 5) or UDim2.fromOffset(8, 8)
brand.BackgroundTransparency = 1
brand.ZIndex = 3
brand.Parent = sidebar

local logo_box = Instance.new("Frame")
logo_box.Size = is_mobile_viewport and UDim2.fromOffset(34, 34) or UDim2.fromOffset(40, 40)
logo_box.Position = is_mobile_viewport and UDim2.fromOffset(2, 4) or UDim2.fromOffset(2, 6)
logo_box.BackgroundColor3 = P.card
logo_box.BorderSizePixel = 0
logo_box.ZIndex = 3
logo_box.Parent = brand
round_all(logo_box, 12)
stroke_all(logo_box, P.stroke_bright, 1.15, 0.25)

local logo_txt = Instance.new("TextLabel")
logo_txt.Size = UDim2.fromScale(1, 1)
logo_txt.BackgroundTransparency = 1
logo_txt.Text = "HN"
logo_txt.TextColor3 = P.text
logo_txt.Font = Enum.Font.GothamBlack
logo_txt.TextSize = 15
logo_txt.ZIndex = 3
logo_txt.Parent = logo_box

local logo_img = Instance.new("ImageLabel")
logo_img.Name = "HanxLogoImage"
logo_img.Size = UDim2.fromScale(1, 1)
logo_img.BackgroundTransparency = 1
logo_img.Image = resolve_icon(HANX_ASSETS.logo_id)
logo_img.ScaleType = Enum.ScaleType.Crop
logo_img.Visible = logo_img.Image ~= ""
logo_img.ZIndex = 4
logo_img.Parent = logo_box
round_all(logo_img, 12)

if logo_img.Visible then
	logo_txt.Visible = false
end

local bypass_badge = Instance.new("Frame")
bypass_badge.Name = "ActiveBypassPingBadge"
bypass_badge.Position = UDim2.fromOffset(6, 6)
bypass_badge.Size = UDim2.fromOffset(146, 24)
bypass_badge.BackgroundColor3 = P.sidebar
bypass_badge.BackgroundTransparency = 0.08
bypass_badge.BorderSizePixel = 0
bypass_badge.Visible = false
bypass_badge.ZIndex = 2500
bypass_badge.Parent = sg
round_all(bypass_badge, 8)
stroke_all(bypass_badge, P.accent, 1.3, 0.15)

local bypass_dot = Instance.new("Frame")
bypass_dot.Name = "StatusDot"
bypass_dot.Size = UDim2.fromOffset(7, 7)
bypass_dot.Position = UDim2.fromOffset(8, 8.5)
bypass_dot.BackgroundColor3 = Color3.fromRGB(168, 85, 247)
bypass_dot.BorderSizePixel = 0
bypass_dot.ZIndex = 2501
bypass_dot.Parent = bypass_badge
round_all(bypass_dot, 99)

local bypass_lbl = Instance.new("TextLabel")
bypass_lbl.Name = "Label"
bypass_lbl.Size = UDim2.new(1, -22, 1, 0)
bypass_lbl.Position = UDim2.fromOffset(20, 0)
bypass_lbl.BackgroundTransparency = 1
bypass_lbl.Text = "ACTIVE BYPASS PING"
bypass_lbl.TextColor3 = P.text
bypass_lbl.Font = Enum.Font.GothamBold
bypass_lbl.TextSize = 10
bypass_lbl.TextXAlignment = Enum.TextXAlignment.Left
bypass_lbl.ZIndex = 2501
bypass_lbl.Parent = bypass_badge

local function sync_bypass_ping_ui(active: boolean)
	pcall(function()
		if bypass_badge and bypass_badge.Parent then
			bypass_badge.Visible = (active == true)
		end
	end)
end

task.spawn(function()
	while sg and sg.Parent do
		local is_on = (AP and AP.AntiBypassPing == true) and true or false
		sync_bypass_ping_ui(is_on)
		task.wait(0.15)
	end
end)

local hanx_notify_token = 0
local function hanx_notify(title_txt: string, body_txt: string, duration: number?)
	pcall(function()
		local target_gui = sg
		if not target_gui or not target_gui.Parent then
			local pg = lp and lp:FindFirstChildOfClass("PlayerGui")
			target_gui = pg and pg:FindFirstChild("HANX_HUB_ROUNDED")
		end
		if not target_gui then return end

		hanx_notify_token += 1
		local my_token = hanx_notify_token

		local old = target_gui:FindFirstChild("HanxNotifyToast")
		if old then
			old:Destroy()
		end

		local toast = Instance.new("Frame")
		toast.Name = "HanxNotifyToast"
		toast.AnchorPoint = Vector2.new(1, 0)
		toast.Position = UDim2.new(1, -16, 0, 48)
		toast.Size = UDim2.fromOffset(250, 52)
		toast.BackgroundColor3 = P.sidebar
		toast.BackgroundTransparency = 0.05
		toast.BorderSizePixel = 0
		toast.ZIndex = 2000
		toast.Parent = target_gui
		round_all(toast, 12)
		stroke_all(toast, P.accent, 1.5, 0.1)

		local bar = Instance.new("Frame")
		bar.Size = UDim2.fromOffset(4, 30)
		bar.Position = UDim2.fromOffset(10, 11)
		bar.BackgroundColor3 = P.accent
		bar.BorderSizePixel = 0
		bar.ZIndex = 2001
		bar.Parent = toast
		round_all(bar, 2)

		local t_lbl = Instance.new("TextLabel")
		t_lbl.Size = UDim2.new(1, -24, 0, 18)
		t_lbl.Position = UDim2.fromOffset(20, 7)
		t_lbl.BackgroundTransparency = 1
		t_lbl.Text = tostring(title_txt)
		t_lbl.TextColor3 = P.text
		t_lbl.Font = Enum.Font.GothamBold
		t_lbl.TextSize = 12
		t_lbl.TextXAlignment = Enum.TextXAlignment.Left
		t_lbl.ZIndex = 2001
		t_lbl.Parent = toast

		local b_lbl = Instance.new("TextLabel")
		b_lbl.Size = UDim2.new(1, -24, 0, 16)
		b_lbl.Position = UDim2.fromOffset(20, 26)
		b_lbl.BackgroundTransparency = 1
		b_lbl.Text = tostring(body_txt)
		b_lbl.TextColor3 = P.muted
		b_lbl.Font = Enum.Font.GothamMedium
		b_lbl.TextSize = 10.5
		b_lbl.TextXAlignment = Enum.TextXAlignment.Left
		b_lbl.TextTruncate = Enum.TextTruncate.AtEnd
		b_lbl.ZIndex = 2001
		b_lbl.Parent = toast

		task.delay(duration or 2.5, function()
			if hanx_notify_token == my_token and toast and toast.Parent then
				toast:Destroy()
			end
		end)
	end)
end

local hub_title = Instance.new("TextLabel")
hub_title.Size = is_mobile_viewport and UDim2.new(1, -42, 0, 16) or UDim2.new(1, -50, 0, 18)
hub_title.Position = is_mobile_viewport and UDim2.fromOffset(40, 4) or UDim2.fromOffset(48, 7)
hub_title.BackgroundTransparency = 1
hub_title.Text = "HANX HUB"
hub_title.TextColor3 = P.text
hub_title.Font = Enum.Font.GothamBold
hub_title.TextSize = is_mobile_viewport and 13 or 14
hub_title.TextXAlignment = Enum.TextXAlignment.Left
hub_title.ZIndex = 3
hub_title.Parent = brand
attach_text_glint(hub_title, 1.45)

local hub_sub = Instance.new("TextLabel")
hub_sub.Size = is_mobile_viewport and UDim2.new(1, -42, 0, 12) or UDim2.new(1, -50, 0, 14)
hub_sub.Position = is_mobile_viewport and UDim2.fromOffset(40, 20) or UDim2.fromOffset(48, 25)
hub_sub.BackgroundTransparency = 1
hub_sub.Text = "SURVIVOR & KILLER TOOLS"
hub_sub.TextColor3 = P.muted
hub_sub.Font = Enum.Font.GothamBold
hub_sub.TextSize = is_mobile_viewport and 8.5 or 9.5
hub_sub.TextXAlignment = Enum.TextXAlignment.Left
hub_sub.ZIndex = 3
hub_sub.Parent = brand

local search_h = is_mobile_viewport and 28 or 34
local search_y = is_mobile_viewport and 50 or 66

local search_wrap = Instance.new("Frame")
search_wrap.Size = is_mobile_viewport and UDim2.new(1, -12, 0, search_h) or UDim2.new(1, -16, 0, search_h)
search_wrap.Position = is_mobile_viewport and UDim2.fromOffset(6, search_y) or UDim2.fromOffset(8, search_y)
search_wrap.BackgroundColor3 = P.card
search_wrap.BackgroundTransparency = 0.18
search_wrap.BorderSizePixel = 0
search_wrap.ZIndex = 3
search_wrap.Parent = sidebar
round_all(search_wrap, 11)
stroke_all(search_wrap, P.stroke, 1, 0.32)

local search_icon = Instance.new("TextLabel")
search_icon.Size = UDim2.fromOffset(24, search_h)
search_icon.Position = UDim2.fromOffset(2, 0)
search_icon.BackgroundTransparency = 1
search_icon.Text = "⌕"
search_icon.TextColor3 = P.accent
search_icon.Font = Enum.Font.GothamBold
search_icon.TextSize = 14
search_icon.ZIndex = 3
search_icon.Parent = search_wrap

search_input = Instance.new("TextBox")
search_input.Size = UDim2.new(1, -30, 1, 0)
search_input.Position = UDim2.fromOffset(26, 0)
search_input.BackgroundTransparency = 1
search_input.PlaceholderText = "Search features..."
search_input.PlaceholderColor3 = P.muted
search_input.Text = ""
search_input.TextColor3 = P.text
search_input.Font = Enum.Font.GothamMedium
search_input.TextSize = is_mobile_viewport and 11 or 11.5
search_input.TextXAlignment = Enum.TextXAlignment.Left
search_input.ClearTextOnFocus = false
search_input.ZIndex = 3
search_input.Parent = search_wrap

local nav_top = search_y + search_h + (is_mobile_viewport and 3 or 4)
local prof_h = is_mobile_viewport and 30 or 36
local prof_bottom_pad = 4
local nav_bottom_reserve = nav_top + prof_h + prof_bottom_pad + 3

nav_scroll = Instance.new("ScrollingFrame")
nav_scroll.Size = is_mobile_viewport and UDim2.new(1, -8, 1, -nav_bottom_reserve) or UDim2.new(1, -12, 1, -(98 + prof_h + prof_bottom_pad + 3))
nav_scroll.Position = is_mobile_viewport and UDim2.fromOffset(4, nav_top) or UDim2.fromOffset(6, 98)
nav_scroll.BackgroundTransparency = 1
nav_scroll.ScrollBarThickness = 0
nav_scroll.ScrollBarImageTransparency = 1
nav_scroll.ScrollingEnabled = false
nav_scroll.ScrollingDirection = Enum.ScrollingDirection.Y
nav_scroll.ElasticBehavior = Enum.ElasticBehavior.Never
nav_scroll.Active = true
nav_scroll.AutomaticCanvasSize = Enum.AutomaticSize.None
nav_scroll.CanvasSize = UDim2.fromOffset(0, 0)
nav_scroll.ClipsDescendants = true
nav_scroll.ZIndex = 3
nav_scroll.Parent = sidebar

local nav_layout = Instance.new("UIListLayout")
nav_layout.Padding = is_mobile_viewport and UDim.new(0, 1) or UDim.new(0, 2)
nav_layout.SortOrder = Enum.SortOrder.LayoutOrder
nav_layout.Parent = nav_scroll

local prof_wrap = Instance.new("Frame")
prof_wrap.Size = is_mobile_viewport and UDim2.new(1, -12, 0, prof_h) or UDim2.new(1, -16, 0, prof_h)
prof_wrap.Position = is_mobile_viewport and UDim2.new(0, 6, 1, -(prof_h + prof_bottom_pad)) or UDim2.new(0, 8, 1, -52)
prof_wrap.BackgroundColor3 = P.card
prof_wrap.BackgroundTransparency = 0.20
prof_wrap.BorderSizePixel = 0
prof_wrap.ZIndex = 3
prof_wrap.Parent = sidebar
round_all(prof_wrap, is_mobile_viewport and 17 or 22)
stroke_all(prof_wrap, P.stroke, 1, 0.32)

local avatar_size = is_mobile_viewport and 24 or 32
local avatar_img = Instance.new("ImageLabel")
avatar_img.Size = UDim2.fromOffset(avatar_size, avatar_size)
avatar_img.Position = is_mobile_viewport and UDim2.fromOffset(5, 5) or UDim2.fromOffset(6, 6)
avatar_img.BackgroundColor3 = P.drawer
avatar_img.BorderSizePixel = 0
avatar_img.ZIndex = 4
avatar_img.Parent = prof_wrap
round_all(avatar_img, math.floor(avatar_size / 2))
stroke_all(avatar_img, P.accent, 1, 0.35)

task.spawn(function()
	local ok, thumb = pcall(function()
		return Players:GetUserThumbnailAsync(lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
	end)
	if ok and thumb and avatar_img.Parent then
		avatar_img.Image = thumb
	end
end)

local masked_name = string.sub(lp.Name, 1, 3) .. "****"
local prof_txt = Instance.new("TextLabel")
prof_txt.Size = is_mobile_viewport and UDim2.new(1, -60, 1, 0) or UDim2.new(1, -74, 1, 0)
prof_txt.Position = is_mobile_viewport and UDim2.fromOffset(34, 0) or UDim2.fromOffset(44, 0)
prof_txt.BackgroundTransparency = 1
prof_txt.Text = masked_name
prof_txt.TextColor3 = P.text
prof_txt.Font = Enum.Font.GothamBold
prof_txt.TextSize = is_mobile_viewport and 10.5 or 11.5
prof_txt.TextXAlignment = Enum.TextXAlignment.Left
prof_txt.TextTruncate = Enum.TextTruncate.AtEnd
prof_txt.ZIndex = 4
prof_txt.Parent = prof_wrap

local right_x = sidebar_w + 12
local right_w_sub = sidebar_w + 20

right_pane = Instance.new("Frame")
right_pane.Name = "RightPane"
right_pane.Size = UDim2.new(1, -right_w_sub, 1, -12)
right_pane.Position = UDim2.fromOffset(right_x, 6)
right_pane.BackgroundTransparency = 1
right_pane.ZIndex = 2
right_pane.Parent = window

local top_header = Instance.new("Frame")
top_header.Size = UDim2.new(1, -6, 0, 56)
top_header.Position = UDim2.fromOffset(0, 0)
top_header.BackgroundColor3 = P.sidebar
top_header.BackgroundTransparency = 0.18
top_header.BorderSizePixel = 0
top_header.ZIndex = 3
top_header.Parent = right_pane
round_all(top_header, 14)
stroke_all(top_header, P.stroke, 1.1, 0.35)
attach_drag(top_header, root)

header_icon_img = Instance.new("ImageLabel")
header_icon_img.Size = UDim2.fromOffset(20, 20)
header_icon_img.Position = UDim2.fromOffset(12, 18)
header_icon_img.BackgroundTransparency = 1
header_icon_img.ScaleType = Enum.ScaleType.Fit
header_icon_img.Visible = false
header_icon_img.ZIndex = 4
header_icon_img.Parent = top_header

header_icon_txt = Instance.new("TextLabel")
header_icon_txt.Size = UDim2.fromOffset(24, 24)
header_icon_txt.Position = UDim2.fromOffset(10, 16)
header_icon_txt.BackgroundTransparency = 1
header_icon_txt.Text = TAB_ICONS.Home.Fallback
header_icon_txt.TextColor3 = P.accent
header_icon_txt.Font = Enum.Font.GothamBold
header_icon_txt.TextSize = 17
header_icon_txt.ZIndex = 4
header_icon_txt.Parent = top_header

header_title = Instance.new("TextLabel")
header_title.Size = UDim2.new(0.55, -42, 0, 22)
header_title.Position = UDim2.fromOffset(42, 8)
header_title.BackgroundTransparency = 1
header_title.Text = "Home"
header_title.TextColor3 = P.text
header_title.Font = Enum.Font.GothamBold
header_title.TextSize = 16
header_title.TextXAlignment = Enum.TextXAlignment.Left
header_title.ZIndex = 4
header_title.Parent = top_header

header_desc = Instance.new("TextLabel")
header_desc.Size = UDim2.new(1, -220, 0, 18)
header_desc.Position = UDim2.fromOffset(42, 30)
header_desc.BackgroundTransparency = 1
header_desc.Text = "Script information and status"
header_desc.TextColor3 = P.muted
header_desc.Font = Enum.Font.GothamMedium
header_desc.TextSize = 11.5
header_desc.TextXAlignment = Enum.TextXAlignment.Left
header_desc.TextTruncate = Enum.TextTruncate.AtEnd
header_desc.ZIndex = 4
header_desc.Parent = top_header

local live_pill = Instance.new("Frame")
live_pill.Name = "PremiumBadge"
live_pill.Size = UDim2.fromOffset(66, 20)
live_pill.Position = UDim2.new(1, -144, 0.5, -10)
live_pill.BackgroundColor3 = P.accent_soft
live_pill.BackgroundTransparency = 0.25
live_pill.BorderSizePixel = 0
live_pill.ZIndex = 4
live_pill.Parent = top_header
round_all(live_pill, 10)
stroke_all(live_pill, P.accent, 1, 0.35)

local live_txt = Instance.new("TextLabel")
live_txt.Size = UDim2.fromScale(1, 1)
live_txt.BackgroundTransparency = 1
live_txt.Text = "• HN Free"
live_txt.TextColor3 = P.text
live_txt.Font = Enum.Font.GothamBold
live_txt.TextSize = 10
live_txt.ZIndex = 5
live_txt.Parent = live_pill

local btn_min = Instance.new("TextButton")
btn_min.Name = "MinBtn"
btn_min.Size = UDim2.fromOffset(28, 28)
btn_min.Position = UDim2.new(1, -68, 0.5, -14)
btn_min.BackgroundColor3 = P.card
btn_min.Text = "-"
btn_min.TextColor3 = P.text
btn_min.Font = Enum.Font.GothamBold
btn_min.TextSize = 16
btn_min.AutoButtonColor = false
btn_min.ZIndex = 4
btn_min.Parent = top_header
round_all(btn_min, 9)
stroke_all(btn_min, P.stroke, 1, 0.35)

local btn_close = Instance.new("TextButton")
btn_close.Name = "CloseBtn"
btn_close.Size = UDim2.fromOffset(28, 28)
btn_close.Position = UDim2.new(1, -36, 0.5, -14)
btn_close.BackgroundColor3 = P.card
btn_close.Text = "×"
btn_close.TextColor3 = P.text
btn_close.Font = Enum.Font.GothamBold
btn_close.TextSize = 15
btn_close.AutoButtonColor = false
btn_close.ZIndex = 4
btn_close.Parent = top_header
round_all(btn_close, 9)
stroke_all(btn_close, P.stroke, 1, 0.35)

local confirm_backdrop = Instance.new("Frame")
confirm_backdrop.Name = "CloseConfirmBackdrop"
confirm_backdrop.Size = UDim2.fromScale(1, 1)
confirm_backdrop.Position = UDim2.fromOffset(0, 0)
confirm_backdrop.BackgroundColor3 = Color3.fromRGB(6, 5, 10)
confirm_backdrop.BackgroundTransparency = 0.45
confirm_backdrop.BorderSizePixel = 0
confirm_backdrop.Visible = false
confirm_backdrop.ZIndex = 30
confirm_backdrop.Parent = window
round_all(confirm_backdrop, 18)

local confirm_box = Instance.new("Frame")
confirm_box.Name = "CloseConfirmBox"
confirm_box.Size = UDim2.fromOffset(300, 148)
confirm_box.Position = UDim2.new(0.5, -150, 0.5, -74)
confirm_box.BackgroundColor3 = P.sidebar
confirm_box.BorderSizePixel = 0
confirm_box.ZIndex = 31
confirm_box.Parent = confirm_backdrop
round_all(confirm_box, 16)
stroke_all(confirm_box, P.accent, 1.3)

local confirm_title = Instance.new("TextLabel")
confirm_title.Size = UDim2.new(1, -24, 0, 24)
confirm_title.Position = UDim2.fromOffset(12, 14)
confirm_title.BackgroundTransparency = 1
confirm_title.Text = "Close HANX HUB?"
confirm_title.TextColor3 = P.text
confirm_title.Font = Enum.Font.GothamBold
confirm_title.TextSize = 14
confirm_title.ZIndex = 32
confirm_title.Parent = confirm_box

local confirm_sub = Instance.new("TextLabel")
confirm_sub.Size = UDim2.new(1, -24, 0, 34)
confirm_sub.Position = UDim2.fromOffset(12, 40)
confirm_sub.BackgroundTransparency = 1
confirm_sub.Text = "Select Yes to close the UI or No to cancel."
confirm_sub.TextColor3 = P.muted
confirm_sub.Font = Enum.Font.GothamMedium
confirm_sub.TextSize = 11.5
confirm_sub.TextWrapped = true
confirm_sub.ZIndex = 32
confirm_sub.Parent = confirm_box

local yes_glow = Instance.new("Frame")
yes_glow.Name = "YesGlowLayer"
yes_glow.Size = UDim2.new(0.5, -10, 0, 46)
yes_glow.Position = UDim2.fromOffset(8, 88)
yes_glow.BackgroundColor3 = Color3.fromRGB(255, 25, 70)
yes_glow.BackgroundTransparency = 0.55
yes_glow.BorderSizePixel = 0
yes_glow.ZIndex = 31
yes_glow.Parent = confirm_box
round_all(yes_glow, 13)

local yes_btn = Instance.new("TextButton")
yes_btn.Name = "YesCloseBtn"
yes_btn.Size = UDim2.new(0.5, -18, 0, 38)
yes_btn.Position = UDim2.fromOffset(12, 92)
yes_btn.BackgroundColor3 = Color3.fromRGB(255, 32, 74)
yes_btn.Text = "Yes"
yes_btn.TextColor3 = Color3.fromRGB(255, 255, 255)
yes_btn.Font = Enum.Font.GothamBold
yes_btn.TextSize = 13
yes_btn.AutoButtonColor = false
yes_btn.ZIndex = 32
yes_btn.Parent = confirm_box
round_all(yes_btn, 10)
local yes_stroke = stroke_all(yes_btn, Color3.fromRGB(255, 165, 185), 2, 0.05)

local yes_hovered = false
local yes_pulse_active = true
local yes_bright_bg = Color3.fromRGB(255, 68, 108)
local yes_mid_bg = Color3.fromRGB(220, 16, 52)
local yes_bright_stroke = Color3.fromRGB(255, 200, 212)
local yes_mid_stroke = Color3.fromRGB(255, 95, 125)

local function apply_yes_hover_state(hovered: boolean)
	yes_hovered = hovered
	if hovered then
		TweenService:Create(
			yes_btn,
			TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundColor3 = Color3.fromRGB(255, 90, 125) }
		):Play()
		if yes_stroke then
			TweenService:Create(
				yes_stroke,
				TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Color = Color3.fromRGB(255, 225, 232), Transparency = 0 }
			):Play()
		end
		TweenService:Create(
			yes_glow,
			TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundColor3 = Color3.fromRGB(255, 55, 95), BackgroundTransparency = 0.25 }
		):Play()
	end
end

yes_btn.MouseEnter:Connect(function()
	apply_yes_hover_state(true)
end)

yes_btn.MouseLeave:Connect(function()
	apply_yes_hover_state(false)
end)

task.spawn(function()
	while yes_pulse_active and yes_btn and yes_btn.Parent do
		if confirm_backdrop.Visible and confirm_box.Visible and yes_btn.Visible and not yes_hovered then
			local bg_up = TweenService:Create(
				yes_btn,
				TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{ BackgroundColor3 = yes_bright_bg }
			)
			local st_up = yes_stroke and TweenService:Create(
				yes_stroke,
				TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{ Color = yes_bright_stroke, Transparency = 0 }
			)
			local gl_up = TweenService:Create(
				yes_glow,
				TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{ BackgroundColor3 = Color3.fromRGB(255, 45, 85), BackgroundTransparency = 0.35 }
			)
			bg_up:Play()
			if st_up then
				st_up:Play()
			end
			gl_up:Play()
			bg_up.Completed:Wait()

			if not (yes_pulse_active and yes_btn and yes_btn.Parent) then
				break
			end

			if not yes_hovered then
				local bg_down = TweenService:Create(
					yes_btn,
					TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{ BackgroundColor3 = yes_mid_bg }
				)
				local st_down = yes_stroke and TweenService:Create(
					yes_stroke,
					TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{ Color = yes_mid_stroke, Transparency = 0.25 }
				)
				local gl_down = TweenService:Create(
					yes_glow,
					TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{ BackgroundColor3 = Color3.fromRGB(235, 18, 56), BackgroundTransparency = 0.68 }
				)
				bg_down:Play()
				if st_down then
					st_down:Play()
				end
				gl_down:Play()
				bg_down.Completed:Wait()
			else
				task.wait(0.1)
			end
		else
			task.wait(0.15)
		end
	end
end)

local no_btn = Instance.new("TextButton")
no_btn.Name = "NoCancelBtn"
no_btn.Size = UDim2.new(0.5, -18, 0, 38)
no_btn.Position = UDim2.new(0.5, 6, 0, 92)
no_btn.BackgroundColor3 = P.card
no_btn.Text = "No"
no_btn.TextColor3 = P.text
no_btn.Font = Enum.Font.GothamBold
no_btn.TextSize = 13
no_btn.AutoButtonColor = false
no_btn.ZIndex = 32
no_btn.Parent = confirm_box
round_all(no_btn, 10)
stroke_all(no_btn, P.stroke, 1, 0.3)

btn_min.MouseButton1Click:Connect(function()
	confirm_backdrop.Visible = false
	root.Visible = false
	mini_box.Visible = true
end)

attach_drag(mini_box, mini_box, function()
	root.Visible = true
	mini_box.Visible = false
end)

btn_close.MouseButton1Click:Connect(function()
	confirm_backdrop.Visible = true
end)

yes_btn.MouseButton1Click:Connect(function()
	yes_pulse_active = false
	manual_closed = true
	TOF_Bridge.Cleanup()
	TH_ClearHighlightMap(TrapEngine.TrapHighlights)
	TH_ClearHighlightMap(TrapEngine.GenHighlights)
	TH_ClearHighlightMap(TrapEngine.SurvivorHighlights)
	if FloatingParryButton then
		FloatingParryButton.Destroy()
		FloatingParryButton = nil
	end
	FC_SetEnabled(false)
	sg:Destroy()
end)

no_btn.MouseButton1Click:Connect(function()
	confirm_backdrop.Visible = false
end)
end

local pages_host = Instance.new("Frame")
pages_host.Size = UDim2.new(1, -10, 1, -64)
pages_host.Position = UDim2.fromOffset(0, 64)
pages_host.BackgroundTransparency = 1
pages_host.ZIndex = 3
pages_host.Parent = right_pane

local function make_toggle_row(parent_box: Instance, label_txt: string, init_on: boolean, cb: ((boolean) -> ())?, cfg_key: string?)
	local active_flag = init_on
	local row = Instance.new("TextButton")
	row.Size = UDim2.new(1, -6, 0, 32)
	row.BackgroundColor3 = P.sidebar
	row.BackgroundTransparency = 0.16
	row.BorderSizePixel = 0
	row.Text = ""
	row.AutoButtonColor = false
	row.Parent = parent_box
	round_all(row, 8)
	local r_stroke = stroke_all(row, active_flag and P.accent or P.stroke, 1, active_flag and 0.22 or 0.48)

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -54, 1, 0)
	lbl.Position = UDim2.fromOffset(10, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = label_txt
	lbl.TextColor3 = active_flag and P.text or P.muted
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 11.5
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextTruncate = Enum.TextTruncate.AtEnd
	lbl.Parent = row

	local sw = Instance.new("Frame")
	sw.Size = UDim2.fromOffset(34, 18)
	sw.Position = UDim2.new(1, -44, 0.5, -9)
	sw.BackgroundColor3 = active_flag and P.on_col or P.off_col
	sw.BorderSizePixel = 0
	sw.Parent = row
	round_all(sw, 9)

	local knob = Instance.new("Frame")
	knob.Size = UDim2.fromOffset(14, 14)
	knob.Position = active_flag and UDim2.fromOffset(18, 2) or UDim2.fromOffset(2, 2)
	knob.BackgroundColor3 = P.text
	knob.BorderSizePixel = 0
	knob.Parent = sw
	round_all(knob, 7)

	local function apply_state(next_v: boolean, fire_cb: boolean)
		active_flag = next_v == true
		lbl.TextColor3 = active_flag and P.text or P.muted
		r_stroke.Color = active_flag and P.accent or P.stroke
		r_stroke.Transparency = active_flag and 0.22 or 0.48
		TweenService:Create(sw, TweenInfo.new(0.14), {
			BackgroundColor3 = active_flag and P.on_col or P.off_col,
		}):Play()
		TweenService:Create(knob, TweenInfo.new(0.14), {
			Position = active_flag and UDim2.fromOffset(18, 2) or UDim2.fromOffset(2, 2),
		}):Play()
		if fire_cb and cb then
			cb(active_flag)
		end
	end

	row.MouseEnter:Connect(function()
		TweenService:Create(row, TweenInfo.new(0.12), { BackgroundColor3 = P.card_hover }):Play()
	end)
	row.MouseLeave:Connect(function()
		TweenService:Create(row, TweenInfo.new(0.12), { BackgroundColor3 = P.sidebar }):Play()
	end)
	row.MouseButton1Click:Connect(function()
		apply_state(not active_flag, true)
	end)

	local key = cfg_key or label_txt
	register_config_item(key, "toggle", function()
		return active_flag
	end, function(val, silent)
		apply_state(val == true, not silent)
	end)

	local reg_entry = {
		getState = function() return active_flag end,
		setState = function(v: boolean, fire_cb: boolean?) apply_state(v == true, fire_cb ~= false) end,
	}
	ToggleRegistry[string.lower(label_txt)] = reg_entry
	ToggleRegistry[key] = reg_entry
end

local function make_slider_row(parent_box: Instance, label_txt: string, min_v: number, max_v: number, def_v: number, cb: ((number) -> ())?, cfg_key: string?)
	local is_float = (min_v % 1 ~= 0) or (max_v % 1 ~= 0) or (def_v % 1 ~= 0)
	local cur = math.clamp(def_v, min_v, max_v)
	local box = Instance.new("Frame")
	box.Size = UDim2.new(1, -6, 0, 38)
	box.BackgroundColor3 = P.sidebar
	box.BackgroundTransparency = 0.16
	box.BorderSizePixel = 0
	box.Parent = parent_box
	round_all(box, 8)
	stroke_all(box, P.stroke, 1, 0.48)

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0.70, 0, 0, 16)
	lbl.Position = UDim2.fromOffset(10, 4)
	lbl.BackgroundTransparency = 1
	lbl.Text = label_txt
	lbl.TextColor3 = P.text
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 11.5
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextTruncate = Enum.TextTruncate.AtEnd
	lbl.Parent = box

	local function fmt_val(v: number): string
		if is_float then
			return string.format("%.2f", v):gsub("0+$", ""):gsub("%.$", "")
		end
		return tostring(v)
	end

	local val_lbl = Instance.new("TextLabel")
	val_lbl.Size = UDim2.new(0.30, -10, 0, 16)
	val_lbl.Position = UDim2.new(0.70, 0, 0, 4)
	val_lbl.BackgroundTransparency = 1
	val_lbl.Text = fmt_val(cur)
	val_lbl.TextColor3 = P.accent
	val_lbl.Font = Enum.Font.GothamBold
	val_lbl.TextSize = 11.5
	val_lbl.TextXAlignment = Enum.TextXAlignment.Right
	val_lbl.Parent = box

	local hit_area = Instance.new("TextButton")
	hit_area.Size = UDim2.new(1, -20, 0, 16)
	hit_area.Position = UDim2.fromOffset(10, 20)
	hit_area.BackgroundTransparency = 1
	hit_area.Text = ""
	hit_area.AutoButtonColor = false
	hit_area.Parent = box

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, 0, 0, 6)
	bar.Position = UDim2.new(0, 0, 0.5, -3)
	bar.BackgroundColor3 = P.card
	bar.BorderSizePixel = 0
	bar.Parent = hit_area
	round_all(bar, 3)

	local fill = Instance.new("Frame")
	local ratio = (cur - min_v) / math.max(max_v - min_v, 1e-6)
	fill.Size = UDim2.new(ratio, 0, 1, 0)
	fill.BackgroundColor3 = P.accent
	fill.BorderSizePixel = 0
	fill.Parent = bar
	round_all(fill, 3)

	local knob_s = Instance.new("Frame")
	knob_s.Size = UDim2.fromOffset(12, 12)
	knob_s.AnchorPoint = Vector2.new(0.5, 0.5)
	knob_s.Position = UDim2.new(ratio, 0, 0.5, 0)
	knob_s.BackgroundColor3 = P.text
	knob_s.BorderSizePixel = 0
	knob_s.Parent = bar
	round_all(knob_s, 6)

	local function set_num(v: number, fire_cb: boolean)
		local raw_v = math.clamp(tonumber(v) or min_v, min_v, max_v)
		if is_float then
			cur = math.floor(raw_v * 100 + 0.5) / 100
		else
			cur = math.floor(raw_v + 0.5)
		end
		local ex = (cur - min_v) / math.max(max_v - min_v, 1e-6)
		fill.Size = UDim2.new(ex, 0, 1, 0)
		knob_s.Position = UDim2.new(ex, 0, 0.5, 0)
		val_lbl.Text = fmt_val(cur)
		if fire_cb and cb then
			cb(cur)
		end
	end

	local dragging_s = false
	local function set_x(px: number)
		local r = math.clamp((px - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
		set_num(min_v + (max_v - min_v) * r, true)
	end

	hit_area.InputBegan:Connect(function(inp: InputObject)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging_s = true
			set_x(inp.Position.X)
		end
	end)

	UserInputService.InputChanged:Connect(function(inp: InputObject)
		if dragging_s and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
			set_x(inp.Position.X)
		end
	end)

	UserInputService.InputEnded:Connect(function(inp: InputObject)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging_s = false
		end
	end)

	local key = cfg_key or label_txt
	register_config_item(key, "slider", function()
		return cur
	end, function(val, silent)
		set_num(tonumber(val) or cur, not silent)
	end)
end

local function make_button_row(parent_box: Instance, label_txt: string, cb: (() -> ())?)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 32)
	btn.BackgroundColor3 = P.card
	btn.Text = label_txt
	btn.TextColor3 = P.text
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11.5
	btn.AutoButtonColor = false
	btn.Parent = parent_box
	round_all(btn, 8)
	stroke_all(btn, P.accent, 1, 0.35)

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = P.card_hover }):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = P.card }):Play()
	end)
	btn.MouseButton1Click:Connect(function()
		if cb then
			cb()
		end
	end)
	return btn
end

local pages = {}
local nav_items = {}
local searchable_cards = {}
local page_builders = {}

search_input:GetPropertyChangedSignal("Text"):Connect(function()
	local q = string.lower(search_input.Text)
	for _, entry in ipairs(searchable_cards) do
		if q == "" then
			entry.frame.Visible = true
		else
			entry.frame.Visible = string.find(string.lower(entry.name), q, 1, true) ~= nil
		end
	end
end)

local function switch_tab(tab_name: string)
	for p_name, p_frame in pairs(pages) do
		p_frame.Visible = (p_name == tab_name)
		if p_name == tab_name then
			p_frame.CanvasPosition = Vector2.new(0, 0)
		end
	end
	for n_name, n_obj in pairs(nav_items) do
		local is_cur = (n_name == tab_name)
		TweenService:Create(n_obj.btn, TweenInfo.new(0.14), {
			BackgroundColor3 = is_cur and P.card_active or P.sidebar,
			BackgroundTransparency = is_cur and 0.12 or 1,
		}):Play()
		n_obj.txt.TextColor3 = is_cur and P.text or P.muted
		n_obj.ic_txt.TextColor3 = is_cur and P.accent or P.muted
		n_obj.bar.Visible = is_cur
		n_obj.stroke.Enabled = is_cur
	end
	local meta = nav_items[tab_name]
	if meta then
		local resolved = resolve_icon(meta.icon_id)
		if resolved ~= "" then
			header_icon_img.Image = resolved
			header_icon_img.Visible = true
			header_icon_txt.Visible = false
		else
			header_icon_img.Visible = false
			header_icon_txt.Visible = true
			header_icon_txt.Text = meta.fallback
		end
		header_title.Text = tab_name
		header_desc.Text = meta.subtitle
	end
end

local function create_page(tab_name: string, subtitle_txt: string, order_n: number)
	local icon_cfg = TAB_ICONS[tab_name] or { Id = "", Fallback = "•" }
	local resolved_ic = resolve_icon(icon_cfg.Id)

	local btn = Instance.new("TextButton")
	btn.Name = tab_name .. "_Nav"
	btn.Size = UDim2.new(1, 0, 0, 28)
	btn.BackgroundColor3 = P.sidebar
	btn.BackgroundTransparency = 1
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.LayoutOrder = order_n
	btn.Parent = nav_scroll
	round_all(btn, 9)
	local b_stroke = stroke_all(btn, P.stroke_bright, 1, 0.30)
	b_stroke.Enabled = false

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(0, 3, 0.56, 0)
	bar.Position = UDim2.fromOffset(7, 6)
	bar.BackgroundColor3 = P.accent
	bar.BorderSizePixel = 0
	bar.Visible = false
	bar.Parent = btn
	round_all(bar, 3)

	local ic_img = Instance.new("ImageLabel")
	ic_img.Size = UDim2.fromOffset(15, 15)
	ic_img.Position = UDim2.fromOffset(16, 6.5)
	ic_img.BackgroundTransparency = 1
	ic_img.Image = resolved_ic
	ic_img.ScaleType = Enum.ScaleType.Fit
	ic_img.Visible = resolved_ic ~= ""
	ic_img.Parent = btn

	local ic_txt = Instance.new("TextLabel")
	ic_txt.Size = UDim2.fromOffset(22, 28)
	ic_txt.Position = UDim2.fromOffset(15, 0)
	ic_txt.BackgroundTransparency = 1
	ic_txt.Text = icon_cfg.Fallback
	ic_txt.TextColor3 = P.muted
	ic_txt.Font = Enum.Font.GothamBold
	ic_txt.TextSize = 12
	ic_txt.Visible = resolved_ic == ""
	ic_txt.Parent = btn

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.new(1, -44, 1, 0)
	txt.Position = UDim2.fromOffset(39, 0)
	txt.BackgroundTransparency = 1
	txt.Text = tab_name
	txt.TextColor3 = P.muted
	txt.Font = Enum.Font.GothamMedium
	txt.TextSize = 12
	txt.TextXAlignment = Enum.TextXAlignment.Left
	txt.Parent = btn

	local page = Instance.new("ScrollingFrame")
	page.Name = tab_name .. "_Page"
	page.Size = UDim2.new(1, -6, 1, 0)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ScrollBarThickness = 4
	page.ScrollBarImageColor3 = P.accent
	page.ScrollingDirection = Enum.ScrollingDirection.Y
	page.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
	page.Active = true
	page.ClipsDescendants = true
	page.AutomaticCanvasSize = Enum.AutomaticSize.None
	page.CanvasSize = UDim2.fromOffset(0, 0)
	page.Visible = false
	page.Parent = pages_host
	pad_all(page, 4, 22, 4, 4)

	local cols_wrap = Instance.new("Frame")
	cols_wrap.Name = "ColsWrap"
	cols_wrap.Size = UDim2.new(1, 0, 0, 0)
	cols_wrap.AutomaticSize = Enum.AutomaticSize.Y
	cols_wrap.BackgroundTransparency = 1
	cols_wrap.Parent = page

	local left_col = Instance.new("Frame")
	left_col.Name = "LeftColumn"
	left_col.Size = UDim2.new(0.5, -8, 0, 0)
	left_col.Position = UDim2.fromOffset(0, 0)
	left_col.AutomaticSize = Enum.AutomaticSize.Y
	left_col.BackgroundTransparency = 1
	left_col.Parent = cols_wrap

	local left_list = Instance.new("UIListLayout")
	left_list.Padding = UDim.new(0, 12)
	left_list.SortOrder = Enum.SortOrder.LayoutOrder
	left_list.Parent = left_col

	local right_col = Instance.new("Frame")
	right_col.Name = "RightColumn"
	right_col.Size = UDim2.new(0.5, -8, 0, 0)
	right_col.Position = UDim2.new(0.5, 4, 0, 0)
	right_col.AutomaticSize = Enum.AutomaticSize.Y
	right_col.BackgroundTransparency = 1
	right_col.Parent = cols_wrap

	local right_list = Instance.new("UIListLayout")
	right_list.Padding = UDim.new(0, 12)
	right_list.SortOrder = Enum.SortOrder.LayoutOrder
	right_list.Parent = right_col

local function sync_page_canvas()
		local h = math.max(left_list.AbsoluteContentSize.Y, right_list.AbsoluteContentSize.Y, cols_wrap.AbsoluteSize.Y)
		page.CanvasSize = UDim2.fromOffset(0, h + 110)
	end
	left_list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(sync_page_canvas)
	right_list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(sync_page_canvas)
	cols_wrap:GetPropertyChangedSignal("AbsoluteSize"):Connect(sync_page_canvas)
	task.defer(sync_page_canvas)

	pages[tab_name] = page
	nav_items[tab_name] = {
		btn = btn,
		txt = txt,
		ic_txt = ic_txt,
		bar = bar,
		stroke = b_stroke,
		icon_id = icon_cfg.Id,
		fallback = icon_cfg.Fallback,
		subtitle = subtitle_txt,
	}

	btn.MouseButton1Click:Connect(function()
		switch_tab(tab_name)
	end)

	local col_counter = 0

	local function add_card(title_upper: string, build_items_fn: ((body_frame: Instance, helpers: {
		toggle: (string, boolean, ((boolean) -> ())?, string?) -> (),
		slider: (string, number, number, number, ((number) -> ())?, string?) -> (),
		button: (string, (() -> ())?) -> TextButton,
	}) -> ())?)
		col_counter += 1
		local parent_col = (col_counter % 2 == 1) and left_col or right_col

		local slot = Instance.new("Frame")
		slot.Name = title_upper .. "_Slot"
		slot.Size = UDim2.new(1, 0, 0, 40)
		slot.AutomaticSize = Enum.AutomaticSize.None
		slot.BackgroundTransparency = 1
		slot.ClipsDescendants = false
		slot.LayoutOrder = col_counter
		slot.Parent = parent_col

		local slot_list = Instance.new("UIListLayout")
		slot_list.Padding = UDim.new(0, 6)
		slot_list.HorizontalAlignment = Enum.HorizontalAlignment.Center
		slot_list.SortOrder = Enum.SortOrder.LayoutOrder
		slot_list.Parent = slot

		local card_btn = Instance.new("TextButton")
		card_btn.Name = title_upper .. "_Card"
		card_btn.Size = UDim2.new(1, 0, 0, 40)
		card_btn.BackgroundColor3 = P.card
		card_btn.BackgroundTransparency = 0.12
		card_btn.Text = ""
		card_btn.AutoButtonColor = false
		card_btn.LayoutOrder = 1
		card_btn.Parent = slot
		round_all(card_btn, 11)
		local c_stroke = stroke_all(card_btn, P.white_glow, 1.25, 0.18)

		local c_grad = Instance.new("UIGradient")
		c_grad.Name = "BorderSyncRunner"
		c_grad.Enabled = true
		c_grad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.78),
			NumberSequenceKeypoint.new(0.35, 0.55),
			NumberSequenceKeypoint.new(0.50, 0.04),
			NumberSequenceKeypoint.new(0.65, 0.55),
			NumberSequenceKeypoint.new(1, 0.78),
		})
		c_grad.Parent = c_stroke

		local glow_rec = { btn = card_btn, stroke = c_stroke, grad = c_grad, hovered = false, expanded = false }
		table.insert(card_glow_entries, glow_rec)

		local pipe = Instance.new("Frame")
		pipe.Size = UDim2.fromOffset(3, 18)
		pipe.Position = UDim2.fromOffset(12, 11)
		pipe.BackgroundColor3 = P.accent
		pipe.BorderSizePixel = 0
		pipe.Parent = card_btn
		round_all(pipe, 3)

		local c_lbl = Instance.new("TextLabel")
		c_lbl.Size = UDim2.new(1, -48, 1, 0)
		c_lbl.Position = UDim2.fromOffset(23, 0)
		c_lbl.BackgroundTransparency = 1
		c_lbl.Text = string.upper(title_upper)
		c_lbl.TextColor3 = P.text
		c_lbl.Font = Enum.Font.GothamBold
		c_lbl.TextSize = 12
		c_lbl.TextXAlignment = Enum.TextXAlignment.Left
		c_lbl.TextTruncate = Enum.TextTruncate.AtEnd
		c_lbl.Parent = card_btn

		local chev = Instance.new("TextLabel")
		chev.Size = UDim2.fromOffset(24, 40)
		chev.Position = UDim2.new(1, -26, 0, 0)
		chev.BackgroundTransparency = 1
		chev.Text = ">"
		chev.TextColor3 = P.muted
		chev.Font = Enum.Font.Code
		chev.TextSize = 14
		chev.Parent = card_btn

		local sub_panel = Instance.new("Frame")
		sub_panel.Name = title_upper .. "_InlineBody"
		sub_panel.Size = UDim2.new(0.98, 0, 0, 0)
		sub_panel.AutomaticSize = Enum.AutomaticSize.Y
		sub_panel.BackgroundColor3 = P.drawer
		sub_panel.BackgroundTransparency = 0.12
		sub_panel.BorderSizePixel = 0
		sub_panel.Visible = false
		sub_panel.LayoutOrder = 2
		sub_panel.Parent = slot
		round_all(sub_panel, 9)
		stroke_all(sub_panel, P.accent, 1, 0.40)
		pad_all(sub_panel, 6, 8, 12, 8)

		local sub_list = Instance.new("UIListLayout")
		sub_list.Padding = UDim.new(0, 6)
		sub_list.SortOrder = Enum.SortOrder.LayoutOrder
		sub_list.Parent = sub_panel

		local built = false
		local function ensure_built()
			if built then
				return
			end
			built = true
			if build_items_fn then
				build_items_fn(sub_panel, {
					toggle = function(t_lbl: string, init_v: boolean, callback: ((boolean) -> ())?, cfg_key: string?)
						make_toggle_row(sub_panel, t_lbl, init_v, callback, cfg_key or (tab_name .. "." .. title_upper .. "." .. t_lbl))
					end,
					slider = function(s_lbl: string, min_v: number, max_v: number, def_v: number, callback: any, cfg_key: any)
						if type(callback) == "string" then
							callback, cfg_key = cfg_key, nil
						end
						if type(cfg_key) ~= "string" then cfg_key = nil end
						make_slider_row(sub_panel, s_lbl, min_v, max_v, def_v, callback, cfg_key or (tab_name .. "." .. title_upper .. "." .. s_lbl))
					end,
					button = function(b_lbl: string, callback: (() -> ())?)
						return make_button_row(sub_panel, b_lbl, callback)
					end,
				})
			end
		end
		table.insert(page_builders, ensure_built)

local function refresh_slot_size()
	task.defer(function()
		if sub_panel.Visible then
			local content_h = sub_list.AbsoluteContentSize.Y
			slot.Size = UDim2.new(1, 0, 0, 40 + 6 + content_h + 36)
		else
			slot.Size = UDim2.new(1, 0, 0, 40)
		end
		sync_page_canvas()
	end)
end
		sub_list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			if sub_panel.Visible then
				refresh_slot_size()
			end
		end)

		card_btn.MouseEnter:Connect(function()
			glow_rec.hovered = true
			TweenService:Create(card_btn, TweenInfo.new(0.12), { BackgroundColor3 = P.card_hover }):Play()
		end)

		card_btn.MouseLeave:Connect(function()
			glow_rec.hovered = false
			TweenService:Create(card_btn, TweenInfo.new(0.12), { BackgroundColor3 = glow_rec.expanded and P.card_active or P.card }):Play()
		end)

		card_btn.MouseButton1Click:Connect(function()
			ensure_built()
			glow_rec.expanded = not glow_rec.expanded
			sub_panel.Visible = glow_rec.expanded
			chev.Text = glow_rec.expanded and "v" or ">"
			chev.TextColor3 = glow_rec.expanded and P.accent or P.muted
			TweenService:Create(card_btn, TweenInfo.new(0.12), {
				BackgroundColor3 = glow_rec.expanded and P.card_active or P.card,
			}):Play()
			refresh_slot_size()
		end)

		table.insert(searchable_cards, { name = title_upper, frame = slot })
	end

	return add_card, page, ensure_built
end


-- Tab Home: khusus info script (tanpa card fitur)
local _, home_page = create_page("Home", "Script information and status", 1)

if home_page and home_page:IsA("ScrollingFrame") then
	home_page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	home_page.CanvasSize = UDim2.new(0, 0, 0, 0)
end

local home_layout = home_page and home_page:FindFirstChildOfClass("UIListLayout")
if not home_layout and home_page then
	home_layout = Instance.new("UIListLayout")
	home_layout.Padding = UDim.new(0, 8)
	home_layout.SortOrder = Enum.SortOrder.LayoutOrder
	home_layout.Parent = home_page
elseif home_layout then
	home_layout.SortOrder = Enum.SortOrder.LayoutOrder
end

local info_card = Instance.new("Frame")
info_card.Name = "ScriptInfoCard"
info_card.Size = UDim2.new(1, -2, 0, 0)
info_card.AutomaticSize = Enum.AutomaticSize.Y
info_card.BackgroundColor3 = P.card
info_card.BackgroundTransparency = 0.12
info_card.BorderSizePixel = 0
info_card.LayoutOrder = 1
info_card.Parent = home_page
round_all(info_card, 14)
stroke_all(info_card, P.stroke_bright, 1.15, 0.28)
pad_all(info_card, 12, 12, 14, 14)

local info_layout = Instance.new("UIListLayout")
info_layout.Padding = UDim.new(0, 6)
info_layout.SortOrder = Enum.SortOrder.LayoutOrder
info_layout.Parent = info_card

local function add_info_line(title_txt: string, value_txt: string, order_i: number)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 22)
	row.BackgroundTransparency = 1
	row.LayoutOrder = order_i
	row.Parent = info_card

	local k = Instance.new("TextLabel")
	k.Size = UDim2.new(0.34, 0, 1, 0)
	k.BackgroundTransparency = 1
	k.Text = title_txt
	k.TextColor3 = P.muted
	k.Font = Enum.Font.GothamBold
	k.TextSize = 11.5
	k.TextXAlignment = Enum.TextXAlignment.Left
	k.Parent = row

	local v = Instance.new("TextLabel")
	v.Size = UDim2.new(0.66, 0, 1, 0)
	v.Position = UDim2.fromScale(0.34, 0)
	v.BackgroundTransparency = 1
	v.Text = value_txt
	v.TextColor3 = P.text
	v.Font = Enum.Font.GothamMedium
	v.TextSize = 11.5
	v.TextXAlignment = Enum.TextXAlignment.Left
	v.TextTruncate = Enum.TextTruncate.AtEnd
	v.Parent = row
end

add_info_line("SCRIPT NAME", SCRIPT_INFO.hub_name, 1)
add_info_line("VERSION", SCRIPT_INFO.version, 2)
add_info_line("STATUS", SCRIPT_INFO.status, 3)
add_info_line("PLACE ID", tostring(game.PlaceId), 4)
add_info_line("TABS", SCRIPT_INFO.tabs_list, 5)

local note_lbl = Instance.new("TextLabel")
note_lbl.Size = UDim2.new(1, 0, 0, 34)
note_lbl.BackgroundTransparency = 1
note_lbl.Text = SCRIPT_INFO.note
note_lbl.TextColor3 = P.muted
note_lbl.Font = Enum.Font.GothamMedium
note_lbl.TextSize = 11.5
note_lbl.TextWrapped = true
note_lbl.TextXAlignment = Enum.TextXAlignment.Left
note_lbl.LayoutOrder = 6
note_lbl.Parent = info_card

local function create_home_card(card_name: string, header_txt: string, order_num: number)
	local card = Instance.new("Frame")
	card.Name = card_name
	card.Size = UDim2.new(1, -2, 0, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.BackgroundColor3 = P.card
	card.BackgroundTransparency = 0.12
	card.BorderSizePixel = 0
	card.LayoutOrder = order_num
	card.Parent = home_page
	round_all(card, 14)
	stroke_all(card, P.stroke_bright, 1.15, 0.28)
	pad_all(card, 12, 12, 14, 14)

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = card

	local hdr = Instance.new("TextLabel")
	hdr.Size = UDim2.new(1, 0, 0, 20)
	hdr.BackgroundTransparency = 1
	hdr.Text = header_txt
	hdr.TextColor3 = P.text
	hdr.Font = Enum.Font.GothamBold
	hdr.TextSize = 12
	hdr.TextXAlignment = Enum.TextXAlignment.Left
	hdr.LayoutOrder = 1
	hdr.Parent = card

	return card
end

local function add_home_card_row(card: Frame, title_txt: string, value_txt: string, order_i: number)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 22)
	row.BackgroundTransparency = 1
	row.LayoutOrder = order_i
	row.Parent = card

	local k = Instance.new("TextLabel")
	k.Size = UDim2.new(0.34, 0, 1, 0)
	k.BackgroundTransparency = 1
	k.Text = title_txt
	k.TextColor3 = P.muted
	k.Font = Enum.Font.GothamBold
	k.TextSize = 11.5
	k.TextXAlignment = Enum.TextXAlignment.Left
	k.Parent = row

	local v = Instance.new("TextLabel")
	v.Size = UDim2.new(0.66, 0, 1, 0)
	v.Position = UDim2.fromScale(0.34, 0)
	v.BackgroundTransparency = 1
	v.Text = value_txt
	v.TextColor3 = P.text
	v.Font = Enum.Font.GothamMedium
	v.TextSize = 11.5
	v.TextXAlignment = Enum.TextXAlignment.Left
	v.TextTruncate = Enum.TextTruncate.AtEnd
	v.Parent = row
end

local function add_home_link_row(card: Frame, title_txt: string, value_txt: string, copy_val: string?, order_i: number)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 24)
	row.BackgroundTransparency = 1
	row.LayoutOrder = order_i
	row.Parent = card

	local has_btn = (type(copy_val) == "string" and copy_val ~= "")
	local btn_w = has_btn and 82 or 0
	local gap_w = has_btn and 6 or 0

	local k = Instance.new("TextLabel")
	k.Size = UDim2.new(0.32, 0, 1, 0)
	k.BackgroundTransparency = 1
	k.Text = title_txt
	k.TextColor3 = P.muted
	k.Font = Enum.Font.GothamBold
	k.TextSize = 11.5
	k.TextXAlignment = Enum.TextXAlignment.Left
	k.Parent = row

	local v = Instance.new("TextLabel")
	v.Size = UDim2.new(0.68, -(btn_w + gap_w), 1, 0)
	v.Position = UDim2.fromScale(0.32, 0)
	v.BackgroundTransparency = 1
	v.Text = value_txt
	v.TextColor3 = P.text
	v.Font = Enum.Font.GothamMedium
	v.TextSize = 11.5
	v.TextXAlignment = Enum.TextXAlignment.Left
	v.TextTruncate = Enum.TextTruncate.AtEnd
	v.Parent = row

	if has_btn then
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, btn_w, 0, 22)
		btn.Position = UDim2.new(1, -btn_w, 0.5, -11)
		btn.BackgroundColor3 = P.sidebar
		btn.BackgroundTransparency = 0.12
		btn.BorderSizePixel = 0
		btn.Text = "Copy  link"
		btn.TextColor3 = P.text
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 10
		btn.AutoButtonColor = false
		btn.Parent = row
		round_all(btn, 6)
		stroke_all(btn, P.accent, 1, 0.35)

		btn.MouseButton1Click:Connect(function()
			if type(setclipboard) == "function" then
				pcall(setclipboard, copy_val)
			end
			local prev = btn.Text
			btn.Text = "copied!"
			task.delay(1.1, function()
				if btn and btn.Parent then
					btn.Text = prev
				end
			end)
		end)
	end
end

-- Kotak Baru 1: Sosial Media (link disembunyikan, cukup klik Salin Link)
local social_card = create_home_card("SocialMediaCard", "Social Media", 2)
add_home_link_row(social_card, "YOUTUBE", "Official Channel", SOCIAL_INFO.youtube, 2)
add_home_link_row(social_card, "SAWERIA", "Donations & Support", SOCIAL_INFO.saweria, 3)
add_home_link_row(social_card, "DISCORD", "Server / Contact", SOCIAL_INFO.discord, 4)

-- Kotak Baru 2: Kontribusi / Collab
local collab_card = create_home_card("CollabCard", "CONTRIBUTION & COLLAB", 3)
add_home_link_row(collab_card, "CREATOR", COLLAB_INFO.creator, nil, 2)
add_home_link_row(collab_card, "COLLAB", COLLAB_INFO.collab, COLLAB_INFO.contact, 3)
add_home_link_row(collab_card, "SUPPORT", COLLAB_INFO.support, SOCIAL_INFO.saweria, 4)
add_home_link_row(collab_card, "CREDIT", COLLAB_INFO.credit, nil, 5)

local AlwaysFastVaultState, InstallAlwaysFastVaultHooks, StartUnlimitedVaultLoop, UnlimitedVaultState
do
local genv = (getgenv and getgenv()) or _G

AlwaysFastVaultState = genv.HanxAlwaysFastVaultState or { Enabled = false }
genv.HanxAlwaysFastVaultState = AlwaysFastVaultState
AlwaysFastVaultState.Enabled = false

function InstallAlwaysFastVaultHooks()
    pcall(function()
        local modules = ReplicatedStorage:WaitForChild("Modules", 5)
        local survivors = modules and modules:WaitForChild("Survivors", 5)
        local module = survivors and survivors:WaitForChild("SurvivorVault", 5)
        local mod = module and require(module)
        if mod and type(mod.evaluate) == "function" and not mod._HanxAlwaysFastVaultHooked then
            mod._HanxAlwaysFastVaultOriginal = mod.evaluate
            mod.evaluate = function(self, ...)
                if genv.HanxAlwaysFastVaultState and genv.HanxAlwaysFastVaultState.Enabled then
                    return true, "ready", 5
                end
                return mod._HanxAlwaysFastVaultOriginal(self, ...)
            end
            mod._HanxAlwaysFastVaultHooked = true
        end
    end)

pcall(function()
        local modules = ReplicatedStorage:WaitForChild("Modules", 5)
        local survivors = modules and modules:WaitForChild("Survivors", 5)
        local module = survivors and survivors:WaitForChild("SurvivorAnimationsController", 5)
        local ctl = module and require(module)
        if ctl and type(ctl._validateFastVault) == "function" and not ctl._HanxAlwaysFastVaultHooked then
            ctl._HanxAlwaysFastVaultOriginal = ctl._validateFastVault
            ctl._validateFastVault = function(self, ...)
                if genv.HanxAlwaysFastVaultState and genv.HanxAlwaysFastVaultState.Enabled then
                    return true, "ready", 5
                end
                return ctl._HanxAlwaysFastVaultOriginal(self, ...)
            end
            ctl._HanxAlwaysFastVaultHooked = true
        end
    end)
end

UnlimitedVaultState = genv.HanxUnlimitedVaultState or { Enabled = false }
genv.HanxUnlimitedVaultState = UnlimitedVaultState
UnlimitedVaultState.Enabled = false

function StartUnlimitedVaultLoop()
	if UnlimitedVaultState._LoopStarted then
		return
	end
	UnlimitedVaultState._LoopStarted = true
	task.spawn(function()
		while true do
			if UnlimitedVaultState.Enabled then
				pcall(function()
					for _, inst in ipairs(CollectionService:GetTagged("Blocked")) do
						CollectionService:RemoveTag(inst, "Blocked")
					end
				end)
			end
			task.wait(0.25)
		end
	end)
end

end
-- Tab Survivor: TOF SILENT AIM + AUTO PARRY + SKILLCHECK GENERATOR + TRAPS
local surv_card = create_page("Survivor", "Survivor actions and checks", 2)
local tof_st = TOF_Bridge.State.TOFSilent

surv_card("FAST VAULT", function(_, ui)
	ui.toggle("Always Fast Vault", false, function(v)
		AlwaysFastVaultState.Enabled = v and true or false
		if AlwaysFastVaultState.Enabled then
			task.spawn(function()
				for _ = 1, 20 do
					InstallAlwaysFastVaultHooks()
					task.wait(0.25)
				end
			end)
		end
	end)
	ui.toggle("Always Vault", false, function(v)
		UnlimitedVaultState.Enabled = v and true or false
		if UnlimitedVaultState.Enabled then
			StartUnlimitedVaultLoop()
		end
	end)
end)



local FB_SetEnabled, SHop_Rejoin, SHop_ServerHop, SHop_ServerLow
do
-- ============================================================
--  HANX HUB FULLBRIGHT + NO FOG / NO SMOKE (VISUAL)
-- ============================================================
local Lighting = Lighting or game:GetService("Lighting")

local FullbrightNoFog = {
	Enabled = false,
	SavedLighting = nil,
	SavedAtmospheres = {},
	SavedEffects = {},
	LoopThread = nil,
}

local function FB_CaptureOriginal()
	if FullbrightNoFog.SavedLighting then return end
	FullbrightNoFog.SavedLighting = {
		Brightness = Lighting.Brightness,
		ClockTime = Lighting.ClockTime,
		GlobalShadows = Lighting.GlobalShadows,
		Ambient = Lighting.Ambient,
		OutdoorAmbient = Lighting.OutdoorAmbient,
		FogStart = Lighting.FogStart,
		FogEnd = Lighting.FogEnd,
		FogColor = Lighting.FogColor,
		ExposureCompensation = Lighting.ExposureCompensation,
	}

	for _, obj in ipairs(Lighting:GetDescendants()) do
		if obj:IsA("Atmosphere") then
			FullbrightNoFog.SavedAtmospheres[obj] = {
				Density = obj.Density,
				Offset = obj.Offset,
				Glare = obj.Glare,
				Haze = obj.Haze,
			}
		elseif obj:IsA("BlurEffect") or obj:IsA("BloomEffect") or obj:IsA("ColorCorrectionEffect") or obj:IsA("SunRaysEffect") then
			FullbrightNoFog.SavedEffects[obj] = obj.Enabled
		end
	end
end

local function FB_ApplyBrightNoFog()
	FB_CaptureOriginal()
	pcall(function()
		Lighting.Brightness = 2
		Lighting.ClockTime = 14
		Lighting.GlobalShadows = false
		Lighting.Ambient = Color3.fromRGB(220, 220, 220)
		Lighting.OutdoorAmbient = Color3.fromRGB(235, 235, 235)
		Lighting.FogStart = 1e6
		Lighting.FogEnd = 1e6
		Lighting.FogColor = Color3.fromRGB(255, 255, 255)
		Lighting.ExposureCompensation = 0.1
	end)

	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Atmosphere") then
			if not FullbrightNoFog.SavedAtmospheres[obj] then
				FullbrightNoFog.SavedAtmospheres[obj] = {
					Density = obj.Density,
					Offset = obj.Offset,
					Glare = obj.Glare,
					Haze = obj.Haze,
				}
			end
			pcall(function()
				obj.Density = 0
				obj.Haze = 0
				obj.Glare = 0
			end)
		elseif obj:IsA("ParticleEmitter") or obj:IsA("Smoke") then
			local n = string.lower(obj.Name)
			if obj:IsA("Smoke") or string.find(n, "fog", 1, true) or string.find(n, "smoke", 1, true) or string.find(n, "mist", 1, true) or string.find(n, "asap", 1, true) or string.find(n, "kabut", 1, true) then
				pcall(function()
					obj.Enabled = false
				end)
			end
		end
	end

	for atm, _ in pairs(FullbrightNoFog.SavedAtmospheres) do
		if atm and atm.Parent then
			pcall(function()
				atm.Density = 0
				atm.Haze = 0
				atm.Glare = 0
			end)
		end
	end
end

local function FB_RestoreOriginal()
	local saved = FullbrightNoFog.SavedLighting
	if saved then
		pcall(function()
			Lighting.Brightness = saved.Brightness
			Lighting.ClockTime = saved.ClockTime
			Lighting.GlobalShadows = saved.GlobalShadows
			Lighting.Ambient = saved.Ambient
			Lighting.OutdoorAmbient = saved.OutdoorAmbient
			Lighting.FogStart = saved.FogStart
			Lighting.FogEnd = saved.FogEnd
			Lighting.FogColor = saved.FogColor
			Lighting.ExposureCompensation = saved.ExposureCompensation
		end)
	end

	for atm, props in pairs(FullbrightNoFog.SavedAtmospheres) do
		if atm and atm.Parent and props then
			pcall(function()
				atm.Density = props.Density
				atm.Offset = props.Offset
				atm.Glare = props.Glare
				atm.Haze = props.Haze
			end)
		end
	end

	for eff, wasEnabled in pairs(FullbrightNoFog.SavedEffects) do
		if eff and eff.Parent then
			pcall(function()
				eff.Enabled = wasEnabled
			end)
		end
	end
end

function FB_SetEnabled(v: boolean)
	FullbrightNoFog.Enabled = v == true
	if FullbrightNoFog.LoopThread then
		pcall(function() task.cancel(FullbrightNoFog.LoopThread) end)
		FullbrightNoFog.LoopThread = nil
	end

	if FullbrightNoFog.Enabled then
		FB_ApplyBrightNoFog()
		FullbrightNoFog.LoopThread = task.spawn(function()
			while FullbrightNoFog.Enabled do
				FB_ApplyBrightNoFog()
				task.wait(1.5)
			end
		end)
	else
		FB_RestoreOriginal()
	end
end

-- ============================================================
--  HANX HUB ANTI-LAG: SMOOTH & SUPER SMOOTH (MISC)
-- ============================================================
local Players = Players or game:GetService("Players")
local Lighting = Lighting or game:GetService("Lighting")

local AntiLagDual = {
	Mode = "None", -- "None" | "Smooth" | "SuperSmooth"
	SavedProps = setmetatable({}, { __mode = "k" }),
	SavedSurfaceApps = {},
	SavedLighting = nil,
	DescConn = nil,
}

local FOLIAGE_KEYWORDS = {
	"tree", "leaf", "leaves", "foliage", "bush", "shrub", "vine",
	"grass", "weed", "fern", "clover", "plant", "flower", "petal"
}

local function ALD_IsProtected(obj)
	if not obj or not obj.Parent then return true end
	if obj:IsDescendantOf(Players) then return true end
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character and obj:IsDescendantOf(plr.Character) then
			return true
		end
	end
	if obj:IsA("ProximityPrompt") or obj:IsA("ClickDetector") then
		return true
	end
	return false
end

local function ALD_IsFoliageOrGrass(obj)
	local nameLower = string.lower(obj.Name)
	for _, kw in ipairs(FOLIAGE_KEYWORDS) do
		if string.find(nameLower, kw, 1, true) then
			return true
		end
	end
	local parent = obj.Parent
	local depth = 0
	while parent and parent ~= workspace and depth < 5 do
		local pName = string.lower(parent.Name)
		for _, kw in ipairs(FOLIAGE_KEYWORDS) do
			if string.find(pName, kw, 1, true) then
				return true
			end
		end
		parent = parent.Parent
		depth += 1
	end
	return false
end

local function ALD_SaveOnce(obj, key, val)
	if not AntiLagDual.SavedProps[obj] then
		AntiLagDual.SavedProps[obj] = {}
	end
	if AntiLagDual.SavedProps[obj][key] == nil then
		AntiLagDual.SavedProps[obj][key] = val
	end
end

local function ALD_OptimizeInstance(obj, mode)
	if ALD_IsProtected(obj) then return end

	-- Level 1 (Smooth) & Level 2 (SuperSmooth): matikan seluruh partikel, emitter, trail, beam, cahaya efek & post-effect
	if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") or obj:IsA("PostEffect") or obj:IsA("Highlight") then
		ALD_SaveOnce(obj, "Enabled", obj.Enabled)
		pcall(function() obj.Enabled = false end)
		return
	elseif obj:IsA("SurfaceAppearance") then
		if not AntiLagDual.SavedSurfaceApps[obj] then
			AntiLagDual.SavedSurfaceApps[obj] = obj.Parent
			pcall(function() obj.Parent = nil end)
		end
		return
	end

	-- Level 2 (SuperSmooth): pangkas tekstur, material, lampu lokal, serta sembunyikan pohon & grass
	if mode == "SuperSmooth" then
		if obj:IsA("BasePart") then
			if ALD_IsFoliageOrGrass(obj) and not obj.CanCollide then
				ALD_SaveOnce(obj, "Transparency", obj.Transparency)
				ALD_SaveOnce(obj, "CastShadow", obj.CastShadow)
				pcall(function()
					obj.Transparency = 1
					obj.CastShadow = false
				end)
			else
				ALD_SaveOnce(obj, "Material", obj.Material)
				ALD_SaveOnce(obj, "CastShadow", obj.CastShadow)
				ALD_SaveOnce(obj, "Reflectance", obj.Reflectance)
				pcall(function()
					obj.Material = Enum.Material.SmoothPlastic
					obj.CastShadow = false
					obj.Reflectance = 0
					obj.MaterialVariant = ""
				end)
			end
		elseif obj:IsA("Decal") or obj:IsA("Texture") then
			ALD_SaveOnce(obj, "Transparency", obj.Transparency)
			pcall(function() obj.Transparency = 1 end)
		elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
			ALD_SaveOnce(obj, "Enabled", obj.Enabled)
			ALD_SaveOnce(obj, "Shadows", obj.Shadows)
			pcall(function()
				obj.Shadows = false
				obj.Enabled = false
			end)
		elseif obj:IsA("SpecialMesh") then
			ALD_SaveOnce(obj, "TextureId", obj.TextureId)
			pcall(function() obj.TextureId = "" end)
		end
	end
end

local function ALD_RestoreAll()
	if AntiLagDual.DescConn then
		AntiLagDual.DescConn:Disconnect()
		AntiLagDual.DescConn = nil
	end

	if AntiLagDual.SavedLighting then
		pcall(function()
			Lighting.GlobalShadows = AntiLagDual.SavedLighting.GlobalShadows
		end)
		pcall(function()
			if settings and settings().Rendering then
				settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
			end
		end)
		AntiLagDual.SavedLighting = nil
	end

	for sa, oldParent in pairs(AntiLagDual.SavedSurfaceApps) do
		if sa and oldParent and oldParent.Parent then
			pcall(function() sa.Parent = oldParent end)
		end
	end
	table.clear(AntiLagDual.SavedSurfaceApps)

	for obj, props in pairs(AntiLagDual.SavedProps) do
		if obj and obj.Parent and props then
			pcall(function()
				for propName, val in pairs(props) do
					obj[propName] = val
				end
			end)
		end
	end
	table.clear(AntiLagDual.SavedProps)
end

function ALD_ApplyMode(mode)
	ALD_RestoreAll()
	AntiLagDual.Mode = mode
	if mode == "None" then return end

	if not AntiLagDual.SavedLighting then
		AntiLagDual.SavedLighting = {
			GlobalShadows = Lighting.GlobalShadows,
		}
	end

	pcall(function()
		Lighting.GlobalShadows = false
	end)
	pcall(function()
		if settings and settings().Rendering then
			settings().Rendering.QualityLevel = (mode == "SuperSmooth") and Enum.QualityLevel.Level01 or Enum.QualityLevel.Level02
		end
	end)

	if mode == "SuperSmooth" then
		local terrain = workspace:FindFirstChildOfClass("Terrain")
		if terrain then
			pcall(function()
				terrain.WaterWaveSize = 0
				terrain.WaterWaveSpeed = 0
				terrain.WaterReflectance = 0
				terrain.WaterTransparency = 0
			end)
		end
	end

	for _, eff in ipairs(Lighting:GetDescendants()) do
		ALD_OptimizeInstance(eff, mode)
	end

	task.spawn(function()
		local all = workspace:GetDescendants()
		for i = 1, #all do
			if AntiLagDual.Mode ~= mode then break end
			ALD_OptimizeInstance(all[i], mode)
			if i % 500 == 0 then
				task.wait()
			end
		end
	end)

	AntiLagDual.DescConn = workspace.DescendantAdded:Connect(function(desc)
		if AntiLagDual.Mode == mode then
			ALD_OptimizeInstance(desc, mode)
		end
	end)
end

if getgenv then
	getgenv().ALD_ApplyMode = ALD_ApplyMode
end

-- ============================================================
--  HANX HUB SERVER ACTIONS (REJOIN / SERVER HOP / LOW SERVER)
-- ============================================================
local TeleportService = game:GetService("TeleportService")

function SHop_Rejoin()
	pcall(function()
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
	end)
end

local function SHop_FetchServers(sortOrder: string, limit: number)
	local url = string.format(
		"https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=%s&limit=%d",
		game.PlaceId,
		sortOrder,
		limit or 100
	)
	local ok, raw = pcall(function()
		return game:HttpGet(url)
	end)
	if not ok or type(raw) ~= "string" then
		return nil
	end
	local decOk, data = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	if not decOk or type(data) ~= "table" or type(data.data) ~= "table" then
		return nil
	end
	return data.data
end

function SHop_ServerHop()
	task.spawn(function()
		local servers = SHop_FetchServers("Desc", 100)
		if not servers then return end

		local candidates = {}
		for _, srv in ipairs(servers) do
			if type(srv) == "table" and srv.id and srv.id ~= game.JobId then
				local playing = tonumber(srv.playing) or 0
				local maxPlayers = tonumber(srv.maxPlayers) or 0
				if playing > 0 and playing < maxPlayers then
					candidates[#candidates + 1] = srv.id
				end
			end
		end

		if #candidates > 0 then
			local picked = candidates[math.random(1, #candidates)]
			pcall(function()
				TeleportService:TeleportToPlaceInstance(game.PlaceId, picked, LocalPlayer)
			end)
		end
	end)
end

function SHop_ServerLow()
	task.spawn(function()
		local servers = SHop_FetchServers("Asc", 100)
		if not servers then return end

		local bestId, bestCount = nil, math.huge
		for _, srv in ipairs(servers) do
			if type(srv) == "table" and srv.id and srv.id ~= game.JobId then
				local playing = tonumber(srv.playing) or 0
				local maxPlayers = tonumber(srv.maxPlayers) or 0
				if playing > 0 and playing < maxPlayers and playing < bestCount then
					bestCount = playing
					bestId = srv.id
				end
			end
		end

		if bestId then
			pcall(function()
				TeleportService:TeleportToPlaceInstance(game.PlaceId, bestId, LocalPlayer)
			end)
		end
	end)
end


end

local KC_InstallHook, KillerCombat
do
-- ============================================================
--  HANX HUB KILLER COMBAT ENGINE (1:1 TIAN HUB)
-- ============================================================
KillerCombat = {
	AutoAttack = false,
	AttackRange = 12,
	AttackCooldown = 0.15,
	InfiniteLunge = false,
	CounterParry = false,
	AntiBlind = false,
	AutoDestroyPallet = false,
	UnlockCarrySkill = false,
	AutoHook = false,
	AimlockAttack = false,
	SmoothLock = 0,
	LockDistance = 15,

	HookedNamecall = false,
	LastAttackAt = 0,
	LastCounterAt = 0,
	LastPalletAt = 0,
	LastHookAt = 0,
	LastAttrAt = 0,
	LastScanCacheAt = 0,
	CachedTargetChar = nil,
	CachedTargetPart = nil,
	CachedTargetDist = math.huge,
}

getgenv().TianHub_KillerCombat = KillerCombat

local function KC_IsKillerTeam(): boolean
	local plr = LocalPlayer
	if not plr then return false end
	local team = plr.Team and string.lower(plr.Team.Name) or ""
	if string.find(team, "killer", 1, true) then
		return true
	end
	local ch = plr.Character
	if ch and (ch:GetAttribute("Role") == "Killer" or ch:GetAttribute("IsKiller") == true) then
		return true
	end
	return plr:GetAttribute("Role") == "Killer" or plr:GetAttribute("IsKiller") == true
end

local function KC_RefreshNearestSurvivor(maxDist: number, force: boolean?)
	local now = os.clock()
	if not force and (now - KillerCombat.LastScanCacheAt) < 0.04 and KillerCombat.CachedTargetPart and KillerCombat.CachedTargetPart.Parent then
		if KillerCombat.CachedTargetDist <= maxDist then
			return KillerCombat.CachedTargetChar, KillerCombat.CachedTargetPart
		end
	end

	local myChar = LocalPlayer.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	if not myRoot then
		KillerCombat.CachedTargetChar = nil
		KillerCombat.CachedTargetPart = nil
		KillerCombat.CachedTargetDist = math.huge
		return nil, nil
	end

	local bestChar, bestPart = nil, nil
	local bestDist = math.max(maxDist, 60)
	local myPos = myRoot.Position

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character then
			local tName = plr.Team and string.lower(plr.Team.Name) or ""
			if not string.find(tName, "killer", 1, true) then
				local ch = plr.Character
				local hum = ch:FindFirstChildOfClass("Humanoid")
				local part = ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso") or ch:FindFirstChild("HumanoidRootPart")
				if hum and hum.Health > 0 and part and not ch:GetAttribute("IsHooked") and not ch:GetAttribute("IsDead") then
					local dist = (part.Position - myPos).Magnitude
					if dist <= bestDist then
						bestDist = dist
						bestChar = ch
						bestPart = part
					end
				end
			end
		end
	end

	KillerCombat.LastScanCacheAt = now
	KillerCombat.CachedTargetChar = bestChar
	KillerCombat.CachedTargetPart = bestPart
	KillerCombat.CachedTargetDist = bestChar and bestDist or math.huge

	if bestChar and bestDist <= maxDist then
		return bestChar, bestPart
	end
	return nil, nil
end

local function KC_GetNearestSurvivor(maxDist: number?): (Model?, BasePart?)
	return KC_RefreshNearestSurvivor(maxDist or 60, false)
end

local function KC_GetPromptPart(prompt: ProximityPrompt): BasePart?
	local p = prompt.Parent
	if not p then return nil end
	if p:IsA("BasePart") then return p end
	if p:IsA("Attachment") and p.Parent and p.Parent:IsA("BasePart") then return p.Parent end
	return p:FindFirstChildWhichIsA("BasePart", true)
end

local function KC_TriggerMatchingPrompt(rootPos: Vector3, keywords: {string}): boolean
	local searchRoot = workspace:FindFirstChild("Map") or workspace
	for _, desc in ipairs(searchRoot:GetDescendants()) do
		if desc:IsA("ProximityPrompt") and desc.Enabled then
			local pName = string.lower(desc.Name .. " " .. desc.ActionText .. " " .. desc.ObjectText)
			local matched = false
			for _, kw in ipairs(keywords) do
				if string.find(pName, kw, 1, true) then
					matched = true
					break
				end
			end
			if matched then
				local parentPart = KC_GetPromptPart(desc)
				if parentPart and (parentPart.Position - rootPos).Magnitude <= (desc.MaxActivationDistance + 4) then
					pcall(function()
						fireproximityprompt(desc)
					end)
					return true
				end
			end
		end
	end
	return false
end

function KC_InstallHook()
	if KillerCombat.HookedNamecall then return end
	if type(hookmetamethod) ~= "function" or type(getnamecallmethod) ~= "function" then return end
	KillerCombat.HookedNamecall = true

	local wrap = newcclosure or function(f) return f end
	local oldCall
	pcall(function()
		oldCall = hookmetamethod(game, "__namecall", wrap(function(self, ...)
			local method = getnamecallmethod()
			if (method == "FireServer" or method == "fireServer") and not (checkcaller and checkcaller()) then
				if KillerCombat.AntiBlind and KC_IsKillerTeam() then
					local fullName = string.lower(tostring(self))
					if string.find(fullName, "blind", 1, true) or string.find(fullName, "flash", 1, true) then
						if setnamecallmethod then pcall(setnamecallmethod, method) end
						return nil
					end
				end

				if KillerCombat.AimlockAttack and KC_IsKillerTeam() then
					local rName = string.lower(tostring(self.Name))
					if string.find(rName, "attack", 1, true) or string.find(rName, "hit", 1, true) or string.find(rName, "slash", 1, true) then
						local _, targetPart = KC_GetNearestSurvivor(tonumber(KillerCombat.LockDistance) or 15)
						if targetPart then
							local args = table.pack(...)
							for i = 1, args.n do
								if typeof(args[i]) == "Vector3" then
									local origin = workspace.CurrentCamera and workspace.CurrentCamera.CFrame.Position or args[i]
									local d = targetPart.Position - origin
									if d.Magnitude > 0.01 then
										args[i] = d.Unit
									end
								elseif typeof(args[i]) == "CFrame" then
									args[i] = CFrame.lookAt(args[i].Position, targetPart.Position)
								end
							end
							if setnamecallmethod then pcall(setnamecallmethod, method) end
							return oldCall(self, table.unpack(args, 1, args.n))
						end
					end
				end
			end

			if setnamecallmethod then pcall(setnamecallmethod, method) end
			return oldCall(self, ...)
		end))
	end)
end

task.spawn(function()
	pcall(KC_InstallHook)
end)

RunService.Heartbeat:Connect(function(dt)
	if not KC_IsKillerTeam() then return end

	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not char or not root then return end

	local now = os.clock()

	if (KillerCombat.InfiniteLunge or KillerCombat.UnlockCarrySkill) and (now - KillerCombat.LastAttrAt) >= 0.25 then
		KillerCombat.LastAttrAt = now
		if KillerCombat.InfiniteLunge then
			pcall(function()
				char:SetAttribute("LungeDuration", 999)
				char:SetAttribute("LungeDistance", 999)
				char:SetAttribute("MaxLunge", 999)
				LocalPlayer:SetAttribute("LungeDuration", 999)
			end)
		end
		if KillerCombat.UnlockCarrySkill then
			pcall(function()
				char:SetAttribute("CanUseSkillWhileCarrying", true)
				char:SetAttribute("BlockSkillCarry", false)
				LocalPlayer:SetAttribute("CanUseSkillWhileCarrying", true)
			end)
		end
	end

	if KillerCombat.AutoAttack then
		if now - KillerCombat.LastAttackAt >= (tonumber(KillerCombat.AttackCooldown) or 0.15) then
			local _, targetPart = KC_GetNearestSurvivor(tonumber(KillerCombat.AttackRange) or 12)
			if targetPart then
				KillerCombat.LastAttackAt = now
				pcall(function()
					local tool = char:FindFirstChildWhichIsA("Tool")
					if tool then
						tool:Activate()
					elseif type(mouse1click) == "function" then
						mouse1click()
					end
				end)
			end
		end
	end

	if KillerCombat.AimlockAttack then
		local _, targetPart = KC_GetNearestSurvivor(tonumber(KillerCombat.LockDistance) or 15)
		if targetPart then
			local flatGoal = Vector3.new(targetPart.Position.X, root.Position.Y, targetPart.Position.Z)
			if (flatGoal - root.Position).Magnitude > 0.1 then
				local targetCF = CFrame.lookAt(root.Position, flatGoal)
				local smooth = tonumber(KillerCombat.SmoothLock) or 0
				pcall(function()
					if smooth <= 0 then
						root.CFrame = targetCF
					else
						local alpha = math.clamp((dt * 12) / smooth, 0.05, 1)
						root.CFrame = root.CFrame:Lerp(targetCF, alpha)
					end
				end)
			end
		end
	end

	if KillerCombat.CounterParry then
		if now - KillerCombat.LastCounterAt >= 0.25 then
			local _, nearPart = KC_GetNearestSurvivor(15)
			if nearPart then
				KillerCombat.LastCounterAt = now
				pcall(function()
					local tool = char:FindFirstChildWhichIsA("Tool")
					if tool then tool:Activate() end
				end)
			end
		end
	end

	if KillerCombat.AutoHook and char:GetAttribute("IsCarrying") == true then
		if now - KillerCombat.LastHookAt >= 0.25 then
			KillerCombat.LastHookAt = now
			KC_TriggerMatchingPrompt(root.Position, {"hook"})
		end
	end

	if KillerCombat.AutoDestroyPallet then
		if now - KillerCombat.LastPalletAt >= 0.4 then
			KillerCombat.LastPalletAt = now
			KC_TriggerMatchingPrompt(root.Position, {"pallet", "break", "destroy"})
		end
	end
end)
end

-- ============================================================
-- KILLER CD HUD (VERSI SURVIVOR - NGELACAK TIM KILLER)
-- ============================================================
local KillerCDHUD = (function()
    local Players            = game:GetService("Players")
    local RunService         = game:GetService("RunService")
    local UserInputService   = game:GetService("UserInputService")
    local CollectionService  = game:GetService("CollectionService")
    local ReplicatedStorage  = game:GetService("ReplicatedStorage")
    local LP                 = Players.LocalPlayer

    local K = { Enabled = false }

    local MOVES = {
        Slasher = { name = "Slasher", move1 = "rbxassetid://134862031194933", move2 = "rbxassetid://136973921948245", move1Name = "Lake of Mist", move2Name = "Pursuit", move1CD = 30, move2CD = 60, missCD = 1.4 },
        Stalker = { name = "Stalker", move1 = "rbxassetid://85894094209457", move2 = "rbxassetid://110045688062234", move1Name = "Hunt Mode", move2Name = "Evil Surge", move1CD = 30, move2CD = 40, missCD = 1.5 },
        Masked = { name = "Masked", move1 = "rbxassetid://110441838520158", move2 = "rbxassetid://95375588266919", move1Name = "Frenzy Sprint", move2Name = "Mask Swap", move1CD = 30, move2CD = 30, missCD = 1.5 },
        Killer = { name = "Nina", move1 = "rbxassetid://108114231850675", move2 = "rbxassetid://95375588266919", move1Name = "Shadow Step", move2Name = "Agony Lunge", move1CD = 30, move2CD = 30, missCD = 1.5 },
        Hidden = { name = "Hidden", move1 = "rbxassetid://129570234771869", move2 = "rbxassetid://130915693370693", move1Name = "Phantom Dash", move2Name = "Leap Vault", move1CD = 20, move2CD = 20, missCD = 1.5 },
        Abysswalker = { name = "Abysswalker", move1 = "rbxassetid://86213737463907", move2 = "rbxassetid://100395868673407", move1Name = "Abyssal Wave", move2Name = "Shadow Leap", move1CD = 30, move2CD = 6, missCD = 1.5 },
        Veil = { name = "Veil", move1 = "rbxassetid://110881025348309", move2 = "rbxassetid://95375588266919", move1Name = "Spear Throw", move2Name = "Spear Reload", move1CD = 30, move2CD = 3.5, missCD = 1.5 },
        Cure = { name = "The Cure", move1 = "rbxassetid://119792658841268", move2 = "rbxassetid://81019828986691", move1Name = "Elucidation", move2Name = "Gas Cloud", move1CD = 15, move2CD = 15, missCD = 1.5 },
        Butcher = { name = "Butcher", move1 = "rbxassetid://121475438777829", move2 = "rbxassetid://95375588266919", move1Name = "Chain Throw", move2Name = "Bear Trap", move1CD = 15, move2CD = 45, missCD = 1.5 },
    }
    local THEME = {
        Veil = Color3.fromRGB(0,150,255), Abysswalker = Color3.fromRGB(168,85,247), Butcher = Color3.fromRGB(239,68,68),
        Cure = Color3.fromRGB(34,197,94), Masked = Color3.fromRGB(244,63,94), Slasher = Color3.fromRGB(249,115,22),
        Stalker = Color3.fromRGB(148,163,184), Hidden = Color3.fromRGB(99,102,241), Killer = Color3.fromRGB(217,119,6),
    }
    local M1_ICON = "rbxassetid://123571635310131"
    local RED, GREEN, AMBER = Color3.fromRGB(244,63,94), Color3.fromRGB(52,230,150), Color3.fromRGB(251,191,36)

    local H = {
        Gui = nil, Frame = nil, Rows = {}, Conns = {}, UIConns = {}, RemoteConns = {},
        Active = nil, Type = "Unknown", Moves = MOVES.Veil,
        Att = {Until=0,Total=1.5}, S1 = {Until=0,Total=30}, S2 = {Until=0,Total=12},
        Action = {Text="",Until=0,Total=0}, ToastUntil=0, Min=false,
    }

    local function new(cls, props, parent)
        local obj = Instance.new(cls)
        for k,v in pairs(props) do obj[k] = v end
        if parent then obj.Parent = parent end
        return obj
    end
    local function corner(obj, radius)
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,radius); c.Parent = obj
    end
    local function track(conn) table.insert(H.Conns,conn); return conn end
    local function clear(list) for _,conn in ipairs(list) do pcall(function() conn:Disconnect() end) end table.clear(list) end
    local function trig(slot,duration) slot.Until = os.clock() + duration; slot.Total = duration end
    local function triggerAttack(d) trig(H.Att,d or 1.5) end
    
    local function toast(skill,duration)
        if not H.Toast then return end
        local theme = THEME[H.Type] or Color3.fromRGB(168,85,247)
        H.ToastText.Text = ("%s  •  %s  •  CD %.1fs"):format(string.upper(H.Moves.name or H.Type),skill,duration)
        H.ToastStroke.Color = theme; H.ToastIcon.ImageColor3 = theme
        H.Toast.Visible = true; H.ToastUntil = os.clock()+2.5
    end
    
    local function triggerSkill1(d) local f=H.S1.Until<os.clock(); trig(H.S1,d or H.Moves.move1CD); if f then toast(H.Moves.move1Name,H.S1.Total) end end
    local function triggerSkill2(d) local f=H.S2.Until<os.clock(); trig(H.S2,d or H.Moves.move2CD); if f then toast(H.Moves.move2Name,H.S2.Total) end end
    local function triggerSafe(txt,d,col) H.Action.Text,H.Action.Until,H.Action.Total,H.Action.Color=txt,os.clock()+d,d,col or GREEN end
    
    local function guiParent()
        local ok,hui = pcall(function() return gethui and gethui() end)
        if ok and typeof(hui)=="Instance" then return hui end
        local core = game:GetService("CoreGui")
        local okCore = pcall(function() local f=Instance.new("Folder"); f.Parent=core; f:Destroy() end)
        if okCore then return core end
        return LP:WaitForChild("PlayerGui")
    end

    local function makeRow(parent,order,iconImage,nameText)
        local row = new("Frame",{Size=UDim2.new(1,0,0,27),BackgroundTransparency=1,LayoutOrder=order},parent)
        local icon = new("ImageLabel",{Position=UDim2.new(0,9,0.5,-9),Size=UDim2.fromOffset(18,18),BackgroundTransparency=1,Image=iconImage or "rbxassetid://10709798433",ScaleType=Enum.ScaleType.Fit},row)
        corner(icon,4)
        local name = new("TextLabel",{Position=UDim2.new(0,34,0,0),Size=UDim2.new(1,-92,1,0),BackgroundTransparency=1,Text=nameText or "-",TextColor3=Color3.fromRGB(235,235,245),Font=Enum.Font.GothamBold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},row)
        local tm = new("TextLabel",{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-10,0,0),Size=UDim2.fromOffset(55,26),BackgroundTransparency=1,Text="READY",TextColor3=GREEN,Font=Enum.Font.GothamBold,TextSize=10,TextXAlignment=Enum.TextXAlignment.Right},row)
        local bg = new("Frame",{Position=UDim2.new(0,34,1,-2),Size=UDim2.new(1,-46,0,2),BackgroundColor3=Color3.fromRGB(40,40,52),BorderSizePixel=0,Visible=false},row)
        local bar = new("Frame",{Size=UDim2.fromScale(0,1),BackgroundColor3=RED,BorderSizePixel=0},bg)
        return {Row=row,Icon=icon,Name=name,Time=tm,BarBg=bg,Bar=bar}
    end

    local function separator(parent,order)
        new("Frame",{Size=UDim2.new(1,-18,0,1),Position=UDim2.new(0,9,0,0),BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=0.88,BorderSizePixel=0,LayoutOrder=order or 1},parent)
    end

    local function paintRow(r,remaining,total)
        if remaining>0 then
            r.Time.Text=("%.1fs"):format(remaining); r.Time.TextColor3=RED; r.BarBg.Visible=true
            r.Bar.Size=UDim2.fromScale(math.clamp(remaining/math.max(.01,total),0,1),1); r.Icon.ImageTransparency=.5
        else
            r.Time.Text="READY"; r.Time.TextColor3=GREEN; r.BarBg.Visible=false; r.Icon.ImageTransparency=0
        end
    end

    local function buildUI()
        if H.Gui then return end
        local gui = new("ScreenGui",{Name="KinonKillerCD_Merged",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=997,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},guiParent())
        H.Gui=gui
        local frame = new("Frame",{Name="UnifiedPanel",Size=UDim2.fromOffset(155,0),AutomaticSize=Enum.AutomaticSize.Y,Position=UDim2.new(.015,0,.12,0),BackgroundColor3=Color3.fromRGB(22,23,31),BackgroundTransparency=.24,BorderSizePixel=0,Active=true},gui)
        corner(frame,11)
        new("UIStroke",{Color=Color3.fromRGB(120,135,165),Transparency=.55,Thickness=1},frame)
        new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,2)},frame)
        new("UIPadding",{PaddingTop=UDim.new(0,4),PaddingBottom=UDim.new(0,7)},frame)
        H.Frame=frame

        local head=new("Frame",{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,LayoutOrder=1},frame)
        new("TextLabel",{Position=UDim2.new(0,11,0,0),Size=UDim2.new(1,-80,1,0),BackgroundTransparency=1,Text="Killer CD",TextColor3=Color3.fromRGB(240,242,250),Font=Enum.Font.GothamBold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left},head)
        
        H.Portrait=new("ImageLabel",{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-9,.5,0),Size=UDim2.fromOffset(21,21),BackgroundColor3=Color3.fromRGB(40,40,52),BorderSizePixel=0,Image="rbxassetid://10709798433",ScaleType=Enum.ScaleType.Crop},head)
        corner(H.Portrait,6)
        H.PortraitStroke=new("UIStroke",{Color=Color3.fromRGB(0,170,255),Transparency=.35,Thickness=1.3},H.Portrait)
        
        H.MinBtn=new("TextButton",{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-39,.5,0),Size=UDim2.fromOffset(20,20),BackgroundColor3=Color3.fromRGB(43,46,59),BorderSizePixel=0,Text="−",TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold,TextSize=14,AutoButtonColor=false},head)
        corner(H.MinBtn,6)

        local info=new("Frame",{Size=UDim2.new(1,0,0,22),BackgroundTransparency=1,LayoutOrder=2},frame)
        H.KillerLbl=new("TextLabel",{Position=UDim2.new(0,11,0,0),Size=UDim2.new(1,-75,1,0),BackgroundTransparency=1,Text="Killer: -",TextColor3=Color3.fromRGB(170,174,190),Font=Enum.Font.GothamMedium,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},info)
        H.DistLbl=new("TextLabel",{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-10,0,0),Size=UDim2.fromOffset(62,25),BackgroundTransparency=1,Text="--m",TextColor3=GREEN,Font=Enum.Font.GothamBold,TextSize=10,TextXAlignment=Enum.TextXAlignment.Right},info)
        
        separator(frame,3)
        
        H.Rows.Attack=makeRow(frame,4,M1_ICON,"Attack")
        H.Rows.S1=makeRow(frame,5,"rbxassetid://10709798433","-")
        H.Rows.S2=makeRow(frame,6,"rbxassetid://10709798433","-")
        
        separator(frame,7)
        
        local autoRow=new("Frame",{Size=UDim2.new(1,0,0,27),BackgroundTransparency=1,LayoutOrder=8},frame)
        H.Rows.Safe=makeRow(frame,9,"rbxassetid://10709798433"); H.Rows.Safe.Row.Visible=false
        new("TextLabel",{Position=UDim2.new(0,10,0,0),Size=UDim2.new(1,-62,1,0),BackgroundTransparency=1,Text="Auto ON",TextColor3=Color3.fromRGB(235,235,245),Font=Enum.Font.GothamBold,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left},autoRow)
        H.AutoBtn=new("TextButton",{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-10,.5,0),Size=UDim2.fromOffset(35,18),BackgroundColor3=GREEN,BorderSizePixel=0,Text="",AutoButtonColor=false},autoRow)
        corner(H.AutoBtn,9)
        H.AutoKnob=new("Frame",{Position=UDim2.fromOffset(19,2),Size=UDim2.fromOffset(14,14),BackgroundColor3=Color3.fromRGB(255,255,255),BorderSizePixel=0},H.AutoBtn)
        corner(H.AutoKnob,7)

        local function paintControls()
            local on=K.Enabled==true
            H.AutoBtn.BackgroundColor3=on and GREEN or Color3.fromRGB(75,78,91)
            H.AutoKnob.Position=on and UDim2.fromOffset(19,2) or UDim2.fromOffset(2,2)
        end
        H.PaintControls=paintControls
        
        H.AutoBtn.MouseButton1Click:Connect(function() K.SetEnabled(not K.Enabled); paintControls() end)
        H.Min=false
        H.MinBtn.MouseButton1Click:Connect(function()
            H.Min=not H.Min
            H.MinBtn.Text=H.Min and "+" or "−"
            for _,child in ipairs(frame:GetChildren()) do
                if child:IsA("GuiObject") then
                    local order=child.LayoutOrder
                    if order>=2 and order<=9 then child.Visible=not H.Min end
                end
            end
        end)

        local dragging,dragStart,startPos
        table.insert(H.UIConns,frame.InputBegan:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
                dragging,dragStart,startPos=true,input.Position,frame.Position
                input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then dragging=false end end)
            end
        end))
        table.insert(H.UIConns,UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
                local delta=input.Position-dragStart
                frame.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
            end
        end))
        table.insert(H.UIConns,UserInputService.InputBegan:Connect(function(input,gp)
            if not gp and input.KeyCode==Enum.KeyCode.RightControl then
                K.SetEnabled(not K.Enabled)
                if H.PaintControls then H.PaintControls() end
            end
        end))

        H.Toast=new("Frame",{Name="SkillToast",AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,.09,0),Size=UDim2.fromOffset(0,26),AutomaticSize=Enum.AutomaticSize.X,BackgroundColor3=Color3.fromRGB(22,23,31),BackgroundTransparency=.04,BorderSizePixel=0,Visible=false},gui)
        corner(H.Toast,8)
        H.ToastStroke=new("UIStroke",{Color=Color3.fromRGB(0,170,255),Transparency=.2,Thickness=1.2},H.Toast)
        new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,VerticalAlignment=Enum.VerticalAlignment.Center,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,6)},H.Toast)
        new("UIPadding",{PaddingLeft=UDim.new(0,9),PaddingRight=UDim.new(0,10)},H.Toast)
        H.ToastIcon=new("ImageLabel",{Size=UDim2.fromOffset(14,14),BackgroundTransparency=1,Image="rbxassetid://10709798433",LayoutOrder=1},H.Toast)
        H.ToastText=new("TextLabel",{Size=UDim2.fromOffset(0,26),AutomaticSize=Enum.AutomaticSize.X,BackgroundTransparency=1,Text="",TextColor3=Color3.fromRGB(235,235,245),Font=Enum.Font.GothamBold,TextSize=10,LayoutOrder=2},H.Toast)
        paintControls()
    end

    -- Logic untuk nyari Killer
    local function isKillerChar(char)
        if not char or not char:IsA("Model") or char==LP.Character or not char:FindFirstChildOfClass("Humanoid") then return false end
        local plr=Players:GetPlayerFromCharacter(char)
        if plr==LP then return false end
        if char:GetAttribute("Role")=="Killer" or char:GetAttribute("IsKiller")==true then return true end
        if plr and plr.Team then
            local team=string.lower(plr.Team.Name)
            if team:find("killer") or team:find("slasher") then return true end
        end
        return false
    end
    local function findKiller()
        for _,tag in ipairs(CollectionService:GetTagged("Killer")) do
            local model=tag:IsA("Model") and tag or tag:FindFirstAncestorOfClass("Model")
            if model and model~=LP.Character and model:FindFirstChild("HumanoidRootPart") then return model end
        end
        for _,plr in ipairs(Players:GetPlayers()) do if plr~=LP and plr.Character and isKillerChar(plr.Character) then return plr.Character end end
        return nil
    end
    
    local function resolveType(char)
        local name=char:GetAttribute("MorphedKiller") or char:GetAttribute("SelectedKiller")
        local plr=Players:GetPlayerFromCharacter(char)
        if not name and plr then name=plr:GetAttribute("SelectedKiller") or plr:GetAttribute("Killer") end
        if not name and MOVES[char.Name] then name=char.Name end
        if not name then for key in pairs(MOVES) do if string.find(string.lower(char.Name),string.lower(key),1,true) then name=key; break end end end
        if name and not MOVES[name] then name=nil end
        return name or "Veil"
    end

    local function bind(char)
        if not char or char==H.Active then return end
        clear(H.Conns)
        H.Active=char
        local kType=resolveType(char); H.Type=kType; H.Moves=MOVES[kType] or MOVES.Veil
        local moves=H.Moves; local theme=THEME[kType] or Color3.fromRGB(168,85,247)
        local plr=Players:GetPlayerFromCharacter(char)
        
        H.S1.Total,H.S2.Total,H.Att.Total=moves.move1CD,moves.move2CD,moves.missCD
        H.S1.Until,H.S2.Until,H.Att.Until=0,0,0
        
        if H.Gui then
            H.KillerLbl.Text="Killer: "..(plr and (plr.DisplayName~="" and plr.DisplayName or plr.Name) or moves.name)
            H.PortraitStroke.Color=theme; H.PortraitStroke.Transparency=0
            if plr and plr.UserId>0 then H.Portrait.Image=("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150"):format(plr.UserId) end
            
            H.Rows.S1.Icon.Image=moves.move1; H.Rows.S2.Icon.Image=moves.move2
            H.Rows.S1.Name.Text=moves.move1Name; H.Rows.S2.Name.Text=moves.move2Name
        end
        
        local hum=char:FindFirstChildOfClass("Humanoid")
        local animator=hum and hum:FindFirstChildOfClass("Animator")
        
        -- KARENA KITA JADI SURVIVOR, KITA CUMA BISA DENGERIN ANIMASI DARI REMOTE / NGE-LOOP
        -- Tapi ini tetep jalan kok buat ngeliat CD pas killer lagi deket.
        local function hookAnim(anim)
            track(anim.AnimationPlayed:Connect(function(trk)
                local id=(trk.Animation and trk.Animation.AnimationId) or ""
                local name=string.lower(trk.Name or "")
                local m1=moves.move1:match("%d+"); local m2=moves.move2:match("%d+")
                if (m1 and id:find(m1,1,true)) or name:find("flask") or name:find("spear") or name:find("chain") or name:find("wave") or name:find("mist") then
                    triggerSkill1(moves.move1CD)
                elseif (m2 and id:find(m2,1,true)) or name:find("gas") or name:find("inject") or name:find("trap") or name:find("leap") or name:find("frenzy") or name:find("stalk") or name:find("reload") or name:find("pursuit") or name:find("mask") then
                    triggerSkill2(moves.move2CD)
                elseif name:find("attack") or name:find("swing") or name:find("lunge") or name:find("slash") or id:find("113691709436161",1,true) then
                    triggerAttack(moves.missCD)
                elseif trk.Priority==Enum.AnimationPriority.Action or trk.Priority==Enum.AnimationPriority.Action2 or trk.Priority==Enum.AnimationPriority.Action3 or trk.Priority==Enum.AnimationPriority.Action4 then
                    triggerAttack(moves.missCD)
                end
            end))
        end
        if animator then hookAnim(animator) else track(char.DescendantAdded:Connect(function(d) if d:IsA("Animator") then hookAnim(d) end end)) end
        
        track(char.AttributeChanged:Connect(function(attr)
            local value=char:GetAttribute(attr)
            if (attr=="isBreakingPallet" or attr=="isBreaking") and value==true then triggerSafe("Breaking Pallet",2.16,GREEN)
            elseif attr=="isBreakingGen" and value==true then triggerSafe("Kicking Generator",1.90,AMBER)
            elseif attr=="isVaulting" and value==true then triggerSafe("Vaulting Window",1.525,Color3.fromRGB(6,182,212))
            elseif (attr=="IsStunned" or attr=="isTrueStunned") and value==true then triggerSafe("Pallet Stunned",3,RED)
            elseif attr=="isAttacking" or attr=="isLunging" then if value==true then triggerAttack(moves.missCD) end
            elseif attr=="ChainMove1CD" then if type(value)=="number" and value>0 then triggerSkill1(math.max(value,15)) end
            elseif attr=="PlacingTrap" and value==true then triggerSkill2(45) end
        end))
        
        local function hookWeapon(weapon)
            if not weapon then return end
            for _,desc in ipairs(weapon:GetDescendants()) do
                if desc:IsA("Trail") and desc:GetAttribute("SwingTrail") then
                    track(desc:GetPropertyChangedSignal("Enabled"):Connect(function() if desc.Enabled then triggerAttack(moves.missCD) end end))
                end
            end
        end
        hookWeapon(char:FindFirstChild("Weapon"))
        track(char.ChildAdded:Connect(function(child) if child.Name=="Weapon" then hookWeapon(child) end end))
        track(workspace.ChildAdded:Connect(function(child)
            local name=string.lower(child.Name)
            if name:find("flask") then triggerSkill1(15) elseif name:find("spear") then triggerSkill1(30) elseif name:find("wave") then triggerSkill1(30) end
        end))
    end

    -- LOOP UTAMA (Di sini kita pantau jarak dan nge-bind ulang kalau killer ganti)
    local accumulator=0
    local function render(dt)
        if not K.Enabled or not H.Gui then return end
        accumulator=accumulator+dt; if accumulator<.05 then return end; accumulator=0
        if not H.Active or not H.Active.Parent then
            H.Active=nil
            local killer=findKiller()
            if killer then bind(killer) else H.KillerLbl.Text="Killer: -"; H.DistLbl.Text="--m" end
        end
        local now=os.clock()
        if H.Toast and H.Toast.Visible and now>H.ToastUntil then H.Toast.Visible=false end
        
        -- Nampilin Jarak (Distance)
        local root=H.Active and H.Active:FindFirstChild("HumanoidRootPart")
        local mine=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if root and mine then
            local distance=(root.Position-mine.Position).Magnitude
            H.DistLbl.Text=("%dm"):format(math.floor(distance))
            H.DistLbl.TextColor3=distance<25 and RED or (distance<50 and AMBER or GREEN)
        else
            H.DistLbl.Text="--m"
        end
        
        paintRow(H.Rows.Attack,H.Att.Until-now,H.Att.Total)
        paintRow(H.Rows.S1,H.S1.Until-now,H.S1.Total)
        paintRow(H.Rows.S2,H.S2.Until-now,H.S2.Total)
        local remaining=H.Action.Until-now; local safe=H.Rows.Safe
        if H.Min then safe.Row.Visible=false
        elseif remaining>0 then
            safe.Row.Visible=true; safe.Name.Text=H.Action.Text; safe.Time.Text=("%.1fs"):format(remaining)
            safe.Time.TextColor3=H.Action.Color or GREEN; safe.BarBg.Visible=true
            safe.Bar.BackgroundColor3=H.Action.Color or GREEN
            safe.Bar.Size=UDim2.fromScale(math.clamp(remaining/math.max(.01,H.Action.Total),0,1),1)
        else safe.Row.Visible=false; safe.BarBg.Visible=false end
    end

    local stepConn
    function K.SetEnabled(value,legacyValue)
        local on=(type(value)=="table" and value==K) and legacyValue or value
        K.Enabled=(on==true)
        if K.Enabled then
            buildUI()
            local killer=findKiller(); if killer then bind(killer) end
            if stepConn then stepConn:Disconnect() end
            stepConn=RunService.RenderStepped:Connect(render)
        else
            K.Destroy()
        end
        if H.PaintControls then H.PaintControls() end
    end
    function K.SetCompact(value)
        if not H.Gui then return end
        local want = value == true
        if H.Min ~= want and H.MinBtn then
            for _, conn in ipairs(getconnections and getconnections(H.MinBtn.MouseButton1Click) or {}) do pcall(function() conn:Fire() end) end
        end
    end
    function K.StopMonitoring()
        K.Enabled=false
        if stepConn then stepConn:Disconnect(); stepConn=nil end
        clear(H.Conns); clear(H.RemoteConns); H.Active=nil
        if H.PaintControls then H.PaintControls() end
    end
    function K.Destroy()
        K.StopMonitoring()
        clear(H.UIConns)
        if H.Gui then pcall(function() H.Gui:Destroy() end) end
        H.Gui,H.Frame=nil,nil
        table.clear(H.Rows)
    end
    return K
end)()

getgenv().KillerCDHUD = KillerCDHUD

do
	local NS = { On = false, Conn = nil, Base = 17, Until = 0 }
	local genvA = (getgenv and getgenv()) or _G
	local AF = genvA.TianAntiFall or { On = false }
	genvA.TianAntiFall = AF
	AF.On = false
	local afConn
	local afFallActive = false
	local afFallStart = nil

	local function isKillerRole()
		if type(TianHub_IsKiller) == "function" then
			local ok, res = pcall(TianHub_IsKiller, LocalPlayer)
			if ok then return res == true end
		end
		local team = LocalPlayer.Team and string.lower(LocalPlayer.Team.Name) or ""
		if string.find(team, "killer", 1, true) then return true end
		local ch = LocalPlayer.Character
		return (ch and (ch:GetAttribute("Role") == "Killer" or ch:GetAttribute("IsKiller") == true))
			or LocalPlayer:GetAttribute("Role") == "Killer"
			or LocalPlayer:GetAttribute("IsKiller") == true
	end

	local function getTargetWalkSpeed(hum)
		local ch = LocalPlayer.Character
		local attrSpeed = (ch and (ch:GetAttribute("BaseSpeed") or ch:GetAttribute("NormalWalkSpeed")))
			or LocalPlayer:GetAttribute("BaseSpeed")
			or LocalPlayer:GetAttribute("NormalWalkSpeed")
		if type(attrSpeed) == "number" and attrSpeed > 0 then
			return attrSpeed
		end
		if hum and hum.WalkSpeed > 18 then
			return hum.WalkSpeed
		end
		return NS.Base
	end

	local function restoreFallSpeed(hum, duration)
		local ch = LocalPlayer.Character
		local targetSpeed = getTargetWalkSpeed(hum)
		NS.Until = math.max(NS.Until, os.clock() + duration)
		if hum and hum.Parent and hum.WalkSpeed < targetSpeed - 0.05 then
			pcall(function() hum.WalkSpeed = targetSpeed end)
		end
		if ch then
			pcall(function()
				if ch:GetAttribute("FallSlow") then ch:SetAttribute("FallSlow", false) end
				if ch:GetAttribute("LandingSlow") then ch:SetAttribute("LandingSlow", false) end
				if ch:GetAttribute("IsSlowed") then ch:SetAttribute("IsSlowed", false) end
			end)
		end
	end

	local function nsAttach(hum)
		if NS.Conn then NS.Conn:Disconnect(); NS.Conn = nil end
		if not hum then return end
		NS.Conn = RunService.Heartbeat:Connect(function()
			if not NS.On or os.clock() > NS.Until or not hum.Parent then return end
			if isKillerRole() then return end
			local ch = LocalPlayer.Character
			if ch and (ch:GetAttribute("IsHooked") or ch:GetAttribute("IsCarried") or hum.Health <= 50) then return end
			local targetSpeed = getTargetWalkSpeed(hum)
			if hum.WalkSpeed < targetSpeed - 0.05 then
				pcall(function() hum.WalkSpeed = targetSpeed end)
			end
		end)
	end

	local function afAttach(hum)
		if afConn then afConn:Disconnect(); afConn = nil end
		afFallActive = false
		afFallStart = nil
		if not hum then return end
		afConn = hum.StateChanged:Connect(function(_, new)
			if not AF.On then return end
			if new == Enum.HumanoidStateType.Freefall then
				if not afFallActive then
					afFallActive = true
					afFallStart = os.clock()
				end
			elseif new == Enum.HumanoidStateType.Landed
				or (afFallActive and (new == Enum.HumanoidStateType.Running or new == Enum.HumanoidStateType.RunningNoPhysics or new == Enum.HumanoidStateType.GettingUp)) then
				local fell = afFallStart and (os.clock() - afFallStart) > 0.22
				afFallActive = false
				afFallStart = nil
				if not fell or isKillerRole() then return end

				task.spawn(function()
					local t0 = os.clock()
					while AF.On and hum.Parent and os.clock() - t0 < 1.6 do
						local ch = LocalPlayer.Character
						if ch and hum.Health > 0 and not (ch:GetAttribute("IsHooked") or ch:GetAttribute("IsCarried")) then
							restoreFallSpeed(hum, 0.25)
						end
						RunService.Heartbeat:Wait()
					end
				end)
			end
		end)
	end

	if hookmetamethod and not genvA.TianFallHooked then
		genvA.TianFallHooked = true
		task.spawn(function()
			local okF, fall = pcall(function()
				return ReplicatedStorage:WaitForChild("Remotes", 10):WaitForChild("Mechanics", 10):WaitForChild("Fall", 10)
			end)
			if not okF or not fall then genvA.TianFallHooked = false; return end
			local old
			local wrap = newcclosure or function(f) return f end
			old = hookmetamethod(game, "__namecall", wrap(function(self, ...)
				local cur = genvA.TianAntiFall
				local method = getnamecallmethod and getnamecallmethod() or ""
				if cur and cur.On and (method == "FireServer" or method == "fireServer") and rawequal(self, fall) then
					if setnamecallmethod then pcall(setnamecallmethod, method) end
					return nil
				end
				if setnamecallmethod then pcall(setnamecallmethod, method) end
				return old(self, ...)
			end))
		end)
	end

	if TianHubState then
		TianHubState.SetAntiFallDamage = function(enabled)
			AF.On = enabled and true or false
			local ch = LocalPlayer.Character
			local hum = ch and ch:FindFirstChildOfClass("Humanoid")
			if AF.On then
				afAttach(hum)
			elseif afConn then
				afConn:Disconnect()
				afConn = nil
			end
		end
	end

	LocalPlayer.CharacterAdded:Connect(function(ch)
		local hum = ch:WaitForChild("Humanoid", 5)
		if NS.On then nsAttach(hum) end
		if AF.On then afAttach(hum) end
	end)

	if surv_card then
		surv_card("ANTI FALL SLOW", function(_, ui)
			ui.toggle("Anti Fall Slow", false, function(v: boolean)
				AF.On = v
				local ch = LocalPlayer.Character
				local hum = ch and ch:FindFirstChildOfClass("Humanoid")
				if v then
					afAttach(hum)
				else
					if afConn then afConn:Disconnect(); afConn = nil end
				end
			end)
		end)
	end
end

-- ============================================================
--  HANX HUB SURVIVOR MOONWALK
-- ============================================================
local Players = Players or game:GetService("Players")
local RunService = RunService or game:GetService("RunService")
local UserInputService = UserInputService or game:GetService("UserInputService")
local LocalPlayer = LocalPlayer or Players.LocalPlayer

do
	local MW = { On = false, Spam = 35, Intensity = 30, Float = nil }
	local setMoonwalkUI

	local function bindConn(name, conn)
		if type(setConn) == "function" then
			setConn(name, conn)
		end
		return conn
	end

	bindConn("Hanx_Moonwalk", RunService.RenderStepped:Connect(function()
		if not MW.On then return end
		local c = LocalPlayer and LocalPlayer.Character
		local hum = c and c:FindFirstChildOfClass("Humanoid")
		local hrp = c and c:FindFirstChild("HumanoidRootPart")
		local cam = workspace.CurrentCamera
		if not hum or not hrp or not cam or hum.Health <= 0 then return end
		local st = c:GetAttribute("State")
		if st == "Downed" or st == "Dead" then return end

		if hum.AutoRotate ~= false then hum.AutoRotate = false end
		local look, right = cam.CFrame.LookVector, cam.CFrame.RightVector
		local unit = Vector3.new(look.X, 0, look.Z)
		if unit.Magnitude > 0.001 then unit = unit.Unit end
		local unit2 = Vector3.new(right.X, 0, right.Z)
		if unit2.Magnitude > 0.001 then unit2 = unit2.Unit end
		local sw = math.sin(tick() * MW.Spam)
		local face = CFrame.Angles(0, math.rad(MW.Intensity * sw), 0) * unit
		hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + face)
		hum:Move(-unit * 1.2 + unit2 * (sw * 1.05), false)
	end))

	local function label()
		return MW.On and "MOON ON" or "MOON OFF"
	end

	local function setMoonwalk(v)
		MW.On = v == true
		if not MW.On then
			local c = LocalPlayer and LocalPlayer.Character
			local hum = c and c:FindFirstChildOfClass("Humanoid")
			if hum then hum.AutoRotate = true end
		end
		if MW.Float and MW.Float.SetText then
			MW.Float.SetText(label())
		end
	end

	local function makeFallbackFloat(text, pos, onClick)
		local parentGui = (gethui and gethui()) or game:GetService("CoreGui")
		local old = parentGui:FindFirstChild("HanxMoonwalkFloatGui")
		if old then old:Destroy() end

		local sg = Instance.new("ScreenGui")
		sg.Name = "HanxMoonwalkFloatGui"
		sg.ResetOnSpawn = false
		sg.Parent = parentGui

		local btn = Instance.new("TextButton")
		btn.Name = "HanxMoonwalkButton"
		btn.Size = UDim2.new(0, 110, 0, 36)
		btn.Position = pos
		btn.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 13
		btn.Text = text
		btn.Active = true
		btn.Draggable = true
		btn.Parent = sg

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = btn

		btn.MouseButton1Click:Connect(function()
			if onClick then onClick() end
		end)

		return {
			SetText = function(t)
				if btn and btn.Parent then btn.Text = t end
			end,
			Destroy = function()
				if sg and sg.Parent then sg:Destroy() end
			end,
		}
	end

	local function toggleMoonwalkAll()
		local nextState = not MW.On
		if type(setMoonwalkUI) == "function" then
			pcall(setMoonwalkUI, nextState)
		end
		setMoonwalk(nextState)
	end

	local function setFloat(on)
		if MW.Float and MW.Float.Destroy then
			MW.Float.Destroy()
			MW.Float = nil
		end
		if on then
			if TianHubState and type(TianHubState.MakeFloat) == "function" then
				MW.Float = TianHubState.MakeFloat("TianMoonwalkButton", label(), UDim2.new(0.85, 0, 0.45, 0), toggleMoonwalkAll)
			else
				MW.Float = makeFallbackFloat(label(), UDim2.new(0.85, 0, 0.45, 0), toggleMoonwalkAll)
			end
		end
	end

	bindConn("Hanx_MoonwalkKey", UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.KeyCode == Enum.KeyCode.B then
			toggleMoonwalkAll()
		end
	end))

	if surv_card then
		surv_card("MOONWALK", function(_, ui)
			setMoonwalkUI = ui.toggle("Moonwalk", false, function(v: boolean)
				setMoonwalk(v)
			end)
			ui.toggle("Show Floating Button Moonwalk", false, function(v: boolean)
				setFloat(v)
			end)
			ui.slider("Spam Speed", 1, 50, 35, function(v: number)
				MW.Spam = tonumber(v) or 35
			end)
			ui.slider("Intensity", 1, 60, 30, function(v: number)
				MW.Intensity = tonumber(v) or 30
			end)
		end)
	end
end

-- Taruh blok fungsi & state ini DI ATAS --========== TOF AIM =============--
local FlashState = {
	Active = false,
	LaserBeam = nil,
	FlashlightPart = nil,
	Hooked = false,
	Enabled = false,
	TargetPart = "Head",
	Range = 120,
	Smooth = 0.35,
	ShowLaser = false,
}

local FlashTargetParts = { "Head", "UpperTorso", "Torso", "HumanoidRootPart" }
local FlashTargetIdx = 1

local function Flash_IsKillerTarget(plr: Player): boolean
	if not plr or plr == lp then
		return false
	end
	if type(is_killer) == "function" then
		local ok, res = pcall(is_killer, plr)
		if ok then
			return res == true
		end
	end
	local char = plr.Character
	if char and (char:FindFirstChild("Killer") or char:GetAttribute("IsKiller") == true) then
		return true
	end
	if plr.Team and string.find(string.lower(plr.Team.Name), "killer", 1, true) then
		return true
	end
	return false
end

local function Flash_GetActivateRemote()
	local r = ReplicatedStorage:FindFirstChild("Remotes")
	local i = r and r:FindFirstChild("Items")
	local f = i and i:FindFirstChild("Flashlight")
	local a = f and f:FindFirstChild("Activate")
	if a and a:IsA("RemoteEvent") then
		return a
	end
end

local function Flash_GetTargetPart(char: Model?)
	if not char then
		return nil
	end
	local part = char:FindFirstChild(FlashState.TargetPart or "Head")
	if part and part:IsA("BasePart") then
		return part
	end
	return char:FindFirstChild("Head")
		or char:FindFirstChild("UpperTorso")
		or char:FindFirstChild("Torso")
		or char:FindFirstChild("HumanoidRootPart")
end

local function Flash_GetTarget()
	local myChar = lp.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	if not myRoot then
		return nil
	end
	local best, bestD = nil, math.huge
	local maxRange = tonumber(FlashState.Range) or 120
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= lp and plr.Character and Flash_IsKillerTarget(plr) then
			local hum = plr.Character:FindFirstChildOfClass("Humanoid")
			local part = hum and hum.Health > 0 and Flash_GetTargetPart(plr.Character)
			if part then
				local d = (myRoot.Position - part.Position).Magnitude
				if d <= maxRange and d < bestD then
					best, bestD = part, d
				end
			end
		end
	end
	return best
end

local function Flash_ClearLaser()
	if FlashState.LaserBeam then
		pcall(function()
			FlashState.LaserBeam:Destroy()
		end)
		FlashState.LaserBeam = nil
	end
end

local function Flash_UpdateLaser(origin: Vector3, target: Vector3)
	if not FlashState.LaserBeam then
		local beam = Instance.new("Part")
		beam.Name = "HanxSilentFlashlightLaser"
		beam.Anchored = true
		beam.CanCollide = false
		beam.CanTouch = false
		beam.CanQuery = false
		beam.CastShadow = false
		beam.Material = Enum.Material.Neon
		beam.Color = Color3.fromRGB(255, 255, 255)
		beam.Transparency = 0.35
		beam.Parent = workspace
		FlashState.LaserBeam = beam
	end
	local dist = (target - origin).Magnitude
	if dist < 0.1 then
		return
	end
	local beam = FlashState.LaserBeam
	beam.Size = Vector3.new(0.16, 0.16, dist)
	beam.CFrame = CFrame.new((origin + target) / 2, target)
	beam.Transparency = 0.35
end

local function Flash_GetOrigin(cam: Camera?)
	local src = FlashState.FlashlightPart
	if typeof(src) == "Instance" then
		if src:IsA("BasePart") then
			return src.Position
		end
		local part = src:FindFirstChildWhichIsA("BasePart", true)
		if part then
			return part.Position
		end
	end
	local char = lp.Character
	local hand = char and (char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm") or char:FindFirstChild("HumanoidRootPart"))
	if hand and hand:IsA("BasePart") then
		return hand.Position
	end
	return cam and cam.CFrame.Position
end

local function Flash_Step()
	if not (FlashState.Enabled and FlashState.Active) then
		if FlashState.LaserBeam then
			FlashState.LaserBeam.Transparency = 1
		end
		return
	end
	local cam = workspace.CurrentCamera
	local target = Flash_GetTarget()
	if not (cam and target) then
		if FlashState.LaserBeam then
			FlashState.LaserBeam.Transparency = 1
		end
		return
	end
	local smooth = math.clamp(tonumber(FlashState.Smooth) or 0.35, 0.05, 1)
	local origin = Flash_GetOrigin(cam)
	if FlashState.ShowLaser and origin then
		pcall(Flash_UpdateLaser, origin, target.Position)
	elseif FlashState.LaserBeam then
		FlashState.LaserBeam.Transparency = 1
	end
	pcall(function()
		cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, target.Position), smooth)
	end)
	pcall(function()
		local char = lp.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root then
			root.CFrame = CFrame.new(root.Position, Vector3.new(target.Position.X, root.Position.Y, target.Position.Z))
		end
	end)
end

local function Flash_SetActive(active: boolean, part: any)
	FlashState.Active = active and true or false
	FlashState.FlashlightPart = FlashState.Active and part or nil
	if not FlashState.Active and FlashState.LaserBeam then
		FlashState.LaserBeam.Transparency = 1
	end
end

local function Flash_InstallHook()
	if FlashState.Hooked or type(hookmetamethod) ~= "function" or type(getnamecallmethod) ~= "function" then
		return
	end
	local remote = Flash_GetActivateRemote()
	if not remote then
		return
	end
	local oldNamecall
	oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
		if self == remote and getnamecallmethod() == "FireServer" then
			local args = { ... }
			pcall(function()
				Flash_SetActive(args[2] == true, args[1])
			end)
		end
		return oldNamecall(self, ...)
	end)
	FlashState.Hooked = true
end

local flashConn
local function Flash_SetEnabled(v: boolean)
	FlashState.Enabled = v and true or false
	if v then
		if not flashConn then
			flashConn = RunService.RenderStepped:Connect(function()
				pcall(Flash_Step)
			end)
		end
		task.spawn(function()
			for _ = 1, 20 do
				pcall(Flash_InstallHook)
				if FlashState.Hooked then
					break
				end
				task.wait(0.25)
			end
		end)
	else
		if flashConn then
			flashConn:Disconnect()
			flashConn = nil
		end
		FlashState.Active = false
		FlashState.FlashlightPart = nil
		Flash_ClearLaser()
	end
end

--========== TOF AIM =============--

surv_card("Twist of Fate", function(_, ui)
	ui.toggle("TOF Silent Aim", false, function(v: boolean)
		TOF_Bridge.Set(v)
	end)
	ui.toggle("Smart Predict", false, function(v: boolean)
		tof_st.SmartPredict = v
	end)
	ui.toggle("Show FOV Circle", false, function(v: boolean)
		tof_st.ShowCircle = v
	end)
	ui.toggle("Show Aim Laser", false, function(v: boolean)
		tof_st.ShowLaser = v
	end)
	ui.toggle("Use Snap (NetRemote)", false, function(v: boolean)
		tof_st.UseSnap = v
	end)
	ui.toggle("Use Travel Time", false, function(v: boolean)
		tof_st.UseTravel = v
	end)
	ui.toggle("Wall Check", false, function(v: boolean)
		tof_st.WallCheck = v
	end)
	ui.slider("FOV", 10, 360, tof_st.FOV, function(v: number)
		tof_st.FOV = v
	end)
	ui.slider("Line Smooth", 0, 100, tof_st.LineSmooth, function(v: number)
		tof_st.LineSmooth = v
	end)
end)

surv_card("Silent Flashlight", function(_, ui)
	ui.toggle("Enable Silent Flashlight", false, function(v: boolean)
		pcall(Flash_SetEnabled, v)
	end)
	local targetBtn
	targetBtn = ui.button("Target Part: " .. FlashState.TargetPart, function()
		FlashTargetIdx = (FlashTargetIdx % #FlashTargetParts) + 1
		FlashState.TargetPart = FlashTargetParts[FlashTargetIdx]
		targetBtn.Text = "Target Part: " .. FlashState.TargetPart
	end)
	ui.slider("Max Range", 20, 250, FlashState.Range, function(v: number)
		FlashState.Range = tonumber(v) or 120
	end)
	ui.slider("Smoothness", 0.05, 1, FlashState.Smooth, function(v: number)
		FlashState.Smooth = tonumber(v) or 0.35
	end)
	ui.toggle("Show Laser", FlashState.ShowLaser, function(v: boolean)
		FlashState.ShowLaser = v
		if not v then
			Flash_ClearLaser()
		end
	end)
end)

--========== TOF AIM =============--

surv_card("SKILLCHECK TRAPS", function(_, ui)
	ui.toggle("Auto Skill Check Trap", false, function(v: boolean)
		TrapEngine.AutoTrapSC = v == true
		TrapEngine.TrapLastLine = nil
		TrapEngine.TrapBusy = false
		TrapGuiCache.Check = nil
		TrapGuiCache.Line = nil
		TrapGuiCache.Target = nil
		TrapGuiCache.NextScan = 0
	end)

	local methodButton
	local function formatTrapMethodLabel()
		local mode = tostring(TrapEngine.TrapMode or "Legit")
		return mode .. " [Tap]"
	end

	local function applyMethodButtonStyle()
		if not methodButton then
			return
		end
		methodButton.Text = formatTrapMethodLabel()
		pcall(function()
			methodButton.TextTruncate = Enum.TextTruncate.AtEnd
			methodButton.TextSize = 11
		end)
	end

	methodButton = ui.button(formatTrapMethodLabel(), function()
		TrapEngine.TrapMode = TrapEngine.TrapMode == "Legit" and "Instant" or "Legit"
		TrapEngine.TrapLastLine = nil
		TrapGuiCache.Check = nil
		TrapGuiCache.Line = nil
		TrapGuiCache.Target = nil
		TrapGuiCache.NextScan = 0
		applyMethodButtonStyle()
	end)

	applyMethodButtonStyle()
end)

surv_card("Twist of Fate", function(_, ui)
	ui.toggle("TOF Silent Aim", false, function(v: boolean)
		TOF_Bridge.Set(v)
	end)
	ui.toggle("Smart Predict", false, function(v: boolean)
		tof_st.SmartPredict = v
	end)
	ui.toggle("Show FOV Circle", false, function(v: boolean)
		tof_st.ShowCircle = v
	end)
	ui.toggle("Show Aim Laser", false, function(v: boolean)
		tof_st.ShowLaser = v
	end)
	ui.toggle("Use Snap (NetRemote)", false, function(v: boolean)
		tof_st.UseSnap = v
	end)
	ui.toggle("Use Travel Time", false, function(v: boolean)
		tof_st.UseTravel = v
	end)
	ui.toggle("Wall Check", false, function(v: boolean)
		tof_st.WallCheck = v
	end)
	ui.slider("FOV", 10, 360, tof_st.FOV, function(v: number)
		tof_st.FOV = v
	end)
	ui.slider("Line Smooth", 0, 100, tof_st.LineSmooth, function(v: number)
		tof_st.LineSmooth = v
	end)
end)

surv_card("KILLER CD HUD (SURVIVOR)", function(_, ui)
    -- Toggle buat nyalain HUD-nya
    ui.toggle("Show Killer CD & Distance", false, function(v: boolean)
        if getgenv().KillerCDHUD then
            getgenv().KillerCDHUD.SetEnabled(v)
        end
    end)
    
    -- Toggle buat versi kecil
    ui.toggle("Compact Mode", false, function(v: boolean)
        if getgenv().KillerCDHUD then
            getgenv().KillerCDHUD.SetCompact(v)
        end
    end)
end)

surv_card("AUTO PARRY", function(_, ui)
	ui.toggle("AUTO PARRY", false, function(v: boolean)
		AP.SetEnabled(v)
		AP.SetAggressiveMode(v)
	end, "auto_parry")
	ui.toggle("ESP RANGE", false, function(v: boolean)
		AP.SetRangeESP(v)
	end)
	ui.slider("PARRY RADIUS", 5, 35, AP.Range, function(v: number)
		AP.SetRange(v)
	end)
	ui.slider("PARRY DELAY (MS)", 0, 350, AP.DelayMs, function(v: number)
		AP.SetDelay(v)
	end)
	ui.slider("FACE SENSITIVITY", 0, 10, AP.FaceSensitivity, function(v: number)
		AP.SetFaceSensitivity(v)
	end)
	ui.toggle("Killer Trace", false, function(v: boolean)
		VisualESP.KillerFOV.LineEnabled = v
		if type(kf_sync_loop) == "function" then
			kf_sync_loop()
		end
	end)
	ui.toggle("Threat Scope", false, function(v: boolean)
		VisualESP.KillerFOV.SensorEnabled = v
		if type(kf_sync_loop) == "function" then
			kf_sync_loop()
		end
	end)
	ui.slider("Trace Range", 10, 100, 50, function(v: number)
		VisualESP.KillerFOV.AlwaysLength = v
	end)
end)

surv_card("SKILLCHECK GENERATOR", function(_, ui)
	ui.toggle("Auto Skill Check", false, function(v: boolean)
		AutoSkill.Active = v == true
		if not AutoSkill.Active then
			AS_Reset()
			AS_ApplySpeed(false)
		end
	end)

	local modeButton
	local function formatGenModeLabel()
		local mode = tostring(AutoSkill.Mode or "Normal")
		if mode ~= "Normal" and mode ~= "Perfect" then
			mode = "Normal"
			AutoSkill.Mode = mode
		end
		return mode .. " [Tap]"
	end

	local function applyGenModeButtonStyle()
		if not modeButton then
			return
		end
		modeButton.Text = formatGenModeLabel()
		pcall(function()
			modeButton.TextTruncate = Enum.TextTruncate.AtEnd
			modeButton.TextSize = 11
		end)
	end

	modeButton = ui.button(formatGenModeLabel(), function()
		AutoSkill.Mode = AutoSkill.Mode == "Normal" and "Perfect" or "Normal"
		AS_Reset()
		applyGenModeButtonStyle()
	end)

	applyGenModeButtonStyle()

	if ui.slider then
		ui.slider("Skill Check Speed", 0.1, 3, AutoSkill.Speed, function(v)
			AutoSkill.Speed = math.clamp(tonumber(v) or 1, 0.1, 3)
			if AutoSkill.Active then
				AS_ApplySpeed(true)
			end
		end)
	end
end)

-- ============================================================
--  HANX HUB VISUALS ESP ENGINE (PLAYER, KILLER, MAP, TRAP, FOV)
-- ============================================================
local v_clear_beartrap, v_refresh_player_esp, v_scan_map, v_start_beartrap, v_sync_windows, v_cleanup_all
do
VisualESP = {
	PlayerESP = {
		Player = false,
		KillerEnabled = false,
		PlayerName = true,
		KillerName = true,
		PlayerShowDistance = true,
		Status = true,
		HookCount = false, -- Tidak lagi memaksa survivor ESP nyala sendiri
		ItemIcon = false,
		KillerWarn = false,
		SurvivorColor = Color3.fromRGB(64, 224, 208),
		KillerColor = Color3.fromRGB(255, 55, 55),
		SurvivorDistance = 500,
		FillTransparency = 0.55,
		OutlineAll = false,
	},
	MapESP = {
		Generator = false,
		Hook = false,
		Gate = false,
		ShowOnlyClosest = false,
		ShowProgress = true,
		ShowOutline = true,
		GeneratorColor = Color3.fromRGB(255, 255, 255),
		HookColor = Color3.fromRGB(255, 105, 180),
		GateColor = Color3.fromRGB(255, 255, 255),
	},
	ObjectESP = {
		Pallet = false,
		Vault = false,
		Window = false,
		Pumpkin = false,
		SCP = false,
		Distance = 500,
		Cached = false,
	},
	BearTrap = {
		Enabled = false,
		Color = Color3.fromRGB(180, 120, 255),
		MaxDistance = 500,
		Highlights = setmetatable({}, { __mode = "k" }),
		Generation = 0,
	},
	KillerFOV = {
		LineEnabled = false,
		SensorEnabled = false,
		AlwaysLength = 50,
		LineObjects = setmetatable({}, { __mode = "k" }),
		SensorObjects = setmetatable({}, { __mode = "k" }),
		Connection = nil,
	},
}

local VisualConns = {}
local function v_set_conn(key, conn)
	if VisualConns[key] then
		pcall(function() VisualConns[key]:Disconnect() end)
		VisualConns[key] = nil
	end
	VisualConns[key] = conn
end

local function v_is_killer(plr)
	if not plr then return false end
	if plr.Team and string.lower(plr.Team.Name) == "killer" then
		return true
	end
	local role = plr:GetAttribute("Role") or plr:GetAttribute("Team") or plr:GetAttribute("Class")
	if typeof(role) == "string" and string.lower(role) == "killer" then
		return true
	end
	local sel = plr:GetAttribute("SelectedKiller")
	if sel ~= nil and tostring(sel) ~= "" and tostring(sel) ~= "None" then
		return true
	end
	return false
end

-- --- A. PLAYER & KILLER ESP ---
local function v_clear_player_esp()
	for _, plr in ipairs(Players:GetPlayers()) do
		local ch = plr.Character
		if ch then
			for _, n in ipairs({ "PE_Text", "KE_Text", "PEH", "KEH", "KillerWarn" }) do
				local o = ch:FindFirstChild(n)
				if o then pcall(function() o:Destroy() end) end
			end
			local hrp = ch:FindFirstChild("HumanoidRootPart")
			local kw = hrp and hrp:FindFirstChild("KillerWarn")
			if kw then pcall(function() kw:Destroy() end) end
		end
	end
end

local function v_get_status(character)
	if not character then return nil end
	if character:GetAttribute("IsHooked") == true then return "HOOKED" end
	if character:GetAttribute("Knocked") == true then return "DOWN" end
	local hum = character:FindFirstChildOfClass("Humanoid")
	if hum and hum.Health > 0 and hum.Health < hum.MaxHealth then return "INJURED" end
	return nil
end

local function v_create_tag(character, key, name_str, info_rich, status_str, color)
	local gui = character:FindFirstChild(key)
	if not gui then
		gui = Instance.new("BillboardGui")
		gui.Name = key
		gui.AlwaysOnTop = true
		gui.Size = UDim2.fromOffset(110, 24)
		gui.StudsOffset = Vector3.new(0, 0.85, 0)
		gui.MaxDistance = 0
		gui.Adornee = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart") or character:FindFirstChildWhichIsA("BasePart")
		gui.Parent = character

		local wrapper = Instance.new("Frame")
		wrapper.Name = "Wrapper"
		wrapper.AutomaticSize = Enum.AutomaticSize.XY
		wrapper.Position = UDim2.new(0.5, 0, 0.5, -3)
		wrapper.AnchorPoint = Vector2.new(0.5, 1)
		wrapper.BackgroundTransparency = 1
		wrapper.Parent = gui

		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Vertical
		layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.Padding = UDim.new(0, 0)
		layout.Parent = wrapper

		local status_lbl = Instance.new("TextLabel")
		status_lbl.Name = "StatusText"
		status_lbl.AutomaticSize = Enum.AutomaticSize.X
		status_lbl.Size = UDim2.fromOffset(0, 8)
		status_lbl.BackgroundTransparency = 1
		status_lbl.Font = Enum.Font.GothamBold
		status_lbl.TextSize = 9
		status_lbl.TextStrokeTransparency = 0.25
		status_lbl.LayoutOrder = 1
		status_lbl.Parent = wrapper

		local box = Instance.new("Frame")
		box.Name = "Box"
		box.AutomaticSize = Enum.AutomaticSize.X
		box.Size = UDim2.fromOffset(0, 14)
		box.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
		box.BackgroundTransparency = 0.12
		box.BorderSizePixel = 0
		box.LayoutOrder = 2
		box.Parent = wrapper
		round_all(box, 4)
		pad_all(box, 0, 0, 6, 6)

		local row = Instance.new("UIListLayout")
		row.FillDirection = Enum.FillDirection.Horizontal
		row.VerticalAlignment = Enum.VerticalAlignment.Center
		row.HorizontalAlignment = Enum.HorizontalAlignment.Center
		row.Padding = UDim.new(0, 4)
		row.Parent = box

		local name_lbl = Instance.new("TextLabel")
		name_lbl.Name = "Name"
		name_lbl.AutomaticSize = Enum.AutomaticSize.X
		name_lbl.Size = UDim2.new(0, 0, 1, 0)
		name_lbl.BackgroundTransparency = 1
		name_lbl.Font = Enum.Font.GothamBold
		name_lbl.TextSize = 9
		name_lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		name_lbl.TextStrokeTransparency = 0.35
		name_lbl.LayoutOrder = 1
		name_lbl.Parent = box

		local info_lbl = Instance.new("TextLabel")
		info_lbl.Name = "Info"
		info_lbl.AutomaticSize = Enum.AutomaticSize.X
		info_lbl.Size = UDim2.new(0, 0, 1, 0)
		info_lbl.BackgroundTransparency = 1
		info_lbl.Font = Enum.Font.GothamMedium
		info_lbl.TextSize = 9
		info_lbl.TextColor3 = Color3.fromRGB(230, 230, 230)
		info_lbl.RichText = true
		info_lbl.LayoutOrder = 2
		info_lbl.Parent = box
	end

	local wrapper = gui:FindFirstChild("Wrapper")
	local box = wrapper and wrapper:FindFirstChild("Box")
	local status_lbl = wrapper and wrapper:FindFirstChild("StatusText")
	local name_lbl = box and box:FindFirstChild("Name")
	local info_lbl = box and box:FindFirstChild("Info")

	if name_lbl then
		name_lbl.Text = name_str or ""
		name_lbl.Visible = (name_str ~= nil and name_str ~= "")
	end
	if info_lbl then
		info_lbl.Text = info_rich
		info_lbl.Visible = (info_rich ~= "")
	end
	if status_lbl then
		status_lbl.Text = status_str or ""
		status_lbl.Visible = (status_str ~= nil and status_str ~= "")
		if status_str == "HOOKED" then
			status_lbl.TextColor3 = Color3.fromRGB(255, 50, 50)
		elseif status_str == "DOWN" then
			status_lbl.TextColor3 = Color3.fromRGB(255, 150, 50)
		elseif status_str == "INJURED" then
			status_lbl.TextColor3 = Color3.fromRGB(255, 255, 50)
		else
			status_lbl.TextColor3 = color
		end
	end
end

local function v_apply_player_esp(plr, cam_pos)
	if plr == LocalPlayer or not plr.Parent then return end
	local char = plr.Character
	local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso"))
	if not char or not root then return end

	local pe = VisualESP.PlayerESP
	local killer = v_is_killer(plr)
	local enabled = killer and pe.KillerEnabled or (not killer and pe.Player)
	local tag_name = killer and "KE_Text" or "PE_Text"
	local hl_name = killer and "KEH" or "PEH"
	local other_tag = killer and "PE_Text" or "KE_Text"
	local other_hl = killer and "PEH" or "KEH"
	local color = killer and pe.KillerColor or pe.SurvivorColor
	local dist = (cam_pos - root.Position).Magnitude

	local stale_other = char:FindFirstChild(other_tag)
	if stale_other then pcall(function() stale_other:Destroy() end) end
	local stale_hl = char:FindFirstChild(other_hl)
	if stale_hl then pcall(function() stale_hl:Destroy() end) end

	if not enabled or dist > (tonumber(pe.SurvivorDistance) or 500) then
		for _, n in ipairs({ tag_name, hl_name }) do
			local old = char:FindFirstChild(n)
			if old then pcall(function() old:Destroy() end) end
		end
		return
	end

	local hl = char:FindFirstChild(hl_name)
	if not hl then
		hl = Instance.new("Highlight")
		hl.Name = hl_name
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.Parent = char
	end
	hl.Enabled = true
	hl.Adornee = char
	hl.FillColor = color
	hl.OutlineColor = color
	if killer then
		hl.FillTransparency = math.clamp(tonumber(pe.FillTransparency) or 0.55, 0.25, 0.8)
	else
		hl.FillTransparency = pe.OutlineAll and 1 or (tonumber(pe.FillTransparency) or 0.55)
	end
	hl.OutlineTransparency = 0

	local d_int = math.floor(dist + 0.5)
	local status_s = (not killer and pe.Status) and v_get_status(char) or nil
	local hook_val = (not killer and pe.HookCount) and (tonumber(plr:GetAttribute("HookCount")) or 0) or nil
	local hook_roman = (hook_val and hook_val > 0) and (hook_val == 1 and "I" or hook_val == 2 and "II" or "III") or nil

	local name_s = (killer and pe.KillerName or (not killer and pe.PlayerName)) and plr.Name or nil
	if killer and name_s then
		local sel = plr:GetAttribute("SelectedKiller")
		if sel and tostring(sel) ~= "" then name_s = tostring(sel) end
	end

	local info_parts = {}
	if pe.PlayerShowDistance then
		table.insert(info_parts, string.format('<font color="#00FF00">[%ds]</font>', d_int))
	end
	if hook_roman then
		table.insert(info_parts, string.format('<font color="#FF4444">[%s]</font>', hook_roman))
	end
	local info_rich = table.concat(info_parts, " ")

	if name_s or info_rich ~= "" or status_s then
		v_create_tag(char, tag_name, name_s, info_rich, status_s, color)
	else
		local old = char:FindFirstChild(tag_name)
		if old then pcall(function() old:Destroy() end) end
	end
end

local function v_update_killer_warn()
	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or not VisualESP.PlayerESP.KillerWarn or v_is_killer(LocalPlayer) then
		local old = root and root:FindFirstChild("KillerWarn")
		if old then pcall(function() old:Destroy() end) end
		return
	end
	local nearest = math.huge
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and v_is_killer(plr) and plr.Character then
			local kr = plr.Character:FindFirstChild("HumanoidRootPart")
			if kr then nearest = math.min(nearest, (kr.Position - root.Position).Magnitude) end
		end
	end
	local warn_gui = root:FindFirstChild("KillerWarn")
	if nearest <= 80 then
		if not warn_gui then
			warn_gui = Instance.new("BillboardGui")
			warn_gui.Name = "KillerWarn"
			warn_gui.Size = UDim2.fromOffset(30, 30)
			warn_gui.AlwaysOnTop = true
			warn_gui.StudsOffset = Vector3.new(0, 4, 0)
			warn_gui.Parent = root
			local lbl = Instance.new("TextLabel")
			lbl.Name = "WarnText"
			lbl.Size = UDim2.fromScale(1, 1)
			lbl.BackgroundTransparency = 1
			lbl.TextScaled = true
			lbl.TextStrokeTransparency = 0
			lbl.Font = Enum.Font.GothamBlack
			lbl.Parent = warn_gui
		end
		local lbl = warn_gui:FindFirstChild("WarnText")
		if lbl then
			lbl.Text = nearest <= 40 and "!!" or "!"
			lbl.TextColor3 = nearest <= 40 and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 255, 0)
		end
	elseif warn_gui then
		pcall(function() warn_gui:Destroy() end)
	end
end

function v_refresh_player_esp()
	local pe = VisualESP.PlayerESP
	if pe.Player or pe.KillerEnabled or pe.KillerWarn then
		if not VisualConns["PlayerESP"] then
			local last = 0
			v_set_conn("PlayerESP", RunService.Heartbeat:Connect(function()
				local now = os.clock()
				if now - last < 0.35 then return end
				last = now
				local cam = workspace.CurrentCamera
				if not cam then return end
				local pos = cam.CFrame.Position
				for _, plr in ipairs(Players:GetPlayers()) do
					pcall(v_apply_player_esp, plr, pos)
				end
				pcall(v_update_killer_warn)
			end))
		end
	else
		v_set_conn("PlayerESP", nil)
		v_clear_player_esp()
	end
end

-- --- B. MAP ESP (GENERATOR + PROGRESS, HOOK, GATE) ---
local v_gens, v_hooks, v_gates = {}, {}, {}
local v_map_hls = setmetatable({}, { __mode = "k" })
local v_gen_labels = setmetatable({}, { __mode = "k" })
local v_map_state = { scan_last = 0, scan_busy = false, upd_last = 0 }

local function v_target_part(obj)
	if not obj or not obj.Parent then return nil end
	if obj:IsA("BasePart") then return obj end
	if obj:IsA("Model") or obj:IsA("Folder") then
		return obj:FindFirstChild("HookPoint", true)
			or (obj:IsA("Model") and obj.PrimaryPart)
			or obj:FindFirstChild("Handle", true)
			or obj:FindFirstChildWhichIsA("BasePart", true)
	end
	return nil
end

local function v_clear_map_hl(obj)
	local h = v_map_hls[obj]
	if h then pcall(function() h:Destroy() end) end
	v_map_hls[obj] = nil
	if obj and obj.Parent then
		local old = obj:FindFirstChild("__HanxMapOutline")
		if old then pcall(function() old:Destroy() end) end
	end
end

local function v_clear_gen_label(obj)
	local g = v_gen_labels[obj]
	if g then pcall(function() g:Destroy() end) end
	v_gen_labels[obj] = nil
	if obj and obj.Parent then
		local old = obj:FindFirstChild("__HanxGenProgress")
		if old then pcall(function() old:Destroy() end) end
	end
end

local function v_apply_map_hl(obj, col)
	if not obj or not obj.Parent then return end
	local adornee = obj:IsA("Model") and obj or v_target_part(obj)
	if not adornee then return end
	local h = v_map_hls[obj]
	if not h or not h.Parent then
		h = Instance.new("Highlight")
		h.Name = "__HanxMapOutline"
		h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		h.Parent = obj
		v_map_hls[obj] = h
	end
	h.Adornee = adornee
	h.Enabled = true
	h.FillColor = col
	h.OutlineColor = col
	h.FillTransparency = VisualESP.MapESP.ShowOutline and 1 or VisualESP.PlayerESP.FillTransparency
	h.OutlineTransparency = 0
end

local function v_gen_progress(model)
	for _, key in ipairs({ "RepairProgress", "ProgressRepair", "Progress", "Repair" }) do
		local val = model:GetAttribute(key)
		if typeof(val) == "number" then
			return math.clamp(math.floor(val), 0, 100)
		end
	end
	return 0
end

local function v_update_gen_label(model, idx, col)
	local part = v_target_part(model)
	if not part then return end
	local gui = v_gen_labels[model]
	if not gui or not gui.Parent then
		gui = Instance.new("BillboardGui")
		gui.Name = "__HanxGenProgress"
		gui.Size = UDim2.fromOffset(110, 24)
		gui.StudsOffset = Vector3.new(0, 2.2, 0)
		gui.AlwaysOnTop = true
		gui.Adornee = part
		gui.Parent = model

		local lbl = Instance.new("TextLabel")
		lbl.Name = "Progress"
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.BackgroundTransparency = 1
		lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
		lbl.TextStrokeTransparency = 0
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 9
		lbl.Parent = gui
		v_gen_labels[model] = gui
	end
	local lbl = gui:FindFirstChild("Progress")
	if lbl then
		local prog = v_gen_progress(model)
		local rep = tonumber(model:GetAttribute("PlayersRepairingCount")) or 0
		lbl.Text = rep > 0 and string.format("GEN%d [%d%%] (%d plyr)", idx, prog, rep)
			or string.format("GEN%d [%d%%]", idx, prog)
		lbl.TextColor3 = col
	end
end

function v_scan_map()
	if v_map_state.scan_busy then return end
	v_map_state.scan_busy = true
	task.spawn(function()
		pcall(function()
			local map = workspace:FindFirstChild("Map")
			local root = map or workspace
			local gen_list, hook_list, gate_list = {}, {}, {}
			local seen_g, seen_h, seen_gt = {}, {}, {}
			for _, inst in ipairs(root:GetDescendants()) do
				if inst.Name == "Generator" or inst.Name == "GeneratorPoint" then
					local g_obj = inst
					if inst.Name == "GeneratorPoint" then
						local pm = inst:FindFirstAncestorWhichIsA("Model")
						if pm and pm.Name == "Generator" then g_obj = pm end
					end
					if not seen_g[g_obj] and v_target_part(g_obj) then
						seen_g[g_obj] = true
						table.insert(gen_list, g_obj)
					end
				elseif inst.Name == "Hook" or inst.Name == "HookPoint" then
					local h_obj = inst
					if inst.Name == "HookPoint" or inst:IsA("BasePart") then
						local pm = inst:FindFirstAncestorWhichIsA("Model")
						if pm and pm.Name == "Hook" then h_obj = pm end
					end
					if not seen_h[h_obj] and v_target_part(h_obj) then
						seen_h[h_obj] = true
						table.insert(hook_list, h_obj)
					end
				end
				if inst.Name == "ExitLever" or inst.Name == "ExitGate" then
					local gt_obj = inst:IsA("Model") and inst or (inst:FindFirstAncestorWhichIsA("Model") or inst)
					if not seen_gt[gt_obj] and v_target_part(gt_obj) then
						seen_gt[gt_obj] = true
						table.insert(gate_list, gt_obj)
					end
				end
			end
			for _, o in ipairs(v_gens) do if not seen_g[o] then v_clear_map_hl(o); v_clear_gen_label(o) end end
			for _, o in ipairs(v_hooks) do if not seen_h[o] then v_clear_map_hl(o) end end
			for _, o in ipairs(v_gates) do if not seen_gt[o] then v_clear_map_hl(o) end end
			v_gens, v_hooks, v_gates = gen_list, hook_list, gate_list
		end)
		v_map_state.scan_busy = false
	end)
end

local function v_closest_obj(list)
	local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not root then return nil end
	local best, bd = nil, math.huge
	for _, o in ipairs(list) do
		local p = v_target_part(o)
		if p then
			local d = (p.Position - root.Position).Magnitude
			if d < bd then best, bd = o, d end
		end
	end
	return best
end

v_set_conn("MapESP", RunService.Heartbeat:Connect(function()
	local now = os.clock()
	if now - v_map_state.upd_last < 0.6 then return end
	v_map_state.upd_last = now

	local me = VisualESP.MapESP
	if not (me.Generator or me.Hook or me.Gate) then
		for _, o in ipairs(v_gens) do v_clear_map_hl(o); v_clear_gen_label(o) end
		for _, o in ipairs(v_hooks) do v_clear_map_hl(o) end
		for _, o in ipairs(v_gates) do v_clear_map_hl(o) end
		return
	end

	if now - v_map_state.scan_last >= 3.5 or (#v_gens == 0 and me.Generator) or (#v_hooks == 0 and me.Hook) or (#v_gates == 0 and me.Gate) then
		v_map_state.scan_last = now
		v_scan_map()
	end

	local cg = me.ShowOnlyClosest and v_closest_obj(v_gens) or nil
	local ch = me.ShowOnlyClosest and v_closest_obj(v_hooks) or nil
	local cgt = me.ShowOnlyClosest and v_closest_obj(v_gates) or nil

	local gi = 0
	for _, o in ipairs(v_gens) do
		if me.Generator and o.Parent and (not me.ShowOnlyClosest or o == cg) then
			gi += 1
			local prog = v_gen_progress(o)
			local col = prog >= 100 and Color3.fromRGB(0, 255, 0) or me.GeneratorColor
			v_apply_map_hl(o, col)
			if me.ShowProgress then v_update_gen_label(o, gi, col) else v_clear_gen_label(o) end
		else
			v_clear_map_hl(o); v_clear_gen_label(o)
		end
	end

	for _, o in ipairs(v_hooks) do
		if me.Hook and o.Parent and (not me.ShowOnlyClosest or o == ch) then
			v_apply_map_hl(o, me.HookColor)
		else
			v_clear_map_hl(o)
		end
	end

	for _, o in ipairs(v_gates) do
		if me.Gate and o.Parent and (not me.ShowOnlyClosest or o == cgt) then
			v_apply_map_hl(o, me.GateColor)
		else
			v_clear_map_hl(o)
		end
	end
end))

-- --- C. OBJECT ESP (PALLET, VAULT/WINDOW, PUMPKIN, SCP) ---
local v_obj_hls, v_pump_lbls, v_win_objs = {}, {}, {}
local v_cache_scp, v_cache_pump, v_cache_pallet = {}, {}, {}

local function v_is_pumpkin(obj)
	local map = workspace:FindFirstChild("Map")
	local ps = map and map:FindFirstChild("Pumpkins")
	return (ps ~= nil and obj:IsDescendantOf(ps) and string.match(obj.Name, "^Pumpkin%d*$") ~= nil)
		or string.match(string.lower(obj.Name), "^pumpkin") ~= nil
end

local function v_cache_inst(obj)
	if not obj or not obj.Parent then return end
	local ln = string.lower(obj.Name)
	if string.find(ln, "scp", 1, true) then v_cache_scp[obj] = true end
	if v_is_pumpkin(obj) then v_cache_pump[obj] = true end
	if obj.Name == "Pallet" or obj.Name == "Palletwrong" or string.find(ln, "pallet", 1, true) then
		v_cache_pallet[obj] = true
	end
end

local function v_get_pos(obj)
	if not obj or not obj.Parent then return nil end
	if obj:IsA("BasePart") then return obj.Position end
	if obj:IsA("Model") then
		local ok, piv = pcall(function() return obj:GetPivot().Position end)
		if ok then return piv end
		local p = obj:FindFirstChildWhichIsA("BasePart", true)
		return p and p.Position or nil
	end
	local p = obj:FindFirstChildWhichIsA("BasePart", true)
	return p and p.Position or nil
end

local function v_set_obj_hl(obj, on, col)
	if not on or not obj or not obj.Parent then
		if v_obj_hls[obj] then pcall(function() v_obj_hls[obj]:Destroy() end); v_obj_hls[obj] = nil end
		return
	end
	local h = v_obj_hls[obj]
	if not h or not h.Parent then
		h = Instance.new("Highlight")
		h.Name = "__HanxObjHL"
		h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		h.Parent = obj
		v_obj_hls[obj] = h
	end
	h.Enabled = true
	h.Adornee = obj
	h.FillColor = col
	h.OutlineColor = col
	h.FillTransparency = tonumber(VisualESP.PlayerESP.FillTransparency) or 0.55
	h.OutlineTransparency = 0.2
end

function v_sync_windows()
	local on = VisualESP.ObjectESP.Window or VisualESP.ObjectESP.Vault
	if not on then
		for m, d in pairs(v_win_objs) do
			if d.hl then pcall(function() d.hl:Destroy() end) end
			if d.box then pcall(function() d.box:Destroy() end) end
			v_win_objs[m] = nil
		end
		return
	end
	local map = workspace:FindFirstChild("Map")
	if not map then return end
	for _, ch in ipairs(map:GetDescendants()) do
		if ch.Name == "VaultTrigger" and ch.Parent and ch.Parent:IsA("Model") and not v_win_objs[ch.Parent] then
			local m = ch.Parent
			local bp = m:FindFirstChild("Bottom") or m:FindFirstChildWhichIsA("BasePart")
			if bp and bp:IsA("BasePart") then
				local box = Instance.new("BoxHandleAdornment")
				box.Name = "HanxWindowBox"
				box.Adornee = bp
				box.Size = bp.Size
				box.Color3 = Color3.fromRGB(60, 255, 255)
				box.Transparency = 0.3
				box.AlwaysOnTop = true
				box.ZIndex = 5
				box.Parent = bp
				local hl = Instance.new("Highlight")
				hl.Name = "HanxWindowHL"
				hl.Adornee = m
				hl.FillColor = Color3.fromRGB(60, 255, 255)
				hl.FillTransparency = tonumber(VisualESP.PlayerESP.FillTransparency) or 0.55
				hl.OutlineColor = Color3.fromRGB(60, 255, 255)
				hl.OutlineTransparency = 0.1
				hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				hl.Parent = m
				v_win_objs[m] = { hl = hl, box = box }
			end
		end
	end
end

v_set_conn("ObjectESP", RunService.Heartbeat:Connect((function()
	local acc = 0
	return function(dt)
		acc += dt
		if acc < 0.6 then return end
		acc = 0
		local oe = VisualESP.ObjectESP
		local any = oe.Pallet or oe.Vault or oe.Window or oe.Pumpkin or oe.SCP
		if not any then
			for o, h in pairs(v_obj_hls) do
				if h then pcall(function() h:Destroy() end) end
				v_obj_hls[o] = nil
			end
			for o, g in pairs(v_pump_lbls) do
				if g then pcall(function() g:Destroy() end) end
				v_pump_lbls[o] = nil
			end
			v_sync_windows()
			return
		end
		if not oe.Cached then
			oe.Cached = true
			for _, d in ipairs(workspace:GetDescendants()) do v_cache_inst(d) end
		end
		v_sync_windows()
		local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if not root then return end

		for o in pairs(v_cache_pallet) do
			if not o.Parent then v_cache_pallet[o] = nil else
				local pos = v_get_pos(o)
				v_set_obj_hl(o, oe.Pallet and pos ~= nil and (pos - root.Position).Magnitude <= oe.Distance, Color3.fromRGB(60, 255, 255))
			end
		end
		for o in pairs(v_cache_scp) do
			if not o.Parent then v_cache_scp[o] = nil else
				local pos = v_get_pos(o)
				v_set_obj_hl(o, oe.SCP and pos ~= nil and (pos - root.Position).Magnitude <= oe.Distance, Color3.fromRGB(255, 0, 255))
			end
		end
		for o in pairs(v_cache_pump) do
			if not o.Parent then v_cache_pump[o] = nil else
				local pos = v_get_pos(o)
				local show = oe.Pumpkin and pos ~= nil and (pos - root.Position).Magnitude <= oe.Distance
				v_set_obj_hl(o, show, Color3.fromRGB(255, 140, 0))
				if show then
					local adornee = o:IsA("BasePart") and o or o:FindFirstChildWhichIsA("BasePart", true)
					if adornee then
						local g = v_pump_lbls[o]
						if not g then
							g = Instance.new("BillboardGui")
							g.Name = "HanxPumpkinTag"
							g.Size = UDim2.fromOffset(120, 20)
							g.StudsOffset = Vector3.new(0, 3, 0)
							g.AlwaysOnTop = true
							g.Adornee = adornee
							g.Parent = adornee
							local tl = Instance.new("TextLabel")
							tl.Name = "Lbl"
							tl.Size = UDim2.fromScale(1, 1)
							tl.BackgroundTransparency = 1
							tl.TextColor3 = Color3.fromRGB(255, 140, 0)
							tl.TextStrokeTransparency = 0.15
							tl.Font = Enum.Font.GothamBold
							tl.TextSize = 9
							tl.Parent = g
							v_pump_lbls[o] = g
						end
						local tl = g:FindFirstChild("Lbl")
						if tl then tl.Text = string.format("PUMPKIN [%d]", math.floor((pos - root.Position).Magnitude + 0.5)) end
					end
				elseif v_pump_lbls[o] then
					pcall(function() v_pump_lbls[o]:Destroy() end)
					v_pump_lbls[o] = nil
				end
			end
		end
	end
end)()))

workspace.DescendantAdded:Connect(function(d)
	v_cache_inst(d)
end)

-- --- D. BEAR TRAP ESP ---
function v_clear_beartrap()
	for o, h in pairs(VisualESP.BearTrap.Highlights) do
		if h then pcall(function() h:Destroy() end) end
		VisualESP.BearTrap.Highlights[o] = nil
	end
end

function v_start_beartrap()
	VisualESP.BearTrap.Generation += 1
	local gen = VisualESP.BearTrap.Generation
	v_clear_beartrap()
	if not VisualESP.BearTrap.Enabled then return end
	task.spawn(function()
		while VisualESP.BearTrap.Enabled and gen == VisualESP.BearTrap.Generation do
			local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			if root then
				for _, o in ipairs(workspace:GetDescendants()) do
					if not VisualESP.BearTrap.Enabled or gen ~= VisualESP.BearTrap.Generation then break end
					local clean = string.lower(o.Name or ""):gsub("[%s_%-]", "")
					if (clean:find("beartrap", 1, true) or clean:find("trap", 1, true)) and not clean:find("skillcheck", 1, true) and (o:IsA("Model") or o:IsA("BasePart")) then
						local part = o:IsA("BasePart") and o or (o:IsA("Model") and (o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart", true)))
						local inRange = part and ((part.Position - root.Position).Magnitude <= (tonumber(VisualESP.BearTrap.MaxDistance) or 500))
						local h = VisualESP.BearTrap.Highlights[o]
						if inRange then
							if not h or not h.Parent then
								h = Instance.new("Highlight")
								h.Name = "HanxBearTrapHL"
								h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
								h.Parent = o
								VisualESP.BearTrap.Highlights[o] = h
							end
							h.Adornee = o
							h.Enabled = true
							h.FillColor = VisualESP.BearTrap.Color
							h.OutlineColor = VisualESP.BearTrap.Color
							h.FillTransparency = tonumber(VisualESP.PlayerESP.FillTransparency) or 0.55
							h.OutlineTransparency = 0
						elseif h then
							pcall(function() h:Destroy() end)
							VisualESP.BearTrap.Highlights[o] = nil
						end
					end
				end
			end
			task.wait(1.2)
		end
	end)
end

-- --- E. KILLER FOV (TRACE BEAM & THREAT SCOPE) ---
VisualESP.KillerFOV.LineCol = Color3.fromRGB(248, 248, 255)
VisualESP.KillerFOV.AtkCol = Color3.fromRGB(199, 21, 133)
VisualESP.KillerFOV.AtkAnims = {
	[75258958842388] = true, [96744338559260] = true, [137846825408335] = true,
	[139928639611415] = true, [92098503722633] = true, [84093948968516] = true,
	[138045669415653] = true, [137688077908355] = true, [117886494230451] = true,
}

VisualESP.KillerFOV.DestroyLine = function(ch)
	local d = VisualESP.KillerFOV.LineObjects[ch]
	if d then
		for _, inst in ipairs({ d.Beam, d.Endpoint, d.A0, d.A1 }) do
			if inst then pcall(function() inst:Destroy() end) end
		end
		VisualESP.KillerFOV.LineObjects[ch] = nil
	end
end

VisualESP.KillerFOV.DestroySensor = function(ch)
	local list = VisualESP.KillerFOV.SensorObjects[ch]
	if list then
		for _, p in ipairs(list) do if p then pcall(function() p:Destroy() end) end end
		VisualESP.KillerFOV.SensorObjects[ch] = nil
	end
end

local function kf_is_in_lobby()
	if workspace:GetAttribute("InLobby") == true or LocalPlayer:GetAttribute("InLobby") == true then
		return true
	end
	local myTeam = LocalPlayer.Team and string.lower(LocalPlayer.Team.Name) or ""
	if myTeam == "" or myTeam:find("lobby", 1, true) or myTeam:find("spectat", 1, true) or myTeam:find("none", 1, true) then
		return true
	end
	return false
end

local function kf_is_valid_killer(plr)
	if not plr or plr == LocalPlayer or not plr.Character then return false end
	if kf_is_in_lobby() then return false end

	local ch = plr.Character
	if not ch:FindFirstChild("Head") or not ch:FindFirstChild("HumanoidRootPart") then return false end

	local function chkNonKiller(inst)
		if not inst then return false end
		local role = string.lower(tostring(inst:GetAttribute("Role") or ""))
		if role == "survivor" or role == "lobby" or role == "spectator" then
			return true
		end
		if inst:GetAttribute("InLobby") == true or inst:GetAttribute("IsSurvivor") == true then
			return true
		end
		return false
	end

	if chkNonKiller(plr) or chkNonKiller(ch) then
		return false
	end

	if plr.Team then
		local t = string.lower(plr.Team.Name)
		if t:find("survivor", 1, true) or t:find("lobby", 1, true) or t:find("spectat", 1, true) or t:find("none", 1, true) then
			return false
		end
		if t:find("killer", 1, true) or t:find("slasher", 1, true) or t:find("hunter", 1, true) or t:find("monster", 1, true) then
			return true
		end
	end

	local function chkKillerAttr(inst)
		if not inst then return false end
		local role = string.lower(tostring(inst:GetAttribute("Role") or ""))
		return role == "killer" or inst:GetAttribute("IsKiller") == true
	end

	if chkKillerAttr(plr) or chkKillerAttr(ch) then
		return true
	end

	local killersFolder = workspace:FindFirstChild("Killers")
	if killersFolder and ch:IsDescendantOf(killersFolder) then
		return true
	end

	return false
end

function kf_sync_loop()
	local kf = VisualESP.KillerFOV
	if not kf.LineEnabled and not kf.SensorEnabled then
		v_set_conn("KillerFOV", nil)
		for ch in pairs(kf.LineObjects) do kf.DestroyLine(ch) end
		for ch in pairs(kf.SensorObjects) do kf.DestroySensor(ch) end
		return
	end
	if VisualConns["KillerFOV"] then return end

	v_set_conn("KillerFOV", RunService.RenderStepped:Connect(function()
		local activeChars = {}

		if not kf_is_in_lobby() then
			for _, plr in ipairs(Players:GetPlayers()) do
				if kf_is_valid_killer(plr) then
					local ch = plr.Character
					activeChars[ch] = true
					local head = ch:FindFirstChild("Head")
					local root = ch:FindFirstChild("HumanoidRootPart")
					if head and root then
						if kf.LineEnabled then
							local d = kf.LineObjects[ch]
							if not d or not d.Endpoint or not d.Endpoint.Parent then
								kf.DestroyLine(ch)
								local ep = Instance.new("Part")
								ep.Name = "HanxKF_Endpoint"
								ep.Anchored, ep.CanCollide, ep.CanTouch, ep.CanQuery, ep.CastShadow = true, false, false, false, false
								ep.Shape = Enum.PartType.Ball
								ep.Material = Enum.Material.Neon
								ep.Size = Vector3.new(0.26, 0.26, 0.26)
								ep.Parent = workspace

								local a0 = Instance.new("Attachment"); a0.Parent = head
								local a1 = Instance.new("Attachment"); a1.Parent = ep
								local bm = Instance.new("Beam")
								bm.Attachment0, bm.Attachment1 = a0, a1
								bm.FaceCamera, bm.LightEmission, bm.LightInfluence = true, 1, 0
								bm.Width0, bm.Width1 = 0.12, 0.12
								bm.Transparency = NumberSequence.new(0.45)
								bm.Parent = ep

								local rp = RaycastParams.new()
								rp.FilterType = Enum.RaycastFilterType.Exclude
								rp.IgnoreWater = true
								rp.FilterDescendantsInstances = { ch, LocalPlayer.Character }
								d = { Beam = bm, Endpoint = ep, A0 = a0, A1 = a1, RayParams = rp }
								kf.LineObjects[ch] = d
							end

							local look = root.CFrame.LookVector.Unit
							local len = math.clamp(tonumber(kf.AlwaysLength) or 50, 10, 100)
							local hit = workspace:Raycast(head.Position, look * len, d.RayParams)
							d.Endpoint.CFrame = CFrame.new(head.Position + look * (hit and math.clamp(hit.Distance - 0.13, 0.12, len) or len))

							local col = kf.LineCol
							local hum = ch:FindFirstChildOfClass("Humanoid")
							local anim = hum and hum:FindFirstChildOfClass("Animator")
							if anim then
								for _, tr in ipairs(anim:GetPlayingAnimationTracks()) do
									if tr.IsPlaying then
										local aid = tonumber(tostring(tr.Animation and tr.Animation.AnimationId or ""):match("%d+"))
										if aid and kf.AtkAnims[aid] then col = kf.AtkCol; break end
									end
								end
							end
							d.Endpoint.Color = col
							d.Beam.Color = ColorSequence.new(col)
						else
							kf.DestroyLine(ch)
						end

						if kf.SensorEnabled then
							local look = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
							if look.Magnitude > 0.01 then
								look = look.Unit
								local right = Vector3.new(-look.Z, 0, look.X)
								local y = root.Position.Y - 3
								local parts = kf.SensorObjects[ch]
								if not parts or #parts ~= 9 then
									kf.DestroySensor(ch)
									parts = {}
									for i = 1, 9 do
										local p = Instance.new("Part")
										p.Name = "HanxKF_Sensor"
										p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = true, false, false, false, false
										p.Material = Enum.Material.Neon
										p.Color = kf.LineCol
										p.Transparency = 0.02
										p.Parent = workspace
										parts[i] = p
									end
									kf.SensorObjects[ch] = parts
								end

								local function seg(p, a, b)
									local delta = b - a
									if delta.Magnitude <= 0.001 then p.Transparency = 1; return end
									p.Transparency = 0.02
									p.Size = Vector3.new(0.0825, 0.0825, delta.Magnitude)
									p.CFrame = CFrame.lookAt((a + b) * 0.5, b)
								end

								local s_pt = Vector3.new(root.Position.X + look.X * 0.8, y, root.Position.Z + look.Z * 0.8)
								local l_end = Vector3.new(root.Position.X + look.X * 11.5 - right.X * 7.85, y, root.Position.Z + look.Z * 11.5 - right.Z * 7.85)
								local r_end = Vector3.new(root.Position.X + look.X * 11.5 + right.X * 7.85, y, root.Position.Z + look.Z * 11.5 + right.Z * 7.85)
								seg(parts[1], s_pt, l_end)
								seg(parts[2], s_pt, r_end)

								local pts = {}
								for i = 0, 7 do
									local t = i / 7
									local w_pt = root.Position + look * (11.5 + math.sin(math.pi * t) * 3) + right * (-7.85 + 15.7 * t)
									pts[i + 1] = Vector3.new(w_pt.X, y, w_pt.Z)
								end
								for i = 1, 7 do
									seg(parts[i + 2], pts[i], pts[i + 1])
								end
							end
						else
							kf.DestroySensor(ch)
						end
					end
				end
			end
		end

		for ch in pairs(kf.LineObjects) do
			if not activeChars[ch] then
				kf.DestroyLine(ch)
			end
		end
		for ch in pairs(kf.SensorObjects) do
			if not activeChars[ch] then
				kf.DestroySensor(ch)
			end
		end
	end))
end

function v_cleanup_all()
	for k, c in pairs(VisualConns) do
		pcall(function() c:Disconnect() end)
		VisualConns[k] = nil
	end
	v_clear_player_esp()
	for _, o in ipairs(v_gens) do v_clear_map_hl(o); v_clear_gen_label(o) end
	for _, o in ipairs(v_hooks) do v_clear_map_hl(o) end
	for _, o in ipairs(v_gates) do v_clear_map_hl(o) end
	for o, h in pairs(v_obj_hls) do if h then pcall(function() h:Destroy() end) end; v_obj_hls[o] = nil end
	for o, g in pairs(v_pump_lbls) do if g then pcall(function() g:Destroy() end) end; v_pump_lbls[o] = nil end
	for m, d in pairs(v_win_objs) do
		if d.hl then pcall(function() d.hl:Destroy() end) end
		if d.box then pcall(function() d.box:Destroy() end) end
		v_win_objs[m] = nil
	end
	v_clear_beartrap()
	for ch in pairs(VisualESP.KillerFOV.LineObjects) do VisualESP.KillerFOV.DestroyLine(ch) end
	for ch in pairs(VisualESP.KillerFOV.SensorObjects) do VisualESP.KillerFOV.DestroySensor(ch) end
end
end

local vis_card = create_page("Visuals", "Visual overlays and highlights", 3)

vis_card("PLAYER & KILLER ESP", function(_, ui)
	ui.toggle("Survivor ESP", false, function(v)
		VisualESP.PlayerESP.Player = v
		v_refresh_player_esp()
	end)
	ui.toggle("Killer ESP", false, function(v)
		VisualESP.PlayerESP.KillerEnabled = v
		v_refresh_player_esp()
	end)
	ui.toggle("Show Names", true, function(v)
		VisualESP.PlayerESP.PlayerName = v
		VisualESP.PlayerESP.KillerName = v
	end)
	ui.toggle("Show Distance", true, function(v)
		VisualESP.PlayerESP.PlayerShowDistance = v
	end)
	ui.toggle("Show Status", true, function(v)
		VisualESP.PlayerESP.Status = v
	end)
	ui.toggle("Show Hook Count", true, function(v)
		VisualESP.PlayerESP.HookCount = v
	end)
	ui.toggle("Killer Warning", false, function(v)
		VisualESP.PlayerESP.KillerWarn = v
		v_refresh_player_esp()
	end)
	ui.slider("ESP Distance", 50, 1000, 500, function(v)
		VisualESP.PlayerESP.SurvivorDistance = v
	end)
end)

vis_card("MAP & GENERATOR ESP", function(_, ui)
	ui.toggle("Generator ESP", false, function(v)
		VisualESP.MapESP.Generator = v
		TrapEngine.GenESP = false
		TH_SyncGenESP()
		v_scan_map()
	end)
	ui.toggle("Show Gen Progress", true, function(v)
		VisualESP.MapESP.ShowProgress = v
	end)
	ui.toggle("Hook ESP", false, function(v)
		VisualESP.MapESP.Hook = v
		v_scan_map()
	end)
	ui.toggle("Gate / Exit Lever ESP", false, function(v)
		VisualESP.MapESP.Gate = v
		v_scan_map()
	end)
	ui.toggle("Show Only Closest", false, function(v)
		VisualESP.MapESP.ShowOnlyClosest = v
	end)
end)

vis_card("OBJECT & TRAP ESP", function(_, ui)
	ui.toggle("Pallet ESP", false, function(v)
		VisualESP.ObjectESP.Pallet = v
	end)
	ui.toggle("Vault / Window ESP", false, function(v)
		VisualESP.ObjectESP.Vault = v
		VisualESP.ObjectESP.Window = v
		v_sync_windows()
	end)
	ui.toggle("Pumpkin ESP", false, function(v)
		VisualESP.ObjectESP.Pumpkin = v
	end)
	ui.toggle("SCP ESP", false, function(v)
		VisualESP.ObjectESP.SCP = v
	end)
	ui.toggle("Bear Trap ESP", false, function(v)
		VisualESP.BearTrap.Enabled = v
		if v then v_start_beartrap() else v_clear_beartrap() end
	end)
	ui.slider("Object Distance", 50, 1000, 500, function(v)
		VisualESP.ObjectESP.Distance = v
		VisualESP.BearTrap.MaxDistance = v
	end)
end)

local kill_card = create_page("Killer", "Killer tracking and chase tools", 4)
kill_card("KILLER COMBAT", function(_, ui)
	ui.toggle("Enable Auto Attack", false, function(v)
		KillerCombat.AutoAttack = v == true
	end)
	ui.slider("Attack Range", 5, 30, 12, " studs", function(v)
		KillerCombat.AttackRange = v
	end)
	ui.slider("Attack Cooldown", 0.05, 1.0, 0.15, "s", function(v)
		KillerCombat.AttackCooldown = v
	end)
	ui.toggle("Infinite Lunge (Basic Attack)", false, function(v)
		KillerCombat.InfiniteLunge = v == true
	end)
	ui.toggle("Counter Auto Parry", false, function(v)
		KillerCombat.CounterParry = v == true
	end)
	ui.toggle("Auto Destroy Pallet", false, function(v)
		KillerCombat.AutoDestroyPallet = v == true
	end)
	ui.toggle("Unlock Skill While Carrying", false, function(v)
		KillerCombat.UnlockCarrySkill = v == true
	end)
	ui.toggle("Auto Hook", false, function(v)
		KillerCombat.AutoHook = v == true
	end)
end)

kill_card("KILLER AIM & ANTI-BLIND", function(_, ui)
	ui.toggle("Anti Blind (Flashlight)", false, function(v)
		KillerCombat.AntiBlind = v == true
		if v then pcall(KC_InstallHook) end
	end)
	ui.toggle("Aimlock Attack", false, function(v)
		KillerCombat.AimlockAttack = v == true
		if v then pcall(KC_InstallHook) end
	end)
	ui.slider("Smooth Lock", 0, 10, 0, "", function(v)
		KillerCombat.SmoothLock = v
	end)
	ui.slider("Lock Distance", 1, 500, 15, " studs", function(v)
		KillerCombat.LockDistance = v
	end)
end)

-- [HANX HUB] Silent Veil + Bezier Trail + Target Highlight + FOV Overlay
do
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local LP = Players.LocalPlayer
	local unloaded = false

	local State = {
		Motion = {
			Regress = function(samples, now, window, minSpan)
				if type(samples) ~= "table" or #samples < 2 then return nil end
				local first = math.max(1, #samples - 12)
				local sumT, sumX, sumY, sumZ, count = 0, 0, 0, 0, 0
				for i = first, #samples do
					local sample = samples[i]
					if sample and sample.t and sample.p and now - sample.t <= (window or 0.25) then
						sumT = sumT + sample.t
						sumX = sumX + sample.p.X
						sumY = sumY + sample.p.Y
						sumZ = sumZ + sample.p.Z
						count = count + 1
					end
				end
				if count < 2 then return nil end
				local meanT = sumT / count
				local meanX, meanY, meanZ = sumX / count, sumY / count, sumZ / count
				local denom, vx, vy, vz = 0, 0, 0, 0
				for i = first, #samples do
					local sample = samples[i]
					if sample and sample.t and sample.p and now - sample.t <= (window or 0.25) then
						local dt = sample.t - meanT
						denom = denom + dt * dt
						vx = vx + dt * (sample.p.X - meanX)
						vy = vy + dt * (sample.p.Y - meanY)
						vz = vz + dt * (sample.p.Z - meanZ)
					end
				end
				if denom <= 1e-6 then return nil end
				return Vector3.new(vx / denom, vy / denom, vz / denom)
			end,
		},
		ClearMark = function() end,
		SetMark = function() end,
	}

	if type(_G.KinonSilentSpearStandaloneUnload) == "function" then
		pcall(_G.KinonSilentSpearStandaloneUnload)
	end

	local G = (getgenv and getgenv()) or _G
	if G.KinonSilentSpearV4 and G.KinonSilentSpearV4.Installed then
		G.KinonSilentSpearV4.Installed.namecall = nil
	end

	State.SpearObj = (function()
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local G = (getgenv and getgenv()) or _G

		for _, key in ipairs({ "KinonSpearState", "KinonSpearState2", "KinonSpearState3" }) do
			if G[key] then G[key].Enabled = false end
		end

		local V = G.KinonSilentSpearV4
		if V and V.Destroy then pcall(V.Destroy) end
		V = V or { Installed = {} }
		V.Installed = V.Installed or {}
		G.KinonSilentSpearV4 = V

		V.Enabled, V.UseDeep = false, false
		V.FOV, V.MaxRange, V.FovAim = 240, 500, true
		V.SpearSpeed, V.Drop, V.Predict = 180, 0.5, true
		V.Dead = false
		V.CurPart, V.CurPoint, V.CurOrigin = nil, nil, nil
		V.TargetChar = nil

		local wrap = newcclosure or function(f) return f end

		local BAL = {
			SpawnOffset    = 3,
			MinChargeTime  = 0.3,
			FullChargeTime = 1,
			YVelClamp      = 14,
			VelMagCap      = 32,
		}

		local function getGravity()
			local g = math.max(0, tonumber(workspace.Gravity) or 196.2)
			return Vector3.new(0, -g * math.clamp(tonumber(V.Drop) or 0.5, 0, 1), 0)
		end

		local function getPingHalf()
			local ok, ping = pcall(function() return LP:GetNetworkPing() end)
			if ok and type(ping) == "number" and ping > 0 then
				return math.clamp(ping * 0.5, 0, 0.25)
			end
			return 0.035
		end

		local function getLatencyLead()
			local ok, ping = pcall(function() return LP:GetNetworkPing() end)
			local oneWay = (ok and type(ping) == "number" and ping > 0) and math.clamp(ping, 0.01, 0.2) or 0.05
			return math.clamp(oneWay * 1.5 + 0.04, 0.06, 0.32)
		end

		local velCache = setmetatable({}, { __mode = "k" })

		local function getSmoothedVelocity(char, hrp)
			local now = tick()
			local c = velCache[char]
			local raw
			if c and c.lastPos and now - c.time > 0.03 and now - c.time < 0.5 then
				raw = (hrp.Position - c.lastPos) / (now - c.time)
				local live = hrp.AssemblyLinearVelocity or Vector3.zero
				if raw.Magnitude > 60 then raw = live end
				local smoothed = c.velocity:Lerp(raw, 0.5)
				if smoothed.Magnitude > BAL.VelMagCap then
					smoothed = smoothed.Unit * BAL.VelMagCap
				end
				velCache[char] = { velocity = smoothed, time = now, lastPos = hrp.Position }
				return smoothed
			end
			raw = hrp.AssemblyLinearVelocity or Vector3.zero
			if raw.Magnitude > BAL.VelMagCap then raw = raw.Unit * BAL.VelMagCap end
			velCache[char] = { velocity = raw, time = now, lastPos = hrp.Position }
			return raw
		end

		local function clampVelY(v)
			return Vector3.new(v.X, math.clamp(v.Y, -BAL.YVelClamp, BAL.YVelClamp), v.Z)
		end

		local function isKillerTeam(char)
			local plr = Players:GetPlayerFromCharacter(char)
			if plr and plr.Team and plr.Team.Name == "Killer" then return true end
			if char:GetAttribute("Role") == "Killer" then return true end
			if char:GetAttribute("IsKiller") == true then return true end
			return false
		end

		local function candidates()
			local list = {}
			local camera = workspace.CurrentCamera
			if not camera then return list end
			local center = camera.ViewportSize / 2
			local myChar = LP.Character
			local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
			if not myHRP then return list end

			for _, plr in ipairs(Players:GetPlayers()) do
				if plr ~= LP and plr.Character and plr.Character ~= myChar then
					local char = plr.Character
					if not isKillerTeam(char) then
						local hum = char:FindFirstChildOfClass("Humanoid")
						local hrp = char:FindFirstChild("HumanoidRootPart")
						if hum and hum.Health > 0 and hrp
						   and not char:GetAttribute("Immobile")
						   and not char:GetAttribute("IsHooked")
						   and not char:GetAttribute("Knocked") then
							local dist = (hrp.Position - myHRP.Position).Magnitude
							if dist <= V.MaxRange then
								local s, onScreen = camera:WorldToViewportPoint(hrp.Position)
								if onScreen and s.Z > 0 then
									local px = (Vector2.new(s.X, s.Y) - center).Magnitude
									if (not V.FovAim) or px <= V.FOV then
										table.insert(list, {
											char = char, hrp = hrp, hum = hum,
											px = px, dist = dist,
											health = hum.Health,
										})
									end
								end
							end
						end
					end
				end
			end
			return list
		end

		local function pick(list)
			if #list == 0 then return nil end
			table.sort(list, function(a, b) return a.px < b.px end)
			local cur = V.TargetChar
			if cur then
				for _, c in ipairs(list) do
					if c.char == cur then
						if c.px <= list[1].px + 18 then return c end
						break
					end
				end
			end
			return list[1]
		end

		local tracker = { char = nil, samples = {} }

		local function trackTarget(char, hrp)
			local now = os.clock()
			if tracker.char ~= char then tracker.char, tracker.samples = char, {} end
			local smp = tracker.samples
			smp[#smp + 1] = { t = now, p = hrp.Position }
			while #smp > 2 and now - smp[1].t > 0.9 do table.remove(smp, 1) end
		end

		local function windowVelocity(smp, window)
			local last = smp[#smp]
			local first = smp[1]
			for i = #smp, 1, -1 do
				if last.t - smp[i].t >= window then first = smp[i]; break end
			end
			local dt = last.t - first.t
			if dt < 0.03 then return nil end
			return (last.p - first.p) / dt
		end

		local INTERACT_ATTR = { "repair", "generator", "heal", "unhook", "rescu", "gate", "interact", "opening", "working", "search", "chest", "sabotage", "cleanse", "totem", "pickup" }
		local INTERACT_ANIM = { "repair", "generator", "heal", "unhook", "rescue", "gate", "search", "chest", "sabotage", "cleanse", "totem", "pickup" }

		local function isInteracting(char)
			local okA, attrs = pcall(function() return char:GetAttributes() end)
			if okA and type(attrs) == "table" then
				for name, value in pairs(attrs) do
					if value == true then
						local n = string.lower(tostring(name))
						if not (n:find("^can") or n:find("^has") or n:find("^allow")) then
							for _, key in ipairs(INTERACT_ATTR) do
								if n:find(key, 1, true) then return true end
							end
						end
					end
				end
			end
			local hum = char:FindFirstChildOfClass("Humanoid")
			local animator = hum and hum:FindFirstChildOfClass("Animator")
			if animator then
				local okT, tracks = pcall(function() return animator:GetPlayingAnimationTracks() end)
				if okT and tracks then
					for _, tr in ipairs(tracks) do
						local label = ""
						pcall(function()
							label = string.lower(tostring(tr.Name) .. " " .. tostring(tr.Animation and tr.Animation.Name or ""))
						end)
						if label ~= "" then
							for _, key in ipairs(INTERACT_ANIM) do
								if label:find(key, 1, true) then return true end
							end
						end
					end
				end
			end
			return false
		end

		local function stationaryByHistory(char)
			local smp = tracker.samples
			if tracker.char ~= char or #smp < 6 then return false end
			local last = smp[#smp]
			local first
			for i = #smp, 1, -1 do
				if last.t - smp[i].t >= 0.5 then first = smp[i]; break end
			end
			if not first then return false end
			local d = last.p - first.p
			return Vector3.new(d.X, 0, d.Z).Magnitude < 0.9
		end

		local function estimateVelocity(char, hrp)
			local live = hrp.AssemblyLinearVelocity or Vector3.zero
			local liveFlat = Vector3.new(live.X, 0, live.Z)
			local smp = tracker.samples

			if tracker.char == char and #smp >= 4 then
				local vLong = windowVelocity(smp, 0.30)
				local vShort = windowVelocity(smp, 0.14)
				local vNow = windowVelocity(smp, 0.10) or vShort

				if vLong and vShort and vNow then
					local flatLong = Vector3.new(vLong.X, 0, vLong.Z)
					local flatShort = Vector3.new(vShort.X, 0, vShort.Z)
					local flatNow = Vector3.new(vNow.X, 0, vNow.Z)

					local noInput = false
					local hum = char:FindFirstChildOfClass("Humanoid")
					if hum then
						pcall(function()
							noInput = hum.MoveDirection.Magnitude < 0.05
						end)
					end

					local vel
					if flatNow.Magnitude < 1.2 and liveFlat.Magnitude < 2 then
						vel = Vector3.zero
					elseif noInput and flatShort.Magnitude < 4 and liveFlat.Magnitude < 4 then
						vel = Vector3.zero
					elseif flatShort.Magnitude < flatLong.Magnitude * 0.45
						and liveFlat.Magnitude < flatLong.Magnitude * 0.6 then
						vel = (vNow + live) * 0.5
					else
						local cosA = 1
						if flatLong.Magnitude > 1 and flatShort.Magnitude > 1 then
							cosA = flatLong.Unit:Dot(flatShort.Unit)
						end

						if cosA < 0.5 and liveFlat.Magnitude > 1
							and flatShort.Unit:Dot(liveFlat.Unit) > 0.5 then
							vel = (vNow + live) * 0.5
						else
							vel = vLong * 0.3 + vShort * 0.7
							if liveFlat.Magnitude > 2 then
								vel = vel * 0.6 + live * 0.4
							end
						end
					end

					if vel.Magnitude > BAL.VelMagCap then
						vel = vel.Unit * BAL.VelMagCap
					end
					return vel
				end
			end

			local fallback = live
			if fallback.Magnitude > BAL.VelMagCap then
				fallback = fallback.Unit * BAL.VelMagCap
			end
			return fallback
		end

		local function isAuraMode(char)
			if not char then return false end
			if char:GetAttribute("special") == true or char:GetAttribute("Aura") == true then return true end
			return char:FindFirstChild("Aura") ~= nil
		end

		local function solveThrow(targetChar, origin, chargeTime)
			local hrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
			if not hrp then return nil end

			local dist = (hrp.Position - origin).Magnitude
			local farFactor = math.clamp((dist - 45) / 35, 0, 1)
			local baseSpeed = math.clamp(tonumber(V.SpearSpeed) or 180, 60, 180)
			local speed = baseSpeed + (math.min(150, baseSpeed) - baseSpeed) * farFactor
			local launchSpeed = math.clamp((chargeTime or BAL.FullChargeTime) * speed, 1, speed)
			local gVec = getGravity()
			local gMag = math.abs(gVec.Y)
			local latency = getPingHalf() + 0.07 + 0.07 * farFactor
			local aimPoint = hrp.Position + Vector3.new(0, 0.2, 0)

			local vel = Vector3.zero
			if V.Predict ~= false and not (isInteracting(targetChar) or stationaryByHistory(targetChar)) then
				vel = clampVelY(estimateVelocity(targetChar, hrp))
				if vel.Magnitude > BAL.VelMagCap then
					vel = vel.Unit * BAL.VelMagCap
				end
			end
			local predVel = vel * (1.1 + 0.3 * farFactor)

			local rel = aimPoint + predVel * latency - origin
			local t = math.max(0.04, rel.Magnitude / launchSpeed)
			local ballisticOK = true

			for _ = 1, 5 do
				local toTarget = aimPoint + predVel * (t + latency) - origin
				local hMag = Vector3.new(toTarget.X, 0, toTarget.Z).Magnitude
				local yOff = toTarget.Y
				local a = 0.25 * gMag * gMag
				local b = yOff * gMag - launchSpeed * launchSpeed
				local c = hMag * hMag + yOff * yOff
				local disc = b * b - 4 * a * c
				if gMag < 0.001 then
					t = math.max(0.04, toTarget.Magnitude / launchSpeed)
				elseif disc >= 0 then
					local r = (-b - math.sqrt(disc)) / (2 * a)
					if r > 0 then t = math.sqrt(r) else t = math.max(0.04, toTarget.Magnitude / launchSpeed) end
				else
					ballisticOK = false
					t = math.max(0.04, toTarget.Magnitude / launchSpeed)
					break
				end
			end

			local finalAim = aimPoint + predVel * (t + latency)
			local finalRel = finalAim - origin

			if not ballisticOK and gMag > 0.001 then
				local flat = Vector3.new(finalRel.X, 0, finalRel.Z)
				local flatDir = flat.Magnitude > 0.001 and flat.Unit or Vector3.new(0, 0, -1)
				local num = launchSpeed * launchSpeed - 2 * gMag * finalRel.Y
				local angle = num > 0 and math.atan(launchSpeed / math.sqrt(num)) or math.rad(45)
				local dir = (flatDir * math.cos(angle) + Vector3.new(0, math.sin(angle), 0)).Unit
				return dir, dir * launchSpeed, launchSpeed, finalAim
			end

			local dirVec = (finalRel - 0.5 * gVec * t * t) / t
			return dirVec.Unit, dirVec, launchSpeed, finalAim
		end

		local function isSpearActive(char)
			if not char then return false end
			local morph = char:GetAttribute("MorphedKiller")
			if morph == "Veil" or char:GetAttribute("Veil") == true then return true end
			if char:GetAttribute("spearmode") == true then return true end
			if char:GetAttribute("VeilSpearEquipped") == true then return true end
			local spear = char:FindFirstChild("Spear")
			if spear then
				local inner = spear:FindFirstChild("Spear")
				if inner and inner:IsA("BasePart") then return inner.Transparency < 0.5 end
				return true
			end
			return false
		end

		local endAttackCache, endAttackAnims, endAttackSearched = nil, nil, false

		local function ensureChargeFn()
			local char = LP.Character
			local anims = char and char:FindFirstChild("Animations")
			if not anims then return end
			if type(getgc) ~= "function" or type(getupvalues) ~= "function" then return end
			if endAttackAnims ~= anims then
				endAttackAnims, endAttackCache, endAttackSearched = anims, nil, false
			end
			if endAttackCache or endAttackSearched then return end
			endAttackSearched = true
			pcall(function()
				for _, fn in ipairs(getgc()) do
					if type(fn) == "function" and (not islclosure or islclosure(fn)) then
						if debug.info(fn, "n") == "endAttack" and getfenv(fn).script == anims then
							endAttackCache = fn
							break
						end
					end
				end
			end)
		end

		local function getChargeTime()
			if not endAttackCache then return BAL.FullChargeTime end
			local ok, ups = pcall(getupvalues, endAttackCache)
			if ok and ups then
				local isThrown = ups[2] == true
				local startTime = tonumber(ups[9]) or 0
				if isThrown and startTime > 0 then
					return math.max(BAL.MinChargeTime, workspace:GetServerTimeNow() - startTime)
				end
			end
			return BAL.FullChargeTime
		end

		local viewDelayFn = nil
		task.spawn(function()
			for _ = 1, 40 do
				if unloaded or V.Dead or viewDelayFn then return end
				pcall(function()
					local mods = ReplicatedStorage:FindFirstChild("Modules")
					local world = mods and mods:FindFirstChild("World")
					local vis = world and world:FindFirstChild("ProjectileVisualsClient")
					if vis and vis:IsA("ModuleScript") then
						local m = require(vis)
						if m and type(m.viewDelay) == "function" then viewDelayFn = m.viewDelay end
					end
				end)
				task.wait(0.25)
			end
		end)
		task.spawn(function()
			while not unloaded and not V.Dead do
				if V.Enabled then pcall(ensureChargeFn) end
				task.wait(0.5)
			end
		end)

		local TRAIL_LIFETIME = 1.5
		local function showTrail(origin, dir, speed)
			if typeof(origin) ~= "Vector3" or typeof(dir) ~= "Vector3" or dir.Magnitude < 0.01 then return end
			speed = tonumber(speed) or 180
			task.spawn(function()
				local gravity = getGravity()
				local v0 = dir.Unit * speed
				local params = RaycastParams.new()
				params.FilterType = Enum.RaycastFilterType.Exclude
				params.RespectCanCollide = true
				local ignore = {}
				if LP.Character then table.insert(ignore, LP.Character) end
				params.FilterDescendantsInstances = ignore

				local points = { origin }
				local prev = origin
				local steps, dt = 160, 0.0175
				for i = 1, steps do
					local tt = i * dt
					local nxt = origin + v0 * tt + 0.5 * gravity * tt * tt
					local delta = nxt - prev
					local stop = false
					if delta.Magnitude > 0.01 then
						local hit = workspace:Raycast(prev, delta, params)
						if hit then nxt = hit.Position; stop = true end
					end
					table.insert(points, nxt)
					prev = nxt
					if stop then break end
				end
				if #points < 2 then return end

				local folder = Instance.new("Folder")
				folder.Name = "KINON_SpearTrail"
				folder.Parent = workspace

				local terrain = workspace.Terrain
				local p0, p3 = points[1], points[#points]
				local totalTime = (#points - 1) * dt
				local quadraticControl = origin + v0 * (totalTime * 0.5)
				local control0 = p0 + (quadraticControl - p0) * (2 / 3)
				local control1 = p3 + (quadraticControl - p3) * (2 / 3)

				local function makeRightFacingFrame(position, direction)
					local right = direction.Magnitude > 0.001 and direction.Unit or Vector3.xAxis
					local referenceUp = math.abs(right:Dot(Vector3.yAxis)) > 0.98 and Vector3.xAxis or Vector3.yAxis
					local back = right:Cross(referenceUp).Unit
					local up = back:Cross(right).Unit
					return CFrame.fromMatrix(position, right, up, back)
				end

				local startAttachment = Instance.new("Attachment")
				startAttachment.Name = "TrailStart"
				startAttachment.Parent = terrain
				startAttachment.WorldCFrame = makeRightFacingFrame(p0, control0 - p0)

				local endAttachment = Instance.new("Attachment")
				endAttachment.Name = "TrailEnd"
				endAttachment.Parent = terrain
				endAttachment.WorldCFrame = makeRightFacingFrame(p3, control1 - p3)

				local cam = workspace.CurrentCamera
				local camPos = cam and cam.CFrame.Position or origin
				local k0 = math.clamp((p0 - camPos).Magnitude / 40, 1, 5)
				local k1 = math.clamp((p3 - camPos).Magnitude / 40, 1, 5)

				local function makeBeam(name, color, width0, width1, transparency, emission)
					local b = Instance.new("Beam")
					b.Name = name
					b.Attachment0, b.Attachment1 = startAttachment, endAttachment
					b.CurveSize0 = (control0 - p0).Magnitude
					b.CurveSize1 = (control1 - p3).Magnitude
					b.Color = ColorSequence.new(color)
					b.LightEmission = emission
					b.LightInfluence = 0
					b.FaceCamera = true
					b.Segments = 64
					b.Width0, b.Width1 = width0, width1
					b.Transparency = NumberSequence.new(transparency)
					b.Parent = folder
					return b
				end

				local outerGlow = makeBeam(
					"WidePurpleLightBloom",
					Color3.fromRGB(135, 55, 255),
					2.75 * k0, 1.80 * k1, 0.62, 1
				)
				local innerGlow = makeBeam(
					"SoftPurpleInnerGlow",
					Color3.fromRGB(190, 105, 255),
					1.95 * k0, 1.28 * k1, 0.38, 1
				)
				local outline = makeBeam(
					"DarkSmoothOutline",
					Color3.fromRGB(8, 6, 14),
					1.48 * k0, 0.96 * k1, 0.08, 0.7
				)
				local beam = makeBeam(
					"ContinuousPurpleCore",
					Color3.fromRGB(205, 135, 255),
					1.38 * k0, 0.90 * k1, 0.02, 1
				)

				local start = os.clock()
				while folder.Parent and not unloaded do
					local alpha = (os.clock() - start) / TRAIL_LIFETIME
					if alpha >= 1 then break end
					local function fadeFrom(base)
						return NumberSequence.new(math.clamp(base + alpha * (1 - base), 0, 1))
					end
					outerGlow.Transparency = fadeFrom(0.62)
					innerGlow.Transparency = fadeFrom(0.38)
					outline.Transparency = fadeFrom(0.08)
					beam.Transparency = fadeFrom(0.02)
					RunService.Heartbeat:Wait()
				end
				if folder.Parent then folder:Destroy() end
				startAttachment:Destroy()
				endAttachment:Destroy()
			end)
		end

		local function applyPayload(payload, origin, dir, speed)
			payload.Origin = origin
			payload.Direction = dir
			if payload.Velocity ~= nil then payload.Velocity = dir * speed end
			if viewDelayFn then
				pcall(function() payload.ViewDelay = viewDelayFn(origin, dir) end)
			end
		end

		V.NamecallHandler = function(old, self, ...)
			local method = getnamecallmethod()
			if not V.Enabled or (method ~= "FireServer" and method ~= "fireServer") then
				return old(self, ...)
			end
			local isSpear = false
			pcall(function()
				isSpear = typeof(self) == "Instance" and string.lower(self.Name) == "spearthrow"
			end)
			if not isSpear then
				if setnamecallmethod then pcall(setnamecallmethod, method) end
				return old(self, ...)
			end
			if checkcaller and checkcaller() then
				if setnamecallmethod then pcall(setnamecallmethod, method) end
				return old(self, ...)
			end

			local args = table.pack(...)
			local trailOrigin, trailDir, trailSpeed

			pcall(function()
				local char = LP.Character
				if not char or not isSpearActive(char) then return end
				local camera = workspace.CurrentCamera
				if not camera then return end
				local payload = type(args[1]) == "table" and args[1] or nil

				local origin
				if payload and typeof(payload.Origin) == "Vector3" then
					origin = payload.Origin
				elseif typeof(args[1]) == "Vector3" and typeof(args[2]) == "Vector3" then
					origin = args[1]
				elseif typeof(args[1]) == "Vector3" and type(args[2]) == "number" and typeof(args[3]) == "Vector3" then
					origin = args[3]
				else
					origin = camera.CFrame.Position + camera.CFrame.LookVector * BAL.SpawnOffset
				end

				local speedForm = payload == nil and typeof(args[1]) == "Vector3" and type(args[2]) == "number"
				local charge = speedForm and BAL.FullChargeTime or getChargeTime()
				local target = V.TargetChar
				local redirected = false

				if target and target.Parent then
					local dir, _, speed = solveThrow(target, origin, charge)
					if dir then
						trailOrigin, trailDir, trailSpeed = origin, dir, speed
						if payload then
							local ok = pcall(applyPayload, payload, origin, dir, speed)
							if ok then redirected = true
							else
								local clone = table.clone and table.clone(payload) or nil
								if clone and pcall(applyPayload, clone, origin, dir, speed) then
									args[1] = clone
									redirected = true
								end
							end
						elseif typeof(args[1]) == "Vector3" and typeof(args[2]) == "Vector3" then
							args[1], args[2] = origin, dir
							redirected = true
						elseif speedForm then
							args[1], args[2] = dir, speed
							redirected = true
						elseif typeof(args[1]) == "Vector3" then
							args[1] = dir
							redirected = true
						end
					end
				end

				if not redirected then
					trailOrigin, trailDir, trailSpeed = nil, nil, nil
					if payload and typeof(payload.Direction) == "Vector3" then
						trailOrigin = origin
						trailDir = payload.Direction
						trailSpeed = typeof(payload.Velocity) == "Vector3" and payload.Velocity.Magnitude
							or math.clamp(charge * (tonumber(V.SpearSpeed) or 180), 1, 200)
					elseif typeof(args[1]) == "Vector3" and typeof(args[2]) == "Vector3" then
						trailOrigin, trailDir = args[1], args[2]
						trailSpeed = math.clamp(charge * (tonumber(V.SpearSpeed) or 180), 1, 200)
					end
				end
			end)

			if setnamecallmethod then pcall(setnamecallmethod, method) end
			if setnamecallmethod then pcall(setnamecallmethod, method) end
			local ret = old(self, unpack(args, 1, args.n))
			if trailOrigin then task.defer(showTrail, trailOrigin, trailDir, trailSpeed) end
			return ret
		end

		local function guiParent()
			local parent
			pcall(function() parent = (gethui and gethui()) or game:GetService("CoreGui") end)
			return parent or LP:WaitForChild("PlayerGui")
		end

		local sg = Instance.new("ScreenGui")
		sg.Name = "KinonSilentSpear"
		sg.ResetOnSpawn = false
		sg.IgnoreGuiInset = true
		sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		sg.Parent = guiParent()

		local targetHighlight

		local function clearTargetIndicator()
			if targetHighlight then targetHighlight:Destroy(); targetHighlight = nil end
		end

		local function showTargetIndicator(char)
			if not char or not char.Parent then
				clearTargetIndicator()
				return
			end

			if not targetHighlight or targetHighlight.Parent ~= char then
				clearTargetIndicator()
				targetHighlight = Instance.new("Highlight")
				targetHighlight.Name = "TianHub_Veil_FOV_Target"
				targetHighlight.Adornee = char
				targetHighlight.FillColor = Color3.fromRGB(255, 35, 35)
				targetHighlight.OutlineColor = Color3.fromRGB(255, 35, 35)
				targetHighlight.FillTransparency = 0.78
				targetHighlight.OutlineTransparency = 0
				targetHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				targetHighlight.Parent = char
			end
		end

		local function hideVisuals()
			clearTargetIndicator()
			pcall(State.ClearMark, "spear")
		end

		V.DestroyEsp = function()
			V.TargetChar = nil
			rawset(_G, "TianHub_SilentVeilFOVTarget", nil)
			V.CurPart, V.CurPoint, V.CurOrigin = nil, nil, nil
			hideVisuals()
			tracker.char, tracker.samples = nil, {}
		end

		V.RenderConn = RunService.RenderStepped:Connect(function()
			if unloaded or not V.Enabled then
				rawset(_G, "TianHub_SilentVeilFOVTarget", nil)
				if V.TargetChar then V.DestroyEsp() end
				return
			end

			local t = pick(candidates())
			local nowC = os.clock()
			if t then
				V.LastT, V.LastSeen = t, nowC
			elseif V.LastT and nowC - (V.LastSeen or 0) < 0.3 then
				local lt = V.LastT
				local lh = lt.hum
				if lt.hrp and lt.hrp.Parent and lh and lh.Parent and lh.Health > 0 then t = lt end
			end
			V.TargetChar = t and t.char or nil
			V.CurPart = t and t.hrp or nil
			rawset(_G, "TianHub_SilentVeilFOVTarget", (t and t.px <= (tonumber(V.FOV) or 240)) and t.char or nil)

			if not (LP.Team and LP.Team.Name == "Killer") then
				rawset(_G, "TianHub_SilentVeilFOVTarget", nil)
				hideVisuals()
				return
			end

			if V.TargetChar then
				trackTarget(V.TargetChar, t.hrp)
				if t.px <= (tonumber(V.FOV) or 240) then
					showTargetIndicator(V.TargetChar)
				else
					clearTargetIndicator()
				end
			else
				hideVisuals()
				tracker.char, tracker.samples = nil, {}
			end
		end)

		V.Destroy = function()
			V.Enabled = false
			V.Dead = true
			if V.RenderConn then pcall(function() V.RenderConn:Disconnect() end); V.RenderConn = nil end
			if type(paintName) == "function" then pcall(paintName, lastNamed, false) end
			pcall(State.ClearMark, "spear")
			clearTargetIndicator()
			if ring then pcall(function() ring:Destroy() end) end
			pcall(function() sg:Destroy() end)
			V.TargetChar = nil
			V.CurPart, V.CurPoint, V.CurOrigin = nil, nil, nil
		end

		if not V.Installed.namecall and hookmetamethod and getnamecallmethod then
			pcall(function()
				local old
				old = hookmetamethod(game, "__namecall", wrap(function(self, ...)
					local method = getnamecallmethod()
					if method == "FireServer" or method == "fireServer" then
						local fr = State.FlashRemote
						if fr and self == fr and State.FlashSetActive then
							local fa = { ... }
							pcall(State.FlashSetActive, fa[2] == true, fa[1])
							if setnamecallmethod then pcall(setnamecallmethod, method) end
						end
						if State.AntiBlindOn and not (checkcaller and checkcaller()) and State.IsKillerNow and State.IsKillerNow() then
							local blockBlind = false
							pcall(function()
								local n = string.lower(tostring(self:GetFullName()))
								if n:find("blind", 1, true) then blockBlind = true end
							end)
							if blockBlind then return nil end
							if setnamecallmethod then pcall(setnamecallmethod, method) end
						end
						local ns = State.NoSlow
						if ns and (ns.K or ns.S) and not (checkcaller and checkcaller()) then
							local block = false
							pcall(function()
								if self.Name == "Fall" and self.Parent and self.Parent.Name == "Mechanics" then
									block = true
								end
							end)
							if block then return nil end
							if setnamecallmethod then pcall(setnamecallmethod, method) end
						end
					end
					local handler = V.NamecallHandler
					if handler then return handler(old, self, ...) end
					return old(self, ...)
				end))
				V.Installed.namecall = true
			end)
		end
		V.HookOk = V.Installed.namecall == true

		return V
	end)()

	local V = G.KinonSilentSpearV4

	if V then
		V.ShowFOVCircle = V.ShowFOVCircle == true
		local overlayParent
		pcall(function()
			if type(gethui) == "function" then overlayParent = gethui() end
		end)
		overlayParent = overlayParent or LP:WaitForChild("PlayerGui")

		local oldOverlay = overlayParent:FindFirstChild("TianHub_SilentVeil_FOV")
		if oldOverlay then oldOverlay:Destroy() end

		local overlayGui = Instance.new("ScreenGui")
		overlayGui.Name = "TianHub_SilentVeil_FOV"
		overlayGui.ResetOnSpawn = false
		overlayGui.IgnoreGuiInset = true
		overlayGui.DisplayOrder = 20
		overlayGui.Parent = overlayParent

		local fovCircle = Instance.new("Frame")
		fovCircle.Name = "FOVCircle"
		fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
		fovCircle.Position = UDim2.fromScale(0.5, 0.5)
		fovCircle.Size = UDim2.fromOffset((tonumber(V.FOV) or 240) * 2, (tonumber(V.FOV) or 240) * 2)
		fovCircle.BackgroundTransparency = 1
		fovCircle.BorderSizePixel = 0
		fovCircle.Visible = false
		fovCircle.Parent = overlayGui

		local fovCorner = Instance.new("UICorner")
		fovCorner.CornerRadius = UDim.new(1, 0)
		fovCorner.Parent = fovCircle

		local fovStroke = Instance.new("UIStroke")
		fovStroke.Color = Color3.fromRGB(8, 6, 14)
		fovStroke.Thickness = 1.15
		fovStroke.Transparency = 0
		fovStroke.Parent = fovCircle

		local fovInner = Instance.new("Frame")
		fovInner.Name = "PurpleInnerRing"
		fovInner.AnchorPoint = Vector2.new(0.5, 0.5)
		fovInner.Position = UDim2.fromScale(0.5, 0.5)
		fovInner.Size = UDim2.new(1, -4, 1, -4)
		fovInner.BackgroundTransparency = 1
		fovInner.BorderSizePixel = 0
		fovInner.Parent = fovCircle
		Instance.new("UICorner", fovInner).CornerRadius = UDim.new(1, 0)
		local fovInnerStroke = Instance.new("UIStroke")
		fovInnerStroke.Color = Color3.fromRGB(190, 115, 255)
		fovInnerStroke.Thickness = 2.5
		fovInnerStroke.Transparency = 0
		fovInnerStroke.Parent = fovInner

		local fovRender
		fovRender = RunService.RenderStepped:Connect(function()
			if not overlayGui.Parent then
				if fovRender then fovRender:Disconnect() end
				return
			end
			local camera = workspace.CurrentCamera
			if camera then
				local radius = math.clamp(tonumber(V.FOV) or 240, 30, 600)
				fovCircle.Position = UDim2.fromOffset(
					camera.ViewportSize.X / 2,
					camera.ViewportSize.Y / 2
				)
				fovCircle.Size = UDim2.fromOffset(radius * 2, radius * 2)
				fovCircle.Visible = V.ShowFOVCircle == true
			else
				fovCircle.Visible = false
			end
		end)

		V.SetShowFOVCircle = function(enabled)
			V.ShowFOVCircle = enabled == true
			fovCircle.Visible = V.ShowFOVCircle
		end
		V.DestroyFOVCircle = function()
			if fovRender then fovRender:Disconnect(); fovRender = nil end
			if overlayGui then overlayGui:Destroy() end
		end
	end

	if V then
		local W = (getgenv and getgenv()) or _G
		local Settings = setmetatable({}, {
			__index = function(_, key)
				if key == "Enabled" then return V.Enabled end
				if key == "FOVRadius" then return V.FOV end
				if key == "ShowFOV" then return V.FovAim end
				if key == "TargetHighlightEnabled" then return true end
				if key == "Priority" then return "Nearest" end
			end,
			__newindex = function(_, key, value)
				if key == "Enabled" then
					V.Enabled = value == true
				elseif key == "FOVRadius" then
					V.FOV = math.clamp(tonumber(value) or 240, 30, 600)
				elseif key == "ShowFOV" then
					V.FovAim = value == true
				end
			end,
		})
		W.TianHubSilentVeilSettings = Settings
		W.KinonSilentSpearSettings = V

		_G.KinonSilentSpearStandaloneUnload = function()
			if V then
				V.Enabled = false
				if type(V.Destroy) == "function" then pcall(V.Destroy) end
			end
		end
	end
end

kill_card("SILENT VEIL", function(_, ui)
	local W = (getgenv and getgenv()) or _G
	local veilSettings = W.TianHubSilentVeilSettings
	local kinon = W.KinonSilentSpearSettings
	if veilSettings and kinon then
		veilSettings.Priority = "Nearest"
		ui.toggle("Enable Veil", veilSettings.Enabled, function(v: boolean)
			veilSettings.Enabled = v == true
			if v then veilSettings.Priority = "Nearest" end
		end)
		ui.toggle("FOV Check", veilSettings.ShowFOV, function(v: boolean)
			veilSettings.ShowFOV = v == true
		end)
		ui.toggle("Show FOV", false, function(v: boolean)
			if type(kinon.SetShowFOVCircle) == "function" then
				kinon.SetShowFOVCircle(v == true)
			end
		end)
		if ui.slider then
			ui.slider("FOV Size", 30, 600, veilSettings.FOVRadius, function(v)
				veilSettings.FOVRadius = math.clamp(tonumber(v) or 240, 30, 600)
			end)
			ui.slider("Max Range", 50, 1000, kinon.MaxRange, function(v)
				kinon.MaxRange = math.clamp(tonumber(v) or 500, 50, 1000)
			end)
			ui.slider("Shot Speed", 60, 180, kinon.SpearSpeed, function(v)
				kinon.SpearSpeed = math.clamp(tonumber(v) or 180, 60, 180)
			end)
			ui.slider("Shot Drop", 0, 1, kinon.Drop, function(v)
				kinon.Drop = math.clamp(tonumber(v) or 0.5, 0, 1)
			end)
		end
		ui.toggle("Aim Prediction", kinon.Predict, function(v: boolean)
			kinon.Predict = v == true
		end)
	end
end)

-- [HANX HUB] Silent Aim Butcher (ChainThrow + Target Highlight)
do
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local CollectionService = game:GetService("CollectionService")
	local Teams = game:GetService("Teams")
	local LocalPlayer = Players.LocalPlayer

	local ChainCfg = {
		Enabled = false,
		Debug = true,
		Range = 50,
		Speed = 140,
		PredMultiplier = 1.0,
		Prediction = true,
		Highlight = true,
		AimHeightOffset = 0.5,
		HookOK = false,
	}

	local function chainLog(msg)
		if ChainCfg.Debug then print("[ChainAim] " .. tostring(msg)) end
	end

	local velCache = setmetatable({}, {__mode = "k"})
	local function getSmoothVel(hrp)
		if not hrp then return Vector3.zero end
		local raw = hrp.AssemblyLinearVelocity or hrp.Velocity or Vector3.zero
		local flat = Vector3.new(raw.X, 0, raw.Z)
		if flat.Magnitude > 50 then flat = flat.Unit * 50 end
		local cache = velCache[hrp]
		if not cache then
			velCache[hrp] = {v = flat}
			return flat
		end
		local lerped = cache.v:Lerp(flat, 0.5)
		if lerped.Magnitude < 0.5 then lerped = Vector3.zero end
		cache.v = lerped
		return lerped
	end

	local function CanLatch(char)
		if not char or not char.Parent then return false end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 then return false end
		if char:GetAttribute("Knocked") then return false end
		if char:GetAttribute("IsHooked") or char:GetAttribute("IsCarried") or char:GetAttribute("IsCarrying") then return false end
		if char:GetAttribute("Trapped") then return false end
		return true
	end

	local function IsSurvivor(plr)
		if plr == LocalPlayer then return false end
		local team = plr.Team
		if team then
			local n = team.Name:lower()
			for _, p in ipairs({"killer","murderer","hunter","assassin","slasher","psycho","enemy"}) do
				if n:find(p, 1, true) then return false end
			end
			return true
		end
		return #Teams:GetTeams() > 0
	end

	local function GetChainTarget()
		local myChar = LocalPlayer.Character
		if not myChar then return nil end
		local myRoot = myChar:FindFirstChild("HumanoidRootPart")
		if not myRoot then return nil end

		local bestTarget, bestDist = nil, ChainCfg.Range
		local function check(char)
			if not char or char == myChar then return end
			if not CanLatch(char) then return end
			local root = char:FindFirstChild("HumanoidRootPart")
			if not root then return end
			local d = (root.Position - myRoot.Position).Magnitude
			if d <= ChainCfg.Range and d < bestDist then
				bestDist = d; bestTarget = root
			end
		end
		for _, plr in ipairs(Players:GetPlayers()) do
			if IsSurvivor(plr) then check(plr.Character) end
		end
		for _, bot in ipairs(CollectionService:GetTagged("SurvivorBot")) do
			check(bot)
		end
		return bestTarget
	end

	local ChainHighlight = Instance.new("Highlight")
	ChainHighlight.Name = "N3K0P01_ChainAimHighlight"
	ChainHighlight.FillColor = Color3.fromRGB(255, 255, 255)
	ChainHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	ChainHighlight.FillTransparency = 0.6
	ChainHighlight.OutlineTransparency = 0
	ChainHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	ChainHighlight.Adornee = nil
	ChainHighlight.Parent = workspace.CurrentCamera

	task.spawn(function()
		while ChainHighlight and ChainHighlight.Parent do
			if ChainCfg.Enabled and ChainCfg.Highlight then
				local t = GetChainTarget()
				ChainHighlight.Adornee = t and t.Parent or nil
			else
				ChainHighlight.Adornee = nil
			end
			RunService.RenderStepped:Wait()
		end
	end)

	local function TryRedirect(args)
		local target = GetChainTarget()
		if not target then return false end
		local char = LocalPlayer.Character
		local head = char and char:FindFirstChild("Head")
		if not head then return false end

		local origin = head.Position
		local aimPoint = target.Position + Vector3.new(0, ChainCfg.AimHeightOffset, 0)

		if ChainCfg.Prediction and ChainCfg.PredMultiplier > 0 then
			local vel = getSmoothVel(target)
			local dist = (aimPoint - origin).Magnitude
			local travelTime = dist / math.max(ChainCfg.Speed, 1)
			travelTime = math.min(travelTime, 0.8)
			local leadVec = vel * travelTime * ChainCfg.PredMultiplier
			aimPoint = aimPoint + leadVec
		end

		local dirVec = aimPoint - origin
		local dist = dirVec.Magnitude
		if dist < 0.001 then return false end
		local dir = dirVec.Unit

		chainLog(string.format("dir set | dist=%.1f | spd=%d", dist, ChainCfg.Speed))

		if typeof(args[1]) == "Vector3" then
			args[1] = dir
			return true
		end
		if type(args[3]) == "table" then
			if typeof(args[3].Origin) == "Vector3" then
				args[3].Origin = origin
			end
			if typeof(args[3].Direction) == "Vector3" then
				args[3].Direction = dir
				return true
			end
		end
		return false
	end

	local function InstallChainHook()
		if ChainCfg.HookOK then return true end
		if type(hookmetamethod) ~= "function" or type(getnamecallmethod) ~= "function" then
			return false
		end
		local wrap = newcclosure or function(f) return f end
		local oldNamecall
		oldNamecall = hookmetamethod(game, "__namecall", wrap(function(self, ...)
			local method = getnamecallmethod()
			if method == "FireServer"
			   and typeof(self) == "Instance"
			   and self.ClassName == "RemoteEvent"
			   and self.Name == "ChainThrow"
			   and ChainCfg.Enabled then
				local args = table.pack(...)
				local ok, changed = pcall(TryRedirect, args)
				if ok and changed then
					if setnamecallmethod then setnamecallmethod(method) end
					return oldNamecall(self, table.unpack(args, 1, args.n))
				end
			end
			if setnamecallmethod then setnamecallmethod(method) end
			return oldNamecall(self, ...)
		end))
		ChainCfg.HookOK = true
		return true
	end

	local function setEnabled(state)
		ChainCfg.Enabled = state == true
		if ChainCfg.Enabled and not ChainCfg.HookOK then
			InstallChainHook()
		end
		print("[ChainAim]", ChainCfg.Enabled and "Enabled" or "Disabled")
	end

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.H then
			setEnabled(not ChainCfg.Enabled)
		end
	end)

	task.spawn(function() pcall(InstallChainHook) end)

	_G.N3K0P01_ChainAim = ChainCfg
	_G.N3K0P01_ChainAim_SetEnabled = setEnabled
	_G.N3K0P01_ChainAim_Destroy = function()
		ChainCfg.Enabled = false
		ChainHighlight.Adornee = nil
		if ChainHighlight then pcall(function() ChainHighlight:Destroy() end) end
		print("[ChainAim] Destroyed")
	end

	kill_card("SILENT AIM BUTCHER", function(_, ui)
		ui.toggle("Enable Silent Aim Butcher", ChainCfg.Enabled, function(v: boolean)
			setEnabled(v)
		end)
		ui.toggle("Prediction", ChainCfg.Prediction, function(v: boolean)
			ChainCfg.Prediction = v == true
		end)
		if ui.slider then
			ui.slider("Prediction Multiplier", 0, 3, ChainCfg.PredMultiplier, function(v)
				ChainCfg.PredMultiplier = math.clamp(tonumber(v) or 1.0, 0, 3)
			end)
			ui.slider("Target Range", 10, 200, ChainCfg.Range, function(v)
				ChainCfg.Range = math.clamp(tonumber(v) or 50, 10, 200)
			end)
			ui.slider("Projectile Speed", 50, 300, ChainCfg.Speed, function(v)
				ChainCfg.Speed = math.clamp(tonumber(v) or 140, 50, 300)
			end)
			ui.slider("Aim Height Offset", -2, 3, ChainCfg.AimHeightOffset, function(v)
				ChainCfg.AimHeightOffset = math.clamp(tonumber(v) or 0.5, -2, 3)
			end)
		end
		ui.toggle("Target Highlight", ChainCfg.Highlight, function(v: boolean)
			ChainCfg.Highlight = v == true
			if not ChainCfg.Highlight then ChainHighlight.Adornee = nil end
		end)
	end)
end

local misc_card = create_page("Misc", "Server and utility shortcuts", 5)
misc_card("SERVER", function(_, ui)
	if ui.button then
		ui.button("Rejoin", function()
			SHop_Rejoin()
		end)
		ui.button("Server Hop", function()
			SHop_ServerHop()
		end)
		ui.button("Server Low", function()
			SHop_ServerLow()
		end)
	else
		ui.toggle("Rejoin", false, function(v: boolean)
			if v then SHop_Rejoin() end
		end)
		ui.toggle("Server Hop", false, function(v: boolean)
			if v then SHop_ServerHop() end
		end)
		ui.toggle("Server Low", false, function(v: boolean)
			if v then SHop_ServerLow() end
		end)
	end
end)

misc_card("BYPASS PROTECTION", function(_, ui)
	local bypass_ready = false
	ui.toggle("BYPASS PING", false, function(v: boolean)
		if AP and AP.SetAntiBypassPing then
			AP.SetAntiBypassPing(v)
		end
		if bypass_ready and type(hanx_notify) == "function" then
			hanx_notify(
				"ANTI BYPASS PING",
				v and "Enabled — Ping compensation active" or "Disabled",
				2.2
			)
		end
	end, "misc_anti_bypass_ping")
	bypass_ready = true

	ui.toggle("ANTI FAKE HIT KILLER", false, function(v: boolean)
		if AP and AP.SetAntiFakeHit then
			AP.SetAntiFakeHit(v)
		end
	end, "misc_anti_fake_hit")
end)

vis_card("ENVIRONMENT", function(_, ui)
	ui.toggle("Fullbright & No Fog / Smoke", false, function(v: boolean)
		FB_SetEnabled(v)
	end)
end)

misc_card("FREE CURSOR", function(_, ui)
	ui.toggle("Free Cursor (Hold RMB Turn)", false, function(v: boolean)
		FC_SetEnabled(v)
	end)
end)

local cfg_card = create_page("Config", "UI scale, save/load, and auto load controls", 6)

do
	local cfg_page = (type(pages) == "table" and pages["Config"]) or nil
	local cols = cfg_page and cfg_page:FindFirstChild("ColsWrap")
	local side_parent = (cols and cols:FindFirstChild("RightColumn")) or right_col

	if side_parent then
		local scale_card = Instance.new("Frame")
		scale_card.Name = "HanxSideUiScaleCard"
		scale_card.Size = UDim2.new(1, -6, 0, 0)
		scale_card.AutomaticSize = Enum.AutomaticSize.Y
		scale_card.BackgroundColor3 = P.card
		scale_card.BackgroundTransparency = 0.14
		scale_card.BorderSizePixel = 0
		scale_card.LayoutOrder = 1
		scale_card.Parent = side_parent
		round_all(scale_card, 10)
		stroke_all(scale_card, P.stroke, 1, 0.35)
		pad_all(scale_card, 8, 8, 8, 8)

		local s_list = Instance.new("UIListLayout")
		s_list.Padding = UDim.new(0, 6)
		s_list.SortOrder = Enum.SortOrder.LayoutOrder
		s_list.Parent = scale_card

		local title_lbl = Instance.new("TextLabel")
		title_lbl.Size = UDim2.new(1, 0, 0, 16)
		title_lbl.BackgroundTransparency = 1
		title_lbl.Text = "UI SCALE"
		title_lbl.TextColor3 = P.text
		title_lbl.Font = Enum.Font.GothamBold
		title_lbl.TextSize = 11
		title_lbl.TextXAlignment = Enum.TextXAlignment.Left
		title_lbl.LayoutOrder = 1
		title_lbl.Parent = scale_card

		local val_lbl = Instance.new("TextLabel")
		val_lbl.Size = UDim2.new(1, 0, 0, 16)
		val_lbl.BackgroundTransparency = 1
		val_lbl.Text = "Scale (%): " .. tostring(DEFAULT_SCALE_PCT) .. "%"
		val_lbl.TextColor3 = P.muted
		val_lbl.Font = Enum.Font.GothamMedium
		val_lbl.TextSize = 10.5
		val_lbl.TextXAlignment = Enum.TextXAlignment.Left
		val_lbl.LayoutOrder = 2
		val_lbl.Parent = scale_card

		local track = Instance.new("TextButton")
		track.Size = UDim2.new(1, 0, 0, 18)
		track.BackgroundColor3 = P.sidebar
		track.BackgroundTransparency = 0.15
		track.BorderSizePixel = 0
		track.Text = ""
		track.AutoButtonColor = false
		track.LayoutOrder = 3
		track.Parent = scale_card
		round_all(track, 6)
		stroke_all(track, P.stroke, 1, 0.4)

		local fill = Instance.new("Frame")
		fill.BackgroundColor3 = P.accent
		fill.BorderSizePixel = 0
		fill.Parent = track
		round_all(fill, 6)

		local function apply_scale(pct: number)
			local clamped = math.clamp(math.floor(pct + 0.5), 50, 120)
			ui_scale.Scale = clamped / 100
			val_lbl.Text = "Scale (%): " .. tostring(clamped) .. "%"
			local ratio = (clamped - 50) / (120 - 50)
			fill.Size = UDim2.new(math.clamp(ratio, 0, 1), 0, 1, 0)
			return clamped
		end

		local current_pct = apply_scale(DEFAULT_SCALE_PCT)
		local dragging = false

		local function update_from_x(pos_x: number)
			local abs_x = track.AbsolutePosition.X
			local abs_w = math.max(track.AbsoluteSize.X, 1)
			local alpha = math.clamp((pos_x - abs_x) / abs_w, 0, 1)
			current_pct = apply_scale(50 + alpha * (120 - 50))
		end

		track.InputBegan:Connect(function(inp: InputObject)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				update_from_x(inp.Position.X)
			end
		end)

		track.InputEnded:Connect(function(inp: InputObject)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)

		track.InputChanged:Connect(function(inp: InputObject)
			if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
				update_from_x(inp.Position.X)
			end
		end)

		if type(register_config_item) == "function" then
			register_config_item("HANX_HUB.Config.UIScale", "slider", function()
				return current_pct
			end, function(val)
				if type(val) == "number" then
					current_pct = apply_scale(val)
				end
			end)
		end

		local Players = game:GetService("Players")
		local CoreGui = game:GetService("CoreGui")
		local UserInputService = game:GetService("UserInputService")

		local function get_all_guis(): { ScreenGui }
			local list: { ScreenGui } = {}
			local seen: { [ScreenGui]: boolean } = {}

			local function collect(root: Instance?)
				if not root then
					return
				end
				for _, child in ipairs(root:GetChildren()) do
					if child:IsA("ScreenGui") and not seen[child] then
						seen[child] = true
						table.insert(list, child)
					end
				end
			end

			local lp = Players.LocalPlayer
			collect(lp and lp:FindFirstChildOfClass("PlayerGui"))
			pcall(function()
				collect(CoreGui)
			end)
			return list
		end

		local gui_hidden = false
		local prev_states: { [ScreenGui]: boolean } = {}
		local enabled_conns: { [ScreenGui]: RBXScriptConnection } = {}
		local hide_btn: TextButton

		local function sync_hide_label()
			if hide_btn then
				hide_btn.Text = gui_hidden and "Show GUI (Key: K)" or "Hide GUI (Key: K)"
			end
		end

		local function bind_gui_lock(g: ScreenGui)
			if enabled_conns[g] then
				enabled_conns[g]:Disconnect()
				enabled_conns[g] = nil
			end
			enabled_conns[g] = g:GetPropertyChangedSignal("Enabled"):Connect(function()
				if gui_hidden and g.Enabled then
					g.Enabled = false
				end
			end)
		end

		local function clear_gui_locks()
			for _, conn in pairs(enabled_conns) do
				conn:Disconnect()
			end
			table.clear(enabled_conns)
		end

		local function set_total_gui_hidden(hidden: boolean)
			gui_hidden = hidden == true
			if gui_hidden then
				clear_gui_locks()
				table.clear(prev_states)
				for _, g in ipairs(get_all_guis()) do
					prev_states[g] = g.Enabled
					g.Enabled = false
					bind_gui_lock(g)
				end
			else
				clear_gui_locks()
				for g, was_enabled in pairs(prev_states) do
					if g and g.Parent then
						g.Enabled = was_enabled
					end
				end
				if next(prev_states) == nil then
					for _, g in ipairs(get_all_guis()) do
						g.Enabled = true
					end
				end
				table.clear(prev_states)
			end
			sync_hide_label()
		end

		local function watch_new_gui(container: Instance?)
			if not container then
				return
			end
			container.ChildAdded:Connect(function(child: Instance)
				if gui_hidden and child:IsA("ScreenGui") then
					if prev_states[child] == nil then
						prev_states[child] = child.Enabled
					end
					child.Enabled = false
					bind_gui_lock(child)
				end
			end)
		end

		watch_new_gui(Players.LocalPlayer and Players.LocalPlayer:FindFirstChildOfClass("PlayerGui"))
		pcall(function()
			watch_new_gui(CoreGui)
		end)

		task.spawn(function()
			while true do
				task.wait(0.25)
				if gui_hidden then
					for _, g in ipairs(get_all_guis()) do
						if prev_states[g] == nil then
							prev_states[g] = g.Enabled
						end
						if g.Enabled then
							g.Enabled = false
						end
						if not enabled_conns[g] then
							bind_gui_lock(g)
						end
					end
				end
			end
		end)

		hide_btn = Instance.new("TextButton")
		hide_btn.Size = UDim2.new(1, 0, 0, 24)
		hide_btn.BackgroundColor3 = P.sidebar
		hide_btn.BackgroundTransparency = 0.12
		hide_btn.BorderSizePixel = 0
		hide_btn.Text = "Hide GUI (Key: K)"
		hide_btn.TextColor3 = P.text
		hide_btn.Font = Enum.Font.GothamBold
		hide_btn.TextSize = 10.5
		hide_btn.AutoButtonColor = false
		hide_btn.LayoutOrder = 4
		hide_btn.Parent = scale_card
		round_all(hide_btn, 6)
		stroke_all(hide_btn, P.accent, 1, 0.35)

		hide_btn.MouseButton1Click:Connect(function()
			set_total_gui_hidden(not gui_hidden)
		end)

		UserInputService.InputBegan:Connect(function(inp: InputObject, game_processed: boolean)
			if game_processed then
				return
			end
			if inp.KeyCode == Enum.KeyCode.K then
				set_total_gui_hidden(not gui_hidden)
			end
		end)
	else
		cfg_card("UI SCALE", function(_, ui)
			ui.slider("Scale (%)", 50, 120, DEFAULT_SCALE_PCT, function(v)
				ui_scale.Scale = v / 100
			end)
		end)
	end
end

misc_card("PERFORMANCE", function(_, ui)
	ui.toggle("Anti Lag Smooth", false, function(v: boolean)
		warn("[HANX DEBUG] Anti Lag Smooth diklik:", v, "ALD_ApplyMode:", type(ALD_ApplyMode))
		if type(ALD_ApplyMode) == "function" then
			ALD_ApplyMode(v and "Smooth" or "None")
		end
	end)

	ui.toggle("Anti Lag Super Smooth", false, function(v: boolean)
		warn("[HANX DEBUG] Anti Lag Super Smooth diklik:", v, "ALD_ApplyMode:", type(ALD_ApplyMode))
		if type(ALD_ApplyMode) == "function" then
			ALD_ApplyMode(v and "SuperSmooth" or "None")
		end
	end)
end)

local cfg_status_lbl: TextLabel? = nil
local cfg_slot_input: TextBox? = nil

local function set_cfg_status(msg: string)
	if cfg_status_lbl and cfg_status_lbl.Parent then
		cfg_status_lbl.Text = "Status: " .. msg .. " | Slot: " .. ConfigStore.ActiveSlot
	end
end

local function delete_config_slot(slot_name: string?): (boolean, string)
	local target = sanitize_slot(slot_name or ConfigStore.ActiveSlot)
	ConfigStore.MemorySlots[target] = nil

	if has_fs_support() and type(delfile) == "function" then
		local fp = slot_file_path(target)
		local ok_ex, exists = pcall(function()
			return isfile(fp)
		end)
		if ok_ex and exists then
			pcall(delfile, fp)
		end
	end

	for idx = 1, #ConfigStore.Slots do
		if ConfigStore.Slots[idx] == target then
			ConfigStore.Slots[idx] = "slot_" .. tostring(idx)
		end
	end

	if ConfigStore.ActiveSlot == target then
		ConfigStore.ActiveSlot = ConfigStore.Slots[1] or "slot_1"
	end
	save_meta()
	return true, "Deleted slot '" .. target .. "'"
end

local function reset_all_config_saves(): (boolean, string)
	ConfigStore.MemorySlots = {}
	ConfigStore.Slots = { "slot_1", "slot_2", "slot_3", "slot_4" }
	ConfigStore.ActiveSlot = "slot_1"

	if has_fs_support() and type(delfile) == "function" then
		if type(listfiles) == "function" then
			local ok_l, files = pcall(listfiles, HANX_CFG_DIR)
			if ok_l and type(files) == "table" then
				for _, fp in ipairs(files) do
					local path_str = tostring(fp)
					if string.match(path_str, "%.json$") then
						pcall(delfile, path_str)
					end
				end
			end
		else
			for idx = 1, 4 do
				local fp = slot_file_path("slot_" .. tostring(idx))
				local ok_ex, exists = pcall(function() return isfile(fp) end)
				if ok_ex and exists then
					pcall(delfile, fp)
				end
			end
			local meta_ex, meta_exists = pcall(function() return isfile(HANX_META_FILE) end)
			if meta_ex and meta_exists then
				pcall(delfile, HANX_META_FILE)
			end
		end
	end

	save_meta()
	return true, "All config saves reset"
end

for _, build_fn in ipairs(page_builders) do
	build_fn()
end

do
	local cfg_page = (type(pages) == "table" and pages["Config"]) or nil
	local parent_container = nil
	if cfg_page then
		local cols = cfg_page:FindFirstChild("ColsWrap")
		parent_container = (cols and (cols:FindFirstChild("LeftColumn") or cols:FindFirstChild("RightColumn"))) or cfg_page
	end
	parent_container = parent_container or left_col or right_col

	if parent_container then
		ConfigStore.Slots = ConfigStore.Slots or { "slot_1", "slot_2", "slot_3", "slot_4" }
		for i = 1, 4 do
			if type(ConfigStore.Slots[i]) ~= "string" or ConfigStore.Slots[i] == "" then
				ConfigStore.Slots[i] = "slot_" .. tostring(i)
			end
		end

		local direct_panel = Instance.new("Frame")
		direct_panel.Name = "DirectConfigNoTab"
		direct_panel.Size = UDim2.new(1, -6, 0, 0)
		direct_panel.AutomaticSize = Enum.AutomaticSize.Y
		direct_panel.BackgroundColor3 = P.card
		direct_panel.BackgroundTransparency = 0.14
		direct_panel.BorderSizePixel = 0
		direct_panel.LayoutOrder = -10
		direct_panel.Parent = parent_container
		round_all(direct_panel, 10)
		stroke_all(direct_panel, P.stroke, 1, 0.35)
		pad_all(direct_panel, 6, 6, 6, 6)

		local p_list = Instance.new("UIListLayout")
		p_list.Padding = UDim.new(0, 4)
		p_list.SortOrder = Enum.SortOrder.LayoutOrder
		p_list.Parent = direct_panel

		local function make_direct_btn(label: string, order_n: number, on_click: () -> ())
			local b = Instance.new("TextButton")
			b.Size = UDim2.new(1, 0, 0, 24)
			b.BackgroundColor3 = P.sidebar
			b.BackgroundTransparency = 0.12
			b.BorderSizePixel = 0
			b.Text = label
			b.TextColor3 = P.text
			b.Font = Enum.Font.GothamBold
			b.TextSize = 10.5
			b.AutoButtonColor = false
			b.LayoutOrder = order_n
			b.Parent = direct_panel
			round_all(b, 6)
			stroke_all(b, P.accent, 1, 0.35)
			b.MouseButton1Click:Connect(on_click)
			return b
		end

		local quick_slots = Instance.new("Frame")
		quick_slots.Size = UDim2.new(1, 0, 0, 22)
		quick_slots.BackgroundTransparency = 1
		quick_slots.LayoutOrder = 1
		quick_slots.Parent = direct_panel

		local q_layout = Instance.new("UIListLayout")
		q_layout.FillDirection = Enum.FillDirection.Horizontal
		q_layout.Padding = UDim.new(0, 3)
		q_layout.Parent = quick_slots

		local slot_box = Instance.new("Frame")
		slot_box.Size = UDim2.new(1, 0, 0, 22)
		slot_box.BackgroundColor3 = P.sidebar
		slot_box.BackgroundTransparency = 0.18
		slot_box.BorderSizePixel = 0
		slot_box.LayoutOrder = 2
		slot_box.Parent = direct_panel
		round_all(slot_box, 6)
		stroke_all(slot_box, P.stroke, 1, 0.50)

		local tb = Instance.new("TextBox")
		tb.Size = UDim2.new(1, -12, 1, 0)
		tb.Position = UDim2.fromOffset(6, 0)
		tb.BackgroundTransparency = 1
		tb.PlaceholderText = "Slot name"
		tb.PlaceholderColor3 = P.muted
		tb.Text = ConfigStore.ActiveSlot
		tb.TextColor3 = P.text
		tb.Font = Enum.Font.GothamMedium
		tb.TextSize = 10.5
		tb.TextXAlignment = Enum.TextXAlignment.Left
		tb.ClearTextOnFocus = false
		tb.Parent = slot_box
		cfg_slot_input = tb

		local rename_box = Instance.new("Frame")
		rename_box.Size = UDim2.new(1, 0, 0, 22)
		rename_box.BackgroundColor3 = P.sidebar
		rename_box.BackgroundTransparency = 0.18
		rename_box.BorderSizePixel = 0
		rename_box.LayoutOrder = 3
		rename_box.Parent = direct_panel
		round_all(rename_box, 6)
		stroke_all(rename_box, P.stroke, 1, 0.50)

		local rename_tb = Instance.new("TextBox")
		rename_tb.Size = UDim2.new(1, -12, 1, 0)
		rename_tb.Position = UDim2.fromOffset(6, 0)
		rename_tb.BackgroundTransparency = 1
		rename_tb.PlaceholderText = "New slot name for Rename..."
		rename_tb.PlaceholderColor3 = P.muted
		rename_tb.Text = ""
		rename_tb.TextColor3 = P.text
		rename_tb.Font = Enum.Font.GothamMedium
		rename_tb.TextSize = 10.5
		rename_tb.TextXAlignment = Enum.TextXAlignment.Left
		rename_tb.ClearTextOnFocus = false
		rename_tb.Parent = rename_box

		local slot_btns = {}
		local selected_slot_idx = 1

		local function refresh_slot_buttons()
			for idx = 1, 4 do
				local btn = slot_btns[idx]
				if btn then
					local s_name = ConfigStore.Slots[idx] or ("slot_" .. tostring(idx))
					btn.Text = s_name
				end
			end
		end

		for idx = 1, 4 do
			local s_btn = Instance.new("TextButton")
			s_btn.Size = UDim2.new(0.25, -2.25, 1, 0)
			s_btn.BackgroundColor3 = P.sidebar
			s_btn.Text = ConfigStore.Slots[idx]
			s_btn.TextColor3 = P.text
			s_btn.Font = Enum.Font.GothamBold
			s_btn.TextSize = 9.5
			s_btn.TextTruncate = Enum.TextTruncate.AtEnd
			s_btn.AutoButtonColor = false
			s_btn.Parent = quick_slots
			round_all(s_btn, 6)
			stroke_all(s_btn, P.stroke, 1, 0.35)
			slot_btns[idx] = s_btn

			s_btn.MouseButton1Click:Connect(function()
				selected_slot_idx = idx
				local current_name = sanitize_slot(ConfigStore.Slots[idx] or ("slot_" .. tostring(idx)))
				ConfigStore.Slots[idx] = current_name
				ConfigStore.ActiveSlot = current_name
				tb.Text = current_name
				save_meta()
				if type(set_cfg_status) == "function" then
					set_cfg_status("Active slot: " .. current_name)
				end
			end)
		end

		tb.FocusLost:Connect(function()
			local raw_txt = tostring(tb.Text or "")
			if string.match(raw_txt, "^%s*$") then
				tb.Text = ConfigStore.ActiveSlot
				return
			end
			local clean_name = sanitize_slot(raw_txt)
			ConfigStore.Slots[selected_slot_idx] = clean_name
			ConfigStore.ActiveSlot = clean_name
			tb.Text = clean_name
			refresh_slot_buttons()
			save_meta()
			if type(set_cfg_status) == "function" then
				set_cfg_status("Active slot: " .. clean_name)
			end
		end)

		make_direct_btn("Save Config", 4, function()
			local raw_txt = tostring(tb.Text or "")
			local target_slot = string.match(raw_txt, "^%s*$") and ConfigStore.ActiveSlot or sanitize_slot(raw_txt)
			ConfigStore.Slots[selected_slot_idx] = target_slot
			ConfigStore.ActiveSlot = target_slot
			tb.Text = target_slot
			refresh_slot_buttons()
			local _, msg = save_config_slot(target_slot)
			if type(set_cfg_status) == "function" then
				set_cfg_status(msg)
			end
		end)

		make_direct_btn("Load Config", 5, function()
			local raw_txt = tostring(tb.Text or "")
			local target_slot = string.match(raw_txt, "^%s*$") and ConfigStore.ActiveSlot or sanitize_slot(raw_txt)
			ConfigStore.Slots[selected_slot_idx] = target_slot
			ConfigStore.ActiveSlot = target_slot
			tb.Text = target_slot
			refresh_slot_buttons()
			local _, msg = load_config_slot(target_slot, false)
			if type(set_cfg_status) == "function" then
				set_cfg_status(msg)
			end
		end)

		make_direct_btn("Rename Slot", 6, function()
			if type(rename_config_slot) == "function" then
				local old_target = string.match(tostring(tb.Text or ""), "^%s*$") and ConfigStore.ActiveSlot or sanitize_slot(tb.Text)
				local new_raw = tostring(rename_tb.Text or "")
				if string.match(new_raw, "^%s*$") then
					if type(set_cfg_status) == "function" then
						set_cfg_status("Enter new slot name first")
					end
					return
				end
				local new_clean = sanitize_slot(new_raw)
				local ok_r, msg_r = rename_config_slot(old_target, new_clean)
				if not ok_r then
					ConfigStore.Slots[selected_slot_idx] = new_clean
					ConfigStore.ActiveSlot = new_clean
					tb.Text = new_clean
					rename_tb.Text = ""
					refresh_slot_buttons()
					local _, s_msg = save_config_slot(new_clean)
					if type(set_cfg_status) == "function" then
						set_cfg_status("Renamed & " .. s_msg)
					end
					return
				end
				ConfigStore.Slots[selected_slot_idx] = ConfigStore.ActiveSlot
				tb.Text = ConfigStore.ActiveSlot
				rename_tb.Text = ""
				refresh_slot_buttons()
				if type(set_cfg_status) == "function" then
					set_cfg_status(msg_r)
				end
			end
		end)

		make_direct_btn("Delete Slot", 7, function()
			local target_slot = string.match(tostring(tb.Text or ""), "^%s*$") and ConfigStore.ActiveSlot or sanitize_slot(tb.Text)
			local _, msg_d = delete_config_slot(target_slot)
			tb.Text = ConfigStore.ActiveSlot
			refresh_slot_buttons()
			if type(set_cfg_status) == "function" then
				set_cfg_status(msg_d)
			end
		end)

		make_direct_btn("Reset Save", 8, function()
			local _, msg_rst = reset_all_config_saves()
			selected_slot_idx = 1
			tb.Text = ConfigStore.ActiveSlot
			rename_tb.Text = ""
			refresh_slot_buttons()
			if type(set_cfg_status) == "function" then
				set_cfg_status(msg_rst)
			end
		end)

		local auto_btn = make_direct_btn("Auto Load Config: " .. (ConfigStore.AutoLoad and "ON" or "OFF"), 9, function()
			local enabled = not ConfigStore.AutoLoad
			ConfigStore.AutoLoad = enabled
			save_meta()
			auto_btn.Text = "Auto Load Config: " .. (enabled and "ON" or "OFF")
			if enabled then
				local _, msg = load_config_slot(ConfigStore.ActiveSlot, false)
				if type(set_cfg_status) == "function" then
					set_cfg_status("Auto Load ON • " .. msg)
				end
			elseif type(set_cfg_status) == "function" then
				set_cfg_status("Auto Load OFF")
			end
		end)

		if type(register_config_item) == "function" then
			register_config_item("HANX_HUB.Config.AutoLoad", "toggle", function()
				return ConfigStore.AutoLoad
			end, function(val)
				ConfigStore.AutoLoad = val == true
				save_meta()
				auto_btn.Text = "Auto Load Config: " .. (ConfigStore.AutoLoad and "ON" or "OFF")
			end)
		end

		local st_lbl = Instance.new("TextLabel")
		st_lbl.Size = UDim2.new(1, 0, 0, 16)
		st_lbl.BackgroundTransparency = 1
		st_lbl.Text = "Status: Ready | Slot: " .. ConfigStore.ActiveSlot
		st_lbl.TextColor3 = P.muted
		st_lbl.Font = Enum.Font.GothamMedium
		st_lbl.TextSize = 10
		st_lbl.TextWrapped = true
		st_lbl.TextXAlignment = Enum.TextXAlignment.Left
		st_lbl.LayoutOrder = 10
		st_lbl.Parent = direct_panel
		cfg_status_lbl = st_lbl
	end
end

if ConfigStore.AutoLoad then
	task.defer(function()
		local _, msg = load_config_slot(ConfigStore.ActiveSlot, false)
		set_cfg_status("Auto Load • " .. msg)
	end)
end

switch_tab("Home")

do
local bottom_bar = Instance.new("Frame")
bottom_bar.Name = "BottomTelemetry"
bottom_bar.Size = UDim2.new(1, 0, 0, 50)
bottom_bar.Position = UDim2.new(0, 0, 1, -50)
bottom_bar.BackgroundColor3 = P.sidebar
bottom_bar.BackgroundTransparency = 0.12
bottom_bar.BorderSizePixel = 0
bottom_bar.ZIndex = 4
bottom_bar.Parent = root
round_all(bottom_bar, 16)
local b_aura_stroke = stroke_all(bottom_bar, P.white_glow, 1.25, 0.20)
local b_aura_grad = Instance.new("UIGradient")
b_aura_grad.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.75),
	NumberSequenceKeypoint.new(0.5, 0.08),
	NumberSequenceKeypoint.new(1, 0.75),
})
b_aura_grad.Parent = b_aura_stroke

task.spawn(function()
	while b_aura_grad.Parent do
		local dt = RunService.RenderStepped:Wait()
		b_aura_grad.Rotation = (b_aura_grad.Rotation + dt * 160) % 360
	end
end)

local function make_stat_cell(label_s: string, init_s: string, x_sc: number, w_sc: number)
	local cell = Instance.new("Frame")
	cell.Size = UDim2.new(w_sc, -4, 1, -10)
	cell.Position = UDim2.new(x_sc, 2, 0, 5)
	cell.BackgroundColor3 = P.card
	cell.BackgroundTransparency = 0.20
	cell.BorderSizePixel = 0
	cell.Parent = bottom_bar
	round_all(cell, 11)
	stroke_all(cell, P.stroke, 1, 0.45)

	local k = Instance.new("TextLabel")
	k.Size = UDim2.new(1, 0, 0, 14)
	k.Position = UDim2.fromOffset(0, 4)
	k.BackgroundTransparency = 1
	k.Text = label_s
	k.TextColor3 = P.muted
	k.Font = Enum.Font.GothamBold
	k.TextSize = 9.5
	k.Parent = cell

	local v = Instance.new("TextLabel")
	v.Size = UDim2.new(1, 0, 0, 16)
	v.Position = UDim2.fromOffset(0, 19)
	v.BackgroundTransparency = 1
	v.Text = init_s
	v.TextColor3 = P.text
	v.Font = Enum.Font.GothamBold
	v.TextSize = 11.5
	v.Parent = cell

	return v
end

local mobile_dev = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
make_stat_cell("DEV", mobile_dev and "MOBILE" or "PC", 0.00, 0.09)
local fps_v = make_stat_cell("FPS", "60", 0.09, 0.09)
local ping_v = make_stat_cell("PING", "0ms", 0.18, 0.10)
local mem_v = make_stat_cell("MEM", "0MB", 0.28, 0.10)
local cpu_v = make_stat_cell("CPU", "0.0ms", 0.38, 0.11)
local gpu_v = make_stat_cell("GPU", "0.0ms", 0.49, 0.11)

local scale_cell = Instance.new("Frame")
scale_cell.Size = UDim2.new(0.40, -4, 1, -10)
scale_cell.Position = UDim2.new(0.60, 2, 0, 5)
scale_cell.BackgroundColor3 = P.card
scale_cell.BackgroundTransparency = 0.20
scale_cell.BorderSizePixel = 0
scale_cell.Parent = bottom_bar
round_all(scale_cell, 11)
stroke_all(scale_cell, P.stroke, 1, 0.45)

local sc_lbl = Instance.new("TextLabel")
sc_lbl.Size = UDim2.new(0.5, -12, 0, 14)
sc_lbl.Position = UDim2.fromOffset(12, 4)
sc_lbl.BackgroundTransparency = 1
sc_lbl.Text = "SCALE"
sc_lbl.TextColor3 = P.muted
sc_lbl.Font = Enum.Font.GothamBold
sc_lbl.TextSize = 9.5
sc_lbl.TextXAlignment = Enum.TextXAlignment.Left
sc_lbl.Parent = scale_cell

local sc_pct = Instance.new("TextLabel")
sc_pct.Size = UDim2.new(0.5, -12, 0, 14)
sc_pct.Position = UDim2.new(0.5, 0, 0, 4)
sc_pct.BackgroundTransparency = 1
sc_pct.Text = tostring(DEFAULT_SCALE_PCT) .. "%"
sc_pct.TextColor3 = P.text
sc_pct.Font = Enum.Font.GothamBold
sc_pct.TextSize = 10.5
sc_pct.TextXAlignment = Enum.TextXAlignment.Right
sc_pct.Parent = scale_cell

local sc_track = Instance.new("Frame")
sc_track.Size = UDim2.new(1, -24, 0, 6)
sc_track.Position = UDim2.fromOffset(12, 26)
sc_track.BackgroundColor3 = P.sidebar
sc_track.BorderSizePixel = 0
sc_track.Parent = scale_cell
round_all(sc_track, 3)

local sc_fill = Instance.new("Frame")
sc_fill.Size = UDim2.new((DEFAULT_SCALE_PCT - 50) / 70, 0, 1, 0)
sc_fill.BackgroundColor3 = P.accent
sc_fill.BorderSizePixel = 0
sc_fill.Parent = sc_track
round_all(sc_fill, 3)

local sc_dragging = false

local function apply_ui_scale(px_x: number)
	local r = math.clamp((px_x - sc_track.AbsolutePosition.X) / math.max(sc_track.AbsoluteSize.X, 1), 0, 1)
	local pct = math.floor(50 + (r * 70) + 0.5)
	ui_scale.Scale = pct / 100
	sc_pct.Text = tostring(pct) .. "%"
	sc_fill.Size = UDim2.new((pct - 50) / 70, 0, 1, 0)
end

sc_track.InputBegan:Connect(function(inp: InputObject)
	if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
		sc_dragging = true
		apply_ui_scale(inp.Position.X)
	end
end)

UserInputService.InputChanged:Connect(function(inp: InputObject)
	if sc_dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
		apply_ui_scale(inp.Position.X)
	end
end)

UserInputService.InputEnded:Connect(function(inp: InputObject)
	if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
		sc_dragging = false
	end
end)

local dt_sum = 0
local frames_sum = 0

RunService.RenderStepped:Connect(function(dt: number)
	dt_sum += dt
	frames_sum += 1
	if dt_sum >= 0.5 then
		fps_v.Text = tostring(math.floor((frames_sum / dt_sum) + 0.5))

		local ok_p, p_val = pcall(function()
			local st = Stats.Network.ServerStatsItem["Data Ping"]
			return st and math.floor(st:GetValue() + 0.5) or 0
		end)
		ping_v.Text = tostring(ok_p and p_val or 0) .. "ms"

		local ok_m, m_val = pcall(function()
			return math.floor(Stats:GetTotalMemoryUsageMb() + 0.5)
		end)
		mem_v.Text = tostring(ok_m and m_val or 0) .. "MB"

		cpu_v.Text = string.format("%.1fms", dt * 1000)
		gpu_v.Text = string.format("%.1fms", math.max(dt * 650, 1.0))

		dt_sum = 0
		frames_sum = 0
	end
end)
end
