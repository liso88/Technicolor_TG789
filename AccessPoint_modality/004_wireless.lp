<%
-- Localization
gettext.textdomain('webui-core')

local format = string.format
local proxy = require("datamodel")
local ui_helper = require("web.ui_helper")
local content_helper = require("web.content_helper")
local ipairs, ngx, type = ipairs, ngx, type

-- Safe get (prevents template crash and logs root cause)
local function safe_get(...)
  local ok, res = pcall(proxy.get, ...)
  if not ok then
    ngx.log(ngx.ERR, "[wireless-card] proxy.get failed: ", res or "unknown")
    return nil
  end
  return res
end

-- Read all wifi-iface from UCI (lightweight & reliable)
local uci_wifi = safe_get("uci.wireless.wifi-iface.")
local cfg = content_helper.convertResultToObject("uci.wireless.wifi-iface.", uci_wifi) or {}

-- Build the list to render
local ssid_list = {}
for _, v in ipairs(cfg) do
  local name = v.ssid or ""
  if name ~= "" then
    local mapped = (v.network or ""):lower()         -- e.g., "lan", "guest"
    local disabled = tostring(v.disabled or "0")     -- "1" means disabled
    local is_guest = (mapped == "guest") or (name:lower():find("guest", 1, true) ~= nil)

    ssid_list[#ssid_list+1] = {
      ssid  = name,
      state = (disabled == "1") and "0" or "1",      -- 1 = on (green), 0 = off (grey)
      radio = "",                                    -- unknown without rpc; left blank
      net   = is_guest and "guest" or (mapped == "lan" and "lan" or mapped),
    }
  end
end

-- Stable order by SSID
table.sort(ssid_list, function(a,b) return (a.ssid or "") < (b.ssid or "") end)

-- Modal path (unchanged)
local modalPath
local session = ngx.ctx.session
if session and session.hasAccess and session:hasAccess("/modals/wireless-modal.lp") then
  modalPath = "/modals/wireless-modal.lp"
end
%>

<div class="span3">
  <div class="smallcard">
    <%= ui_helper.createCardHeader(T"Reti Wireless", modalPath, nil, nil) %>
    <div class="content">
<%
if #ssid_list == 0 then
  -- Minimal inline diagnostics so you don't just see "..."
  local count = (type(cfg)=="table") and tostring(#cfg) or "nil"
%>
      <p class="wifi-card"><strong style="margin-left:26px;font-size:30px;">...</strong></p>
      <p class="wifi-card" style="font-size:11px;color:#777;margin-left:26px;">
        Nessuna SSID trovata da <code>uci.wireless.wifi-iface.</code> (voci: <%= count %>).
      </p>
<%
else
  for _, v in ipairs(ssid_list) do
    local status = (v.state == "1") and "light green" or "light off"
%>
      <div class="<%= status %>"></div>
      <p class="wifi-card">
        <strong><% if v.net == "guest" then %>Guest: <% end %> <%= v.ssid %></strong>
        (<%= v.radio %>)
      </p>
<%
  end
end
%>
    </div>
  </div>
</div>
