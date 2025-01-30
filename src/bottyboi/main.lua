local config         = {
  general = {
    interval            = 0.125,
    inventory_threshold = 10, -- Minimum space in inventory to keep running main loop (Does not affect subroutines)
    timeout_threshold   = 30, -- Time in seconds to wait in certain subroutines before trying to exit
  },
  consumables = {
    food   = false, -- Set to an item to enable use during gathering loop (e.g. "Stuffed Peppers <hq>")
    potion = false, -- Set to an item to enable use during gathering loop (e.g. "Superior Spiritbond Potion <hq>")
  },
  subroutines = {
    -- Materia extraction settings
    extract = {
      enabled = false
    },

    -- Aetherial reduction settings
    reduce = {
      enabled = false
    },

    -- Gear auto repair settings
    repair = {
      enabled              = false,
      durability_threshold = 25, -- 0-100 Range
    },

    -- Scrip exchange settings
    trade = {
      enabled            = false,
      collector_location = { -152.465, 0.660, -13.557, 1186 }, -- Solution 9
      exchanger_location = { -158.019, 0.922, -37.884, 1186 }, -- Solution 9
      min_items          = 1,
      scrip_cap          = 3900,
    },

    -- Ventures and market board automation
    retainers = {
      enabled  = false,
      location = { -152.465, 0.660, -13.557, 1186 }, -- Solution 9
    }
  },
  integrations = {
    auto_retainer       = false,
    deliveroo           = false,
    gather_buddy_reborn = false,
  },
  debug = {
    verbose = true,
  }
}

-- Items to trade in for scrips
-- Format: { <row_index>, <item_id>, <job_type>, <scrip_type> }

local trade_in_items = {
  -- MINER (8): Orange Scrips (39)
  { 0, 43922, 8, 39 }, -- Rarefied Ra'kaznar Ore (43922)
  { 1, 43923, 8, 39 }, -- Rarefied Ash Soil (43923)
  { 2, 43918, 8, 39 }, -- Rarefied Volcanic Rock (43918)
  { 3, 43921, 8, 39 }, -- Rarefied Magnesite Ore (43921)

  -- BOTANIST (9): Orange Scrips (39)
  { 0, 43929, 9, 39 }, -- Rarefied Acacia Log (43929)
  { 1, 43930, 9, 39 }, -- Rarefied Windsbalm Bay Leaf (43930)
  { 2, 43925, 9, 39 }, -- Rarefied Wild Agave (43925)
  { 3, 43928, 9, 39 }, -- Rarefied Dark Mahogany (43928)

  -- MINER (8): Purple Scrips (38)
  { 4, 44233, 8, 38 }, -- Rarefied White Gold Ore (44233)
  { 5, 43920, 8, 38 }, -- Rarefied Titanium Gold Ore (43920)
  { 6, 43919, 8, 38 }, -- Rarefied Dark Amber (43919)

  -- BOTANIST (9): Purple Scrips (38)
  { 4, 44234, 9, 38 }, -- Rarefied Acacia Bark (44234)
  { 5, 43927, 9, 38 }, -- Rarefied Kukuru Beans (43927)
  { 6, 43926, 9, 38 }  -- Rarefied Mountain Flax (43926)
}

-- Items to purchase with scrips
-- Format: { <category>, <subcategory>, <item_row>, <cost> }

local exchange_items = {
  -- Mount Token: 1000 Orange Scrips
  { 4, 8, 6, 1000 },

  -- High Cordial: 20 Purple Scrips
  { 4, 1, 0, 20 },
}

-- Maintenance variables
local loop_count     = 1
local terminate      = false

-- Local Function Declarations
local wait, log, teleport, move, lifestream
local subroutine_extract, subroutine_reduce, subroutine_repair, subroutine_trade, subroutine_retainers

--- Runs subroutine checks and handlers
function RunSubroutines()
  local extract, reduce, repair = table.unpack(config.subroutines)

  -- If auto-repair is enabled in config and gear needs repair, run repair subroutine
  if repair.enabled and NeedsRepair(repair.durability_threshold) then
    subroutine_repair()
  end

  -- If materia extraction is enabled in config and player has max spiritbond, run extract subroutine
  if extract.enabled and CanExtractMateria(100) then
    subroutine_extract()
  end

  -- If aetherial reduction is enabled in config, run reduce subroutine (includes checks)
  if reduce.enabled then
    subroutine_reduce()
  end
end

--- Runs one time setup
function Setup()
end

--- The main event loop
function Loop()
end

--- Runs one time cleanup
function Cleanup()
end

-- #region main
Setup()
while not terminate do
  Loop()
  loop_count = loop_count + 1
end
Cleanup()
-- #endregion


-- Subroutines:
-- References are defined above the main loop so these can be out of the way
-- #region subroutines

--- Extracts materia from equipped items
subroutine_extract = function()
end

--- Uses aetherial reduction on eligible items
subroutine_reduce = function()
end

--- Repairs gear when durability falls below a certain threshold
subroutine_repair = function()
end

--- Trades in items for scrips
subroutine_trade = function()
end

--- Runs retainer tasks (requires AutoRetainer)
subroutine_retainers = function()
end

-- #endregion

-- Helper functions
-- #region helpers

--- Pauses the script for a set amount of time
---@param time integer @The time in seconds to wait
wait = function(time)
  if config.debug.verbose then
    log("Waiting for " .. time * config.general.interval .. " seconds")
  end

  yield("/wait " .. config.general.interval * time)
end

--- Logs a message in game chat
---@param message string @The message to log
log = function(message)
  yield("/echo " .. message)
end

--- Teleports to target aetheryte (Requires Teleporter)
---@param target string @Partial or full name of the target aetheryte
teleport = function(target)
  if config.debug.verbose then
    log("Teleporting to " .. target)
  end

  yield("/tp " .. target)
end

--- Teleports to target aethernet shard (Requires Lifestream)
--- @param target string @Partial or full name of the target shard
lifestream = function(target)
  if config.debug.verbose then
    log("Teleporting to " .. target)
  end

  yield("/li " .. target)
end

--- Moves to a target location (Requires vnavmesh)
--- @param x number @The x coordinate to move to
--- @param y number @The y coordinate to move to
--- @param z number @The z coordinate to move to
--- @param fly boolean @Whether or not to fly to the target location
move = function(x, y, z, fly)
  local nav_ready  = NavIsReady()
  local is_casting = GetCharacterCondition(27)
  local is_loading = GetCharacterCondition(45) or GetCharacterCondition(51)

  if config.debug.verbose then
    log("Moving to " .. x .. ", " .. y .. ", " .. z)
    log("nav_ready: " ..
      tostring(nav_ready) .. ", is_casting: " .. tostring(is_casting) .. ", is_loading: " .. tostring(is_loading))
  end

  repeat wait(1) until not is_casting and not is_loading and nav_ready
  PathfindAndMoveTo(x, y, z, fly)
end

-- #endregion
