local Primary = Color(46, 49, 54, 255)
local DarkPrimary = Color(30, 33, 36)
local LightPrimary = Color(54, 57, 62, 255)
local Blue = Color(41, 128, 185)
local Green = Color(39, 174, 96)
local Red = Color(231, 76, 60)
local White = Color(230,230,230)

local function computeTaxes()
	local taxes = ndoc.table.economy.taxes / 100
	local money = 0

	for k,v in pairs(player.GetAll()) do
		money = money + math.Round((v:getDarkRPVar("salary") or 0) * taxes)
	end

	return money
end

// Adds an economy menu into the mayor menu
hook.Add("MayorMenuAdditions", "MayorEconomy", function(cback, w, h)
	local pnl = vgui.Create("DPanel")
	pnl:SetSize(w, h)
	local taxes = "$" .. string.Comma(tonumber(computeTaxes()))
	local status = math.Round(ndoc.table.economy.status, 3) --it isn't crucial that this be updated every frame since it only updates after a dialog. just recompute it on opening!
	local status_dec = status / 100
	local statusCol = Color(255 - (255 * status_dec), 255 * status_dec, 0)

	function pnl:Paint(w, h)
		draw.RoundedBox(0, 0, 0, w, h, Primary)

		local econTbl = ndoc.table.economy

		surface.SetFont("Title")
		local balance = "$" .. string.Comma(econTbl.balance)
		local baseIncome = "$" .. string.Comma(econTbl.baseIncome)
		local boxWidth, boxHeight = surface.GetTextSize(balance .. " + " .. taxes .. " + " .. baseIncome)

		local balanceWidth, _ = surface.GetTextSize(balance)
		local taxesWidth, _ = surface.GetTextSize(" + " .. taxes)
		local baseWidth, _ = surface.GetTextSize(" + " .. baseIncome)

		draw.RoundedBox(0, 10, 25, boxWidth + 20, 20 + boxHeight, DarkPrimary)
		draw.SimpleText(balance, "Title", 20, 35 + boxHeight/2, White, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

		draw.SimpleText(" + " .. taxes, "Title", 20 + balanceWidth, 35 + boxHeight/2, Green, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText(" + " .. baseIncome, "Title", 20 + balanceWidth + taxesWidth, 35 + boxHeight/2, Red, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	
		draw.SimpleText("Vault", "SmallTitle", 20 + balanceWidth/2, 10, White, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("Taxes", "SmallTitle", 20 + balanceWidth + taxesWidth/2, 10, Green, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("Base Income", "SmallTitle", 20 + balanceWidth + taxesWidth + baseWidth/2, 10, Red, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	
		draw.SimpleText("Taxes", "SmallTitle", 10, 100, White, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		draw.SimpleText("Status", "SmallTitle", 10, 135, White, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		
		surface.SetDrawColor(DarkPrimary)
		surface.DrawOutlinedRect(135, 135, 175, 25)
		draw.RoundedBox(0, 136, 136, 173 * status_dec, 23, statusCol)
		draw.SimpleText(status .. "%", "SmallTitle", 138, 146.5, White, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end	

	local taxSlider = vgui.Create("DNumSlider", pnl)
	taxSlider:SetPos(10, 100)
	taxSlider:SetSize(300, 25)
	taxSlider:SetText("")
	taxSlider:SetMin(economy.lowTax)
	taxSlider:SetMax(economy.highTax)
	taxSlider:SetDecimals(1)
	taxSlider:SetValue(ndoc.table.economy.taxes)
	function taxSlider.TextArea:Paint(w, h)
		draw.RoundedBox(0, 0, 0, w, h, DarkPrimary)
		self:DrawTextEntryText(Color(255, 255, 255), Color(30, 130, 255), Color(255, 255, 255))
	end
	function taxSlider:OnValueChanged(val)
		val = val or 0
		if (val < self:GetMin()) then self:SetValue(self:GetMin()) end
		if (val > self:GetMax()) then self:SetValue(self:GetMax()) end

		net.Start("econ.updateTax")
			net.WriteString(val)
		net.SendToServer()

		taxes = "$" .. string.Comma(tonumber(computeTaxes()))
	end

	taxSlider.TextArea:SetFont("SmallTitle")

	cback("", "Economy", pnl)
end)

local dialog = nil

// Force close the dialog (ie out of time)
net.Receive("econ.closeDialog", function()
	if (IsValid(dialog)) then 
		dialog:Close()
	end
end)

// For some reason the real height isn't returned from GetTall when autostretchvertical and setwrap are set..
local function computeAutoHeight(text, font, width, spacing)
	surface.SetFont(font)
	local x, y = surface.GetTextSize(text)
	local rows = math.ceil(x / width)

	return y * rows + (spacing * (rows - 1)), rows
end

// Called to open a new dialog for the mayor
net.Receive("econ.openDialog", function()
	if (IsValid(dialog)) then
		dialog:Close()
	end

	local dialogInfo = economy.dialogs[ndoc.table.economy.activeDialog]


	dialog = vgui.Create("DFrame")
	dialog:SetSize(300, 200)
	dialog:ShowCloseButton(false)
	dialog:SetTitle("")
	function dialog:Paint(w, h)
		draw.RoundedBox(0, 0, 0, w, h, Primary)
		draw.RoundedBox(0, 0, 0, w, 30, Blue)
		draw.SimpleText(dialogInfo["name"], "SmallTitle", w / 2, 15, White, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		
		draw.RoundedBox(0, 0, h - 10, (ndoc.table.economy.dialogCountdown / economy.dialogCountdown) * w, 10, White)
	end

	local desc = vgui.Create("DLabel", dialog)
	desc:SetPos(5, 35)
	desc:SetSize(290, 50)
	desc:SetFont("SubTitle")
	desc:SetText(dialogInfo.desc)
	desc:SetWrap(true)
	desc:SetAutoStretchVertical(true)

	local dHeight = computeAutoHeight(dialogInfo.desc, "SubTitle", desc:GetWide(), 2) 
	local btnHeight = 30
	local tHeight = 30 + dHeight
	for k,v in pairs(dialogInfo["decisions"]) do
		local btn = vgui.Create("DButton", dialog)
		btn:SetSize(290, btnHeight)
		btn:SetPos(5, ((k - 1) * btnHeight) + dHeight + 10 + ((k - 1) * 2) + 30)
		btn:SetText("")
		function btn:Paint(w, h)
			local col = LightPrimary
			if (self:IsHovered()) then
				col = DarkPrimary
			end
			if (self:GetDisabled()) then
				col = DarkPrimary	
			end

			draw.RoundedBox(0, 0, 0, w, h, col)
			draw.SimpleText(v[1], "SubTitle", w / 2, h / 2, White, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		function btn:DoClick()
			net.Start("econ.sendDialogResult")
				net.WriteInt(k, 32)
			net.SendToServer()

			dialog:Close()
		end
		
		tHeight = tHeight + btnHeight + 2
	end

	dialog:SetTall(tHeight + 25)
	dialog:SetPos(0, ScrH() / 2 - dialog:GetTall() / 2)
end)