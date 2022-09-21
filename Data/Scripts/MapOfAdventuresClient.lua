
local TRIGGER = script:GetCustomProperty("Trigger"):WaitForObject()
local OVERRIDE_CAMERA = script:GetCustomProperty("OverrideCamera"):WaitForObject()
local PLAY_SFX = script:GetCustomProperty("PlaySFX"):WaitForObject()
local CALLOUT_SPARKLE = script:GetCustomProperty("CalloutSparkle"):WaitForObject()
local CONTENT_PANEL = script:GetCustomProperty("ContentPanel"):WaitForObject()
local LEFT_ARROW = script:GetCustomProperty("LeftArrow"):WaitForObject()
local RIGHT_ARROW = script:GetCustomProperty("RightArrow"):WaitForObject()

local CAM_APPROACH_DISTANCE = 20
local CAM_APPROACH_SPEED = 1.8

local PLAYER = Game.GetLocalPlayer()

local maps = {}
local selectedIndex = 1

local isFocused = false
local isAwaitingTransfer = false

Task.Wait()


function Play()
	if isAwaitingTransfer then return end
	isAwaitingTransfer = true
	
	PLAY_SFX:Play()
	Events.BroadcastToServer("Map.Play", selectedIndex)
	Events.Broadcast("FadeOut", 5)
	
	Task.Wait(1.25)
	
	isAwaitingTransfer = false
	ExitFocus()
	Events.Broadcast("FadeIn", 5)
end


function Tick(deltaTime)
	local t = deltaTime * CAM_APPROACH_SPEED
	OVERRIDE_CAMERA.currentDistance = CoreMath.Lerp(OVERRIDE_CAMERA.currentDistance, 0, t)
end


function EnterFocus()
	isFocused = true
	
	_G.CursorStack.Enable()

	PLAYER:SetOverrideCamera(OVERRIDE_CAMERA)
	OVERRIDE_CAMERA.currentDistance = CAM_APPROACH_DISTANCE
	
	CALLOUT_SPARKLE.visibility = Visibility.FORCE_OFF
	CALLOUT_SPARKLE:SetSmartProperty("Density", 0)
	
	TRIGGER.isEnabled = false
	
	Events.BroadcastToServer("Map.Focus", true)
end

function ExitFocus()
	if isAwaitingTransfer then return end
	
	isFocused = false
	
	_G.CursorStack.Disable()

	PLAYER:ClearOverrideCamera(0)
	
	CALLOUT_SPARKLE.visibility = Visibility.INHERIT
	CALLOUT_SPARKLE:SetSmartProperty("Density", 1)
	
	Task.Wait(1)
	TRIGGER.isEnabled = true
	
	Events.BroadcastToServer("Map.Focus", false)
end


function UpdateContents()
	local quests = _G.QuestController.GetUnlockedQuests(PLAYER)
	--print("MapOfAdventurersClient::UpdateContents() quests: ".. #quests)
	
	-- Check if it's still the same as before
	if #quests == #maps then
		for i,quest in ipairs(quests) do
			if quest.id ~= maps[i].clientUserData.quest.id then
				goto contentHasChanged
			end
		end
		return --Exit early, no changes
	end
	:: contentHasChanged ::

	-- Clear existing content
	for _,child in ipairs(CONTENT_PANEL:GetChildren()) do
		child:Destroy()
	end
	maps = {}

	-- Add map pages
	for _,questData in ipairs(quests) do
		if questData.mapContent then
			local map = World.SpawnAsset(questData.mapContent, {parent = CONTENT_PANEL})
			table.insert(maps, map)

			map.clientUserData.quest = questData
		end
	end
	if selectedIndex > #maps then
		selectedIndex = #maps
	end
	UpdateMapVisibility()
end


function UpdateMapVisibility()
	for i, map in ipairs(maps) do
		if i == selectedIndex then
			map.visibility = Visibility.INHERIT
		else
			map.visibility = Visibility.FORCE_OFF
		end
	end
	if #maps > 1 then
		LEFT_ARROW.visibility = Visibility.INHERIT
		RIGHT_ARROW.visibility = Visibility.INHERIT
	else
		LEFT_ARROW.visibility = Visibility.FORCE_OFF
		RIGHT_ARROW.visibility = Visibility.FORCE_OFF
	end
end


function Next()
	if isAwaitingTransfer then return end
	
	selectedIndex = selectedIndex + 1
	if selectedIndex > #maps then
		selectedIndex = 1
	end
	UpdateMapVisibility()
end

function Previous()
	if isAwaitingTransfer then return end
	
	selectedIndex = selectedIndex - 1
	if selectedIndex <= 0 then
		selectedIndex = #maps
	end
	UpdateMapVisibility()
end


Next()


-- Events fired from quest system
Events.Connect("Quest_Changed", UpdateContents)
UpdateContents()

-- Events fired from MapButtons script
Events.Connect("NextMap", Next)
Events.Connect("PreviousMap", Previous)
Events.Connect("PlayMap", Play)
Events.Connect("ExitMap", ExitFocus)

TRIGGER.interactedEvent:Connect(EnterFocus)
