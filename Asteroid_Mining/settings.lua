-- order values - [a] All modes, [b] Basic mode (ie the original), [v] Advanced Mode (ie the 1.1.0 update stuff)
data:extend({
    -- All mode options - Just tab group for now
    { -- Put Asteroid Mining items in their own tab group
        type = "bool-setting",
        name = "astmine-newgroup",
        setting_type = "startup",
        default_value = true,
        order = "[a]aastmine-newgroup"
    },
    -- Basic mode options (4)
    { -- Enable the asteroid miner items
        type = "bool-setting",
        name = "astmine-enableminer",
        setting_type = "startup",
        default_value = true,
        order = "[b]aastmine-enableminer"
    },
    { -- Allow productivity modules in chunk processing recipes?
        type = "bool-setting",
        name = "astmine-allowprod",
        setting_type = "startup",
        default_value = false,
        order = "[b]astmine-allowprod"
    },
    { -- Mining prod research effects crushing recipes at 1% per level?
        type = "bool-setting",
        name = "astmine-miningprod",
        setting_type = "startup",
        default_value = false,
        order = "[b]astmine-allowprod2"
    },
    { -- Quality mining modules give quality asteroids?
        type = "bool-setting",
        name = "astmine-quality",
        setting_type = "startup",
        default_value = false,
        order = "[b]astmine-allowquality"
    },
    { -- Should we use Angels crushers for processing chunks if machines are present?
        type = "bool-setting",
        name = "astmine-crushing",
        setting_type = "startup",
        default_value = true,
        order = "[b]astmine-crushing"
    },
    -- { -- Should we use Krastorio crushers for processing chunks if machines are present?
        -- type = "bool-setting",
        -- name = "astmine-k2crushing",
        -- setting_type = "startup",
        -- default_value = true,
        -- order = "[b]astmine-k2crushing"
    -- },
    { -- Should recipes be hidden until we research the rocket silo?
        type = "bool-setting",
        name = "astmine-hiderecipes",
        setting_type = "startup",
        default_value = false,
        order = "[b]astmine-azhiderecipes"
    },
    -- Below this is Advanced mode settings 
    { -- Enable the new items for advanced asteroid mining
        type = "bool-setting",
        name = "astmine-makerockets",
        setting_type = "startup",
        default_value = false,
        order = "[v]aastmine-makerockets",
        hidden = false
    },
    { -- Disallow resources that require a fluid to mine. - TODO Add 'NoRandom' value which allows but won't include them in random ore distribution, only with signal set.
        type = "string-setting",
        name = "astmine-disallowfluid",
        setting_type = "startup",
        default_value = "Allow",
        allowed_values= {"Allow", "Disallow"},
        order = "[v]astmine-disallowfluid",
        hidden = false -- disabled right now
    },
    { -- All surfaces share information, default is based on Nauvis.
        type = "bool-setting",
        name = "astmine-singlesurface",
        setting_type = "startup",
        default_value = false,
        order = "[v]astmine-singlesurface",
        hidden = false -- disabled right now
    },
    { -- Amount to transfer for each asteroid targeter action
        type = "int-setting",
        name = "astmine-resamount",
        setting_type = "runtime-global",
        default_value = 500,
        minimum_value = 100,
        maximum_value = 1000,
        hidden = false,
        order = "[v]astmine-zresamount"
    }
})