--Make the item and entity for the astmine-target


require("scripts/advanced/adv-data-util.lua") -- Has our resource/miner generator functions
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
    name = "astmine-target",
    order = "d[zam-target]",
    stack_size = 10,
    subgroup = subtarget, 
    type = "item",
    place_result = "astmine-target",
    enabled = true
}
-- RECIPE: recipe for item
local amtargetr = {
    enabled = false,
    ingredients = {
        {
          name="processing-unit",
          amount=1,
          type="item"
        },
        {
          name="radar",
          amount=1,
          type="item"
        }
    },
    name = "astmine-target",
    results = {{name="astmine-target",amount=1,type="item"}},
    type = "recipe"        
}

-- ENTITY: The entity form of the Asteroid Target
local amtargete = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
amtargete.name = "astmine-target"
-- We can't put this on resources, because resources need to not be put under it.
amtargete.collision_mask = {"item-layer", "object-layer", "player-layer", "water-tile","resource-layer"}
amtargete.collision_mask = {layers = {item = true, object = true, player = true, water_tile = true, resource = true}}
amtargete.item_slot_count = 1
amtargete.max_health = 250
amtargete.minable = {
    mining_time = 0.1,
    result = "astmine-target"
}
radsprite = {
        filename = "__base__/graphics/entity/electric-mining-drill/electric-mining-drill-radius-visualization.png",
        height = 10,
        width = 10
}
amtargete.radius_visualisation_specification = {
            sprite = radsprite,
            distance = 5.5
}
amtargete.energy_source = data.raw["arithmetic-combinator"]["arithmetic-combinator"].energy_source
amtargete.subgroup = subtarget
amtargete.sprites = {
    layers = {
      {
        filename = "__base__/graphics/entity/programmable-speaker/programmable-speaker.png",
        height = 89,
        hr_version = {
          filename = "__base__/graphics/entity/programmable-speaker/hr-programmable-speaker.png",
          height = 178,
          priority = "extra-high",
          scale = 0.5,
          shift = {
            -0.0703125,
            -1.234375
          },
          width = 59
        },
        priority = "extra-high",
        shift = {
          -0.0625,
          -1.234375
        },
        width = 30
      },
      {
        draw_as_shadow = true,
        filename = "__base__/graphics/entity/programmable-speaker/programmable-speaker-shadow.png",
        height = 25,
        hr_version = {
          draw_as_shadow = true,
          filename = "__base__/graphics/entity/programmable-speaker/hr-programmable-speaker-shadow.png",
          height = 50,
          priority = "extra-high",
          scale = 0.5,
          shift = {
            1.6484375,
            -0.09375
          },
          width = 237
        },
        priority = "extra-high",
        shift = {
          1.640625,
          -0.078125
        },
        width = 119
      }
    }
}
amtargete.collision_box = {{-1.4, -1.4}, {1.4, 1.4}}
amtargete.selection_box = {{-1.4, -1.4}, {1.4, 1.4}}
amtargete.circuit_connector_sprites = {
    blue_led_light_offset = {
      0.03125,
      0.03125
    },
    connector_main = {
      filename = "__base__/graphics/entity/circuit-connector/hr-ccm-universal-04a-base-sequence.png",
      height = 50,
      priority = "low",
      scale = 0.5,
      shift = {
        0,
        -0.21875
      },
      width = 52,
      x = 104,
      y = 100
    },
    connector_shadow = {
      draw_as_shadow = true,
      filename = "__base__/graphics/entity/circuit-connector/hr-ccm-universal-04b-base-shadow-sequence.png",
      height = 46,
      priority = "low",
      scale = 0.5,
      shift = {
        0.21875,
        -0.140625
      },
      width = 62,
      x = 124,
      y = 92
    },
    led_blue = {
      draw_as_glow = true,
      filename = "__base__/graphics/entity/circuit-connector/hr-ccm-universal-04e-blue-LED-on-sequence.png",
      height = 60,
      priority = "low",
      scale = 0.5,
      shift = {
        0,
        -0.25
      },
      width = 60,
      x = 120,
      y = 120
    },
    led_blue_off = {
      filename = "__base__/graphics/entity/circuit-connector/hr-ccm-universal-04f-blue-LED-off-sequence.png",
      height = 44,
      priority = "low",
      scale = 0.5,
      shift = {
        0,
        -0.25
      },
      width = 46,
      x = 92,
      y = 88
    },
    led_green = {
      draw_as_glow = true,
      filename = "__base__/graphics/entity/circuit-connector/hr-ccm-universal-04h-green-LED-sequence.png",
      height = 46,
      priority = "low",
      scale = 0.5,
      shift = {
        0,
        -0.25
      },
      width = 48,
      x = 96,
      y = 92
    },
    led_light = {
      intensity = 0,
      size = 0.9
    },
    led_red = {
      draw_as_glow = true,
      filename = "__base__/graphics/entity/circuit-connector/hr-ccm-universal-04i-red-LED-sequence.png",
      height = 46,
      priority = "low",
      scale = 0.5,
      shift = {
        0,
        -0.25
      },
      width = 48,
      x = 96,
      y = 92
    },
    red_green_led_light_offset = {
      0.015625,
      -0.140625
    },
    wire_pins = {
      filename = "__base__/graphics/entity/circuit-connector/hr-ccm-universal-04c-wire-sequence.png",
      height = 58,
      priority = "low",
      scale = 0.5,
      shift = {
        0,
        -0.25
      },
      width = 62,
      x = 124,
      y = 116
    },
    wire_pins_shadow = {
      draw_as_shadow = true,
      filename = "__base__/graphics/entity/circuit-connector/hr-ccm-universal-04d-wire-shadow-sequence.png",
      height = 54,
      priority = "low",
      scale = 0.5,
      shift = {
        0.15625,
        -0.125
      },
      width = 70,
      x = 140,
      y = 108
    }
}
amtargete.circuit_wire_connection_point = {
        shadow = {
          green = {
            0.625,
            0.171875
          },
          red = {
            0.78125,
            0.078125
          }
        },
        wire = {
          green = {
            0.359375,
            0.03125
          },
          red = {
            0.296875,
            -0.203125
          }
        }
}

-- **************************
-- Mixed miner module and recipe
-- **************************
local astminmixed = table.deepcopy(data.raw['item']['satellite'])
astminmixed.icon = "__Asteroid_Mining__/graphics/mining-sat.png"
astminmixed.name = "astmine-mixed"
astminmixed.order = "astmine-aaa"
astminmixed.subgroup = subminer
astminmixed.rocket_launch_product = nil
-- Recipe for the upgrade module
local astminmixedr = {
    enabled = false,
    ingredients = {
        {
          name="processing-unit",
          amount=5,
          type="item"
        },
        {
          name="speed-module",
          amount=5,
          type="item"
        },
        {
          name="roboport",
          amount=1,
          type="item"
        },
        {
          name="logistic-robot",
          amount=10,
          type="item"
        },
        {
          name="nuclear-reactor",
          amount=1,
          type="item"
        },
        {
          name="radar",
          amount=5,
          type="item"
        },
        {
          name="electric-mining-drill",
          amount=20,
          type="item"
        }
    },
    name = "astmine-mixed",
    results = {{name="astmine-mixed",amount=1,type="item"}},
    type = "recipe"
}


-- **************************
-- Miner upgrade items and recipes
-- **************************
local astminupg5 = table.deepcopy(data.raw['item']['satellite'])
astminupg5.name = "astmine-upgrade-5"
astminupg5.order = "astmine-upgrade-1"
astminupg5.subgroup = subminer
astminupg5.rocket_launch_product = nil
-- Recipe for the upgrade module
local astminupg5r = {
    enabled = false,
    ingredients = {
        {
          name="processing-unit",
          amount=10,
          type="item"
        },
        {
          name="roboport",
          amount=2,
          type="item"
        },
        {
          name="logistic-robot",
          amount=50,
          type="item"
        },
        {
          name="nuclear-reactor",
          amount=2,
          type="item"
        },
        {
          name="radar",
          amount=10,
          type="item"
        }
    },
    name = "astmine-upgrade-5",
    results = {{name="astmine-upgrade-5",amount=1,type="item"}},
    type = "recipe"
}

-- Only difference between 5 and 25 is the name and recipe.
local astminupg25 = table.deepcopy(astminupg5)
astminupg25.name = "astmine-upgrade-25"
astminupg25.order = "astmine-upgrade-2"
-- Recipe for the upgrade module
local astminupg25r = {
    enabled = false,
    ingredients = {
        {
            name="processing-unit",
            amount=50,
            type="item"
        },
        {
            name="roboport",
            amount=10,
            type="item"
        },
        {
            name="logistic-robot",
            amount=100,
            type="item"
        },
        {
            name="radar",
            amount=20,
            type="item"
        },
        {
            name="low-density-structure",
            amount=100,
            type="item"
        },
        {
            name="rocket-silo",
            amount=1,
            type="item"
        }
    },
    name = "astmine-upgrade-25",
    results = {{name="astmine-upgrade-25",amount=1,type="item"}},
    type = "recipe"
}

local astminupg = table.deepcopy(astminupg5)
astminupg.name = "astmine-upgrade-module"
astminupg.order = "astmine-upgrade"
local astminupgr = {
    enabled = false,
    ingredients = {
        {
            name="roboport",
            amount=10,
            type="item"
        },
        {
            name="construction-robot",
            amount=100,
            type="item"
        },
        {
            name="solar-panel",
            amount=100,
            type="item"
        },
        {
            name="accumulator",
            amount=50,
            type="item"
        },
        {
            name="low-density-structure",
            amount=100,
            type="item"
        }
    },
    name = "astmine-upgrade-module",
    results = {{name="astmine-upgrade-module",amount=1,type="item"}},
    type = "recipe"
}

local upgradetech = {
      effects = {
      },
      icon = "__base__/graphics/technology/rocket-silo.png",
      icon_mipmaps = 4,
      icon_size = 256,
      name = "astmine-upgrades",
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
      name = "astmine-resminer",
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
    table.insert(data.raw.technology["rocket-silo"].effects, {type = "unlock-recipe", recipe = "astmine-target"})
    table.insert(data.raw.technology["rocket-silo"].effects, {type = "unlock-recipe", recipe = "astmine-mixed"})
    table.insert(data.raw.technology["astmine-upgrades"].effects, {type = "unlock-recipe", recipe = "astmine-upgrade-module"})
    table.insert(data.raw.technology["astmine-upgrades"].effects, {type = "unlock-recipe", recipe = "astmine-upgrade-5"})
    table.insert(data.raw.technology["astmine-upgrades"].effects, {type = "unlock-recipe", recipe = "astmine-upgrade-25"})
    -- This makes the items for every resource, and will be called again in updates and final-fixes
    make_resources()
end
