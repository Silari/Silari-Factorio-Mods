
-- Adds a few one off ores that don't need any other further additions/balancing/changes.
function addsingles()
    if data.raw.tool["tenemut"] then -- Dark Matter Replicators' (or one of many many ports) tenemut
        addtype("tenemut", {a = 0.6, r = 100, g = 0, b = 100})
    end
    if data.raw.item["omnite"] then -- Omnimatter's Omnite
        addtype("omnite", {a = 0.4, r = 250, g = 0, b = 250})
    end
    if data.raw.resource["sulfur"] then -- Someone has added sulfur as a mineable resource - make a miner for it
        addtype("sulfur", {a = 0.8, r = 255, g = 255, b = 0})
    end
    if mods["bzlead"] and data.raw.resource["lead-ore"] then
        addtype("lead-ore", {a = 0.6, r = .1, g = 0, b = .05})
    end
    if mods["bztungsten"] and data.raw.resource["tungsten-ore"] then
        addtype("tungsten-ore", {a = 0.7, r = 110, g = 110, b = 100})
    end
    if data.raw.resource["titanium-ore"] then
        addtype("titanium-ore", {a = 0.8, r = 40, g = 70, b = 110})
    end
end