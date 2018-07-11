---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0122-New_rules_for_providing_VRHelpItems_VRHelpTitle.md
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case:
-- 1. Mobile app adds 20 commands one by one
-- 2. Mobile app deletes 5 commands one by one
-- 3. Perform reopening session
-- 4. Mobile app adds 15 commands after resumption
-- 5. Mobile app adds 31th command
-- SDL does:
-- 1. resume HMI level and AddCommands
-- 2. send SetGlobalProperties with constructed the vrHelp and helpPrompt parameters using added vrCommand
--  after each resumed command
-- 3. send SetGlobalProperties with full list of command values for vrHelp and helpPrompt parameters after each added command
-- 4. not send SetGlobalProperties after added 31th command
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Handling_VR_help_requests/commonVRhelp')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("Pin OnHashChange", common.pinOnHashChange)
runner.Step("App activation", common.activateApp)

runner.Title("Test")
runner.Title("Add 20 commands")
for i = 1, 20 do
  runner.Step("SetGlobalProperties from SDL after added command " ..i, common.addCommandWithSetGP, { i })
end
runner.Title("Delete 5 commands")
for i = 1, 5 do
  runner.Step("SetGlobalProperties from SDL after deleted command " ..i, common.deleteCommandWithSetGP, { i })
end
runner.Step("App reconnect", common.reconnect)
runner.Step("App resumption", common.registrationWithResumption,
  { 1, common.resumptionLevelFull, common.resumptionDataAddCommands })
runner.Title("Add 15 commands")
for i = 21, 35 do
	runner.Step("SetGlobalProperties from SDL after added command " ..i, common.addCommandWithSetGP, { i })
end
runner.Step("Absence SetGlobalProperties from SDL after adding 31 command", common.addCommandWithoutSetGP, { 36 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
