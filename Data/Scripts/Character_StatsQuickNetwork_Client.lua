local Pkey = 'CStats'
local LOCAL_PLAYER = Game.GetLocalPlayer()

while not _G.CharacterEquipAPI do
    Task.Wait()
end

local EquipAPI = _G.CharacterEquipAPI

function UpdatedEvent(_, key)
    if key == Pkey then
        local character = EquipAPI.GetCurrentCharacter(LOCAL_PLAYER)
        if character then
            local Stats = character:GetComponent('Stats')
            Stats:SetTempStats(LOCAL_PLAYER:GetPrivateNetworkedData(Pkey))
        end
    end
end

LOCAL_PLAYER.privateNetworkedDataChangedEvent:Connect(UpdatedEvent)