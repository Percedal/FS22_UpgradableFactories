UpgradableFactories = {}
UpgradableFactories.dir = g_currentModDirectory
UpgradableFactories.modName = g_currentModName

source(UpgradableFactories.dir .. "gui/InGameMenuUpgradableFactories.lua")

local upgradableFactories = nil

function UpgradableFactories:loadMap()
	if g_currentMission.missionInfo.savegameDirectory then
		UpgradableFactories.xmlFilename = g_currentMission.missionInfo.savegameDirectory .. "/upgradableFactories.xml"
	end

	upgradableFactories = InGameMenuUpgradableFactories.new()
    
	-- g_gui:loadProfiles(UpgradableFactories.dir .. "gui/guiProfiles.xml")
	-- g_gui:loadGui(UpgradableFactories.dir .. "gui/InGameMenuUpgradableFactories.xml", "InGameMenuUpgradableFactories", upgradableFactories, true)
		
	-- UpgradableFactories.fixInGameMenu(upgradableFactories,"InGameMenuUpgradableFactories", {0,0,1024,1024}, 11, UpgradableFactories:makeIsUpgradableFactoriesEnabledPredicate())

	upgradableFactories:initialize()
	
	g_messageCenter:subscribe(MessageType.SAVEGAME_LOADED, self.onSavegameLoaded, self)
end

-- function UpgradableFactories:makeIsUpgradableFactoriesEnabledPredicate()
-- 	return function ()
-- 		return true
-- 	end
-- end

function UpgradableFactories:delete()
	g_messageCenter:unsubscribeAll(self)
end

function UpgradableFactories:onSavegameLoaded()
	upgradableFactories:onSavegameLoaded()
end

-- function UpgradableFactories.fixInGameMenu(frame,pageName,uvs,position,predicateFunc)
-- 	local inGameMenu = g_gui.screenControllers[InGameMenu]

-- 	-- remove all to avoid warnings
-- 	for k, v in pairs({pageName}) do
-- 		inGameMenu.controlIDs[v] = nil
-- 	end

-- 	inGameMenu:registerControls({pageName})

	
-- 	inGameMenu[pageName] = frame
-- 	inGameMenu.pagingElement:addElement(inGameMenu[pageName])

-- 	inGameMenu:exposeControlsAsFields(pageName)

-- 	for i = 1, #inGameMenu.pagingElement.elements do
-- 		local child = inGameMenu.pagingElement.elements[i]
-- 		if child == inGameMenu[pageName] then
-- 			table.remove(inGameMenu.pagingElement.elements, i)
-- 			table.insert(inGameMenu.pagingElement.elements, position, child)
-- 			break
-- 		end
-- 	end

-- 	for i = 1, #inGameMenu.pagingElement.pages do
-- 		local child = inGameMenu.pagingElement.pages[i]
-- 		if child.element == inGameMenu[pageName] then
-- 			table.remove(inGameMenu.pagingElement.pages, i)
-- 			table.insert(inGameMenu.pagingElement.pages, position, child)
-- 			break
-- 		end
-- 	end

-- 	inGameMenu.pagingElement:updateAbsolutePosition()
-- 	inGameMenu.pagingElement:updatePageMapping()
	
-- 	inGameMenu:registerPage(inGameMenu[pageName], position, predicateFunc)
-- 	local iconFileName = Utils.getFilename('images/menuIcon.dds', UpgradableFactories.dir)
-- 	inGameMenu:addPageTab(inGameMenu[pageName],iconFileName, GuiUtils.getUVs(uvs))
-- 	inGameMenu[pageName]:applyScreenAlignment()
-- 	inGameMenu[pageName]:updateAbsolutePosition()

-- 	for i = 1, #inGameMenu.pageFrames do
-- 		local child = inGameMenu.pageFrames[i]
-- 		if child == inGameMenu[pageName] then
-- 			table.remove(inGameMenu.pageFrames, i)
-- 			table.insert(inGameMenu.pageFrames, position, child)
-- 			break
-- 		end
-- 	end

-- 	inGameMenu:rebuildTabList()
-- end

function UpgradableFactories:saveToXML(xmlFilename)
	if not UpgradableFactories.xmlFilename then
		UpgradableFactories.xmlFilename = g_currentMission.missionInfo.savegameDirectory .. "/upgradableFactories.xml"
	end
	local xmlFile = XMLFile.create("UpgradableFactoriesXML", UpgradableFactories.xmlFilename, "upgradableFactories")

    upgradableFactories:saveToXML(xmlFile)

    xmlFile:save()
    xmlFile:delete()
end

FSCareerMissionInfo.saveToXMLFile = Utils.appendedFunction(FSCareerMissionInfo.saveToXMLFile, UpgradableFactories.saveToXML)
InGameMenuProductionFrame.onListSelectionChanged = Utils.appendedFunction(
    InGameMenuProductionFrame.onListSelectionChanged, 
    function (list, section, index)
        upgradableFactories:onListSelectionChanged(list, section, index)
    end
)

addModEventListener(UpgradableFactories)