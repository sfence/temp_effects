
local has_next_effect = false
local next_effect_time = 0
local time_sum = 0

function temp_effects.add_effect_time(time)
  if (time < next_effect_time) or (not has_next_effect) then
    next_effect_time = time
    has_next_effect = true
  end
end

minetest.register_globalstep(function(dtime)
    if has_next_effect then
      time_sum = time_sum + dtime
      next_effect_time = next_effect_time - dtime
      if (next_effect_time <= 0) then
        -- do effect
        for key,effect in pairs(temp_effects.effects) do
          effect.time_to_effect = effect.time_to_effect - time_sum
          if (effect.time_to_effect<=0) then
            local effect_def = temp_effects.effect_types[effect.effect_type]
            local next_time = effect_def.apply_effect(effect.player_name, effect.params)
            if next_time and (next_time>0) then
              effect.time_to_effect = next_time
              if (next_effect_time<=0) or (next_effect_time>next_time) then
                next_effect_time = next_time
              end
            else
              temp_effects.effects[key] = nil
            end
          else
            if (next_effect_time<=0) or (next_effect_time>effect.time_to_effect) then
              next_effect_time = effect.time_to_effect
            end
          end
        end
        time_sum = 0
        
        if (next_effect_time <= 0) then
          next_effect_time = 0
          has_next_effect = false
        end
      end
    end
  end)

-- on load
if true then
  local storage = temp_effects.mod_storage
  
  local data = storage:get("")
  if data then
    local effects = minetest.deserialize(data)
    for _,effect  in pairs(effects) do
      table.insert(temp_effects.effects, effect)
      temp_effects.add_effect_time(effect.time_to_effect)
    end
  end
end

minetest.register_on_shutdown(function()
    local storage = temp_effects.mod_storage

    for key,effect in pairs(temp_effects.effects) do
      local data = storage:get(effect.player_name)
      local effects = {}
      if data then
        effects = minetest.deserialize(data)
      end
      effect.time_to_effect = effect.time_to_effect - time_sum
      table.insert(effects, effect)
      storage:set_string(effect.player_name, minetest.serialize(effects))
      print("Store effect "..effect.effect_type.." of player "..effect.player_name.." to mod storage on shutdown.")
      minetest.log("verbose", "[temp_effects] Store effect "..effect.effect_type.." of player "..effect.player_name.." to mod storage on shutdown.")
    end
    temp_effects.effects = {}
  end)

minetest.register_on_joinplayer(function(player)
    local storage = temp_effects.mod_storage
    local player_name = player:get_player_name()
    local data = storage:get(player_name)
    if data then
      local effects = minetest.deserialize(data)
      for _,effect in pairs(effects) do
        table.insert(temp_effects.effects, effect)
        temp_effects.add_effect_time(effect.time_to_effect)
        print("Load effect "..effect.effect_type.." of player "..effect.player_name.." from mod storage.")
        minetest.log("verbose", "[temp_effects] Load effect "..effect.effect_type.." of player "..effect.player_name.." from mod storage.")
      end
    end
    storage:set_string(player_name, nil)
  end)

minetest.register_on_leaveplayer(function(player)
    local storage = temp_effects.mod_storage
    local player_name = player:get_player_name()
    local effects = {}
    for key,effect in pairs(temp_effects.effects) do
      if (effect.player_name==player_name) then
        temp_effects.effects[key] = nil
        effect.time_to_effect = effect.time_to_effect - time_sum
        table.insert(effects, effect)
        print("Store effect "..effect.effect_type.." of player "..effect.player_name.." to mod storage on player leaves.")
        minetest.log("verbose", "[temp_effects] Store effect "..effect.effect_type.." of player "..effect.player_name.." to mod storage player leaves.")
      end
    end
    
    if #effects>0 then
      storage:set_string(player_name, minetest.serialize(effects))
    end
  end)

minetest.register_on_dieplayer(function(player)
    local player_name = player:get_player_name()
    for key,effect in pairs(temp_effects.effects) do
      if (effect.player_name==player_name) then
        if (not temp_effects.effect_types[effect.effect_type].keep_when_die) then
          temp_effects.effects[key] = nil
          print("Cancel effect "..effect.effect_type.." of player "..effect.player_name.." because of dead.")
          minetest.log("verbose", "[temp_effects] Cancel effect "..effect.effect_type.." of player "..effect.player_name.." because of dead.")
        end
      end
    end
  end)

