local util = require("luci.util")
local cbi = require("luci.cbi")
local instanceof = util.instanceof

local M = {}

function M.get_cvaluetb(children)
    local cvaluetb = {}
    for _, child in ipairs(children) do
        if instanceof(child, cbi.NamedSection) then
            cvaluetb = child.map:get(child.section)
        end
    end

    return cvaluetb
end

function M.wrap_ubus_calltb_wireless(self, cvaluetb)
    local tmpvaluetb = {}
    tmpvaluetb["ssid"] = cvaluetb["ssid"]
    tmpvaluetb["key"] = cvaluetb["key"]
    tmpvaluetb["hide"] = tonumber(cvaluetb["hidden"])
    tmpvaluetb["accessmode"] = tonumber(cvaluetb["accessmode"])
    tmpvaluetb["accessrule"] = tonumber(cvaluetb["accessrule"])
    tmpvaluetb["allowedipport"] = tonumber(cvaluetb["allowedipport"])
    tmpvaluetb["usbandwidth"] = tonumber(cvaluetb["usbandwidth"])
    tmpvaluetb["dsbandwidth"] = tonumber(cvaluetb["dsbandwidth"])

    local tbauth = {psk = "wpa2psk", psk2 = "wpapsk"}
    tbauth['mixed-psk'] = "wpapskwpa2psk"
    local tbencr = {tkip = "tkip", ccmp = "aes"}
    tbencr['tkip+ccmp'] = "aestkip"

    local wifitype = 1
    local wifidevice = cvaluetb["device"]
    local enable = cvaluetb["disabled"]
    local idx = cvaluetb["idx"]
    local encr = cvaluetb["encryption"]

    cvaluetb["auth"] = tbauth[encr:gsub("%+.+$", "")]
    cvaluetb["encrypt"] = tbencr[encr:gsub("^[^%+]+%+", "")]

    tmpvaluetb["auth"] = cvaluetb["auth"]
    tmpvaluetb["encrypt"] = cvaluetb["encrypt"]

    if enable == "0" then
        cvaluetb["enable"] = "yes"
    elseif enable == "1" then
        cvaluetb["enable"] = "no"
    end

    tmpvaluetb["enable"] = cvaluetb["enable"]

    if wifidevice == "wifi0" then
        wifitype = 2
    elseif wifidevice == "wifi1" then
        wifitype = 1
    end

    local objstr = string.format("ctcapd.wifi.%d.ap.%s", wifitype, idx)

    self.uci:revert("wireless")

    local result = util.ubus(objstr, "set", tmpvaluetb)

end

function M.wrap_ubus_calltb_wan(self, cvaluetb)
    local tmpvaluetb = {}

    if cvaluetb["proto"] == "static" then
        tmpvaluetb["networktype"] = "STATIC"
        tmpvaluetb["ipaddr"] = cvaluetb["ipaddr"]
        tmpvaluetb["subnetmask"] = cvaluetb["netmask"]
        tmpvaluetb["gateway"] = cvaluetb["gateway"]
        tmpvaluetb["dns1"] = cvaluetb["dns"][1]
        tmpvaluetb["dns2"] = cvaluetb["dns"][2]
    elseif cvaluetb["proto"] == "dhcp" then
        tmpvaluetb["networktype"] = "DHCP"
    elseif cvaluetb["proto"] == "pppoe" then
        tmpvaluetb["networktype"] = "PPPOE"
        tmpvaluetb["pppoename"] = cvaluetb["username"]
        tmpvaluetb["pppoepwd"] = cvaluetb["password"]
    end

    local objstr = string.format("ctcapd.waninfo")

    self.uci:revert("network")

    local result = util.ubus(objstr, "set", tmpvaluetb)

end

function M.wrap_ubus_calltb(self, cvaluetb, config)

    if config == "wireless" then
        if cvaluetb[".type"] == "wifi-iface" then
            M.wrap_ubus_calltb_wireless(self, cvaluetb)
        end
    elseif config == "network" then
        if cvaluetb[".type"] == "interface" and cvaluetb[".name"] == "wan" then
            M.wrap_ubus_calltb_wan(self, cvaluetb)
        end
    else
        self.uci:commit(config)
    end
end

return M