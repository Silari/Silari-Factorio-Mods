require("scripts/adv-data-util.lua") -- Has our resource/miner generator functions

require("scripts/groups.lua") -- Handles setting our recipe groups

if settings.startup["astmine-makerockets"].value then
    make_resources(makesignals or false) -- Make any resources that weren't caught in the first pass.
end