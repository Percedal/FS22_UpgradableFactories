InGameMenuUpgradableFactories = {}
local inGameMenuUpgradableFactories_mt = Class(InGameMenuUpgradableFactories)

function InGameMenuUpgradableFactories.new(upgradableFactory)
    local self = setmetatable({}, inGameMenuUpgradableFactories_mt)
    
    self.name = "inGameMenuUpgradableFactories"
    self.upgradableFactories = upgradableFactory

    return self
end

function InGameMenuUpgradableFactories:initialize()
    InGameMenuProductionFrame.onFrameOpen = Utils.appendedFunction(InGameMenuProductionFrame.onFrameOpen, InGameMenuUpgradableFactories.onFrameOpen)
    InGameMenuProductionFrame.onFrameClose = Utils.appendedFunction(InGameMenuProductionFrame.onFrameClose, InGameMenuUpgradableFactories.onFrameClose)
end

function InGameMenuUpgradableFactories:delete()
    InGameMenuUpgradableFactories:superClass().delete(self)
end

function InGameMenuUpgradableFactories:editSectionHeader()
    for i,prod in ipairs(g_currentMission.productionChainManager.farmIds[1].productionPoints) do
        local textElement = g_currentMission.inGameMenu.pageProduction.productionListBox.elements[1].sections[i].cells[0].elements[1]
        -- print(prod.productionLevel, prod.owningPlaceable:getName(), textElement.text)
        textElement.text = tostring(prod.productionLevel) .. " - " .. prod.owningPlaceable:getName()
        -- print(textElement.text)
    end
end

function InGameMenuUpgradableFactories:getProductionPoints()
    return g_currentMission.inGameMenu.pageProduction:getProductionPoints()
end

function InGameMenuUpgradableFactories:onButtonUpgrade()
    local pageProduction = g_currentMission.inGameMenu.pageProduction
    production, prodpoint = pageProduction:getSelectedProduction()
    print("Upgrade request for " .. prodpoint.owningPlaceable:getName())
end

function InGameMenuUpgradableFactories:onFrameClose()
    local inGameMenu = g_currentMission.inGameMenu
    if inGameMenu.upgradeFactoryButton ~= nil then
        inGameMenu.upgradeFactoryButton:unlinkElement()
        inGameMenu.upgradeFactoryButton:delete()
        inGameMenu.upgradeFactoryButton = nil
    end
end

function InGameMenuUpgradableFactories:onFrameOpen()
    local inGameMenu = g_currentMission.inGameMenu
        if #self:getProductionPoints() > 0 and inGameMenu.upgradeFactoryButton == nil then
        local menuButton = inGameMenu.menuButton[1]
        local upgradeBtn = menuButton:clone(menuButton.parent)
        upgradeBtn:setText(g_i18n:getText("uf_upgrade"))
        upgradeBtn:setInputAction("MENU_EXTRA_1")
        upgradeBtn.onClickCallback = InGameMenuUpgradableFactories.onButtonUpgrade
        menuButton.parent.addElement(menuButton.parent, upgradeBtn)
        inGameMenu.upgradeFactoryButton = upgradeBtn
        InGameMenuUpgradableFactories:editSectionHeader()
        local pageProduction = g_currentMission.inGameMenu.pageProduction
        pageProduction.productionList.reloadData = Utils.appendedFunction(pageProduction.productionList.reloadData, InGameMenuUpgradableFactories.editSectionHeader)
    end

    if g_currentMission.paused and inGameMenu.upgradeFactoryButton ~= nil then
        inGameMenu.upgradeFactoryButton.disabled = true
    end
end

function InGameMenuUpgradableFactories:onUpgradeConfirm(confirm)
    if confirm then
        local upgradePrice = self:adjUpgradePrice2lvl(self.selectedFactory.basePrice, self.selectedFactory.level)
        g_currentMission:addMoney(-upgradePrice, 1, MoneyType.SHOP_PROPERTY_BUY, true, true)
        self.selectedFactory.level = self.selectedFactory.level + 1
    end
end







