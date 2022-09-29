
local ENTER_TRIGGER = script:GetCustomProperty("EnterTrigger"):WaitForObject()
local EXIT_TRIGGER = script:GetCustomProperty("ExitTrigger"):WaitForObject()

local MODAL = script:GetCustomProperty("ModalPopup"):WaitForObject()
MODAL = MODAL.context

local MAIN_PANEL = script:GetCustomProperty("MainPanel"):WaitForObject()
local CLOSE_BUTTON = script:GetCustomProperty("CloseButton"):WaitForObject()


local STATE_DISABLED = 1
local STATE_ENTERING = 2
local STATE_IDLE = 3
local currentState = STATE_DISABLED
local stateElapsedTime = 0


function SetState(newState)
	if newState == STATE_DISABLED then
		ENTER_TRIGGER.isInteractable = true
		
	elseif newState == STATE_ENTERING then
		ENTER_TRIGGER.isInteractable = false
		
	elseif newState == STATE_IDLE then
		--
	end
	
	currentState = newState
	stateElapsedTime = 0
end


SetState(STATE_DISABLED)



function OnInteracted(trigger, player)
	MODAL.Show()
	SetState(STATE_ENTERING)
	
	Events.BroadcastToServer("CraftEquipmentOpened", player)
end

ENTER_TRIGGER.interactedEvent:Connect(OnInteracted)


function OnLeaveArea(trigger, player)
	if player == Game.GetLocalPlayer() then
		MODAL.Hide()
	end
end

EXIT_TRIGGER.endOverlapEvent:Connect(OnLeaveArea)


function OnModalHidden(modal)
	if modal == MODAL then
		local player = Game.GetLocalPlayer()
		Events.BroadcastToServer("CraftEquipmentClosed", player)
		
		Task.Wait(0.5)
		
		SetState(STATE_DISABLED)
	end
end

Events.Connect("ModalHidden", OnModalHidden)

