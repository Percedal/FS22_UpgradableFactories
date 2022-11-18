InGameMenuUpgradableFactories = {}
local inGameMenuUpgradableFactories_mt = Class(InGameMenuUpgradableFactories)

InGameMenuProductionFrame.UPDATE_INTERVAL = 1000

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

    for _,prod in ipairs(self:getProductionPoints()) do
        prod.owningPlaceable.getName = function (_self) return _self.baseName end
    end
end

function InGameMenuUpgradableFactories:onButtonUpgrade()
    local pageProduction = g_currentMission.inGameMenu.pageProduction
    _, prodpoint = pageProduction:getSelectedProduction()

    if g_currentMission.missionInfo.money >= prodpoint.owningPlaceable.upgradePrice then
        local text = string.format(
            g_i18n:getText("uf_upgrade_dialog"),
            prodpoint.owningPlaceable.baseName,
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

local function prodPointUFName(basename, level)
    return tostring(level) .. " - " .. basename
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

            for _,prod in ipairs(self:getProductionPoints()) do
                prod.owningPlaceable.ufname = prodPointUFName(prod.owningPlaceable.baseName, prod.productionLevel)
                prod.owningPlaceable.getName = function (_self) return _self.ufname end
            end
            
            g_currentMission.inGameMenu.pageProduction.productionList:reloadData()
        end

    if g_currentMission.paused and inGameMenu.upgradeFactoryButton ~= nil then
        inGameMenu.upgradeFactoryButton:setDisabled(true)
        inGameMenu:setMenuButtonInfoDirty()
    end
end

function InGameMenuUpgradableFactories:onUpgradeConfirm(confirm, prodpoint)
    if confirm then
        g_currentMission:addMoney(-prodpoint.owningPlaceable.upgradePrice, 1, MoneyType.SHOP_PROPERTY_BUY, true, true)
        
        prodpoint.productionLevel = prodpoint.productionLevel + 1
        UpgradableFactories:adjProdPoint2lvl(prodpoint, prodpoint.productionLevel)
        
        prodpoint.owningPlaceable.ufname = prodPointUFName(prodpoint.owningPlaceable.baseName, prodpoint.productionLevel)        
        g_currentMission.inGameMenu.pageProduction.productionList:reloadData()
    end
end