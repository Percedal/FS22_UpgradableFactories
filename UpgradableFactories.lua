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

local function getCapacityAtLvl(capacity, lvl)
    -- Strorage capacity increase by it's base value each level
    return math.floor(capacity * lvl)
end

local function getCycleAtLvl(cycle, lvl)
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

local function getActiveCostAtLvl(cost, lvl)
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

local function getUpgradePriceAtLvl(basePrice, lvl)
    -- Upgrade price increase by 10% each level
    return math.floor(basePrice + basePrice * (0.1 * lvl))
end

local function getOverallProductionValue(basePrice, lvl)
	-- Base price + all upgrade prices
	local value = 0
	for l=2, lvl do
		value = value + getUpgradePriceAtLvl(basePrice, l-1)
	end
	return basePrice + value
end

local function prodPointUFName(basename, level)
    return string.format("%d - %s", level, basename)
end

function UpgradableFactories:adjProdPoint2lvl(prodpoint, lvl)
	for _,p in ipairs(prodpoint.productions) do
		p.cyclesPerMinute = getCycleAtLvl(p.baseCyclesPerMinute, lvl)
		p.cyclesPerHour = getCycleAtLvl(p.baseCyclesPerHour, lvl)
		p.cyclesPerMonth = getCycleAtLvl(p.baseCyclesPerMonth, lvl)

		p.costsPerActiveMinute = getActiveCostAtLvl(p.baseCostsPerActiveMinute, lvl)
		p.costsPerActiveHour = getActiveCostAtLvl(p.baseCostsPerActiveHour, lvl)
		p.costsPerActiveMonth = getActiveCostAtLvl(p.baseCostsPerActiveMonth, lvl)
	end
	
	for ft,s in pairs(prodpoint.storage.baseCapacities) do
		prodpoint.storage.capacities[ft] = getCapacityAtLvl(s, lvl)
	end

	prodpoint.owningPlaceable.price = getOverallProductionValue(prodpoint.owningPlaceable.basePrice, lvl)
	prodpoint.owningPlaceable.upgradePrice = getUpgradePriceAtLvl(prodpoint.owningPlaceable.basePrice, lvl)

	prodpoint.name = prodPointUFName(prodpoint.baseName, lvl)

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
	if self.newSavegame or not self.loadedProductions then
		return
	end

	self.productionPoints = g_currentMission.productionChainManager.farmIds[1].productionPoints
	for _,prod in ipairs(self.loadedProductions) do
		local prodpoint = getProductionPointFromPosition(prod.position)
		prodpoint.productionLevel = prod.level
		prodpoint.owningPlaceable.basePrice = prod.basePrice
		prodpoint.owningPlaceable.price = getOverallProductionValue(prod.basePrice, prod.level)

		self:adjProdPoint2lvl(prodpoint, prod.level)

		prodpoint.storage.fillLevels = prod.fillLevels
	end
end

function UpgradableFactories:onFinalizePlacement()
	for _,p in ipairs(g_currentMission.productionChainManager.productionPoints) do
		if not p.productionLevel then
			p.productionLevel = 1

			p.baseName = p:getName()
			p.name = prodPointUFName(p:getName(), 1)
			
			p.owningPlaceable.basePrice = p.owningPlaceable.price
			p.owningPlaceable.upgradePrice = getUpgradePriceAtLvl(p.owningPlaceable.basePrice, 1)
			
			for _,prodline in ipairs(p.productions) do
				prodline.baseCyclesPerMinute = prodline.cyclesPerMinute
				prodline.baseCyclesPerHour = prodline.cyclesPerHour
				prodline.baseCyclesPerMonth = prodline.cyclesPerMonth
				prodline.baseCostsPerActiveMinute = prodline.costsPerActiveMinute
				prodline.baseCostsPerActiveHour = prodline.costsPerActiveHour
				prodline.baseCostsPerActiveMonth = prodline.costsPerActiveMonth
			end

			p.storage.baseCapacities = {}
			for ft,val in pairs(p.storage.capacities) do
				p.storage.baseCapacities[ft] = val
			end
		end
	end
end

function UpgradableFactories.setOwnerFarmId(prodpoint, farmId)
    if farmId == 0 and prodpoint.productions[1].baseCyclesPerMinute then
        prodpoint.productionLevel = 1
        UpgradableFactories:adjProdPoint2lvl(prodpoint, 1)
    end
end

function UpgradableFactories:saveToXML()
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
			xmlFile:setString(key .. "#name", prod.baseName)
			xmlFile:setInt(key .. "#level", prod.productionLevel)
			xmlFile:setInt(key .. "#basePrice", prod.owningPlaceable.basePrice)
	
			local key2 = key .. ".position"
			xmlFile:setFloat(key2 .. "#x", prod.owningPlaceable.position.x)
			xmlFile:setFloat(key2 .. "#y", prod.owningPlaceable.position.y)

			local j = 0
            key2 = ""
            for ft,val in pairs(prod.storage.fillLevels) do
                key2 = key .. string.format(".fillLevels.fillType(%d)", j)
                xmlFile:setInt(key2 .. "#id", ft)
                xmlFile:setString(key2 .. "#fillType", g_currentMission.fillTypeManager:getFillTypeByIndex(ft).name)
                xmlFile:setInt(key2 .. "#fillLevel", val)
                j = j + 1
            end
		end
	end
    xmlFile:save()
end

function UpgradableFactories:loadXML()
	-- append when creating new save.
	if self.newSavegame then return end

    local xmlFile = XMLFile.loadIfExists("UpgradableFactoriesXML", self.xmlFilename)
    if not xmlFile then
		return
    end

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

		local capacities = {}
		local counter2 = 0
        while true do
            local key2 = key .. string.format(".fillLevels.fillType(%d)", counter2)
            
			if not getXMLString(xmlFile.handle, key2 .. "#fillType") then break end

			capacities[getXMLInt(xmlFile.handle, key2 .. "#id")] = getXMLInt(xmlFile.handle, key2 .. "#fillLevel")

            counter2 = counter2 +1
        end

		self.loadedProductions[counter+1].fillLevels = capacities
		
        counter = counter +1
    end
end

PlaceableProductionPoint.onFinalizePlacement = Utils.appendedFunction(PlaceableProductionPoint.onFinalizePlacement, UpgradableFactories.onFinalizePlacement)
FSCareerMissionInfo.saveToXMLFile = Utils.appendedFunction(FSCareerMissionInfo.saveToXMLFile, UpgradableFactories.saveToXML)
ProductionPoint.setOwnerFarmId = Utils.appendedFunction(ProductionPoint.setOwnerFarmId, UpgradableFactories.setOwnerFarmId)