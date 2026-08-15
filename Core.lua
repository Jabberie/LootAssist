local ADDON_NAME = ...

-- ============================================================
-- LootAssist
-- Lightweight automatic looting without external libraries.
-- ============================================================

local LootAssist = {}
local eventFrame = CreateFrame("Frame")

local lootTable = {}
local retryPending = false
local enabled = false

local BUSY_ERROR_ID = 415 -- ERR_OBJECT_IS_BUSY


-- ============================================================
-- Utility
-- ============================================================

local function Print(message)
    print("|cff00ff98LootAssist:|r " .. tostring(message))
end

local function IsMasterLoot()
    -- Legacy API remains available across supported clients and
    -- gives us a consistent string result.
    if type(GetLootMethod) == "function" then
        local method = GetLootMethod()
        return method == "master"
    end

    -- Defensive fallback for newer clients.
    if C_PartyInfo and C_PartyInfo.GetLootMethod then
        local method = C_PartyInfo.GetLootMethod()

        if Enum
            and Enum.LootMethod
            and Enum.LootMethod.Masterlooter
        then
            return method == Enum.LootMethod.Masterlooter
        end
    end

    return false
end


local blizzardLootFrameEvents = nil

local function CaptureBlizzardLootFrameEvents()
    if blizzardLootFrameEvents or not LootFrame then
        return
    end

    blizzardLootFrameEvents = {
        LOOT_OPENED = LootFrame:IsEventRegistered("LOOT_OPENED"),
        LOOT_READY = LootFrame:IsEventRegistered("LOOT_READY"),
        LOOT_SLOT_CLEARED = LootFrame:IsEventRegistered("LOOT_SLOT_CLEARED"),
    }
end


local function SetBlizzardLootFrameEnabled(state)
    if not LootFrame then
        return
    end

    CaptureBlizzardLootFrameEvents()

    if state then
        -- Restore only the events Blizzard originally owned.
        for event, wasRegistered in pairs(blizzardLootFrameEvents) do
            if wasRegistered then
                LootFrame:RegisterEvent(event)
            else
                LootFrame:UnregisterEvent(event)
            end
        end
    else
        -- Retail can drive the loot frame from LOOT_READY as well as
        -- LOOT_OPENED. Suppress both so Blizzard never opens its frame
        -- while LootAssist is handling the loot interaction.
        LootFrame:UnregisterEvent("LOOT_OPENED")
        LootFrame:UnregisterEvent("LOOT_READY")
        LootFrame:UnregisterEvent("LOOT_SLOT_CLEARED")

        if LootFrame:IsShown() then
            HideUIPanel(LootFrame)
        end
    end
end


local function ClearLootTracking()
    wipe(lootTable)
end


-- ============================================================
-- Looting
-- ============================================================

local function LootAllSlots()
    if not enabled then
        return
    end

    local numItems = GetNumLootItems()

    for slot = 1, numItems do
        local link = GetLootSlotLink(slot)

        if link then
            local _, name, _, _, locked = GetLootSlotInfo(slot)

            if name and not locked then
                lootTable[slot] = name
            end
        end

        LootSlot(slot)
    end
end


local function RetryLoot()
    if retryPending or not enabled then
        return
    end

    retryPending = true

    C_Timer.After(0.15, function()
        retryPending = false

        if not enabled then
            return
        end

        if GetNumLootItems() > 0 then
            LootAllSlots()
        end
    end)
end


local function HandleLootReady()
    ClearLootTracking()

    -- Master loot requires Blizzard's normal interface.
    if IsMasterLoot() then
        SetBlizzardLootFrameEnabled(true)
        return
    end

    SetBlizzardLootFrameEnabled(false)
    LootAllSlots()
end


local function HandleLootSlotCleared(slot)
    lootTable[slot] = nil
end


local function HandleLootClosed()
    retryPending = false

    if not enabled then
        ClearLootTracking()
        return
    end

    -- Restore our normal hidden-loot-frame state after any
    -- temporary master-loot fallback.
    SetBlizzardLootFrameEnabled(false)

    C_Timer.After(0.25, function()
        for _, name in pairs(lootTable) do
            Print("Can't loot: " .. name)
        end

        ClearLootTracking()
    end)
end


local function HandleUIError(errorID, message)
    if not enabled then
        return
    end

    if errorID == BUSY_ERROR_ID then
        RetryLoot()
    end
end


-- ============================================================
-- Enable / Disable
-- ============================================================

function LootAssist.Enable(saveChoice)
    enabled = true

    SetBlizzardLootFrameEnabled(false)

    eventFrame:RegisterEvent("LOOT_READY")
    eventFrame:RegisterEvent("LOOT_CLOSED")
    eventFrame:RegisterEvent("LOOT_SLOT_CLEARED")
    eventFrame:RegisterEvent("UI_ERROR_MESSAGE")

    if saveChoice then
        LootAssistChoice = 1
    end
end


function LootAssist.Disable(saveChoice)
    enabled = false
    retryPending = false

    SetBlizzardLootFrameEnabled(true)

    eventFrame:UnregisterEvent("LOOT_READY")
    eventFrame:UnregisterEvent("LOOT_CLOSED")
    eventFrame:UnregisterEvent("LOOT_SLOT_CLEARED")
    eventFrame:UnregisterEvent("UI_ERROR_MESSAGE")

    ClearLootTracking()

    if saveChoice then
        LootAssistChoice = 0
    end
end


-- ============================================================
-- Settings
--
-- LootAssistDefault
--     0 = account default disabled
--     1 = account default enabled
--
-- LootAssistChoice
--     nil = follow account default
--     0   = explicitly disabled on this character
--     1   = explicitly enabled on this character
-- ============================================================

function LootAssist.DefaultOn()
    LootAssistDefault = 1
    Print("Account default enabled.")
end


function LootAssist.DefaultOff()
    LootAssistDefault = 0
    Print("Account default disabled.")
end


function LootAssist.CharacterOn()
    LootAssist.Enable(true)
    Print("Enabled on this character.")
end


function LootAssist.CharacterOff()
    LootAssist.Disable(true)
    Print("Disabled on this character.")
end


function LootAssist.CharacterDefault()
    LootAssistChoice = nil

    if LootAssistDefault == 1 then
        LootAssist.Enable(false)
    else
        LootAssist.Disable(false)
    end

    Print("This character now follows the account default.")
end


function LootAssist.Check()
    local accountState =
        LootAssistDefault == 1 and "enabled" or "disabled"

    local characterState

    if LootAssistChoice == 1 then
        characterState = "enabled override"
    elseif LootAssistChoice == 0 then
        characterState = "disabled override"
    else
        characterState = "following account default"
    end

    local activeState =
        enabled and "enabled" or "disabled"

    Print(
        "Currently "
        .. activeState
        .. ". Account default: "
        .. accountState
        .. ". Character: "
        .. characterState
        .. "."
    )
end


-- ============================================================
-- Slash Commands
-- ============================================================

local function ShowHelp()
    Print("Commands:")
    Print("/lootassist on - Enable on this character")
    Print("/lootassist off - Disable on this character")
    Print("/lootassist default - Follow the account default")
    Print("/lootassist defaulton - Enable account default")
    Print("/lootassist defaultoff - Disable account default")
    Print("/lootassist check - Show current settings")
end


local function HandleSlashCommand(input)
    local command = strtrim(string.lower(input or ""))

    if command == "on" then
        LootAssist.CharacterOn()

    elseif command == "off" then
        LootAssist.CharacterOff()

    elseif command == "default" then
        LootAssist.CharacterDefault()

    elseif command == "defaulton" then
        LootAssist.DefaultOn()

    elseif command == "defaultoff" then
        LootAssist.DefaultOff()

    elseif command == "check" then
        LootAssist.Check()

    elseif command == "help" or command == "" then
        ShowHelp()

    else
        Print("Unknown command: " .. command)
        ShowHelp()
    end
end


SLASH_LOOTASSIST1 = "/lootassist"
SLASH_LOOTASSIST2 = "/lass"
SlashCmdList.LOOTASSIST = HandleSlashCommand


-- Legacy shortcuts

SLASH_LOOTASSISTON1 = "/lasson"
SlashCmdList.LOOTASSISTON = function()
    LootAssist.CharacterOn()
end

SLASH_LOOTASSISTOFF1 = "/lassoff"
SlashCmdList.LOOTASSISTOFF = function()
    LootAssist.CharacterOff()
end

SLASH_LOOTASSISTDEFAULTON1 = "/lassdefaulton"
SlashCmdList.LOOTASSISTDEFAULTON = function()
    LootAssist.DefaultOn()
end

SLASH_LOOTASSISTDEFAULTOFF1 = "/lassdefaultoff"
SlashCmdList.LOOTASSISTDEFAULTOFF = function()
    LootAssist.DefaultOff()
end

SLASH_LOOTASSISTCHECK1 = "/lasscheck"
SlashCmdList.LOOTASSISTCHECK = function()
    LootAssist.Check()
end


-- ============================================================
-- Events
-- ============================================================

eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        if LootAssistDefault == nil then
            LootAssistDefault = 0
        end

        -- nil intentionally means "follow account default".
        if LootAssistChoice == 1 then
            LootAssist.Enable(false)

        elseif LootAssistChoice == 0 then
            LootAssist.Disable(false)

        elseif LootAssistDefault == 1 then
            LootAssist.Enable(false)

        else
            LootAssist.Disable(false)
        end

        LootAssist.Check()

    elseif event == "LOOT_READY" then
        HandleLootReady()

    elseif event == "LOOT_SLOT_CLEARED" then
        HandleLootSlotCleared(...)

    elseif event == "LOOT_CLOSED" then
        HandleLootClosed()

    elseif event == "UI_ERROR_MESSAGE" then
        HandleUIError(...)
    end
end)


eventFrame:RegisterEvent("PLAYER_LOGIN")
