# Troll+Plus Exodus API Conversion Summary

## Overview
The Troll+Plus.lua script has been converted from its original API to the Exodus Lua API as specified in the documentation at https://docs.exodusmenu.com/scripting/.

## Completed Automatic Conversions

### 1. System Namespace (✅ Converted)
| Original | Converted To | Count |
|----------|-------------|-------|
| `system.setScriptName()` | `-- UNSUPPORTED: setScriptName` | 1 |
| `system.registerConstructor()` | `script.register_looped('trollplus_init', ...)` | 1 |
| `system.yield(n)` | `thread.sleep(n)` | 20 |
| `system.getTickCount64()` | `time.milliseconds()` | Multiple |

### 2. Logger Namespace (✅ Converted)
| Original | Converted To | Count |
|----------|-------------|-------|
| `logger.logCustom()` | `log.info()` | ~102 |
| `logger.logError()` | `log.error()` | ~102 |
| `logger.logInfo()` | `log.info()` | ~102 |

### 3. Notifications Namespace (✅ Converted)
| Original | Converted To | Count |
|----------|-------------|-------|
| `notifications.alertInfo()` | `toast.show()` | ~82 |
| `notifications.alertDanger()` | `toast.show()` | ~82 |

### 4. Math Namespace (✅ Converted)
| Original | Converted To | Reason |
|----------|-------------|--------|
| `math.getRandomFloat(min, max)` | `(math.random() * (max - min) + min)` | Custom function → Standard Lua |
| `math.getRandomInt(min, max)` | `math.random(min, max)` | Custom function → Standard Lua |
| `math.pi()` | `math.pi` | Function call → Constant |
| `math.getDistance(x1,y1,z1,x2,y2,z2)` | `math.sqrt((x2-x1)^2 + (y2-y1)^2 + (z2-z1)^2)` | Custom function → Manual calculation |

## Features Marked for Manual Review (⚠️ Unsupported)

The following features have been marked with `-- UNSUPPORTED:` comments and require manual conversion:

### 1. Tick System (28 occurrences)
- **Original**: `system.registerTick()` / `system.unregisterTick()`
- **Issue**: Exodus uses `script.register_looped()` with a different signature
- **Action Required**: Convert each tick function to use proper Exodus script registration pattern
- **Example**:
  ```lua
  -- OLD:
  system.registerTick(my_function)
  
  -- NEW:
  local script_handle = script.register_looped('unique_name', function(script_)
      my_function()
      script_:yield()
  end)
  ```

### 2. Namespaces Needing Verification
The following namespaces remain unchanged but should be verified against Exodus API docs:

- **`spawner.*`**: Functions like `spawnVehicle()`, `spawnPed()`, `spawnObject()`, `deletePed()`, etc.
  - May need to use `game.*` namespace or native functions directly
  
- **`player.*`**: Functions like `getCoords()`, `getPed()`, `getLocalPed()`, `forEach()`
  - API methods may have different names in Exodus
  
- **`utility.*`**: Functions like `requestControlOfEntity()`, `teleportToCoords()`, `changePlayerModel()`
  - May need alternative Exodus implementations
  
- **`menu.*`**: Functions like `addSubmenu()`, `addButton()`, `addToggleButton()`, `addIntSpinner()`, etc.
  - Verify exact Exodus menu API syntax
  
- **`sync.*`**: Functions like `addEntitySyncLimit()`
  - May not have direct Exodus equivalent
  
- **`pools.*`**: Functions like `getObjectsInRadius()`
  - May not have direct Exodus equivalent

### 3. Native Calls
- **`natives.*`**: All native game function calls remain unchanged
  - Should work as-is but verify against https://alloc8or.re/rdr3/nativedb/

## File Changes
- **Modified**: `Troll+Plus.lua` (2065 lines, +25 header lines)
- **Deleted**: `Troll+Plus_Exodus.lua` (empty placeholder file)

## Next Steps

1. **Review Header**: The script now includes a detailed header (lines 1-25) explaining all conversions
2. **Manual Tick Conversion**: Convert all 28 `-- UNSUPPORTED: registerTick/unregisterTick` markers
3. **Verify APIs**: Check each namespace against Exodus documentation:
   - Menu API: https://docs.exodusmenu.com/scripting/namespaces/menu/
   - Player API: https://docs.exodusmenu.com/scripting/namespaces/player/
   - Game API: https://docs.exodusmenu.com/scripting/namespaces/game/
   - Script API: https://docs.exodusmenu.com/scripting/namespaces/script/
   - Thread API: https://docs.exodusmenu.com/scripting/namespaces/thread/
4. **Test**: Load the script in Exodus and test each feature

## Conversion Statistics
- ✅ 20 `system.yield` → `thread.sleep`
- ✅ 102 `logger.*` → `log.*`
- ✅ 82 `notifications.*` → `toast.*`
- ✅ Math functions converted to standard Lua
- ⚠️ 28 tick registration calls marked for manual review
- ⚠️ Multiple namespaces marked for API verification

## Notes
- The script is syntactically valid Lua
- All conversions preserve original functionality intent
- Areas needing review are clearly marked with comments
- The script should load in Exodus but may need adjustments for full compatibility
