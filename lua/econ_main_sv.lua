// Register all sync'd tables
ndoc.table.economy = ndoc.table.economy or {}
ndoc.table.economy.baseIncome = ndoc.table.economy.baseIncome or economy.baseIncome
ndoc.table.economy.taxes = ndoc.table.economy.taxes or economy.baseTax
ndoc.table.economy.balance = ndoc.table.economy.balance or economy.baseBalance
ndoc.table.economy.activeDialog = nil
ndoc.table.economy.dialogCountdown = 0
ndoc.table.economy.status = 100

economy.points = 0
economy.maxPoints = 0

util.AddNetworkString("econ.updateTax")
util.AddNetworkString("econ.sendDialogResult")
util.AddNetworkString("econ.closeDialog")
util.AddNetworkString("econ.openDialog")

/*
	economy.addMoney(money)

	Args: money <type: number, description: adds money to the available balance in the economy>
*/
function economy.addMoney(money)
	money = math.abs(money)

	ndoc.table.economy.balance = ndoc.table.economy.balance + money
end

/* 
	economy.takeMoney(money)

	Args: money <type: number, description: takes a certain value from the economy balance>
*/
function economy.takeMoney(money)
	money = math.abs(money)

	ndoc.table.economy.balance = ndoc.table.economy.balance - money
end

/*
	economy.setMoney(money)

	Args: money <type: number, description: sets the economy money to an exact value>
*/
function economy.setMoney(money)
	ndoc.table.economy.balance = money
end

// Called when the mayor updates the taxes to take out of people's pay checks
net.Receive("econ.updateTax", function(l, client)
	if (client:Team() ~= TEAM_MAYOR) then return end
	
	local amt = math.Round(tonumber(net.ReadString()), 1)
	if (amt < economy.lowTax or amt > economy.highTax) then return end
	amt = math.Round(amt, 1)

	ndoc.table.economy.taxes = amt
end)

// Called when the mayor makes a decision on a dialog result.
net.Receive("econ.sendDialogResult", function(l, client)
	if (ndoc.table.economy.activeDialog == nil or client:Team() ~= TEAM_MAYOR) then return end
		
	timer.Destroy("NewDialogCountdown")
	local dialog = economy.dialogs[ndoc.table.economy.activeDialog]
	economy.maxPoints = economy.maxPoints + 1

	local decision = dialog.decisions[net.ReadInt(32)]
	economy.points = economy.points + decision[2]

	DarkRP.notify(client, 1, 3, decision[2] ~= 0 and "Good decision! " .. decision[2] .. " points have been added to the economy!" or "Oops! No points were added to the economy!")

	local decimal = math.Round(economy.points / economy.maxPoints, 3)
	ndoc.table.economy.baseIncome = economy.baseIncome * decimal
	ndoc.table.economy.status = math.Round(decimal * 100, 1)

	ndoc.table.economy.activeDialog = nil
end)

// Takes the taxes out of a player's pay check, and adds taxes to the economy balance
hook.Add("playerGetSalary", "takeTaxesForEcon", function(ply, amt)
	local taxes = math.Round(amt * (ndoc.table.economy.taxes / 100))
	ndoc.table.economy.balance = ndoc.table.economy.balance + taxes + ndoc.table.economy.baseIncome

	return false, "You've been paid $".. (amt - taxes) .."! $" .. taxes.." was taken out.", (amt - taxes)
end)

// Infinite timer to constantly create a new dialog
timer.Create("NewDialog", economy.dialogInterval, 0, function()
	if (ndoc.table.economy.activeDialog) then 
		ndoc.table.economy.activeDialog = nil
	end

	for k,v in pairs(player.GetAll()) do
		if (v:Team() == TEAM_MAYOR) then
			ndoc.table.economy.dialogCountdown = economy.dialogCountdown
			ndoc.table.economy.activeDialog = math.random(1, #economy.dialogs)

			net.Start("econ.openDialog")
			net.Send(v)

			timer.Create("NewDialogCountdown", 1, economy.dialogCountdown, function()
				ndoc.table.economy.dialogCountdown = ndoc.table.economy.dialogCountdown - 1

				if (ndoc.table.economy.dialogCountdown == 0) then
					ndoc.table.economy.activeDialog = nil
					if (IsValid(v)) then
						net.Start("econ.closeDialog")
						net.Send(v)
					end
				end
			end)
		end
	end
end)

// Test function to make a new dialog
/*concommand.Add("mmd", function()
	if (ndoc.table.economy.activeDialog) then ndoc.table.economy.activeDialog = nil end

	for k,v in pairs(player.GetAll()) do
		if (v:Team() == TEAM_MAYOR) then

			ndoc.table.economy.dialogCountdown = economy.dialogCountdown
			ndoc.table.economy.activeDialog = math.random(1, #economy.dialogs)

			net.Start("econ.openDialog")
			net.Send(v)

			timer.Create("NewDialogCountdown", 1, economy.dialogCountdown, function()
				ndoc.table.economy.dialogCountdown = ndoc.table.economy.dialogCountdown - 1

				if (ndoc.table.economy.dialogCountdown == 0) then
					ndoc.table.economy.activeDialog = nil
					if (IsValid(v)) then
						net.Start("econ.closeDialog")
						net.Send(v)
					end
				end
			end)
		end
	end
end)*/