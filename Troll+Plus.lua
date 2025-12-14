-- ============================================================================
-- Troll+Plus Exodus API Conversion
-- Version 1.1
--
-- IMPORTANT CONVERSION NOTES:
-- This script has been converted to Exodus API following official documentation.
-- The following changes were made:
--
-- 1. system.* -> thread.* (for sleep) 
-- 2. logger.* -> log.*
-- 3. notifications.* -> toast.*
-- 4. math.getRandomFloat/Int/pi() -> standard Lua math functions
-- 5. math.getDistance -> manual calculation
-- 6. Removed invalid script.register_looped() (not in Exodus API)
--
-- NEEDS VERIFICATION:
-- - spawner.*: May need to use game.* or native functions
-- - player.* methods: API may differ, verify syntax
-- - utility.*: May need different approach in Exodus
-- - menu.* methods: Verify exact Exodus menu API syntax per docs
-- - sync.*, pools.*: May not have direct equivalents
-- - Continuous/looped functionality marked with TODO comments
--
-- See https://docs.exodusmenu.com/scripting/ for Exodus API reference
-- ============================================================================

-- Initialization
log.info('<#FFFF00>[<b>Troll+Plus: <#FFFFFF>Loaded!</#FFFF00></b><#FFFF00>]')
toast.show("Have fun trolling :)", "Version 1.1")

-- ============================================================================
-- WARNING: This script uses the following APIs that are NOT documented in 
-- the official Exodus Lua API reference (https://docs.exodusmenu.com/scripting/):
--   - spawner.* (spawnVehicle, spawnPed, spawnObject, deleteVehicle, deletePed, deleteObject)
--   - utility.* (requestControlOfEntity, teleportToCoords, changePlayerModel)
--   - sync.* (addEntitySyncLimit)
--   - pools.* (getObjectsInRadius)
-- These may be custom wrappers, extensions, or may need to be replaced with
-- native game functions or game.* namespace equivalents.
-- ============================================================================

-- Menu
local trolling_id = menu.addSubmenu('player', 'Trolling', 'Trolling options.')
local annoying_id = menu.addSubmenu('player', 'Annoying', 'Annoying options.')
local cage_id = menu.addSubmenu('player', 'Cage', 'Cage options.')
local vehicle_id = menu.addSubmenu('player', 'Vehicle', 'Vehicle options.')
local horse_id = menu.addSubmenu('player', 'Horse', 'Horse options.')
local explosions_id = menu.addSubmenu('player', 'Explosions', 'Explosion options.')
local ptfx_id = menu.addSubmenu('player', 'Ptfx', 'PTFX options.')
local exploits_id = menu.addSubmenu('player', 'Exploits', 'Game Exploits.')
local misc_id = menu.addSubmenu('self', 'Misc', 'Miscellaneous options.')
local session_id = menu.addSubmenu('network', 'Session', 'Session options.')

-- Trolling
local vehicle_models = {
  0xB3C45542,
  0xBE696A8C,
  0x91068FC7,
  0xCEDED274,
  0x85943FE0,
  0xAFB2141B,
  0xDDFBF0AE,
  0x1656E157,
  0x0D10CECB,
  0x02D03A4A,
  0xE98507B4,
  0xF7D816B7,
  0x0598B238,
  0x9324CD4E,
  0xA3EC6EDD
}

local function ram_player(player_idx)
    local target_x, target_y, target_z = player.getCoords(player_idx)
    local target_velocity_x, target_velocity_y, target_velocity_z = native.entity.get_entity_velocity(player.getPed(player_idx), 0)

    local prediction_time = 1.0
    local predicted_x = target_x + target_velocity_x * prediction_time
    local predicted_y = target_y + target_velocity_y * prediction_time
    local predicted_z = target_z + target_velocity_z * prediction_time

    local distance = (math.random() * (24.0 - (20.0)) + (20.0))
    local angle = (math.random() * (2 * math.pi - (0)) + (0))
    local spawn_x = predicted_x + distance * math.cos(angle)
    local spawn_y = predicted_y + distance * math.sin(angle)

    local vehicle_model = vehicle_models[math.random(1, #vehicle_models)]
    local vehicle = spawner.spawnVehicle(vehicle_model, spawn_x, spawn_y, predicted_z, false, true)

    if vehicle then
        local dx = predicted_x - spawn_x
        local dy = predicted_y - spawn_y
        local heading = native.misc.get_heading_from_vector_2d(dx, dy)
        native.entity.set_entity_heading(vehicle, heading)
        thread.sleep(150)
        native.vehicle.set_vehicle_forward_speed(vehicle, 30.0)
    else
        log.error("ERROR: Failed to spawn vehicle.")
        toast.show("ERROR:", "Failed to spawn vehicle.")
    end
end

local function kidnap_player(player_idx)
    local player_ped = player.getPed(player_idx)

    if native.ped.is_ped_on_mount(player_ped) then
        log.error("ERROR: Player is on a mount.")
        toast.show("ERROR", "Player is on a mount.")
        return
    end

    if native.ped.is_ped_in_any_vehicle(player_ped, false) then
        log.error("ERROR: Player is in a vehicle.")
        toast.show("ERROR", "Player is in a vehicle.")
        return
    end

    if native.player.is_player_riding_train(player_idx) then
        log.error("ERROR: Player is on a train.")
        toast.show("ERROR", "Player is on a train.")
        return
    end

    if native.task.is_ped_still(player_ped) then
        toast.show("Status", "Running...")
        thread.sleep(800)

        if native.task.is_ped_still(player_ped) then
            local local_ped = player.getLocalPed()
            local x, y, z = player.getCoords(player_idx)
            local kidnap_vehicle = spawner.spawnVehicle(0xC2D200FE, x, y, z - 1, false, true)

            if kidnap_vehicle then
                if not native.network.network_has_control_of_entity(kidnap_vehicle) then
                    utility.requestControlOfEntity(kidnap_vehicle, 50)
                end
                local target_pitch, target_roll, target_yaw = native.entity.get_entity_rotation(player_ped, 2)
                native.entity.set_entity_rotation(kidnap_vehicle, target_pitch, target_roll, target_yaw, 2, true)
                native.ped.set_ped_into_vehicle(local_ped, kidnap_vehicle, -1)
                toast.show("Status", "Finished.")
            else
                log.error("ERROR: Failed to kidnap player.")
                toast.show("ERROR", "Failed to kidnap player.")
            end
        else
            log.error("ERROR: Player moved.")
            toast.show("ERROR", "Player moved.")
        end
    else
        log.error("ERROR: Player is not standing still.")
        toast.show("ERROR", "Player is not standing still.")
    end
end

local function set_player_on_fire(player_idx)
  local player_ped = player.getPed(player_idx)
  local x, y, z = player.getCoords(player_idx)
  local fire_object = spawner.spawnObject(0x9D3C5512, x, y, z, true)

  if fire_object then
      native.entity.set_entity_alpha(fire_object, 0, false)
      native.entity.attach_entity_to_entity(fire_object, player_ped, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, true, true, 0, true, true, true)
  else
      log.error("ERROR: Failed to spawn fire object.")
      toast.show("ERROR", "Failed to spawn fire object.")
  end
end

local function spam_cage_logs(player_idx)
  local x, y, z = player.getCoords(player_idx)
  spawner.spawnObject(0xF3D580D3, x, y, z - 20, true)
  spawner.spawnObject(0xF3D580D3, x, y + 5, z - 20, true)
  spawner.spawnObject(0xF3D580D3, x, y - 5, z - 20, true)
end

--Attackers
local clone_player = false
local godmode_peds = false
local peds_have_weapons = false
local spawn_as_animal = false
local attacker_count = 1
local spawned_attackers = {}

local random_ped_models = {0xF666E887, 0x838F50CE, 0x9550F451, 0x8F549F46, 0x7CC2FA23, 0xC4CC5EE6, 0xA5F92140, 0xAD789542, 0x0C6E57DB, 0xB545A97B, 0x008F4AD5, 0xF7E2135D, 0xD0A31078, 0xA0600CFB, 0x17C91016, 0x837B740E, 0xD076C393, 0xCF7E73BE, 0xC137D731, 0x0B54641C, 0xA5E02A13, 0xD10CE853, 0x3CF00F0B, 0xE232B9EF, 0x002A0F51, 0x70B728D7, 0xECBDF082, 0x7D65D747, 0x3B777AC0, 0xC7458219, 0x5A3ABACE, 0xE5CED83E, 0x584626EE, 0x2F9417F1, 0x0DB7B411, 0x8DABAE42, 0x542A035C, 0x761D319E, 0x97273585, 0x9DDE71E1, 0x0D4DB92F, 0xEEF71080, 0xB05F73A6, 0xA9DCFB5A, 0xB3410109, 0x5729EC23, 0xD898CFD4, 0x9233448C, 0xBD48CFD4, 0xE40C9EB8, 0x82AF5BFB, 0x950C61AA, 0x7F2FF3A2, 0x6E8E525F, 0x20C236C8, 0xB56ED02B, 0x3A489018, 0x009F6A48, 0x6833EBEE, 0x4335A6E5, 0x1C9C6388, 0x39A29D9C, 0x838F50CE, 0x9550F451, 0x36C66682}
local random_animal_models = {0x8F361781, 0xA0B33A7B, 0xB2C4DE9E, 0x056154F7, 0x629DDF49, 0xBBD91DDA, 0xCB391381, 0xCE924A27, 0xBCFD0E7F}

local function spawn_attacker(player_idx)
  local player_ped = player.getPed(player_idx)
  local x, y, z = player.getCoords(player_idx)
  local model_list = spawn_as_animal and random_animal_models or random_ped_models
  local random_index = math.random(1, #model_list)
  local random_model_hash = model_list[random_index]

  local attacker_ped
  if clone_player then
      attacker_ped = native.ped.clone_ped(player_ped, true, true, true)
  else
      attacker_ped = spawner.spawnPed(random_model_hash, x, y, z, true)
  end

  if attacker_ped then
      table.insert(spawned_attackers, attacker_ped)
      if godmode_peds then
          native.entity.set_entity_invincible(attacker_ped, true)
      end
      if peds_have_weapons then
        native.weapon.give_delayed_weapon_to_ped(attacker_ped, 0x772C8DD6, 69000, true, 0x2CD419DC)
        native.weapon.set_current_ped_weapon(attacker_ped, 0x772C8DD6, true, 0, false, false)
    else
        native.weapon.remove_all_ped_weapons(attacker_ped, true, true)
    end

      native.ped.set_ped_combat_ability(attacker_ped, combat_level)
      native.ped.set_ped_accuracy(attacker_ped, accuracy)
      native.task.task_combat_ped(attacker_ped, player_ped, 0, 16)
      native.ped.set_ped_combat_range(attacker_ped, 4)
      native.ped.set_ped_combat_movement(attacker_ped, 3)
  else
      log.error("ERROR: Failed to spawn attacker.")
      toast.show("ERROR", "Failed to spawn attacker.")
  end
end

menu.addButton(trolling_id, 'Ram Player', '', function(player_idx)
  ram_player(player_idx)
end)

menu.addButton(trolling_id, 'Kidnap Player', '', function(player_idx)
  kidnap_player(player_idx)
end)

menu.addButton(trolling_id, 'Set Player on Fire', '', function(player_idx)
  set_player_on_fire(player_idx)
end)

menu.addButton(trolling_id, 'Spam Cage Logs', '', function(player_idx)
  spam_cage_logs(player_idx)
end)

menu.addButton(trolling_id, 'Spawn Attackers', '', function(player_idx)
    for i = 1, attacker_count do
        spawn_attacker(player_idx)
    end
end)

menu.addIntSpinner(trolling_id, 'Number of Attackers', '', 1, 10, 1, 1, function(value)
  attacker_count = value
end)

menu.addIntSpinner(trolling_id, 'Combat Level', '', 1, 3, 1, 3, function(value)
  combat_level = value
end)

menu.addIntSpinner(trolling_id, 'Accuracy', '', 0, 100, 25, 50, function(value)
  accuracy = value
end)

menu.addToggleButton(trolling_id, 'Peds Have Weapons', '', false, function(toggle)
  peds_have_weapons = toggle
end)

menu.addToggleButton(trolling_id, 'Godmode Peds', '', false, function(toggle)
  godmode_peds = toggle
end)

menu.addToggleButton(trolling_id, 'Clones', '', false, function(toggle)
  clone_player = toggle
end)

menu.addToggleButton(trolling_id, 'Spawn as Animals', '', false, function(toggle)
    spawn_as_animal = toggle
end)

menu.addButton(trolling_id, 'Remove Attackers', '', function()
  for _, attacker in ipairs(spawned_attackers) do
      if utility.requestControlOfEntity(attacker, 50) then
          spawner.deletePed(attacker)
      else
          log.error("ERROR: Failed to gain control of attacker for deletion.")
          toast.show("ERROR", "Failed to gain control of attacker for deletion.")
      end
  end
  spawned_attackers = {}
end)

-- Annoying
local function attach_object_to_player(player_idx, model_hash, bone_index, xOffset, yOffset, zOffset, xRot, yRot, zRot)
  local player_ped = player.getPed(player_idx)
  if player_ped then
      local object = spawner.spawnObject(model_hash, 0.0, 0.0, 0.0, true)
      if object then
          native.entity.attach_entity_to_entity(object, player_ped, bone_index, xOffset, yOffset, zOffset, xRot, yRot, zRot, true, true, true, true, 0, true, true, true)
      else
          log.error("ERROR: Failed to spawn object for attachment.")
      end
  else
      log.error("ERROR: Invalid player index for attachment.")
  end
end

menu.addButton(annoying_id, 'Attach Object 1', '', function(player_idx)
  attach_object_to_player(player_idx, 0xD627AF10, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
end)

menu.addButton(annoying_id, 'Attach Object 2', '', function(player_idx)
  attach_object_to_player(player_idx, 0x0BA09661, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
end)

menu.addButton(annoying_id, 'Attach Object 3', '', function(player_idx)
  attach_object_to_player(player_idx, 0xFE7FA0E6, 0, 0.0, 0.0, - 1.0, 0.0, 0.0, 0.0)
end)

menu.addButton(annoying_id, 'Attach Object 4', '', function(player_idx)
  attach_object_to_player(player_idx, 0x9D3C5512, 0, 0.0, 0.0, - 1.0, 0.0, 0.0, 0.0)
end)

-- Cage
local cage_types = {
  peds = {0xE20455E9, 0xA91215CD, 0xD9E8B86A},
  vehicles = {0x0D10CECB, 0x9AC2F93A, 0xEC2A1018},
  objects = {0x47F582A6, 0xC7AF6993, 0xD3A70902},
  animals = {0xAA89BB8D, 0xBBD91DDA, 0xB91BAB89}
}

local emotes = {
    {hash = 0x0},        -- 1 -- None
    {hash = 0x39C68938}, -- 2 -- Flip Off
    {hash = 0x0EB7A5F2}, -- 3 -- Cry
    {hash = 0x2FDFF3B2}, -- 4 -- Point & Laugh
    {hash = 0xE953BBB7}, -- 5 -- Check Pocket Watch
    {hash = 0xCC2CC3AC}, -- 6 -- Hypnosis Pocket Watch
    {hash = 0x1CFB34E2}, -- 7 -- Point
    {hash = 0x325069E6}, -- 8 -- Prayer
    {hash = 0xB755B5B1}, -- 9 -- Rock Paper Scissors
    {hash = 0x81615BA3}, -- 10 -- Smoke Cigar
    {hash = 0x8B7F8EEB}, -- 11 -- Smoke Cigarette
    {hash = 0xD0528D38}, -- 12 -- Spooky
    {hash = 0xBA51B111}, -- 13 -- Take Notes
    {hash = 0x700DD5CB}, -- 14 -- Greet Tough
    {hash = 0xF2D01E20}, -- 15 -- Reaction Applause
    {hash = 0x09D39270}, -- 16 -- Reaction Beg Mercy
    {hash = 0xC84FB6B6}, -- 17 -- Reaction Clap Along
    {hash = 0xAD799324}, -- 18 -- Reaction Facepalm
}

local selected_emote_index = 1
local spawned_entities = {}
local cage_tasks = {}
local is_cage_active = false
local selected_ped_cage_type = 1
local selected_vehicle_cage_type = 1
local selected_object_cage_type = 1
local selected_animal_cage_type = 1

local function apply_settings(entity, target_x, target_y)
  native.entity.freeze_entity_position(entity, true)
  native.entity.set_entity_invincible(entity, true)
  local ex, ey = native.entity.get_entity_coords(entity, false, false)
  local heading = native.misc.get_heading_from_vector_2d(target_x - ex, target_y - ey)

  if native.entity.is_entity_a_vehicle(entity) then
      native.entity.set_entity_heading(entity, heading)
      native.entity.set_entity_rotation(entity, 90.0, 180.0, heading, 2, true)
  else
      native.entity.set_entity_heading(entity, heading)
  end
end

local function manage_cage_entities(player_idx, entities)
    local px, py, _ = player.getCoords(player_idx)
    for _, entity in ipairs(entities) do
        apply_settings(entity, px, py)
        if native.entity.is_entity_a_ped(entity) and native.ped.is_ped_human(entity) then
            local emote = emotes[selected_emote_index]
            if emote.hash then
                native.task.task_play_emote_with_hash(entity, 0, 1, emote.hash, true, true, false, false, true)
            end
        end
        table.insert(spawned_entities, entity)
    end
end

local function spawn_cage_entities(center_x, center_y, center_z, entities, radius, model_hash, entity_type)
  local angle_step = math.pi * 2 / 8
  for i = 1, 8 do
      local angle = angle_step * i
      local x = center_x + radius * math.cos(angle)
      local y = center_y + radius * math.sin(angle)
      local z = center_z
      local entity
      if entity_type == "ped" or entity_type == "animal" then
          entity = spawner.spawnPed(model_hash, x, y, z - 1, true)
      elseif entity_type == "vehicle" then
          entity = spawner.spawnVehicle(model_hash, x, y, z - 1, true, true)
      elseif entity_type == "object" then
          entity = spawner.spawnObject(model_hash, x, y, z - 1, true)
      end
      if not entity then
          log.error("ERROR: Failed to spawn " .. entity_type .. " entity.")
      else
          table.insert(entities, entity)
      end
  end
end

local function spawn_ped_cage(player_idx)
  local x, y, z = player.getCoords(player_idx)
  local cage_entities = {}
  local model_hash = cage_types.peds[selected_ped_cage_type]
  spawn_cage_entities(x, y, z, cage_entities, 0.8, model_hash, "ped")
  manage_cage_entities(player_idx, cage_entities)
  return cage_entities
end

local function spawn_vehicle_cage(player_idx)
  local x, y, z = player.getCoords(player_idx)
  local cage_entities = {}
  local model_hash = cage_types.vehicles[selected_vehicle_cage_type]
  spawn_cage_entities(x, y, z, cage_entities, 1.5, model_hash, "vehicle")
  manage_cage_entities(player_idx, cage_entities)
  return cage_entities
end

local function spawn_object_cage(player_idx)
  local x, y, z = player.getCoords(player_idx)
  local cage_entities = {}
  local model_hash = cage_types.objects[selected_object_cage_type]
  spawn_cage_entities(x, y, z, cage_entities, 1.2, model_hash, "object")
  manage_cage_entities(player_idx, cage_entities)
  return cage_entities
end

local function spawn_animal_cage(player_idx)
  local x, y, z = player.getCoords(player_idx)
  local cage_entities = {}
  local model_hash = cage_types.animals[selected_animal_cage_type]
  spawn_cage_entities(x, y, z, cage_entities, 1.5, model_hash, "animal")
  manage_cage_entities(player_idx, cage_entities)
  return cage_entities
end

local function remove_cage(cage_entities)
    for _, entity in ipairs(cage_entities) do
        if entity and native.entity.does_entity_exist(entity) then
            if native.entity.is_entity_a_ped(entity) then
                spawner.deletePed(entity)
            elseif native.entity.is_entity_a_vehicle(entity) then
                spawner.deleteVehicle(entity)
            elseif native.entity.is_entity_an_object(entity) then
                spawner.deleteObject(entity)
            end
        end
    end
end

local function get_cage_center(cage_entities)
  local sum_x, sum_y, sum_z = 0, 0, 0
  for _, entity in ipairs(cage_entities) do
      local ex, ey, ez = native.entity.get_entity_coords(entity, false, false)
      sum_x = sum_x + ex
      sum_y = sum_y + ey
      sum_z = sum_z + ez
  end
  return sum_x / #cage_entities, sum_y / #cage_entities, sum_z / #cage_entities
end

local function check_cage_escape(player_idx, cage_entities)
  local player_ped = player.getPed(player_idx)
  local px, py, pz = player.getCoords(player_idx)
  local cage_center_x, cage_center_y, cage_center_z = get_cage_center(cage_entities)
  local dist = math.sqrt(((cage_center_x)-(px))^2 + ((cage_center_y)-(py))^2 + ((cage_center_z)-(pz))^2)

  if dist > 1.5 then
      return true
  end
  return false
end

local function setup_cage_toggle(spawn_func)
    return function(toggle, player_idx)
        if toggle then
            cage_tasks[player_idx] = cage_tasks[player_idx] or {}
            cage_tasks[player_idx].entities = spawn_func(player_idx)
            cage_tasks[player_idx].task = function()
                if check_cage_escape(player_idx, cage_tasks[player_idx].entities) then
                    remove_cage(cage_tasks[player_idx].entities)
                    thread.sleep(500)
                    cage_tasks[player_idx].entities = spawn_func(player_idx)
                end
                thread.sleep(50)
            end
            -- TODO: Implement continuous cage monitoring with proper Exodus pattern
        else
            local cage_data = cage_tasks[player_idx]
            if cage_data then
                remove_cage(cage_data.entities)
                cage_tasks[player_idx] = nil
            end
        end
    end
end

menu.addButton(cage_id, 'Cage with Peds', '', function(player_idx) 
  spawn_ped_cage(player_idx, cage_types.peds[1])
end)

menu.addToggleButton(cage_id, 'Ped Cage Toggle', '', false, setup_cage_toggle(spawn_ped_cage))

menu.addIntSpinner(cage_id, 'Ped Cage Type', '', 1, #cage_types.peds, 1, selected_ped_cage_type, function(value)
  selected_ped_cage_type = value
end)

menu.addIntSpinner(cage_id, 'Select Ped Emote', '', 1, #emotes, 1, selected_emote_index, function(value)
    selected_emote_index = value
end)

menu.addButton(cage_id, 'Cage with Vehicles', '', function(player_idx) 
  spawn_vehicle_cage(player_idx, cage_types.vehicles[1])
end)

menu.addToggleButton(cage_id, 'Vehicle Cage Toggle', '', false, setup_cage_toggle(spawn_vehicle_cage))

menu.addIntSpinner(cage_id, 'Vehicle Cage Type', '', 1, #cage_types.vehicles, 1, selected_vehicle_cage_type, function(value)
  selected_vehicle_cage_type = value
end)

menu.addButton(cage_id, 'Cage with Objects', '', function(player_idx) 
  spawn_object_cage(player_idx, cage_types.objects[1])
end)

menu.addToggleButton(cage_id, 'Object Cage Toggle', '', false, setup_cage_toggle(spawn_object_cage))

menu.addIntSpinner(cage_id, 'Object Cage Type', '', 1, #cage_types.objects, 1, selected_object_cage_type, function(value)
  selected_object_cage_type = value
end)

menu.addButton(cage_id, 'Cage with Animals', '', function(player_idx) 
  spawn_animal_cage(player_idx, cage_types.animals[1])
end)

menu.addToggleButton(cage_id, 'Animal Cage Toggle', '', false, setup_cage_toggle(spawn_animal_cage))

menu.addIntSpinner(cage_id, 'Animal Cage Type', '', 1, #cage_types.animals, 1, selected_animal_cage_type, function(value)
  selected_animal_cage_type = value
end)

local function remove_all_spawned_entities()
  for _, entity in ipairs(spawned_entities) do
      if native.entity.is_entity_a_ped(entity) then
          spawner.deletePed(entity)
      elseif native.entity.is_entity_a_vehicle(entity) then
          spawner.deleteVehicle(entity)
      elseif native.entity.is_entity_an_object(entity) then
          spawner.deleteObject(entity)
      end
  end
  spawned_entities = {}
end

menu.addButton(cage_id, 'Remove All Cages', '', function()
  remove_all_spawned_entities()
end)

-- Vehicle
local function fix_vehicle(player_idx)
    local player_ped = player.getPed(player_idx)
    if native.ped.is_ped_in_any_vehicle(player_ped, false) then
        local vehicle = native.ped.get_vehicle_ped_is_in(player_ped, false)
        if utility.requestControlOfEntity(vehicle, 50) then
            native.vehicle.set_vehicle_fixed(vehicle)
        else
            log.error("ERROR: Failed to gain control of vehicle.")
            toast.show("ERROR", "Failed to gain control of vehicle.")
        end
    else
        log.error("ERROR: Player is not in a vehicle.")
        toast.show("ERROR", "Player is not in a vehicle.")
    end
end

local function godmode_vehicle(player_idx)
    local player_ped = player.getPed(player_idx)
    if native.ped.is_ped_in_any_vehicle(player_ped, false) then
        local vehicle = native.ped.get_vehicle_ped_is_in(player_ped, false)
        if utility.requestControlOfEntity(vehicle, 50) then
            native.entity.set_entity_invincible(vehicle, true)
        else
            log.error("ERROR: Failed to gain control of vehicle.")
            toast.show("ERROR", "Failed to gain control of vehicle.")
        end
    else
        log.error("ERROR: Player is not in a vehicle.")
        toast.show("ERROR", "Player is not in a vehicle.")
    end
end

local function remove_godmode_vehicle(player_idx)
    local player_ped = player.getPed(player_idx)
    if native.ped.is_ped_in_any_vehicle(player_ped, false) then
        local vehicle = native.ped.get_vehicle_ped_is_in(player_ped, false)
        if utility.requestControlOfEntity(vehicle, 50) then
            native.entity.set_entity_invincible(vehicle, false)
        else
            log.error("ERROR: Failed to gain control of vehicle.")
            toast.show("ERROR", "Failed to gain control of vehicle.")
        end
    else
        log.error("ERROR: Player is not in a vehicle.")
        toast.show("ERROR", "Player is not in a vehicle.")
    end
end

local function invisible_vehicle(player_idx)
    local player_ped = player.getPed(player_idx)
    if native.ped.is_ped_in_any_vehicle(player_ped, false) then
        local vehicle = native.ped.get_vehicle_ped_is_in(player_ped, false)
        if utility.requestControlOfEntity(vehicle, 50) then
            native.entity.set_entity_alpha(vehicle, 0, false)
        else
            log.error("ERROR: Failed to gain control of vehicle.")
            toast.show("ERROR", "Failed to gain control of vehicle.")
        end
    else
        log.error("ERROR: Player is not in a vehicle.")
        toast.show("ERROR", "Player is not in a vehicle.")
    end
end

local function remove_invisibility(player_idx)
    local player_ped = player.getPed(player_idx)
    if native.ped.is_ped_in_any_vehicle(player_ped, false) then
        local vehicle = native.ped.get_vehicle_ped_is_in(player_ped, false)
        if utility.requestControlOfEntity(vehicle, 50) then
            native.entity.reset_entity_alpha(vehicle)
        else
            log.error("ERROR: Failed to gain control of vehicle.")
            toast.show("ERROR", "Failed to gain control of vehicle.")
        end
    else
        log.error("ERROR: Player is not in a vehicle.")
        toast.show("ERROR", "Player is not in a vehicle.")
    end
end

local function lock_vehicle(player_idx)
    local player_ped = player.getPed(player_idx)
    if native.ped.is_ped_in_any_vehicle(player_ped, false) then
        local vehicle = native.ped.get_vehicle_ped_is_in(player_ped, false)
        if utility.requestControlOfEntity(vehicle, 50) then
            native.vehicle.set_vehicle_doors_locked(vehicle, 4)
        else
            log.error("ERROR: Failed to gain control of vehicle.")
            toast.show("ERROR", "Failed to gain control of vehicle.")
        end
    else
        log.error("ERROR: Player is not in a vehicle.")
        toast.show("ERROR", "Player is not in a vehicle.")
    end
end

local function unlock_vehicle(player_idx)
    local player_ped = player.getPed(player_idx)
    if native.ped.is_ped_in_any_vehicle(player_ped, false) then
        local vehicle = native.ped.get_vehicle_ped_is_in(player_ped, false)
        if utility.requestControlOfEntity(vehicle, 50) then
            native.vehicle.set_vehicle_doors_locked(vehicle, 1)
        else
            log.error("ERROR: Failed to gain control of vehicle.")
            toast.show("ERROR", "Failed to gain control of vehicle.")
        end
    else
        log.error("ERROR: Player is not in a vehicle.")
        toast.show("ERROR", "Player is not in a vehicle.")
    end
end

local function stop_vehicle(player_idx)
    local player_ped = player.getPed(player_idx)
    if native.ped.is_ped_in_any_vehicle(player_ped, false) then
        local vehicle = native.ped.get_vehicle_ped_is_in(player_ped, false)
        if utility.requestControlOfEntity(vehicle, 50) then
            native.entity.set_entity_velocity(vehicle, 0.0, 0.0, 0.0)
        else
            log.error("ERROR: Failed to gain control of vehicle.")
            toast.show("ERROR", "Failed to gain control of vehicle.")
        end
    else
        log.error("ERROR: Player is not in a vehicle.")
        toast.show("ERROR", "Player is not in a vehicle.")
    end
end

local vehicle_boost_speed = 50.0
local function boost_vehicle(player_idx, speed)
    local player_ped = player.getPed(player_idx)
    if native.ped.is_ped_in_any_vehicle(player_ped, false) then
        local vehicle = native.ped.get_vehicle_ped_is_in(player_ped, false)
        if utility.requestControlOfEntity(vehicle, 50) then
            native.vehicle.set_vehicle_forward_speed(vehicle, speed or vehicle_boost_speed)
        else
            log.error("ERROR: Failed to gain control of vehicle.")
            toast.show("ERROR", "Failed to gain control of vehicle.")
        end
    else
        log.error("ERROR: Player is not in a vehicle.")
        toast.show("ERROR", "Player is not in a vehicle.")
    end
end

local function launch_vehicle(player_idx)
    local player_ped = player.getPed(player_idx)
    if native.ped.is_ped_in_any_vehicle(player_ped, false) then
        local vehicle = native.ped.get_vehicle_ped_is_in(player_ped, false)
        if utility.requestControlOfEntity(vehicle, 50) then
            native.entity.set_entity_velocity(vehicle, 0.0, 0.0, vehicle_boost_speed)
        else
            log.error("ERROR: Failed to gain control of vehicle.")
            toast.show("ERROR", "Failed to gain control of vehicle.")
        end
    else
        log.error("ERROR: Player is not in a vehicle.")
        toast.show("ERROR", "Player is not in a vehicle.")
    end
end

local function teleport_into_vehicle(player_idx)
    local local_ped = player.getLocalPed()
    local player_ped = player.getPed(player_idx)
    if native.ped.is_ped_in_any_vehicle(player_ped, false) then
        local vehicle = native.ped.get_vehicle_ped_is_in(player_ped, false)
        if native.vehicle.are_any_vehicle_seats_free(vehicle) then
            for seat = -1, 4 do
                if native.vehicle.is_vehicle_seat_free(vehicle, seat) then
                    native.ped.set_ped_into_vehicle(local_ped, vehicle, seat)
                    return
                end
            end
            log.error("ERROR: No free seats available in the vehicle.")
            toast.show("ERROR: No free seats available in the vehicle.")
        else
            log.error("ERROR: Vehicle seats are not free.")
            toast.show("ERROR: Vehicle seats are not free.")
        end
    else
        log.error("ERROR: Player is not in a vehicle.")
        toast.show("ERROR", "Player is not in a vehicle.")
    end
end

local function break_off_wheel(player_idx)
    local wheelIndex = math.random(0, 4)
    local player_ped = player.getPed(player_idx)
    if native.ped.is_ped_in_any_vehicle(player_ped, false) then
        local vehicle = native.ped.get_vehicle_ped_is_in(player_ped, false)
        if utility.requestControlOfEntity(vehicle, 50) then
            native.vehicle.break_off_vehicle_wheel(vehicle, wheelIndex)
        else
            log.error("ERROR: Failed to gain control of vehicle.")
            toast.show("ERROR", "Failed to gain control of vehicle.")
        end
    else
        log.error("ERROR: Player is not in a vehicle.")
        toast.show("ERROR", "Player is not in a vehicle.")
    end
end

local function explode_vehicle(player_idx)
    local player_ped = player.getPed(player_idx)
    if native.ped.is_ped_in_any_vehicle(player_ped, false) then
        local vehicle = native.ped.get_vehicle_ped_is_in(player_ped, false)
        if utility.requestControlOfEntity(vehicle, 50) then
            native.vehicle.explode_vehicle(vehicle, true, true, 0, 0)
        else
            log.error("ERROR: Failed to gain control of vehicle.")
            toast.show("ERROR", "Failed to gain control of vehicle.")
        end
    else
        log.error("ERROR: Player is not in a vehicle.")
        toast.show("ERROR", "Player is not in a vehicle.")
    end
end

local function delete_vehicle(player_idx)
    local player_ped = player.getPed(player_idx)
    if native.ped.is_ped_in_any_vehicle(player_ped, false) then
        local vehicle = native.ped.get_vehicle_ped_is_in(player_ped, false)
        if utility.requestControlOfEntity(vehicle, 50) then
            spawner.deleteVehicle(vehicle)
        else
            log.error("ERROR: Failed to gain control of vehicle.")
            toast.show("ERROR", "Failed to gain control of vehicle.")
        end
    else
        log.error("ERROR: Player is not in a vehicle.")
        toast.show("ERROR", "Player is not in a vehicle.")
    end
end

local function rotate_vehicle(player_idx, degrees)
    local player_ped = player.getPed(player_idx)
    if native.ped.is_ped_in_any_vehicle(player_ped, false) then
        local vehicle = native.ped.get_vehicle_ped_is_in(player_ped, false)
        if utility.requestControlOfEntity(vehicle, 50) then
            local pitch, roll, yaw = native.entity.get_entity_rotation(vehicle, 2)
            native.entity.set_entity_rotation(vehicle, pitch, roll, yaw + degrees, 2, true)
        else
            log.error("ERROR: Failed to gain control of vehicle.")
            toast.show("ERROR", "Failed to gain control of vehicle.")
        end
    else
        log.error("ERROR: Player is not in a vehicle.")
        toast.show("ERROR", "Player is not in a vehicle.")
    end
end

menu.addButton(vehicle_id, 'Fix Vehicle', '', function(player_idx)
    fix_vehicle(player_idx)
end)

menu.addButton(vehicle_id, 'Godmode Vehicle', '', function(player_idx)
    godmode_vehicle(player_idx)
end)

menu.addButton(vehicle_id, 'Remove Godmode', '', function(player_idx)
    remove_godmode_vehicle(player_idx)
end)

menu.addButton(vehicle_id, 'Invisible Vehicle', '', function(player_idx)
    invisible_vehicle(player_idx)
end)

menu.addButton(vehicle_id, 'Remove Invisibility', '', function(player_idx)
    remove_invisibility(player_idx)
end)

menu.addButton(vehicle_id, 'Lock Vehicle', '', function(player_idx)
    lock_vehicle(player_idx)
end)

menu.addButton(vehicle_id, 'Unlock Vehicle', '', function(player_idx)
    unlock_vehicle(player_idx)
end)

menu.addButton(vehicle_id, 'Stop Vehicle', '', function(player_idx)
    stop_vehicle(player_idx)
end)

menu.addButton(vehicle_id, 'Boost Vehicle', '', function(player_idx)
    boost_vehicle(player_idx, vehicle_boost_speed)
end)

menu.addFloatSpinner(vehicle_id, 'Boost Speed', '', 10.0, 1000.0, 10.0, vehicle_boost_speed, function(value)
    vehicle_boost_speed = value
end)

menu.addButton(vehicle_id, 'Launch Vehicle', '', function(player_idx)
    launch_vehicle(player_idx)
end)

menu.addButton(vehicle_id, 'Teleport Into Vehicle', '', function(player_idx)
    teleport_into_vehicle(player_idx)
end)

menu.addButton(vehicle_id, 'Break Off Random Wheel', '', function(player_idx)
    break_off_wheel(player_idx)
end)

menu.addButton(vehicle_id, 'Explode Vehicle', '', function(player_idx)
    explode_vehicle(player_idx)
end)

menu.addButton(vehicle_id, 'Delete Vehicle', '', function(player_idx)
    delete_vehicle(player_idx)
end)

menu.addButton(vehicle_id, 'Rotate Vehicle 90� Degrees', '', function(player_idx)
    rotate_vehicle(player_idx, 90)
end)

menu.addButton(vehicle_id, 'Rotate Vehicle 180� Degrees', '', function(player_idx)
    rotate_vehicle(player_idx, 180)
end)

-- Horse
local function buck_off_player(player_idx)
  local player_ped = player.getPed(player_idx)
  if native.ped.is_ped_on_mount(player_ped) then
      local horse = native.ped.get_mount(player_ped)
      if horse then
          utility.requestControlOfEntity(horse, 50)
          native.task.task_horse_action(horse, 2, horse, 0)
      else
          log.error("ERROR: Player is on a mount, but unable to get the horse entity.")
          toast.show("ERROR", "Player is on a mount, but unable to get the horse entity.")
      end
  else
      log.error("ERROR: Player is not on a horse.")
      toast.show("ERROR", "Player is not on a horse.")
  end
end

local buck_off_task
local function buck_off_loop(player_idx)
    if buck_off_task then
        local player_ped = player.getPed(player_idx)
        if native.ped.is_ped_on_mount(player_ped) then
            buck_off_player(player_idx)
        end
        thread.sleep(2000)
    end
end

local function come_to_me(player_idx)
  local player_ped = player.getPed(player_idx)
  local local_ped = player.getLocalPed()
  local horse = nil

  if native.ped.is_ped_on_mount(player_ped) then
      horse = native.ped.get_mount(player_ped)
  else
      horse = native.ped.get_last_mount(player_ped)
  end

  if horse and not native.entity.is_entity_dead(horse) then
      if utility.requestControlOfEntity(horse, 50) then
        native.task.task_go_to_entity(horse, local_ped, -1, 1.0, 5.0, 0.0, 0)
      else
          log.error("ERROR: Failed to gain control of horse.")
          toast.show("ERROR", "Failed to gain control of horse.")
      end
  else
      log.error("ERROR: Player is not on a horse or no last horse found.")
      toast.show("ERROR", "Player is not on a horse or no last horse found.")
  end
end

local function steal_mount(player_idx)
    local player_ped = player.getPed(player_idx)
    local local_ped = player.getLocalPed()
    local horse = nil

    if native.ped.is_ped_on_mount(player_ped) then
        horse = native.ped.get_mount(player_ped)
    else
        horse = native.ped.get_last_mount(player_ped)
        if horse and native.entity.is_entity_dead(horse) then
            horse = nil
        end
    end

    if horse and not native.entity.is_entity_dead(horse) then
        if utility.requestControlOfEntity(horse, 50) then
            if native.ped.is_ped_on_mount(player_ped) then
                toast.show("Status", "Running...")
                native.task.task_horse_action(horse, 2, horse, 0)

                local start_time = time.milliseconds()
                local steal_mount_task = function()
                    local current_time = time.milliseconds()
                    if (current_time - start_time) > 10000 then
                        toast.show("ERROR", "Operation timed out.")
                        log.error("ERROR: Operation timed out.")
                    elseif not native.network.network_has_control_of_entity(horse) then
                        utility.requestControlOfEntity(horse, 50)
                    elseif native.ped.is_mount_seat_free(horse, -1) and native.ped.can_ped_be_mounted(horse) then
                        native.ped.set_mount_security_enabled(horse, false)
                        native.ped.set_ped_onto_mount(local_ped, horse, -1, true)
                        toast.show("Status", "Finished.")
                    end
                end
                -- TODO: Implement continuous mount steal monitoring with proper Exodus pattern
            else
                native.ped.set_mount_security_enabled(horse, false)
                native.ped.set_ped_onto_mount(local_ped, horse, -1, true)
            end
        else
            log.error("ERROR: Failed to gain control of horse.")
            toast.show("ERROR: Failed to gain control of horse.")
        end
    else
        log.error("ERROR: Player is not on a horse or no last horse found.")
        toast.show("ERROR: Player is not on a horse or no last horse found.")
    end
end

local function ragdoll_horse(player_idx)
  local player_ped = player.getPed(player_idx)
  local horse = nil

  if native.ped.is_ped_on_mount(player_ped) then
      horse = native.ped.get_mount(player_ped)
  else
      horse = native.ped.get_last_mount(player_ped)
  end

  if horse and not native.entity.is_entity_dead(horse) then
      if utility.requestControlOfEntity(horse, 50) then
          native.ped.set_ped_to_ragdoll(horse, 1000, 1000, 0, false, false, false)
      else
          log.error("ERROR: Failed to gain control of horse.")
      end
  else
      log.error("ERROR: Player is not on a horse or no last horse found.")
      toast.show("ERROR", "Player is not on a horse or no last horse found.")
  end
end

local function launch_horse(player_idx)
  local player_ped = player.getPed(player_idx)
  local horse = nil

  if native.ped.is_ped_on_mount(player_ped) then
      horse = native.ped.get_mount(player_ped)
  else
      horse = native.ped.get_last_mount(player_ped)
  end

  if horse and not native.entity.is_entity_dead(horse) then
      if utility.requestControlOfEntity(horse, 50) then
          local x, y, z = native.entity.get_entity_coords(horse, false, false)
          native.entity.set_entity_velocity(horse, 0.0, 0.0, 100.0)
          log.info("INFO: Launched horse.")
      else
          log.error("ERROR: Failed to gain control of horse.")
          toast.show("ERROR", "Failed to gain control of horse.")
      end
  else
      log.error("ERROR: Player is not on a horse or no last horse found.")
      toast.show("ERROR", "Player is not on a horse or no last horse found.")
  end
end

local function set_horse_on_fire(player_idx)
  local player_ped = player.getPed(player_idx)
  local horse = nil

  if native.ped.is_ped_on_mount(player_ped) then
      horse = native.ped.get_mount(player_ped)
  else
      horse = native.ped.get_last_mount(player_ped)
      if horse and native.entity.is_entity_dead(horse) then
          horse = nil
      end
  end

  if horse then
      local x, y, z = native.entity.get_entity_coords(horse, false, false)
      local fire_object = spawner.spawnObject(0x9D3C5512, x, y, z, true)

      if fire_object then
          native.entity.set_entity_alpha(fire_object, 0, false)
          native.entity.attach_entity_to_entity(fire_object, horse, 4, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, true, true, 0, true, true, true)
      else
          log.error("ERROR: Failed to spawn fire object.")
          toast.show("ERROR", "Failed to spawn fire object.")
      end
  else
      log.error("ERROR: Player is not on a horse or no last horse found.")
      toast.show("ERROR", "Player is not on a horse or no last horse found.")
  end
end

local function make_horse_bleed_out(player_idx)
  local player_ped = player.getPed(player_idx)
  local horse = nil

  if native.ped.is_ped_on_mount(player_ped) then
      horse = native.ped.get_mount(player_ped)
  else
      horse = native.ped.get_last_mount(player_ped)
  end

  if horse and not native.entity.is_entity_dead(horse) then
      if utility.requestControlOfEntity(horse, 50) then
          native.task.task_animal_bleed_out(horse, 0, false, 0, 0, 0, 0)
      else
          log.error("ERROR: Failed to gain control of horse.")
      end
  else
      log.error("ERROR: Player is not on a horse or no last horse found.")
      toast.show("ERROR", "Player is not on a horse or no last horse found.")
  end
end

local function kill_horse(player_idx)
  local player_ped = player.getPed(player_idx)
  local horse = nil

  if native.ped.is_ped_on_mount(player_ped) then
      horse = native.ped.get_mount(player_ped)
  else
      horse = native.ped.get_last_mount(player_ped)
  end

  if horse and not native.entity.is_entity_dead(horse) then
      if utility.requestControlOfEntity(horse, 50) then
          native.ped.apply_damage_to_ped(horse, 1000, 0, 0, 0)
      else
          log.error("ERROR: Failed to gain control of horse.")
          toast.show("ERROR", "Failed to gain control of horse.")
      end
  else
      log.error("ERROR: Player is not on a horse or no last horse found.")
      toast.show("ERROR", "Player is not on a horse or no last horse found.")
  end
end

menu.addButton(horse_id, 'Buck Off Player', '', function(player_idx)
  buck_off_player(player_idx)
end)

menu.addToggleButton(horse_id, 'Buck Off Player Loop', '', false, function(toggle, player_idx)
    if toggle then
        buck_off_task = function() buck_off_loop(player_idx) end
        -- TODO: Implement continuous buck off with proper Exodus pattern
    else
        if buck_off_task then
            buck_off_task = nil
        end
    end
end)

menu.addButton(horse_id, 'Come To Me', '', function(player_idx)
  come_to_me(player_idx)
end)

menu.addButton(horse_id, 'Steal Mount', '', function(player_idx)
  steal_mount(player_idx)
end)

menu.addButton(horse_id, 'Ragdoll Horse', 'Note: use Buck Off First', function(player_idx)
  ragdoll_horse(player_idx)
end)

menu.addButton(horse_id, 'Launch Horse', 'NOTE: May have to use buck off first.', function(player_idx)
  launch_horse(player_idx)
end)

menu.addButton(horse_id, 'Set Horse on Fire', 'NOTE: This only works on non player owned mounts & Ragdolled Mounts.', function(player_idx)
  set_horse_on_fire(player_idx)
end)

menu.addButton(horse_id, 'Make Horse Bleed Out', 'Note: use Buck Off First', function(player_idx)
  make_horse_bleed_out(player_idx)
end)

menu.addButton(horse_id, 'Kill Horse', 'Note: use Buck Off First', function(player_idx)
  kill_horse(player_idx)
end)

-- Explosions
local explosion_type = 0
local damage_scale = 5
local is_audible = true
local is_invisible = false
local camera_shake = 1.0
local explosion_delay = 1000

local function trigger_explosion(x, y, z, blame_player_ped)
    if x and y and z then
        if blame_player_ped and native.entity.does_entity_exist(blame_player_ped) then
            native.fire.add_owned_explosion(blame_player_ped, x, y, z, explosion_type, damage_scale, is_audible, is_invisible, camera_shake)
        else
            native.fire.add_explosion(x, y, z, explosion_type, damage_scale, is_audible, is_invisible, camera_shake)
        end
    else
        log.error('ERROR: Explosion coordinates are invalid.')
        toast.show('ERROR', 'Explosion coordinates are invalid.')
    end
end

menu.addButton(explosions_id, 'Explode Player', '', function(player_idx)
    local x, y, z = player.getCoords(player_idx)
    if x and y and z then
        trigger_explosion(x, y, z)
    else
        log.error('ERROR: Failed to retrieve player coordinates.')
        toast.show('ERROR', 'Failed to retrieve player coordinates.')
    end
end)

local explode_player_task
menu.addToggleButton(explosions_id, 'Explode Player Toggle', '', false, function(toggle, player_idx)
    if toggle then
        explode_player_task = function()
            if not native.network.network_is_player_connected(player_idx) then
                explode_player_task = nil
                return
            end
            local x, y, z = player.getCoords(player_idx)
            trigger_explosion(x, y, z)
            thread.sleep(explosion_delay)
        end
        -- TODO: Implement continuous explosion with proper Exodus pattern
    else
        explode_player_task = nil
    end
end)

local selected_player_ped_to_blame
menu.addButton(explosions_id, 'Blame Explode Lobby', '', function(player_idx)
    selected_player_ped_to_blame = player.getPed(player_idx)
    player.forEach(function(p)
        local x, y, z = player.getCoords(p.id)
        trigger_explosion(x, y, z, selected_player_ped_to_blame)
    end)
end)

local explode_lobby_task
menu.addToggleButton(explosions_id, 'Blame Explode Lobby Toggle', '', false, function(toggle, player_idx)
    selected_player_ped_to_blame = player.getPed(player_idx)
    if toggle then
        explode_lobby_task = function()
            if not native.network.network_is_player_connected(player_idx) then
                explode_lobby_task = nil
                return
            end
            player.forEach(function(p)
                local x, y, z = player.getCoords(p.id)
                trigger_explosion(x, y, z, selected_player_ped_to_blame)
            end)
            thread.sleep(explosion_delay)
        end
        -- TODO: Implement continuous lobby explosion with proper Exodus pattern
    else
        explode_lobby_task = nil
    end
end)

menu.addIntSpinner(explosions_id, 'Explosion Type', '', 0, 35, 1, 0, function(value)
    explosion_type = value
end)

menu.addIntSpinner(explosions_id, 'Damage Scale', '', 0, 100, 10, 50, function(value)
    damage_scale = value
end)

menu.addIntSpinner(explosions_id, 'Explosion Delay ms', '', 0, 5000, 100, explosion_delay, function(value)
    explosion_delay = value
end)

menu.addToggleButton(explosions_id, 'Audible', '', true, function(toggle)
    is_audible = toggle
end)

menu.addToggleButton(explosions_id, 'Visible', '', true, function(toggle)
    is_invisible = not toggle
end)

menu.addFloatSpinner(explosions_id, 'Camera Shake', '', 0.0, 10, 0.1, 1.0, function(value)
    camera_shake = value
end)

-- PTFX
local ptfx_tasks = {}

local function start_ptfx(asset_name, effect_name, player_idx, scale)
  if not player_idx or player_idx < 0 then
      log.error("ERROR: Invalid player index for PTFX.")
      toast.show("ERROR", "Invalid player index for PTFX.")
      return
  end

  native.graphics.use_particle_fx_asset(asset_name)
  local x, y, z = player.getCoords(player_idx)

  if x and y and z then
      native.graphics.start_networked_particle_fx_non_looped_at_coord(effect_name, x, y, z, 0.0, 0.0, 0.0, scale, false, false, false)
  else
      log.error("ERROR: Failed to get player coordinates for PTFX.")
      toast.show("ERROR", "Failed to get player coordinates for PTFX.")
  end
end

local function toggle_ptfx(asset_name, effect_name, scale, toggle, player_idx)
  if toggle then
      local ptfx_task = function()
          if not native.network.network_is_player_connected(player_idx) then
              ptfx_tasks[effect_name] = nil
              return
          end
          start_ptfx(asset_name, effect_name, player_idx, scale)
          thread.sleep(0)
      end
      ptfx_tasks[effect_name] = ptfx_task
      -- TODO: Implement continuous PTFX with proper Exodus pattern
  else
      local ptfx_task = ptfx_tasks[effect_name]
      if ptfx_task then
          ptfx_tasks[effect_name] = nil
      end
  end
end

menu.addToggleButton(ptfx_id, 'Toggle Laggy PTFX 1', '', false, function(toggle, player_idx)
  toggle_ptfx("SCR_NET_BEAT_WAGON_LIFT", "SCR_NET_BEAT_WAGON_DUST", 10.0, toggle, player_idx)
end)

menu.addToggleButton(ptfx_id, 'Toggle Laggy PTFX 2', '', false, function(toggle, player_idx)
  toggle_ptfx("anm_impacts", "ent_anim_gen_linger_smoke", 50.0, toggle, player_idx)
end)

menu.addToggleButton(ptfx_id, 'Toggle Laggy PTFX 3', '', false, function(toggle, player_idx)
  toggle_ptfx("scr_train_robbery3", "scr_trn_exp_bridge", 10.0, toggle, player_idx)
end)

menu.addToggleButton(ptfx_id, 'Toggle Laggy PTFX 4', '', false, function(toggle, player_idx)
  toggle_ptfx("anm_oddf", "ent_anim_oddf_firework_burst", 100.0, toggle, player_idx)
end)

menu.addToggleButton(ptfx_id, 'Toggle Laggy PTFX 5', '', false, function(toggle, player_idx)
  toggle_ptfx("anm_lom", "ent_anim_lom_cig_exhale_mth", 50.0, toggle, player_idx)
end)

menu.addToggleButton(ptfx_id, 'Toggle Annoying PTFX 1', '', false, function(toggle, player_idx)
  toggle_ptfx("anm_rally", "ent_anim_rally_cross_fire", 10.0, toggle, player_idx)
end)

menu.addToggleButton(ptfx_id, 'Toggle Annoying PTFX 2', '', false, function(toggle, player_idx)
  toggle_ptfx("anm_shows", "ent_anim_magician_smoke", 10.0, toggle, player_idx)
end)

-- Exploits
local function bug_vehicle(player_idx)
    local player_ped = player.getPed(player_idx)

    if native.ped.is_ped_in_any_vehicle(player_ped, false) then
        local vehicle = native.ped.get_vehicle_ped_is_in(player_ped, false)

        if native.vehicle.are_any_vehicle_seats_free(vehicle) then
            local available_seats = {}
            for i = -1, 4 do
                if native.vehicle.is_vehicle_seat_free(vehicle, i) then
                    table.insert(available_seats, i)
                end
            end

            if #available_seats > 0 then
                local random_seat_index = available_seats[math.random(1, #available_seats)]
                local x, y, z = native.entity.get_entity_coords(player_ped, false, false)
                local local_player = player.getLocalPed()

                native.ped.set_ped_into_vehicle(local_player, vehicle, random_seat_index)
                native.vehicle.set_vehicle_exclusive_driver(vehicle, local_player, 1)
            else
                log.error("ERROR: No free seats available in the vehicle.")
                toast.show("ERROR", "No free seats available in the vehicle.")
            end
        else
            log.error("ERROR: No free seats available in the vehicle.")
            toast.show("ERROR", "No free seats available in the vehicle.")
        end
    else
        log.error("ERROR: Player is not in a vehicle.")
        toast.show("ERROR", "Player is not in a vehicle.")
    end
end

local function remove_vehicle_godmode(player_idx)
  local player_ped = player.getPed(player_idx)
  if native.ped.is_ped_in_any_vehicle(player_ped, false) then
      local vehicle = native.ped.get_vehicle_ped_is_in(player_ped, false)
      if utility.requestControlOfEntity(vehicle, 50) then
          native.vehicle.set_vehicle_can_break(vehicle, true)
          native.entity.set_entity_invincible(vehicle, false)
          native.entity.set_entity_can_be_damaged(vehicle, true)
          native.entity.set_entity_proofs(vehicle, 0, false)
          native.vehicle.explode_vehicle(vehicle, true, true, 0, 0)
      else
          log.error("ERROR: Failed to gain control of the vehicle.")
          toast.show("ERROR", "Failed to gain control of the vehicle.")
      end
  else
      log.error("ERROR: Player is not in a vehicle.")
      toast.show("ERROR", "Player is not in a vehicle.")
  end
end

local function remove_player_godmode(player_idx)
    local player_ped = player.getPed(player_idx)
    local x, y, z = player.getCoords(player_idx)
    if utility.requestControlOfEntity(player_ped, 50) then -- Ive been told this doesnt work but the code runs so it must work right? idek anymore �\_(?)_/�
        native.entity.set_entity_can_be_damaged(player_ped, true)
        native.entity.set_entity_invincible(player_ped, false)
        native.entity.set_entity_can_be_damaged(player_ped, true)
        native.entity.set_entity_proofs(player_ped, 0, false)
        native.ped.apply_damage_to_ped(player_ped, 1000, 0, 0, 0)
        native.fire.add_explosion(x, y, z, 27, 10000.0, false, true, 0.0)
    else
        log.error("ERROR: Failed to gain control of the player.")
        toast.show("ERROR", "Failed to gain control of the player.")
    end
end

local function teleport_player(player_idx)
  toast.show("Status", "Running...")
  local player_ped = player.getPed(player_idx)
  if not native.ped.is_ped_on_mount(player_ped) and 
     not native.ped.is_ped_in_any_vehicle(player_ped, false) and 
     not native.player.is_player_riding_train(player_idx) then

      if native.task.is_ped_still(player_ped) then
          thread.sleep(800)
          if native.task.is_ped_still(player_ped) then
              local local_x, local_y, local_z = player.getLocalPedCoords()
              local x, y, z = player.getCoords(player_idx)
              local vehicle = spawner.spawnVehicle(0xC2D200FE, x, y, z - 1.1, false, true)

              if vehicle then
                  if not native.network.network_has_control_of_entity(vehicle) then
                      utility.requestControlOfEntity(vehicle, 50)
                  end
                  native.entity.set_entity_heading(vehicle, native.entity.get_entity_heading(player_ped))
                  native.entity.set_entity_collision(vehicle, true, true)
                  native.entity.set_entity_dynamic(vehicle, true)
                  local target_pitch, target_roll, target_yaw = native.entity.get_entity_rotation(player_ped, 2)
                  native.entity.set_entity_rotation(vehicle, target_pitch, target_roll, target_yaw, 2, true)
                  thread.sleep(1000)
                  sync.addEntitySyncLimit(vehicle, player_ped)
                  native.entity.set_entity_coords(vehicle, local_x, local_y, local_z - 1.1, false, true, true, false)
                  thread.sleep(600)
                  toast.show("Status", "Finished.")
                  if native.network.network_has_control_of_entity(vehicle) then
                      thread.sleep(1000)
                      spawner.deleteVehicle(vehicle)
                  else
                      utility.requestControlOfEntity(vehicle, 50)
                      thread.sleep(1000)
                      spawner.deleteVehicle(vehicle)
                  end
              else
                  log.error("ERROR: Failed to spawn the trap vehicle.")
                  toast.show("ERROR", "Failed to spawn the trap vehicle.")
              end
          else
              log.error("ERROR: Player moved.")
              toast.show("ERROR", "Player moved.")
          end
      else
          log.error("ERROR: Player is not standing still.")
          toast.show("ERROR", "Player is not standing still.")
      end
  else
      log.error("ERROR: Player is on a mount, in a vehicle, or on a train.")
      toast.show("ERROR", "Player is on a mount, in a vehicle, or on a train.")
  end
end

local function teleport_vehicle(player_idx)
    local local_x, local_y, local_z = player.getLocalPedCoords()
    local player_ped = player.getPed(player_idx)

    if native.ped.is_ped_in_any_vehicle(player_ped, false) then
        local vehicle = native.ped.get_vehicle_ped_is_in(player_ped, false)
        if vehicle and utility.requestControlOfEntity(vehicle, 50) then
            native.entity.set_entity_coords(vehicle, local_x, local_y, local_z, false, false, false, true)
        else
            log.error("ERROR: Failed to get control of the vehicle.")
            toast.show("ERROR: Failed to get control of the vehicle.")
        end
    else
        log.error("ERROR: Player is not in a vehicle.")
        toast.show("ERROR: Player is not in a vehicle.")
    end
end

-- Credit goes to Lucifer/qsilence
local target_ped = nil

function spawn_entity(pos_x, pos_y, pos_z)
    local model_hash = native.misc.get_hash_key('breach_cannon')
    local vehicle_entity = spawner.spawnVehicle(model_hash, pos_x, pos_y, pos_z + 5, false, true)
    native.entity.set_entity_visible(vehicle_entity, false)
    native.entity.set_entity_collision(vehicle_entity, false, false, false)
    native.entity.freeze_entity_position(vehicle_entity, true)
    return vehicle_entity
end

function attach_entity_to_entity(entity, entity2, pos_x, pos_y, pos_z)
    native.ped.set_ped_into_vehicle(player.getLocalPed(), entity, -1)
    native.entity.attach_entity_to_entity(entity, entity2, 550, pos_x, pos_y, pos_z, 0, 0, 0, false, false, false, false, 0, false, true, true)
end

function detach_entity(entity)
    native.entity.detach_entity(entity, true, false)
    log.info("Detached")
end

function cleanup_entity(local_ped, entity, pos_x, pos_y, pos_z)
    native.entity.freeze_entity_position(entity, false)
    native.entity.set_entity_coords(local_ped, pos_x, pos_y, pos_z, false, false, false, false)
    native.entity.freeze_entity_position(local_ped, false)
    native.entity.set_entity_visible(local_ped, true)
    spawner.deleteVehicle(entity)
    log.info("Finished")
end

-- Credit goes to jamison for finding this.
local function awning_crash(player_idx)
    local target_ped = native.player.get_player_ped(player_idx)
    local target_x, target_y, target_z = player.getCoords(player_idx)
    local focus_object_z = target_z + 10000
    local focus_object = spawner.spawnObject(0x0FD92BD2, target_x, target_y, focus_object_z)
    native.streaming.set_focus_entity(focus_object)
    
    local awning_object = spawner.spawnObject(native.misc.get_hash_key("s_chuckwagonawning01b"), target_x, target_y, target_z)
    log.info('Awning Crash Sent.')
    thread.sleep(500)
    spawner.deleteObject(awning_object)
    spawner.deleteObject(focus_object)
end

-- object_lag goes to me nobody_272
local spawned_objects = {}
local max_objects = 80
local object_hash = 0x21552E68
local spawn_delay = 1

local function object_lag(player_idx)
    local target_x, target_y, target_z = player.getCoords(player_idx)
    local player_x, player_y, player_z = player.getLocalPedCoords()

    local distance = math.sqrt(((target_x)-(player_x))^2 + ((target_y)-(player_y))^2 + ((target_z)-(player_z))^2)

    if distance < 1000 then
        log.info("Too close to the target. Move at least 1000m away.")
        toast.show("Warning", "Too close to the target. Move at least 1000m away.")
        return
    end

    log.info("Lag Sent")
    for i = 1, max_objects do
        local object = native.object.create_object(object_hash, target_x, target_y, target_z - 14, true, false, true, false, false)
        table.insert(spawned_objects, object)

        if i % spawn_delay == 0 then
            thread.sleep(0)
        else
            native.entity.set_entity_velocity(object, 0, 0, 1)
        end
    end
end

local function delete_objs()
    if #spawned_objects > 0 then
        for _, obj in ipairs(spawned_objects) do
            spawner.deleteObject(obj)
        end
        spawned_objects = {}
    end
end

menu.addButton(exploits_id, 'Bug Vehicle', '', function(player_idx)
    bug_vehicle(player_idx)
end)

menu.addButton(exploits_id, 'Destroy Godmode Vehicle', '', function(player_idx)
    remove_vehicle_godmode(player_idx)
end)

menu.addButton(exploits_id, 'Kill Godmode Player', 'NOTE: Patched by most menus.', function(player_idx)
    remove_player_godmode(player_idx)
end)

menu.addButton(exploits_id, 'Teleport Player', 'NOTE: Patched by most menus and will only teleport the person 15m', function(player_idx)
    teleport_player(player_idx)
end)

menu.addButton(exploits_id, 'Vehicle Teleport', '', function(player_idx)
    teleport_vehicle(player_idx)
end)

menu.addDivider(exploits_id, 'Crashes')

menu.addButton(exploits_id, 'Render Crash ~e~ [Large AOE]', '', function(player_idx)
    local target_ped = native.player.get_player_ped(player_idx)
    local player_pos_x, player_pos_y, player_pos_z = native.entity.get_entity_coords(target_ped, true, true)
    local self_pos_x, self_pos_y, self_pos_z = player.getLocalPedCoords()
    
    if target_ped ~= 0 and native.entity.does_entity_exist(target_ped) and not native.ped.is_ped_dead_or_dying(target_ped, true) then
        local entity = spawn_entity(player_pos_x, player_pos_y, player_pos_z)
        
        if entity ~= 0 and native.entity.does_entity_exist(entity) then
            attach_entity_to_entity(entity, target_ped, player_pos_x, player_pos_y, player_pos_z)
            thread.sleep(1500)
            detach_entity(entity)
            thread.sleep(700)
            cleanup_entity(player.getLocalPed(), entity, self_pos_x, self_pos_y, self_pos_z)
        else
            log.info("Failed to spawn entity.")
        end
    else
        log.info("Invalid target or " .. native.player.get_player_name(player_idx) .. " is dead.")
    end
    target_ped = nil
end)

menu.addButton(exploits_id, 'Awning Crash ~e~ [Small AOE]', '', awning_crash)

menu.addButton(exploits_id, 'Lag area', '~e~Warning:~q~ Do not get within 1000m of the players location before or after you do this. ~t6~Recommended:~q~ Get ready to click the Stop button. ', function(player_idx)
    object_lag(player_idx)
end)

menu.addButton(exploits_id, 'Stop the lag', '', function()
    delete_objs()
end)

-- Sound
local sound_tick_function = nil
local function play_sound(sound_id, sound_set)
    player.forEach(function(p)
        if p.ped and native.entity.does_entity_exist(p.ped) then
            native.audio.play_sound_from_entity(sound_id, p.ped, sound_set, true, 0, 0)
        end
    end)
end

local function toggle_sound(toggle, sound_id, sound_set)
    if toggle then
        if not sound_tick_function then
            sound_tick_function = function()
                play_sound(sound_id, sound_set)
            end
            -- TODO: Implement continuous sound with proper Exodus pattern
        end
    else
        if sound_tick_function then
            sound_tick_function = nil
        end
    end
end

local function bird_crash()
    utility.changePlayerModel(0x6A640A7B)
    thread.sleep(200)
    local local_player = player.getLocalPed()
    native.task.task_fly_to_coord(local_player, 0, 0, 0, 0, 0, 0)
    thread.sleep(1800)
    utility.changePlayerModel(0xF5C1611E)
end

menu.addToggleButton(session_id, 'Photo', '', false, function(toggle, player_idx)
    toggle_sound(toggle, "photograph", "rdro_gamemode_transition_sounds")
end)

menu.addToggleButton(session_id, 'River', 'NOTE: Infinite Duration.', false, function(toggle, player_idx)
    toggle_sound(toggle, "river_fast", "rdch3_CME_SoundSet")
end)

menu.addToggleButton(session_id, 'UFO', 'NOTE: Infinite Duration.', false, function(toggle, player_idx)
    toggle_sound(toggle, "Loop_A", "Ufos_Sounds")
end)

menu.addToggleButton(session_id, 'Thunder', '', false, function(toggle, player_idx)
    toggle_sound(toggle, "LIGHTENING_STRIKE", "DSLIT_Sounds")
end)

menu.addToggleButton(session_id, 'Race Start', '', false, function(toggle, player_idx)
    toggle_sound(toggle, "321_GO", "RDRO_Race_sounds")
end)

menu.addToggleButton(session_id, 'Fort Notification', '', false, function(toggle, player_idx)
    toggle_sound(toggle, "Idle_Kick_Message", "RDRO_Idle_Kick_Sounds")
end)

menu.addToggleButton(session_id, 'Rain', 'NOTE: Infinite Duration.', false, function(toggle, player_idx)
    toggle_sound(toggle, "rain_loop", "BE22_SOUNDS")
end)

menu.addToggleButton(session_id, 'Police Whistle', '', false, function(toggle, player_idx)
    toggle_sound(toggle, "POLICE_WHISTLE_MULTI", "GNG3_Sounds")
end)
menu.addDivider(session_id, 'Crashes')
menu.addButton(session_id, 'Bird Crash', '', bird_crash)

-- AFK Monitor
local afk_monitor_enabled = false
local afk_monitor_timer = time.milliseconds()

local last_positions = {}
local afk_start_time = {}

-- Why is math.floor not supported?
local function format_time(duration_ms)
    local total_seconds = duration_ms / 1000
    local hours = total_seconds / 3600
    local minutes = (total_seconds % 3600) / 60
    local seconds = total_seconds % 60

    hours = hours - (hours % 1)
    minutes = minutes - (minutes % 1)
    seconds = seconds - (seconds % 1)

    local time_parts = {}
    if hours > 0 then
        table.insert(time_parts, string.format("%d hour%s", hours, hours ~= 1 and "s" or ""))
    end
    if minutes > 0 then
        table.insert(time_parts, string.format("%d minute%s", minutes, minutes ~= 1 and "s" or ""))
    end
    if seconds > 0 or #time_parts == 0 then
        table.insert(time_parts, string.format("%d second%s", seconds, seconds ~= 1 and "s" or ""))
    end
    
    return table.concat(time_parts, " and ")
end

local function check_afk_players()
    if time.milliseconds() - afk_monitor_timer > 30000 then
        afk_monitor_timer = time.milliseconds()
        player.forEach(function(player_record)
            local player_ped = player_record.ped
            local current_x, current_y, current_z = player.getCoords(player_record.id)
            local last_pos = last_positions[player_record.id]

            if last_pos and last_pos.x == current_x and last_pos.y == current_y and last_pos.z == current_z then
                if player_ped and native.task.is_ped_still(player_ped) then
                    local afk_duration = time.milliseconds() - afk_start_time[player_record.id]
                    local formatted_time = format_time(afk_duration)
                    log.info('<red>Player "' .. player_record.name .. '" has been AFK for ' .. formatted_time)
                end
            else
                afk_start_time[player_record.id] = time.milliseconds()
            end
            last_positions[player_record.id] = {x = current_x, y = current_y, z = current_z}
        end)
    end
end

-- More of a proof of concept thing you can use this to log coords easily if you want to add more positions.
--[[
menu.addButton('self', 'Log coords', '', function()
    local x, y, z = player.getLocalPedCoords()
    log.info(string.format("{x = %.2f, y = %.2f, z = %.2f},", x, y, z))
end)
]]
local locations = {
    {x = -1892.47, y = 1334.11, z = 203.12},
    {x = -2368.59, y = 473.42, z = 132.01},
    {x = 3005.02, y = 479.00, z = 44.30},
    {x = 2153.21, y = -1647.31, z = 40.61},
    {x = -3548.46, y = -3007.08, z = 11.10},
    {x = -720.38, y = 925.55, z = 116.08},
    {x = -1807.66, y = -405.87, z = 152.93},
    {x = -5198.34, y = -2093.83, z = 12.32},
    {x = -5393.61, y = -3665.48, z = -24.46},
    {x = 1962.87, y = -1214.89, z = 42.09},
    {x = 2337.35, y = -1199.35, z = 44.59},
    {x = 2557.49, y = -919.47, z = 42.46},
    {x = 2256.44, y = -793.31, z = 44.26},
    {x = 2063.96, y = -854.26, z = 43.14},
    {x = 1709.54, y = -1006.03, z = 42.95},
    {x = 1372.07, y = -1411.82, z = 79.22},
    {x = 1332.22, y = -1375.45, z = 79.68},
    {x = 1183.26, y = -99.68, z = 94.54},
    {x = 901.09, y = 264.48, z = 116.06},
    {x = 1927.66, y = 1963.68, z = 263.47},
    {x = -1963.05, y = 2156.88, z = 327.61},
    {x = -881.90, y = -1647.19, z = 68.59},
    {x = -4786.57, y = -2729.23, z = -14.37},
    {x = -5576.78, y = -2575.94, z = -8.50},
    {x = -2054.04, y = -1918.17, z = 112.91},
    {x = 171.14, y = -766.05, z = 41.64},
    {x = -701.87, y = -462.89, z = 41.70},
    {x = -2116.14, y = -65.82, z = 258.68},
    {x = -981.33, y = 1530.21, z = 241.69},
    {x = -1039.99, y = 2651.62, z = 314.85},
    {x = 807.38, y = 2000.19, z = 279.98},
    {x = 2384.59, y = 987.66, z = 73.99},
    {x = 2381.81, y = -634.09, z = 42.20},
    {x = 2163.06, y = -857.47, z = 41.69},
    {x = 1850.92, y = -860.08, z = 42.05},
    {x = 1904.50, y = -1822.19, z = 41.88},
    {x = 1117.72, y = -1987.33, z = 55.35},
    {x = 1357.03, y = -1248.07, z = 79.95},
    {x = 2539.69, y = -1456.69, z = 46.32},
    {x = 2410.74, y = -1078.86, z = 47.42},
    {x = 1625.53, y = -364.60, z = 75.90},
    {x = 2236.21, y = -141.89, z = 47.62},
    {x = 2931.37, y = 1389.46, z = 56.25},
    {x = 554.96, y = 567.49, z = 116.66},
    {x = -420.79, y = 1736.11, z = 216.56},
    {x = -1415.58, y = 1131.71, z = 225.54},
    {x = -1813.71, y = 660.12, z = 131.94},
    {x = -977.44, y = -1202.03, z = 58.12},
    {x = -1976.83, y = -1650.20, z = 117.12},
    {x = 2695.59, y = -1524.86, z = 46.34},
    {x = 1838.09, y = -1275.66, z = 43.36},
    {x = 1269.34, y = -402.19, z = 97.61},
    {x = 577.49, y = 1689.76, z = 187.65},
    {x = -26.66, y = 1223.92, z = 173.09},
    {x = -325.28, y = 764.91, z = 117.44},
    {x = -1319.03, y = 2435.95, z = 309.59},
    {x = -2216.15, y = 726.49, z = 127.70},
    {x = -1819.97, y = -372.05, z = 163.30},
    {x = -755.18, y = -1352.08, z = 43.54},
    {x = -1639.39, y = -1360.80, z = 84.51},
    {x = -2322.13, y = -2389.21, z = 63.18},
    {x = -5200.77, y = -3439.57, z = -11.05},
    {x = -5462.38, y = -2907.60, z = 0.78},
}

local collectibles = {
    0x41214181, 0xA726CB88, 0x7D6ABF6F,
    0x77F8227E, 0x29F1867A, 0xB4AE10C1,
    0xD6E0BED5, 0x1D8EA4C0, 0x06A06284,
    0x9B099D4F, 0x52998C88, 0xEFA4C6A4,
    0x97A169CE, 0x9E3FF6EB, 0x306D9B48,
    0x45FABEA6, 0x50B0D41E, 0x1767E18D,
    0x00EF35B4, 0xDAC6E964, 0x2421FC0D,
    0xA8CA206B, 0x68711F8A, 0xFB2B44FC,
    0x1154726A, 0x8B17E5F7, 0x346F38A3,
    0x49806415, 0x1D820C15, 0x6283961B,
    0x2DB536EB, 0xA8342C03, 0x91A37EE2,
    0x7318395C, 0x424C57ED, 0x01815628,
    0x4CA4288E, 0xB95F820B, 0x6548D9DB,
    0xB0020880, 0x8616B4AA, 0xCBFCC079,
    0x75AAB43E, 0x764A3581, 0x67EF18CB,
    0x6B0C5986, 0x581A334E, 0x0EA72069,
    0x3BB293E6, 0x6B457347, 0x25E5E889,
    0xEB0BF2D6, 0xD7A1B25F, 0xA14A8B85,
    0x51494AF4, 0x1E1F4B85, 0x389CC45E,
    0x4464644D, 0xA4F19AF6, 0xEA20A407,
    0xC477D792, 0x71321644, 0xB60D9ED6,
    0x6759091E, 0x29F2BB3F, 0xC607737A,
    0x9D77B301, 0x2FB0894D, 0xA347A5C5,
    0x16E266B5, 0x8D703947, 0xDD0E0706,
    0x3EEE193C, 0xBED06A3E, 0x40FFAFA6,
    0xE4AD10C1, 0xDF25A12D, 0x2F177E32,
    0xA34FF0E7, 0x437B69E7, 0x710329A2,
    0x16E618E8, 0x1399EFBE, 0x51DD81F8,
    0x632F9323, 0x06F37801, 0x835EEBC8,
    0x37F9F778, 0x44E0D361, 0x5D92D04B,
    0x049281AC, 0x4ED9480E, 0x875BE972,
    0xEF9D5545, 0x1D7A9171, 0x8598C1C3,
    0x80DA7E8B, 0x7FC5FEBE, 0x8AF7572A,
    0x1BDC17B2, 0x72AF40FA, 0x61B1DF3C,
    0xE71FF735, 0x993D7F00, 0x619B7EEF,
    0x3AF966D7, 0x453BA146, 0x87E5C1D8,
    0x4C5B2A0D, 0x886721FC, 0x06C23C90,
    0x1F4FB3C2, 0xA738020E, 0x90682B5C,
    0x103CFFA3, 0x77C2D500, 0x2AB52790,
    0xD20A7E3B, 0x39B2CB66, 0x78C52A23,
    0x4A7F72F3, 0x22E8F630, 0xEED898DB,
    0x8904CB57, 0xFEF68704, 0xD7E3CDC3,
    0xD30ABF4E, 0x46EC3B0D, 0x2103A446,
    0x47614E1F, 0xC37352A4, 0x8C8978BF,
    0x6FA4E08C, 0x60FB38F3, 0x927245FE,
    0x5CA05317, 0x92D498AB, 0xBACD73DF,
    0xFDC1A891, 0xAE91C0EE, 0xDC487FB4,
    0xBAA15780, 0x4378D22B, 0x6A0959CB,
    0xE854BF26, 0x39F16D9F, 0x7EEC54D5,
    0xE1F95E04, 0x575C0C8C, 0x10C144B7,
    0xC3CA448A, 0x53E3A47F, 0x6793097B,
    0x60431E06, 0x2858B99A, 0xB867EC85,
    0xCFE17743, 0xF4271318, 0xEE6B558B,
    0x810D8A8C, 0xF82CF600, 0xBE1D9CFE,
    0x42C83743, 0xD456E551, 0xF58A10A5,
    0x53658FA8, 0x96A7B31E, 0xCD3115CE,
    0x2244AD81, 0x8E74EF00, 0x190D449D,
    0x780541A5, 0x8A7FC823, 0x29E53781,
    0x93447D9D, 0xC7C69AB6, 0x0E3C4429,
    0xF1F5568D, 0xCF1C45EB, 0xDCA977B4,
    0xB4E8D89F, 0xBBEBD5F2, 0xD3A9703A,
    0x73F2AA05, 0x6659D517, 0x849D3487,
    0x5CF5424C, 0x34C347E7, 0xA2310759,
    0x89C859E7, 0x8F595B1C, 0x402D1476,
    0xB0DFDE10, 0x178D5023, 0x95787329,
    0xB851ECDC, 0xDF36445D, 0xA5296FFC,
    0xF234A5A8, 0x373B0C69, 0x04902715,
    0xB0F346BB, 0xD1751EEE, 0x3F0887FF,
    0xB2D5FDAB, 0x906DF761, 0x0112CA3F,
    0x52A6C006, 0x6A084B60, 0xC570E402,
    0x557612F9, 0xA34AB33C, 0x5E3A6888,
    0xAF735FDF, 0x9DD889CF, 0xF2610F2E,
    0x35E768E7, 0x5AB8F9FF, 0x829A0C5F,
    0xD8F8A0D7, 0xF46DCFA5, 0x2AB28031,
    0xDF53E37F, 0xDC836190, 0x2C681671,
    0x3F479FBF, 0x09A4E44E, 0x74CA3FFF,
    0x66F3BCB4, 0x0B84A2B9, 0x86814AE7,
    0x03CE0E2C, 0xB3027EC9, 0x7EED6108,
    0xF4A04EC6, 0xF572EF18, 0xB8C84807,
    0xED0D7B18, 0x12E3F98F, 0x8C14F046,
    0x1B197C23, 0x792D94A6, 0xE6C7BF06,
    0x61C4BE3D, 0x474379BC, 0xC337ADAF,
    0x2176260A, 0xEB05ED3C, 0x36C4502C,
    0xF7E840F6, 0x65FE72AF, 0xAD37F4E6,
    0x6D4324D2, 0x6741AB7B, 0x516697E3,
    0xE3FF4A58, 0x26DA2E29, 0xB03C20D5,
    0xA903976F, 0x89F2A24E, 0xEDC521CC,
    0xBC7A2745, 0xB2BCA30F, 0xA0CB9B5A,
    0x079C4552, 0x1FA55AF9, 0x5FBDEA64,
    0x1F9CFF70, 0xA575BC70, 0x4CE83771,
    0xDD59252D, 0xD94FFDEA, 0xF5449F55,
    0xEA4CBAA7, 0x1F021CAD, 0x6111682F,
    0xCB570334, 0x2001C671, 0xFB5E830E,
    0xFE12CFF0, 0xEC4B205B, 0x1F6FE2DC,
    0x39A5F09D, 0x50EAE2AF, 0x82EF4622,
    0x29C1837F, 0x7185642C, 0xF0B4035C,
    0x162B262C, 0xA7D1435D, 0xE9BFB75A,
    0xF0E70E0F, 0x8DDB8E7F, 0x9DD0C8CA,
    0xFDC3FDB1, 0x2C77E86C, 0x80E6F1C8,
    0x5B47CD50, 0x9BF58DBC, 0x6AAAF739,
    0xFBB6A636, 0x3581EF56, 0x3F0887FF,
    0xB851ECDC, 0xDF36445D, 0xA5296FFC,
    0xF234A5A8, 0x373B0C69, 0x04902715,
    0xB0F346BB, 0xD1751EEE,
}

local current_location = 1
local bot_active = false
local auto_collect = false
local marker_coords = nil

local function draw_marker()
    if marker_coords then
        native.graphics.draw_marker(0x94FDAE17, marker_coords.x, marker_coords.y, marker_coords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 5.0, 173, 216, 230, 100, true, false, 0, true, '', '', false)
    end
end

local function area_scan()
    local found = false
    for _, collectible_hash in ipairs(collectibles) do
        if not bot_active then return false end
        pools.getObjectsInRadius(400.0, function(entity_handle, entity_model)
            if not bot_active then return end
            if entity_model == collectible_hash and native.entity.does_entity_exist(entity_handle) and native.entity.is_entity_visible(entity_handle) then
                local x, y, z = native.entity.get_entity_coords(entity_handle, false, true)
                utility.teleportToCoords(x, y, z)
                marker_coords = {x = x, y = y, z = z}
                log.info("Collectible found at coordinates: (" .. x .. ", " .. y .. ", " .. z .. ")")
                toast.show("Recovery Bot", "Collectible Found!")
                -- TODO: Implement draw marker with proper Exodus pattern

                if auto_collect then
                    local local_ped = player.getLocalPed()
                    native.task.clear_ped_tasks(local_ped, true, true)
                    native.task.task_pickup_carriable_entity(local_ped, entity_handle)
                end

                found = true
            end
        end)
        if found then
            log.info("Found a collectible nearby.")
            break
        end
    end
    return found
end

local function main_bot()
    if not area_scan() then
        for i = current_location, #locations do
            if not bot_active then
                log.info("Bot stopped.")
                break
            end
            local location = locations[i]
            log.info("Teleporting to Location " .. i .. ": (" .. location.x .. ", " .. location.y .. ", " .. location.z .. ")")
            utility.teleportToCoords(location.x, location.y, location.z)
            thread.sleep(6000)

            if area_scan() then break end
            current_location = i + 1
        end
    end

    if current_location > #locations then
        log.info("All locations have been checked. No more locations to visit.")
    end
end

menu.addToggleButton(misc_id, 'AFK Monitor', 'Check Console', false, function(toggle)
    afk_monitor_enabled = toggle
    if afk_monitor_enabled then
        afk_monitor_timer = time.milliseconds() - 30000
        last_positions = {}
        player.forEach(function(player_record)
            afk_start_time[player_record.id] = time.milliseconds()
        end)
        -- TODO: Implement AFK monitoring with proper Exodus pattern
        log.info('AFK monitoring enabled. Waiting 30sec')
    else
        log.info('AFK monitoring disabled')
        afk_start_time = {}
    end
end)

menu.addToggleButton(misc_id, 'Collectible Scan', '', false, function(toggle)
    bot_active = toggle
    if bot_active then
        if not area_scan() then
            log.info("No collectibles found in the area.")
            toast.show("Recovery Bot", "No collectibles found nearby.")
        end
    else
        marker_coords = nil
        native.task.clear_ped_tasks(player.getLocalPed(), true, true)
    end
end)

menu.addDivider(misc_id, 'Recovery Bot')
menu.addToggleButton(misc_id, 'Collectible Bot', '~e~WARNING: ~q~Once toggled it will not turn off until it finds a collectible.~e~DO NOT UNLOAD WHILE RUNNING. ~t6~Please wait until the bot has found a collectible to unload the script.', false, function(toggle)
    bot_active = toggle
    if bot_active then
        log.info("Bot enabled.")
        -- TODO: Implement collectible bot with proper Exodus pattern
    else
        marker_coords = nil
        native.task.clear_ped_tasks(player.getLocalPed(), true, true)
        log.info("Bot disabled.")
    end
end)

menu.addToggleButton(misc_id, 'Auto Collect', '', false, function(toggle)
    auto_collect = toggle
end)

menu.addButton(misc_id, 'Reset Bot', '', function()
    current_location = 1
    log.info("Bot locations reset.")
end)

-- Panic Button
menu.addDivider('self', 'Advanced Settings')
menu.addButton('self', 'Panic Button', 'NOTE: If you are worried you will crash when unloading then press this button.', function()
    -- Clean up any active tasks
    bot_active = false
    marker_coords = nil
    log.info("Panic button pressed - all tasks cleaned up.")
end)
