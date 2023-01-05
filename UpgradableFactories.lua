UpgradableFactories = {}
local modDirectory = g_currentModDirectory
local modName = g_currentModName
UpgradableFactories.MAX_LEVEL = 10

source(modDirectory .. "InGameMenuUpgradableFactories.lua")
addModEventListener(UpgradableFactories)

function UFInfo(infoMessage, ...)
	print(string.format("  UpgradableFactories: " .. infoMessage, ...))
end

function UpgradableFactories:loadMap()
	addConsoleCommand('ufMaxLevel', 'Update UpgradableFactories max level', 'updateml', self)

	-- check if savegameDirectory exist -> on a new save, savegameDirectory doesn't exist at that moment
	if g_currentMission.missionInfo.savegameDirectory then
		self.xmlFilename = g_currentMission.missionInfo.savegameDirectory .. "/upgradableFactories.xml"
	else
		self.newSavegame = true
	end
	self.productionPoints = {}
	InGameMenuUpgradableFactories:initialize()

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
		if MathUtil.getPointPointDistanceSquared(pos.x, pos.y, prod.owningPlaceable.position.x, prod.owningPlaceable.position.y) < 0.0001 then
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
    return math.floor(basePrice + basePrice * 0.1 * lvl)
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
	if self.newSavegame or not self.loadedProductions or #self.loadedProductions < 1 then
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

function UpgradableFactories:initializeProduction(prodpoint)
	if not prodpoint.isUpgradable then
		prodpoint.isUpgradable = true
		prodpoint.productionLevel = 1

		prodpoint.baseName = prodpoint:getName()
		prodpoint.name = prodPointUFName(prodpoint:getName(), 1)
		
		prodpoint.owningPlaceable.basePrice = prodpoint.owningPlaceable.price
		prodpoint.owningPlaceable.upgradePrice = getUpgradePriceAtLvl(prodpoint.owningPlaceable.basePrice, 1)
		
		for _,prod in ipairs(prodpoint.productions) do
			prod.baseCyclesPerMinute = prod.cyclesPerMinute
			prod.baseCyclesPerHour = prod.cyclesPerHour
			prod.baseCyclesPerMonth = prod.cyclesPerMonth
			prod.baseCostsPerActiveMinute = prod.costsPerActiveMinute
			prod.baseCostsPerActiveHour = prod.costsPerActiveHour
			prod.baseCostsPerActiveMonth = prod.costsPerActiveMonth
		end

		prodpoint.storage.baseCapacities = {}
		for ft,val in pairs(prodpoint.storage.capacities) do
			prodpoint.storage.baseCapacities[ft] = val
		end
	end
end

function UpgradableFactories:onFinalizePlacement()
	for _,p in ipairs(g_currentMission.productionChainManager.productionPoints) do
		if not p.productionLevel then
			UpgradableFactories:initializeProduction(p)
		end
	end
end

function UpgradableFactories.setOwnerFarmId(prodpoint, farmId)
    if farmId == 0 and prodpoint.productions[1].baseCyclesPerMinute then
        prodpoint.productionLevel = 1
        UpgradableFactories:adjProdPoint2lvl(prodpoint, 1)
    end
end

function UpgradableFactories:updateml(arg)
	if not arg then
		print("ufMaxLevel <max_level>")
		return
	end

	local n = tonumber(arg)
	if not n then
		print("ufMaxLevel <max_level>")
		print("<max_level> must be a number")
		return
	elseif n < 1 or n > 99 then
		print("ufMaxLevel <max_level>")
		print("<max_level> must be between 1 and 99")
		return
	end

	self.MAX_LEVEL = n

	self:initProductions()

	UFInfo("Production maximum level has been updated to level "..n, "")
end

function UpgradableFactories:saveToXML()
	UFInfo("Saving to XML")
	-- on a new save, create xmlFile path
	if g_currentMission.missionInfo.savegameDirectory then
		self.xmlFilename = g_currentMission.missionInfo.savegameDirectory .. "/upgradableFactories.xml"
	end

	local xmlFile = XMLFile.create("UpgradableFactoriesXML", self.xmlFilename, "upgradableFactories")
	xmlFile:setInt("upgradableFactories#maxLevel", UpgradableFactories.MAX_LEVEL)

	-- check if player has owned production installed
	if #g_currentMission.productionChainManager.farmIds > 0 then	
		self.productionPoints = g_currentMission.productionChainManager.farmIds[1].productionPoints
		for i,prodpoint in ipairs(self.productionPoints) do
			if prodpoint.isUpgradable then
				local key = string.format("upgradableFactories.production(%d)", i-1)
				xmlFile:setInt(key .. "#id", i)
				xmlFile:setString(key .. "#name", prodpoint.baseName)
				xmlFile:setInt(key .. "#level", prodpoint.productionLevel)
				xmlFile:setInt(key .. "#basePrice", prodpoint.owningPlaceable.basePrice)
		
				local key2 = key .. ".position"
				xmlFile:setFloat(key2 .. "#x", prodpoint.owningPlaceable.position.x)
				xmlFile:setFloat(key2 .. "#y", prodpoint.owningPlaceable.position.y)

				local j = 0
				key2 = ""
				for ft,val in pairs(prodpoint.storage.fillLevels) do
					key2 = key .. string.format(".fillLevels.fillType(%d)", j)
					xmlFile:setInt(key2 .. "#id", ft)
					xmlFile:setString(key2 .. "#fillType", g_currentMission.fillTypeManager:getFillTypeByIndex(ft).name)
					xmlFile:setInt(key2 .. "#fillLevel", val)
					j = j + 1
				end
			end
		end
	end
    xmlFile:save()
end

function UpgradableFactories:loadXML()
	UFInfo("Loading XML...")

	if self.newSavegame then
		UFInfo("New savegame")
		return
	end

    local xmlFile = XMLFile.loadIfExists("UpgradableFactoriesXML", self.xmlFilename)
    if not xmlFile then
		UFInfo("No XML file found")
		return
    end

	self.loadedProductions = {}
    local counter = 0
    while true do
        local key = string.format("upgradableFactories.production(%d)", counter)
		
		if not getXMLInt(xmlFile.handle, key .. "#id") then break end
		
		local level = getXMLInt(xmlFile.handle,key .. "#level")
		table.insert(
			self.loadedProductions,
			{
				level = level,
				name = getXMLString(xmlFile.handle, key .. "#name"),
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

	local ml = getXMLInt(xmlFile.handle, "upgradableFactories#maxLevel")
	if ml and ml > 0 and ml < 100 then
		self.MAX_LEVEL = ml
	end
	UFInfo(#self.loadedProductions.." productions loaded from XML")
	UFInfo("Production maximum level: "..self.MAX_LEVEL)

	if #self.loadedProductions > 0 then
		for _,p in ipairs(self.loadedProductions) do
			if p.level > self.MAX_LEVEL then
				UFInfo("%s over max level: %d", p.name, p.level)
			end
		end
	end
end

PlaceableProductionPoint.onFinalizePlacement = Utils.appendedFunction(PlaceableProductionPoint.onFinalizePlacement, UpgradableFactories.onFinalizePlacement)
FSCareerMissionInfo.saveToXMLFile = Utils.appendedFunction(FSCareerMissionInfo.saveToXMLFile, UpgradableFactories.saveToXML)
ProductionPoint.setOwnerFarmId = Utils.appendedFunction(ProductionPoint.setOwnerFarmId, UpgradableFactories.setOwnerFarmId)