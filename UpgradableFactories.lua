UpgradableFactories = {}
UpgradableFactories.dir = g_currentModDirectory
UpgradableFactories.modName = g_currentModName

source(UpgradableFactories.dir .. "InGameMenuUpgradableFactories.lua")
addModEventListener(UpgradableFactories)

function UpgradableFactories:loadMap()
	-- check if savegameDirectory exist -> on a new save, savegameDirectory doesn't exist at that moment
	if g_currentMission.missionInfo.savegameDirectory then
		self.xmlFilename = g_currentMission.missionInfo.savegameDirectory .. "/upgradableFactories.xml"
	else
		self.newSavegame = true
	end
	self.productionPoints = {}
	self.upgradableFactories = InGameMenuUpgradableFactories.new(self)
	self.upgradableFactories:initialize()

	self:loadXML()

	g_messageCenter:subscribe(MessageType.SAVEGAME_LOADED, self.onSavegameLoaded, self)
end

function UpgradableFactories:delete()
	g_messageCenter:unsubscribeAll(self)
end

function UpgradableFactories:onSavegameLoaded()
	self:initProductions()
end

local function getProductionPointFromPosition(pos)
	if #g_currentMission.productionChainManager.farmIds < 1 then
		return nil
	end
	
	for _,prod in ipairs(g_currentMission.productionChainManager.farmIds[1].productionPoints) do
		if MathUtil.getPointPointDistanceSquared(pos.x, pos.y, prod.owningPlaceable.position.x, prod.owningPlaceable.position.y) < 1 then
			return prod
		end
	end
	return nil
end

local function adjUpgradePrice2lvl(price, lvl)
    -- Upgrade price increase by 5% each level
    return math.floor(price + price * (0.05 * (lvl - 1)))
end

local function adjCapa2lvl(capacity, lvl)
    -- Strorage capacity increase by it's base value each level
    return math.floor(capacity * lvl)
end

local function adjCycl2lvl(cycle, lvl)
    -- Production speed increase by it's base value each level.
	-- A bonus of 15% of the base speed is applied per level starting at the level 2
	lvl = tonumber(lvl)
	local adj = cycle * lvl + cycle * 0.15 * (lvl - 1)
	if adj < 1 then
		return adj
	else
		return math.floor(adj)
	end
end

local function adjCost2lvl(cost, lvl)
    -- Running cost increase by it's base value each level
	-- A reduction of 10% of the base cost is applied par level starting at the level 2
	lvl = tonumber(lvl)
	local adj = cost * lvl - cost * 0.1 * (lvl - 1)
	if adj < 1 then
		return adj
	else
		return math.floor(adj)
	end
end

local function adjPrice2lvl(price, lvl)
    -- Total value of the production point
	-- Include base price and all upgrade costs
	local upgradeValue = 0
	for i=2, lvl do
		upgradeValue = upgradeValue + adjUpgradePrice2lvl(price, i)
	end
    return price + upgradeValue
end

function UpgradableFactories:adjProdPoint2lvl(prodpoint, lvl)
	if lvl > 1 then
		for _,p in ipairs(prodpoint.productions) do
			p.cyclesPerMinute = adjCycl2lvl(p.cyclesPerMinute, lvl)
			p.cyclesPerHour = adjCycl2lvl(p.cyclesPerHour, lvl)
			p.cyclesPerMonth = adjCycl2lvl(p.cyclesPerMonth, lvl)

			p.costsPerActiveMinute = adjCost2lvl(p.costsPerActiveMinute, lvl)
			p.costsPerActiveHour = adjCost2lvl(p.costsPerActiveHour, lvl)
			p.costsPerActiveMonth = adjCost2lvl(p.costsPerActiveMonth, lvl)
		end
		
		for ft,s in pairs(prodpoint.storage.capacities) do
			prodpoint.storage.capacities[ft] = adjCapa2lvl(s, lvl)
		end

		prodpoint.owningPlaceable.price = adjPrice2lvl(prodpoint.owningPlaceable.basePrice, lvl)
		prodpoint.owningPlaceable["upgradePrice"] = adjUpgradePrice2lvl(prodpoint.owningPlaceable.basePrice, lvl)
		
	end

	prodpoint.owningPlaceable.getSellPrice = function ()
		local priceMultiplier = 0.75
		local maxAge = prodpoint.owningPlaceable.storeItem.lifetime
		if maxAge ~= nil and maxAge ~= 0 then
			priceMultiplier = priceMultiplier * math.exp(-3.5 * math.min(prodpoint.owningPlaceable.age / maxAge, 1))
		end
		return math.floor(prodpoint.owningPlaceable.price * math.max(priceMultiplier, 0.05))
	end
end

function UpgradableFactories:initProductions()
	-- print("UpgradableFactories - Production points initialisation")
	if self.newSavegame or #g_currentMission.productionChainManager.farmIds < 1 then return end

	self.productionPoints = g_currentMission.productionChainManager.farmIds[1].productionPoints

	if self.modFirstLoad then
		-- print("UpgradableFactories - Initialisation of mod first load")
		for _,prod in ipairs(self.productionPoints) do
			prod["productionLevel"] = 1
			prod.owningPlaceable["basePrice"] = prod.owningPlaceable.price
		end
		return
	end

	if #self.loadedProductions < 1 then
		-- print("UpgradableFactories - No production to initialize")
		return
	end

	-- printf("UpgradableFactories - %d production to initialize", #self.loadedProductions)
	for _,prod in ipairs(self.loadedProductions) do
		local prodpoint = getProductionPointFromPosition(prod.position)
		prodpoint["productionLevel"] = prod.level
		prodpoint.owningPlaceable.price = prod.basePrice
		prodpoint.owningPlaceable["basePrice"] = prod.basePrice

		if prodpoint then
			self:adjProdPoint2lvl(prodpoint, prod.level)
		end
	end
	-- print("UpgradableFactories - Succesfully initialized productions")
end

function UpgradableFactories:saveToXML()
	-- print("UpgradableFactories - Saving to XML file")
	-- on a new save, create xmlFile path
	if g_currentMission.missionInfo.savegameDirectory then
		self.xmlFilename = g_currentMission.missionInfo.savegameDirectory .. "/upgradableFactories.xml"
	end

	local xmlFile = XMLFile.create("UpgradableFactoriesXML", self.xmlFilename, "upgradableFactories")
	
	-- check if player has owned production installed
	if #g_currentMission.productionChainManager.farmIds > 0 then
		local key = ""
		self.productionPoints = g_currentMission.productionChainManager.farmIds[1].productionPoints
		for i,prod in ipairs(self.productionPoints) do
			key = string.format("upgradableFactories.production(%d)", i-1)
			xmlFile:setInt(key .. "#id", i)
			xmlFile:setString(key .. "#name", prod.owningPlaceable:getName())
			local plevel = 1 if prod.productionLevel then plevel = prod.productionLevel end
			xmlFile:setInt(key .. "#level", plevel)
			local bprice = prod.owningPlaceable.price if prod.owningPlaceable.basePrice then bprice = prod.owningPlaceable.basePrice end
			xmlFile:setInt(key .. "#basePrice", bprice)
	
			local key2 = key .. ".position"
			xmlFile:setFloat(key2 .. "#x", prod.owningPlaceable.position.x)
			xmlFile:setFloat(key2 .. "#y", prod.owningPlaceable.position.y)
		end
	end
    xmlFile:save()
end

function UpgradableFactories:loadXML()
	-- append when creating new save.
	if self.newSavegame then return end

	-- print("UpgradableFactories - Loading XML file")

    local xmlFile = XMLFile.loadIfExists("UpgradableFactoriesXML", self.xmlFilename)
    if not xmlFile then
        self.modFirstLoad = true
		-- print("UpgradableFactories - No XML file found, mod first load")
		return
    end

	-- print("UpgradableFactories - XML file found")

	self.loadedProductions = {}
    local counter = 0
    while true do
        local key = string.format("upgradableFactories.production(%d)", counter)
		
		if not getXMLInt(xmlFile.handle, key .. "#id") then break end
		
		table.insert(
			self.loadedProductions,
			{
				level = getXMLInt(xmlFile.handle,key .. "#level"),
				basePrice = getXMLInt(xmlFile.handle,key .. "#basePrice"),
				position = {
					x = getXMLFloat(xmlFile.handle, key .. ".position#x"),
					y = getXMLFloat(xmlFile.handle, key .. ".position#y")
				}
			}
		)
		
        counter = counter +1
    end

	-- printf("UpgradableFactories - %d Factory found in the XML file", #self.loadedProductions)
end

FSCareerMissionInfo.saveToXMLFile = Utils.appendedFunction(FSCareerMissionInfo.saveToXMLFile, UpgradableFactories.saveToXML)