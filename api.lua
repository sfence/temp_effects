
temp_effects.effect_types = {}
temp_effects.effects = {}

local function table_add(orig, added)
  for key,value in pairs(added) do
    if (type(value)=="table") then
      orig[key] = table.copy(value)
    else
      orig[key] = value
    end
  end
end

function temp_effects.register_effect_type(effect_type, effect_def)
  assert(type(effect_def.apply_effect)=="function", "Effect type "..effect_type.." missing apply_effect callback.")
  temp_effects.effect_types[effect_type] = effect_def
end

function temp_effects.add_effect(effect_type, player_name, time_to_effect, effect_params)
  local effect_def = temp_effects.effect_types[effect_type]
  if not effect_def then
    minetest.log("error", "[temp_effects] Unknown effect key "..effect_type.." cannot be added.")
    return
  end
  local effect_data = {
    effect_type = effect_type,
    player_name = player_name,
    time_to_effect = time_to_effect,
    params = effect_params or {},
  }
  if effect_def.params then
    table_add(effect_data.params, effect_def.params)
  end
  table.insert(temp_effects.effects, effect_data)
  temp_effects.add_effect_time(time_to_effect)
end

function temp_effects.get_player_effects(player_name)
  local effects = {}
  for key,effect in pairs(temp_effects.effects) do
    if (effect.player_name==player_name) then
      effects[key] = effect
    end
  end
  return effects
end

function temp_effects.remove_player_effect(key)
  temp_effects.effects[key] = nil
end

