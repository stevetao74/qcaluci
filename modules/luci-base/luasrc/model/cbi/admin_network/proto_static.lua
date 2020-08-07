-- Copyright 2011 Jo-Philipp Wich <jow@openwrt.org>
-- Licensed to the public under the Apache License 2.0.

local map, section, net = ...
local ifc = net:get_interface()

local ipaddr, netmask, gateway, broadcast, dns, accept_ra, send_rs, ip6addr, ip6gw
local mtu, metric


ipaddr = section:taboption("general", Value, "ipaddr", translate("IPv4 address"))
ipaddr.datatype = "ip4addr"


netmask = section:taboption("general", Value, "netmask",
	translate("IPv4 netmask"))

netmask.datatype = "ip4addr"
netmask:value("255.255.255.0")
netmask:value("255.255.0.0")
netmask:value("255.0.0.0")


gateway = section:taboption("general", Value, "gateway", translate("IPv4 gateway"))
gateway.datatype = "ip4addr"

dns1 = section:taboption("general", Value, "dns1",	translate("DNS1"))
dns1.datatype = "ip4addr"

dns2 = section:taboption("general", Value, "dns2",	translate("DNS2"))
dns2.datatype = "ip4addr"

function dns1.cfgvalue(self, section)
	local value = self.map:get(section, "dns")
	if value ~= nil and #value > 0 then
		return value[1]
	end
end

function dns2.cfgvalue(self, section)
	local value = self.map:get(section, "dns")
	if value ~= nil and #value > 1 then
		return value[2]
	end
end

function dns1.write(self, section)

end

function dns2.write(self, section, value1, value2)
	local valuetb = {}
	if value1 ~= nil then
		table.insert(valuetb, 1, value1)
	elseif value1 == nil then
		table.insert(valuetb, 1, "")
	end

	if value1 ~= nil then
		table.insert(valuetb, 2, value2)
	elseif value1 == nil then
		table.insert(valuetb, 2, "")
	end
	self.map:set(section, "dns", valuetb)
end

function dns2.parse(self, section, novld)
	local value1 = AbstractValue.formvalue(dns1, section)
	local value2 = AbstractValue.formvalue(dns2, section)
	self:write(section, value1, value2)
end

--[[
broadcast = section:taboption("general", Value, "broadcast", translate("IPv4 broadcast"))
broadcast.datatype = "ip4addr"


dns = section:taboption("general", DynamicList, "dns",
	translate("Use custom DNS servers"))

dns.datatype = "ipaddr"
dns.cast     = "string"

if luci.model.network:has_ipv6() then

	local ip6assign = section:taboption("general", Value, "ip6assign", translate("IPv6 assignment length"),
		translate("Assign a part of given length of every public IPv6-prefix to this interface"))
	ip6assign:value("", translate("disabled"))
	ip6assign:value("64")
	ip6assign.datatype = "max(64)"

	local ip6hint = section:taboption("general", Value, "ip6hint", translate("IPv6 assignment hint"),
		translate("Assign prefix parts using this hexadecimal subprefix ID for this interface."))
	for i=33,64 do ip6hint:depends("ip6assign", i) end

	ip6addr = section:taboption("general", Value, "ip6addr", translate("IPv6 address"))
	ip6addr.datatype = "ip6addr"
	ip6addr:depends("ip6assign", "")


	ip6gw = section:taboption("general", Value, "ip6gw", translate("IPv6 gateway"))
	ip6gw.datatype = "ip6addr"
	ip6gw:depends("ip6assign", "")


	local ip6prefix = s:taboption("general", Value, "ip6prefix", translate("IPv6 routed prefix"),
		translate("Public prefix routed to this device for distribution to clients."))
	ip6prefix.datatype = "ip6addr"
	ip6prefix:depends("ip6assign", "")

end


luci.tools.proto.opt_macaddr(section, ifc, translate("Override MAC address"))


mtu = section:taboption("advanced", Value, "mtu", translate("Override MTU"))
mtu.placeholder = "1500"
mtu.datatype    = "max(9200)"


metric = section:taboption("advanced", Value, "metric",
	translate("Use gateway metric"))

metric.placeholder = "0"
metric.datatype    = "uinteger"
]]--