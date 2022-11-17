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
        textElement.text = tostring(prod.productionLevel) .. " - " .. prod.owningPlaceable:getName()
    end
end

function InGameMenuUpgradableFactories:getProductionPoints()
    return g_currentMission.inGameMenu.pageProduction:getProductionPoints()
end

function InGameMenuUpgradableFactories:onFrameClose()
    local inGameMenu = g_currentMission.inGameMenu
    if inGameMenu.upgradeFactoryButton ~= nil then
        inGameMenu.upgradeFactoryButton:unlinkElement()
        inGameMenu.upgradeFactoryButton:delete()
        inGameMenu.upgradeFactoryButton = nil
    end
end

function InGameMenuUpgradableFactories:onButtonUpgrade()
    local pageProduction = g_currentMission.inGameMenu.pageProduction
    production, prodpoint = pageProduction:getSelectedProduction()

    if g_currentMission.missionInfo.money >= prodpoint.owningPlaceable.upgradePrice then
        local text = string.format(
            g_i18n:getText("uf_upgrade_dialog"),
            prodpoint.owningPlaceable:getName(),
            prodpoint.productionLevel+1,
            g_i18n:formatMoney(prodpoint.owningPlaceable.upgradePrice)
        )
        g_gui:showYesNoDialog({
            text = text,
            title = "Upgrade Factory",
            callback = InGameMenuUpgradableFactories.onUpgradeConfirm,
            target=InGameMenuUpgradableFactories,
            args=prodpoint
        })
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

function InGameMenuUpgradableFactories:onUpgradeConfirm(confirm, prodpoint)
    if confirm then
        g_currentMission:addMoney(-prodpoint.owningPlaceable.upgradePrice, 1, MoneyType.SHOP_PROPERTY_BUY, true, true)
        prodpoint.productionLevel = prodpoint.productionLevel + 1
        UpgradableFactories:adjProdPoint2lvl(prodpoint, prodpoint.productionLevel)
        g_currentMission.inGameMenu.pageProduction.productionList:reloadData()
    end
end