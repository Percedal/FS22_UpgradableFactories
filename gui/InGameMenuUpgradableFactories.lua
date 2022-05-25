InGameMenuUpgradableFactories = {}
InGameMenuUpgradableFactories._mt = Class(InGameMenuUpgradableFactories, TabbedMenuFrameElement)

-- InGameMenuUpgradableFactories.CONTROLS = {
--     MAIN_BOX = "mainBox",
--     TABLE_SLIDER = "tableSlider",
--     HEADER_BOX = "tableHeaderBox",
--     TABLE = "upgradableFactoriesTable",
--     TABLE_TEMPLATE = "upgradableFactoriesRowTemplate",
-- }

function InGameMenuUpgradableFactories.new(i18n, messageCenter)
    local self = InGameMenuUpgradableFactories:superClass().new(nil, InGameMenuUpgradableFactories._mt)
    
    self.name = "inGameMenuUpgradableFactories"
    self.i18n = i18n
    self.messageCenter = messageCenter
    self.factories = {}
    
    -- self:registerControls(InGameMenuUpgradableFactories.CONTROLS)
    
    -- self.backButtonInfo = {
    --     inputAction = InputAction.MENU_BACK
    -- }
    -- self.btnUpgrade = {
    --     text = "Upgrade",
    --     inputAction = InputAction.MENU_ACTIVATE,
    --     callback = function ()
    --         self:upgrade()
    --     end
    -- }
    
    -- self:setMenuButtonInfo({
    --     self.backButtonInfo,
    --     self.btnUpgrade
    -- })
    
    return self
end

function InGameMenuUpgradableFactories:initialize()
    InGameMenuProductionFrame.onFrameOpen = Utils.appendedFunction(InGameMenuProductionFrame.onFrameOpen, function ()
        self:onFrameOpen()
    end)
    self:loadFromXML()
end

function InGameMenuUpgradableFactories:onSavegameLoaded()
    -- On load, update production points storage capacities based on their levels
    -- This cannot be done when loading xml file : g_currentMission.productionChainManager does not exist at that moment
    for _,f in pairs(self.factories) do
        f.productionPointObject = self:getPCMFactoryByPosition(f.position)
        if not f.productionPointObject then
            printf("Error when searching factory %d by position", f.id)
            break
        end

        for fillType,fillLevel in pairs(f.fillLevels) do
            f.productionPointObject.storage.fillLevels[fillType] = fillLevel
        end

        self:overwriteFactoryName(f)

        f.id = nil
        f.fillLevels = nil
    end

    self:lookForPCMFactories()
    self:updatePCMFactoriesRates()
end

function InGameMenuUpgradableFactories:overwriteFactoryName(factory)
    local name = factory.productionPointObject.owningPlaceable:getName()
    name = string.gsub(name, "lvl.%d+", "")
    factory.productionPointObject.owningPlaceable.getName = Utils.overwrittenFunction(
        factory.productionPointObject.owningPlaceable.getName,
        function ()
            return name .. " lvl." .. tostring(factory.level)
        end
    )
end

function InGameMenuUpgradableFactories:delete()
    InGameMenuUpgradableFactories:superClass().delete(self)
end

-- function InGameMenuUpgradableFactories:copyAttributes(src)
--     InGameMenuUpgradableFactories:superClass().copyAttributes(self, src)
--     self.i18n = src.i18n
-- end

-- function InGameMenuUpgradableFactories:onGuiSetupFinished()
--     InGameMenuUpgradableFactories:superClass().onGuiSetupFinished(self)
--     self.upgradableFactoriesTable:setDataSource(self)
--     self.upgradableFactoriesTable:setDelegate(self)
-- end

function InGameMenuUpgradableFactories:onFrameOpen()
    -- print("InGameMenuProductionFrame")
    -- print_r(InGameMenuProductionFrame, 0)
    -- print("pageProduction")
    -- print_r(g_currentMission.inGameMenu.pageProduction, 0)
    -- print("pageProduction.productionList")
    -- print_r(g_currentMission.inGameMenu.pageProduction.productionList, 0)
    -- print("pageProduction.productionList.sections")
    -- print_r(g_currentMission.inGameMenu.pageProduction.productionList.sections, 2)

    self:lookForPCMFactories()

    local inGameMenu = g_currentMission.inGameMenu
    if inGameMenu.upgradeFactoryButton == nil then
        local upgradeBtn = inGameMenu.menuButton[1]:clone(self)
        upgradeBtn:setText("Upgrade")
        upgradeBtn:setInputAction("MENU_EXTRA_1")
        upgradeBtn.onClickCallback = function ()
            self:upgrade()
        end

        inGameMenu.menuButton[1].parent:addElement(upgradeBtn)
        inGameMenu.upgradeFactoryButton = upgradeBtn
    end
end

function InGameMenuUpgradableFactories:onFrameClose()
    local inGameMenu = g_currentMission.inGameMenu
    if inGameMenu.upgradeFactoryButton ~= nil then
        inGameMenu.upgradeFactoryButton:unlinkElement()
        inGameMenu.upgradeFactoryButton:delete()
        inGameMenu.upgradeFactoryButton = nil
    end
end
InGameMenuProductionFrame.onFrameClose = Utils.appendedFunction(InGameMenuProductionFrame.onFrameClose, InGameMenuUpgradableFactories.onFrameClose)

function InGameMenuUpgradableFactories:lookForPCMFactories()
    for _,f in ipairs(g_currentMission.productionChainManager.productionPoints) do
        if f.isOwned and not self:getFactoryById(f.id) then
            local tab = {
                productionPointObject = f,
                level = 1,
                basePrice = f.owningPlaceable:getPrice(),
                productions = {},
                baseCapacities = {}
            }

            for _,p in ipairs(f.productions) do
                table.insert(
                    tab.productions,
                    {
                        id = p.id,
                        cyclesPerMonth = p.cyclesPerMonth,
                        costsPerActiveMonth = p.costsPerActiveMonth
                    }
                )
            end

            for fillType,capacity in pairs(f.storage.capacities) do
                table.insert(tab.baseCapacities, fillType, capacity)
            end
            
            table.insert(
                self.factories,
                tab
            )
        end
    end
end

function InGameMenuUpgradableFactories:getFactoryById(id)
    for _,f in ipairs(self.factories) do
        if f.productionPointObject.id == id then
            return f
        end
    end
    return nil
end

function InGameMenuUpgradableFactories:getPCMFactoryById(id)
    for _,f in ipairs(g_currentMission.productionChainManager.productionPoints) do
        if f.id == id then
            return f
        end
    end
    return nil
end

local function approxEq(f1, f2)
    return math.abs(f1 - f2) < 0.001
end

function InGameMenuUpgradableFactories:getPCMFactoryByPosition(position)
    for _,f in ipairs(g_currentMission.productionChainManager.productionPoints) do
        local position2 = f.owningPlaceable.position
        if approxEq(position.x, position2.x) and approxEq(position.y, position2.y) and approxEq(position.z, position2.z) then
            return f
        end
    end
    return nil
end

function InGameMenuUpgradableFactories:getFactoryByPosition(position)
    for _,f in ipairs(self.factories) do
        local position2 = f.productionPointObject.owningPlaceable.position
        if approxEq(position.x, position2.x) and approxEq(position.y, position2.y) and approxEq(position.z, position2.z) then
            return f
        end
    end
    return nil
end

-- function InGameMenuUpgradableFactories:getNumberOfSections()
--     return 1
-- end

-- function InGameMenuUpgradableFactories:getNumberOfItemsInSection(list, section)
--     return #self.factories
-- end

-- function InGameMenuUpgradableFactories:getTitleForSectionHeader(list, section)
--     return "owned productions"
-- end

-- function InGameMenuUpgradableFactories:populateCellForItemInSection(list, section, index, cell)
--     local f = self.factories[index]
--     cell:getAttribute("factory"):setText(f.productionPointObject.owningPlaceable:getName())
--     cell:getAttribute("level"):setText(f.level)
--     cell:getAttribute("value"):setText(g_i18n:formatMoney(f.basePrice * f.level))
--     cell:getAttribute("cost"):setText(g_i18n:formatMoney(self:adjUpgradePrice2lvl(f.basePrice, f.level)))
-- end

function InGameMenuUpgradableFactories:onListSelectionChanged(list, section, index)
    self.selectedFactory = self:getFactoryByPosition(list.selectedProductionPoint.owningPlaceable.position)
end

function InGameMenuUpgradableFactories:upgrade()
    if g_currentMission.missionInfo.money >= self.selectedFactory.basePrice then
        local upgradePrice = self:adjUpgradePrice2lvl(self.selectedFactory.basePrice, self.selectedFactory.level)
        local text = string.format(
            "Upgrade %s to level %d for %s?",
            self.selectedFactory.productionPointObject.owningPlaceable:getName(),
            self.selectedFactory.level+1,
            g_i18n:formatMoney(upgradePrice)
        )
        g_gui:showYesNoDialog(
            {
                text = text,
                title = "Upgrade Factory",
                callback = self.onUpgradeConfirm,
                target = self
            }
        )
    end
end

function InGameMenuUpgradableFactories:onUpgradeConfirm(confirm)
    if confirm then
        local upgradePrice = self:adjUpgradePrice2lvl(self.selectedFactory.basePrice, self.selectedFactory.level)
        g_currentMission:addMoney(-upgradePrice, 1, MoneyType.SHOP_PROPERTY_BUY, true, true)
        self.selectedFactory.level = self.selectedFactory.level + 1
        self:overwriteFactoryName(self.selectedFactory)
        self:updatePCMFactoriesRates()
        -- print_r(g_currentMission.inGameMenu.pageProduction.storageList, 0)
    end
end

function InGameMenuUpgradableFactories:adjUpgradePrice2lvl(price, lvl)
    -- Upgrade price increase by 7.5% each level
    return math.floor(price * (1 + (0.075 * lvl)))
end

function InGameMenuUpgradableFactories:adjCapa2lvl(capacity, lvl)
    -- Strorage capacity increase by 2.5 times the base capacity each level
    return math.floor(capacity + capacity * 2.5 * (lvl - 1))
end

function InGameMenuUpgradableFactories:adjCycl2lvl(cycle, lvl)
    -- Production speed gets multiplied by the level and 5% faster each time
    return math.floor(cycle * lvl * (1 + (0.05 * (lvl - 1))))
end

function InGameMenuUpgradableFactories:adjCost2lvl(cost, lvl)
    -- Running cost gets multiplied by the level but is slightly cheaper each time by 5%
    return math.floor(cost + cost * 0.95 * (lvl - 1))
end

function InGameMenuUpgradableFactories:adjSellPrice2lvl(price, lvl)
    -- Sell price is 75% of facotry's value (base is 50%)
    return math.floor(price * lvl * 0.75)
end

function InGameMenuUpgradableFactories:updatePCMFactoriesRates()
    for _,f in ipairs(self.factories) do
        local ppo = f.productionPointObject
        for i,prods in ipairs(ppo.productions) do
            local fprods = f.productions[i]
            
            if not fprods or prods.id ~= fprods.id then
                for j,n in ipairs(f.productions) do
                    if n.id == prods.id then
                        fprods = f.productions[j]
                    end
                end

                if not fprods or prods.id ~= fprods.id then
                    printf("Error while updating %s factory [%s|%s|%s]", prods.id, type(fprods), prods.id, prods.id)
                    break
                end
            end

            prods.cyclesPerMonth = self:adjCycl2lvl(fprods.cyclesPerMonth, f.level)
            prods.cyclesPerHour = prods.cyclesPerMonth / 24
            prods.cyclesPerMinute = prods.cyclesPerHour / 60

            prods.costsPerActiveMonth = self:adjCost2lvl(fprods.costsPerActiveMonth, f.level)
            prods.costsPerActiveHour = prods.costsPerActiveMonth / 24
            prods.costsPerActiveMinute = prods.costsPerActiveHour / 60
        end

        local pcmc = ppo.storage.capacities
        for fillType,capacity in pairs(ppo.storage.capacities) do
            pcmc[fillType] = self:adjCapa2lvl(capacity, f.level)
        end

        ppo.owningPlaceable.getSellPrice = Utils.overwrittenFunction(
            ppo.owningPlaceable.getSellPrice,
            function ()
                return self:adjSellPrice2lvl(f.basePrice, f.level)
            end
        )
    end
end

function InGameMenuUpgradableFactories:saveToXML(xmlFile)
    self:lookForPCMFactories()
    
    local key = ""
    for i,f in ipairs(self.factories) do
        if f.productionPointObject and f.productionPointObject.isOwned then
            key = string.format("upgradableFactories.factory(%d)", i)
            xmlFile:setInt(key .. "#id", f.productionPointObject.id)
            xmlFile:setString(key .. "#name", string.gsub(f.productionPointObject.owningPlaceable:getName(), "lvl.%d+", ""))
            xmlFile:setInt(key .. "#level", f.level)
            xmlFile:setInt(key .. "#basePrice", f.basePrice)

            local key2 = key..".position"
            xmlFile:setFloat(key2 .. "#x", f.productionPointObject.owningPlaceable.position.x)
            xmlFile:setFloat(key2 .. "#y", f.productionPointObject.owningPlaceable.position.y)
            xmlFile:setFloat(key2 .. "#z", f.productionPointObject.owningPlaceable.position.z)
            
            local j = 0
            key2 = ""
            for _,p in ipairs(f.productions) do
                key2 = key .. string.format(".productions.production(%d)", j)
                xmlFile:setString(key2 .. "#id", p.id)
                xmlFile:setInt(key2 .. "#cyclesPerMonth", p.cyclesPerMonth)
                xmlFile:setInt(key2 .. "#costsPerActiveMonth", p.costsPerActiveMonth)
                j = j + 1
            end

            local fls = f.productionPointObject.storage.fillLevels
            j = 0
            key2 = ""
            for k,v in pairs(f.baseCapacities) do
                key2 = key .. string.format(".capacities.baseCapacity(%d)", j)
                xmlFile:setInt(key2 .. "#fillType", k)
                xmlFile:setInt(key2 .. "#capacity", v)
                xmlFile:setInt(key2 .. "#fillLevel", fls[k])
                j = j + 1
            end
        else
            f = nil
        end
    end
end

function InGameMenuUpgradableFactories:loadFromXML()
    if not UpgradableFactories.xmlFilename then
        return
    end

    local xmlFile = loadXMLFile("UpgradableFactoriesXML", UpgradableFactories.xmlFilename)

    local counter = 1
    while true do
        local key = string.format("upgradableFactories.factory(%d)", counter)
        local id = getXMLInt(xmlFile, key .. "#id")
        
        if not id then
            break
        end

        local level = getXMLInt(xmlFile, key .. "#level")
        local basePrice = getXMLInt(xmlFile, key .. "#basePrice")
        local position = {
            x = getXMLFloat(xmlFile, key .. ".position#x"),
            y = getXMLFloat(xmlFile, key .. ".position#y"),
            z = getXMLFloat(xmlFile, key .. ".position#z")
        }
        local productions = {}
        local baseCapacities = {}
        local fillLevels = {}

        local counter2 = 0
        while true do
            local key2 = key .. string.format(".productions.production(%d)", counter2)
            
            local pid = getXMLString(xmlFile, key2 .. "#id")
            local cypm = getXMLInt(xmlFile, key2 .. "#cyclesPerMonth")
            local copm = getXMLInt(xmlFile, key2 .. "#costsPerActiveMonth")
            if not (pid and cypm and copm) then
                break
            end

            table.insert(
                productions,
                {
                    id = pid,
                    cyclesPerMonth = cypm,
                    costsPerActiveMonth = copm
                }
            )

            counter2 = counter2 +1
        end
        
        counter2 = 0
        while true do
            local key2 = key .. string.format(".capacities.baseCapacity(%d)", counter2)
            
            local fillType = getXMLInt(xmlFile, key2 .. "#fillType")
            local capacity = getXMLInt(xmlFile, key2 .. "#capacity")
            local fillLevel = getXMLInt(xmlFile, key2 .. "#fillLevel")
            if not (fillType and capacity) then
                break
            end

            table.insert(baseCapacities, fillType, capacity)
            table.insert(fillLevels, fillType, fillLevel)

            counter2 = counter2 +1
        end

        if level and basePrice then
            table.insert(
                self.factories,
                {
                    id = id,
                    level = level,
                    basePrice = basePrice,
                    productions = productions,
                    baseCapacities = baseCapacities,
                    fillLevels = fillLevels,
                    position = position
                }
            )
        end
        
        counter = counter +1
    end

    delete(xmlFile)
end

-- TODO
-- add default values to xml loading to avoid bugs due to missing values (-> XMLUtil)
-- create mod/menu icon
-- remove the sections of the gui production table. the table is divided into a single section (titled "owned production") => useless usage of sections
-- Translation

-- BUG
-- first factory in the xml file is empty : <factory/>

-- FEATURE
-- add a "sell factory" button
-- add a "rename factory" button
-- add a "downgrade factory" button