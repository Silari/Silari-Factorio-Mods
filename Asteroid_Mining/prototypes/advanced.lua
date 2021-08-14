--Make the item and entity for the astmine-target

require("scripts/adv-data-util.lua") -- Has our resource/miner generator functions
-- **************************
-- Asteroid Target item/entity/recipe
-- **************************
-- ITEM: The item form of the Asteroid Target
local amtargeti = {
  --   icons = {
    --   {
      --   icon = "__Asteroid_Mining__/graphics/astmine-target.png",
      --   icon_mipmaps = 4,
      --   icon_size = 64
    --   }
  --   },
    icon = "__base__/graphics/icons/constant-combinator.png",
    icon_mipmaps = 4,
    icon_size = 64,
    name = "astmin-target",
    order = "d[zam-target]",
    stack_size = 10,
    subgroup = subtarget, 
    type = "item",
    place_result = "astmin-target",
    enabled = true
}
-- RECIPE: recipe for item
local amtargetr = {
    enabled = false,
    ingredients = {
        {
          "rocket-control-unit",
          1
        },
        {
          "radar",
          1
        }
    },
    name = "astmin-target",
    result = "astmin-target",
    type = "recipe"        
}

-- ENTITY: The entity form of the Asteroid Target
local amtargete = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
amtargete.name = "astmin-target"
-- We can't put this on resources, because resources need to not be put under it.
amtargete.collision_mask = {"item-layer", "object-layer", "player-layer", "water-tile","resource-layer"}
amtargete.item_slot_count = 1
amtargete.max_health = 250
amtargete.minable = {
    mining_time = 0.1,
    result = "astmin-target"
}
radsprite = {
        filename = "__base__/graphics/entity/electric-mining-drill/electric-mining-drill-radius-visualization.png",
        height = 10,
        width = 10
}
amtargete.radius_visualisation_specification = {
            sprite = radsprite,
            distance = 5
}
amtargete.energy_source = data.raw["arithmetic-combinator"]["arithmetic-combinator"].energy_source
amtargete.subgroup = subtarget

-- **************************
-- Mixed miner module and recipe
-- **************************
local astminmixed = table.deepcopy(data.raw['item']['satellite'])
astminmixed.name = "astmin-mixed"
astminmixed.order = "astmin-aaa"
astminmixed.subgroup = subminer
astminmixed.rocket_launch_product = nil
-- Recipe for the upgrade module
local astminmixedr = {
    enabled = false,
    ingredients = {
        {
          "rocket-control-unit",
          5
        },
        {
          "roboport",
          1
        },
        {
          "logistic-robot",
          50
        },
        {
          "nuclear-reactor",
          2
        },
        {
          "radar",
          5
        }
    },
    name = "astmin-mixed",
    result = "astmin-mixed",
    type = "recipe"
}


-- **************************
-- Miner upgrade items and recipes
-- **************************
local astminupg5 = table.deepcopy(data.raw['item']['satellite'])
astminupg5.name = "astmin-upgrade-5"
astminupg5.order = "astmin-upgrade-1"
astminupg5.subgroup = subminer
astminupg5.rocket_launch_product = nil
-- Recipe for the upgrade module
local astminupg5r = {
    enabled = false,
    ingredients = {
        {
          "rocket-control-unit",
          5
        },
        {
          "roboport",
          1
        },
        {
          "logistic-robot",
          50
        },
        {
          "nuclear-reactor",
          2
        },
        {
          "radar",
          5
        }
    },
    name = "astmin-upgrade-5",
    result = "astmin-upgrade-5",
    type = "recipe"
}

-- Only difference between 5 and 25 is the name and recipe.
local astminupg25 = table.deepcopy(astminupg5)
astminupg25.name = "astmin-upgrade-25"
astminupg25.order = "astmin-upgrade-2"
-- Recipe for the upgrade module
local astminupg25r = {
    enabled = false,
    ingredients = {
        {
            "rocket-control-unit",
            25
        },
        {
            "roboport",
            1
        },
        {
            "logistic-robot",
            50
        },
        {
            "radar",
            10
        },
        {
            "low-density-structure",
            50
        }
    },
    name = "astmin-upgrade-25",
    result = "astmin-upgrade-25",
    type = "recipe"
}

local astminupg = table.deepcopy(astminupg5)
astminupg.name = "astmin-upgrade-module"
astminupg.order = "astmin-upgrade"
local astminupgr = {
    enabled = false,
    ingredients = {
        {
            "roboport",
            10
        },
        {
            "construction-robot",
            100
        },
        {
            "solar-panel",
            100
        },
        {
            "accumulator",
            50
        },
        {
            "low-density-structure",
            100
        }
    },
    name = "astmin-upgrade-module",
    result = "astmin-upgrade-module",
    type = "recipe"
}

local upgradetech = {
      effects = {
      },
      icon = "__base__/graphics/technology/rocket-silo.png",
      icon_mipmaps = 4,
      icon_size = 256,
      name = "ast-min-upgrades",
      order = "k-b",
      prerequisites = {
        "space-science-pack"
      },
      type = "technology",
      unit = {
        count = 1000,
        ingredients = {
          {
            "automation-science-pack",
            1
          },
          {
            "logistic-science-pack",
            1
          },
          {
            "chemical-science-pack",
            1
          },
          {
            "production-science-pack",
            1
          },
          {
            "utility-science-pack",
            1
          },
          {
            "space-science-pack",
            1
          }
        },
        time = 60
      }
    }

local resourcetech = {
      effects = {
      },
      icon = "__base__/graphics/technology/rocket-silo.png",
      icon_mipmaps = 4,
      icon_size = 256,
      name = "ast-min-resminer",
      order = "k-c",
      prerequisites = {
        "space-science-pack"
      },
      type = "technology",
      unit = {
        count = 2000,
        ingredients = {
          {
            "automation-science-pack",
            1
          },
          {
            "logistic-science-pack",
            1
          },
          {
            "chemical-science-pack",
            1
          },
          {
            "production-science-pack",
            1
          },
          {
            "utility-science-pack",
            1
          },
          {
            "space-science-pack",
            1
          }
        },
        time = 60
      }
    }

-- If advanced mining enabled, add our items.
if settings.startup["astmine-makerockets"].value then
    data:extend({amtargeti,amtargetr,amtargete,astminmixed,astminmixedr,astminupg5,astminupg25,astminupg5r,astminupg25r,astminupg,astminupgr,resourcetech,upgradetech})
    table.insert(data.raw.technology["rocket-silo"].effects, {type = "unlock-recipe", recipe = "astmin-target"})
    table.insert(data.raw.technology["rocket-silo"].effects, {type = "unlock-recipe", recipe = "astmin-mixed"})
    table.insert(data.raw.technology["ast-min-upgrades"].effects, {type = "unlock-recipe", recipe = "astmin-upgrade-module"})
    table.insert(data.raw.technology["ast-min-upgrades"].effects, {type = "unlock-recipe", recipe = "astmin-upgrade-5"})
    table.insert(data.raw.technology["ast-min-upgrades"].effects, {type = "unlock-recipe", recipe = "astmin-upgrade-25"})
    -- This makes the items for every resource, and will be called again in updates and final-fixes
    make_resources()
end
