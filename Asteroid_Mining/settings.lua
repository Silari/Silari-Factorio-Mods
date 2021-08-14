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
        default_value = false,
        order = "[b]aastmine-enableminer"
    },
    { -- Allow productivity modules in chunk processing recipes?
        type = "bool-setting",
        name = "astmine-allowprod",
        setting_type = "startup",
        default_value = false,
        order = "[b]astmine-allowprod"
    },
    { -- Should we use Angels crushers for processing chunks if machines are present?
        type = "bool-setting",
        name = "astmine-crushing",
        setting_type = "startup",
        default_value = true,
        order = "[b]astmine-crushing"
    },
    { -- Should we use Krastorio crushers for processing chunks if machines are present?
        type = "bool-setting",
        name = "astmine-k2crushing",
        setting_type = "startup",
        default_value = true,
        order = "[b]astmine-k2crushing"
    },
    -- Below this is Advanced mode settings 
    { -- Enable the new items for advanced asteroid mining
        type = "bool-setting",
        name = "astmine-makerockets",
        setting_type = "startup",
        default_value = true,
        order = "[v]aastmine-makerockets"
    },
    { -- Disallow resources that require a fluid to mine. - TODO Add 'NoRandom' value which allows but won't include them in random ore distribution, only with signal set.
        type = "string-setting",
        name = "astmine-disallowfluid",
        setting_type = "startup",
        default_value = "Allow",
        allowed_values= {"Allow", "Disallow"},
        order = "[v]astmine-disallowfluid"
    },
    { -- All surfaces share information, default is based on Nauvis.
        type = "bool-setting",
        name = "astmine-singlesurface",
        setting_type = "startup",
        default_value = false,
        order = "[v]astmine-singlesurface"
    },
    {
        type = "int-setting",
        name = "astmine-resamount",
        setting_type = "runtime-global",
        default_value = 500,
        minimum_value = 100,
        maximum_value = 1000,
        hidden = true,
        order = "[v]astmine-zresamount"
    }
})