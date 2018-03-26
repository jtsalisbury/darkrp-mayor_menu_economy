economy.dialogs = economy.dialogs or {}

/* 
	economy.getMoney()

	Args: None
	Returns the current balance available in the economy
*/
function economy.getMoney()
	return ndoc.table.economy.balance
end

/*
	economy.canAfford(money)

	Args: money <type: number>
	Returns whether or not the money is available in the economy
*/
function economy.canAfford(money)
	money = math.abs(money)

	return economy.getMoney() - money >= 0
end

/*
	economy.registerDialog(name, desc, descision1, ..., decisionN)

	Args:   name <type: string, description: identifier for the dialog>
			description <type: string, description: the query for this dialog>
			... <type: n list of tables, description: each of the tables have two values structured like {"Decision1", PointsToAddToEconomy}>
	Returns: None

	This function registers a dialog and its decisions to the master list. These are then presented at random to the mayor who chooses a decision to either impact the economy or not.
*/
function economy.registerDialog(name, description, ...)
	assert(name, "Must provide a name!")
	assert(description, "Must provide a description for " .. name)

	local decisions = {...}
	assert(#decisions >= 2, "Must provide more than one decision for " .. name)

	table.insert(economy.dialogs, {["name"] = name, ["desc"] = description, ["decisions"] = decisions})
end