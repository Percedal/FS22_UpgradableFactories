InGameMenuUpgradableFactories = {}

InGameMenuProductionFrame.UPDATE_INTERVAL = 1000

function InGameMenuUpgradableFactories:initialize()
    self.inGameMenu = g_currentMission.inGameMenu
    self.pageProduction = g_currentMission.inGameMenu.pageProduction
    self.pageProduction.upgradeButtonInfo = {
        profile = "buttonOK",
        inputAction = InputAction.MENU_EXTRA_1,
        text = g_i18n:getText("uf_upgrade"),
        callback = InGameMenuUpgradableFactories.onButtonUpgrade
    }

    InGameMenuProductionFrame.updateMenuButtons = Utils.appendedFunction(InGameMenuProductionFrame.updateMenuButtons, InGameMenuUpgradableFactories.updateMenuButtons)
    InGameMenuProductionFrame.onListSelectionChanged = Utils.appendedFunction(InGameMenuProductionFrame.onListSelectionChanged, InGameMenuUpgradableFactories.onListSelectionChanged)
end

-- function InGameMenuUpgradableFactories:getProductionPoints()
--     return g_currentMission.inGameMenu.pageProduction:getProductionPoints()
-- end

function InGameMenuUpgradableFactories:onButtonUpgrade()
    -- local pageProduction = g_currentMission.inGameMenu.pageProduction
    local _, prodpoint = self.pageProduction:getSelectedProduction()

    local money = g_farmManager:getFarmById(g_currentMission:getFarmId()):getBalance()
    UFInfo(
        "Request upgrade %s to level %d/%d (%s / %s)",
        prodpoint.owningPlaceable:getName(),
        prodpoint.productionLevel,
        UpgradableFactories.MAX_LEVEL,
        g_i18n:formatMoney(prodpoint.owningPlaceable.upgradePrice),
        g_i18n:formatMoney(money)
    )

    if prodpoint.productionLevel >= UpgradableFactories.MAX_LEVEL then
        g_gui:showInfoDialog({text = g_i18n:getText("uf_max_level")})
        UFInfo("Production already at max level")
    elseif money >= prodpoint.owningPlaceable.upgradePrice then
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
    else
        g_gui:showInfoDialog({text = self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.NOT_ENOUGH_MONEY_BUY)})
        UFInfo("Not enough money")
    end
end

function InGameMenuUpgradableFactories.onListSelectionChanged(pageProduction, list, section, index)
    local prodpoints = pageProduction:getProductionPoints()
    if #prodpoints > 0 then
        local prodpoint = prodpoints[section]
        pageProduction.upgradeButtonInfo.disabled = not prodpoint.isUpgradable
        pageProduction:setMenuButtonInfoDirty()
    end
end

function InGameMenuUpgradableFactories:onUpgradeConfirm(confirm, prodpoint)
    if confirm then
        g_currentMission:addMoney(-prodpoint.owningPlaceable.upgradePrice, 1, MoneyType.SHOP_PROPERTY_BUY, true, true)
        
        prodpoint.productionLevel = prodpoint.productionLevel + 1
        UpgradableFactories:adjProdPoint2lvl(prodpoint, prodpoint.productionLevel)
     
        self.pageProduction.productionList:reloadData()
        
        UFInfo("Upgrade confirmed")
    else
        UFInfo("Upgrade canceled")
    end
end

function InGameMenuUpgradableFactories.updateMenuButtons(pageProduction)
    if #pageProduction:getProductionPoints() > 0 then
        table.insert(pageProduction.menuButtonInfo, pageProduction.upgradeButtonInfo)
    end
end