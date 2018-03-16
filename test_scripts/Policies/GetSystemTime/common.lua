---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local security = require("user_modules/sequences/security")
local utils = require("user_modules/utils")
local test = require("user_modules/dummy_connecttest")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")

--[[ General configuration parameters ]]
config.serverCertificatePath = "./files/Security/GetSystemTime_certificates/spt_credential.pem"
config.serverPrivateKeyPath = "./files/Security/GetSystemTime_certificates/spt_credential.pem"
config.serverCAChainCertPath = "./files/Security/GetSystemTime_certificates/spt_credential.pem"

--[[ Module ]]
local m = actions

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 3
config.isCheckClientCertificate = false
config.application1.registerAppInterfaceParams.appName = "server"
config.application1.registerAppInterfaceParams.appID = "SPT"
m.appHMIType = "DEFAULT"
config.application1.registerAppInterfaceParams.appHMIType = { m.appHMIType }

--[[ Variables ]]
m.frameInfo = security.frameInfo
m.delayedExp = utils.wait
m.readFile = utils.readFile

--[[ Functions ]]
local function GetSystemTimeValue()
  local dd = os.date("*t")
  return {
    millisecond = 0,
    second = dd.sec,
    minute = dd.min,
    hour = dd.hour,
    day = dd.day,
    month = dd.month,
    year = dd.year,
    tz_hour = 2,
    tz_minute = 0
  }
end

function m.setForceProtectedServiceParam(pParamValue)
  m.setSDLIniParameter("ForceProtectedService", pParamValue)
end

function m.getAppID(pAppId)
  return m.getConfigAppParams(pAppId).appID
end

local function allowSDL(self)
  self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {
    allowed = true,
    source = "GUI",
    device = {
      id = utils.getDeviceMAC(),
      name = utils.getDeviceName()
    }
  })
end

function m.start(pOnSystemTime, pHMIParams)
  test:runSDL()
  commonFunctions:waitForSDLStart(test)
  :Do(function()
      test:initHMI()
      :Do(function()
          utils.cprint(35, "HMI initialized")
          test:initHMI_onReady(pHMIParams)
          :Do(function()
              utils.cprint(35, "HMI is ready")
              if pOnSystemTime then
                m.getHMIConnection():SendNotification("BasicCommunication.OnSystemTimeReady")
              end
              test:connectMobile()
              :Do(function()
                  utils.cprint(35, "Mobile connected")
                  allowSDL(test)
                end)
            end)
        end)
    end)
end

function m.ExpectHandshakeMessage(pMobSession, handshakeOccurences, pGetSystemTimeOccur, pTime)
  if not pTime then
    pTime = GetSystemTimeValue()
  end
  pMobSession:ExpectHandshakeMessage()
  :Times(handshakeOccurences)
  EXPECT_HMICALL("BasicCommunication.GetSystemTime")
  :Do(function(_, d)
    m.getHMIConnection():SendResponse(d.id, d.method, "SUCCESS", { systemTime = pTime })
  end)
  :Times(pGetSystemTimeOccur)
end

function m.startServiceSecured(pData, serviceId, pGetSystemTimeOccur, pTime)
  m.getMobileSession():StartSecureService(serviceId)
  m.getMobileSession():ExpectControlMessage(serviceId, pData)

  m.getHMIConnection():ExpectNotification("SDL.OnStatusUpdate")
  :Times(0)

  local handshakeOccurences = 0
  if pData.encryption == true then handshakeOccurences = 1 end
  m.ExpectHandshakeMessage(m.getMobileSession(), handshakeOccurences, pGetSystemTimeOccur, pTime)
end

local function ExpNotDuringPTU()
  m.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { odometer = true })
end

function m.startServiceSecuredwithPTU(pData, serviceId, pGetSystemTimeOccur, pTime, pPTUpdateFunc)
  m.getMobileSession():StartSecureService(serviceId)
  m.getMobileSession():ExpectControlMessage(serviceId, pData)

  m.getHMIConnection():ExpectNotification("SDL.OnStatusUpdate",
    { status = "UPDATE_NEEDED" }, { status = "UPDATING" }, { status = "UP_TO_DATE" })
    :Times(3)
    :Do(function(e)
      if e.occurences == 1 then
        m.policyTableUpdate(pPTUpdateFunc, ExpNotDuringPTU)
      end
    end)

  local handshakeOccurences = 0
  if pData.encryption == true then handshakeOccurences = 1 end
  m.ExpectHandshakeMessage(m.getMobileSession(), handshakeOccurences, pGetSystemTimeOccur, pTime)
end

return m
