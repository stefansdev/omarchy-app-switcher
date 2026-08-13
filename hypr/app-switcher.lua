local TAB_KEYCODE = 23
local SUPER_KEYCODES = {
  [133] = true,
  [134] = true,
}

local switching = false

local function super_down()
  local left_ok, left_down = pcall(hl.is_key_down, "Super_L")
  local right_ok, right_down = pcall(hl.is_key_down, "Super_R")
  return (left_ok and left_down == true) or (right_ok and right_down == true)
end

local function commit_selection()
  hl.exec_cmd(
    "omarchy-shell -q shell call stefans.app-switcher commit '' >/dev/null 2>&1"
  )
end

hl.on("input.keyboard.key", function(keycode, _, key_state)
  keycode = tonumber(keycode)

  if key_state == 1 and keycode == TAB_KEYCODE and super_down() then
    switching = true
    return
  end

  if key_state == 0 and SUPER_KEYCODES[keycode] then
    if switching then commit_selection() end
    switching = false
  end
end)

hl.on("config.reloaded", function()
  switching = false
end)
