---------------------------------------------------------------------------------------------------
-- Issues:
--   https://github.com/smartdevicelink/sdl_core/issues/1617
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/Security/SSLHandshakeFlow/common")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.appName = "Test Application"

--[[ Local Variables ]]

--[[ Local Functions ]]
local function startServiceProtectedACK()
  local serviceId = 7
  common.getMobileSession():StartSecureService(serviceId)
  common.getMobileSession():ExpectControlMessage(serviceId, {
    frameInfo = common.frameInfo.START_SERVICE_ACK,
    encryption = true
  })
  common.getMobileSession():ExpectHandshakeMessage()
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Init SDL certificates", common.initSDLCertificates, { "./files/Security/client_credential.pem" })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("Register App", common.registerApp)
runner.Step("Switch RPC Service to Protected mode ACK", startServiceProtectedACK)
runner.Step("Activate App Protected", common.activateAppProtected)
runner.Step("AddCommand Protected", common.sendAddCommandProtected)

runner.Title("Postconditions")
runner.Step("Stop SDL, clean-up certificates", common.postconditions)
