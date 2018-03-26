-- The lowest tax the mayor can set
economy.lowTax = 0

-- The highest tax the mayor can set
economy.highTax = 10

-- The default tax
economy.baseTax = 7.5

-- Economy base income they get ever pay day
economy.baseIncome = 2500

-- How much is in the vault initially
economy.baseBalance = 10000

-- How often should a new dialog appear? In seconds
economy.dialogInterval = 300

-- How long should the dialog last? In seconds
economy.dialogCountdown = 30

economy.registerDialog("Test1", "TestDesc", {"TestDecision1", 1}, {"TestDecision2", 0}, {"TestDecision2", 0}, {"TestDecision2", 0})