local MasterLooter = nil
local lootTable = {};
local CurrencyLoot = {};

local dummyFrame=CreateFrame("FRAME");

------------------------------------------------------------------
-- /lassdefaultoff	Account Default off
-- /lassdefaulton	Account Default on
-- /lassoff			Character specific off
-- /lasson			Character specific on
-- /lasscheck		Check current settings
------------------------------------------------------------------

SLASH_LOOTASSISTOFF1 = '/lassoff';
function SlashCmdList.LOOTASSISTOFF()
    LootFrame:RegisterEvent("LOOT_OPENED");
    LootFrame:RegisterEvent("LOOT_SLOT_CLEARED");

    dummyFrame:UnregisterEvent("LOOT_READY");
    dummyFrame:UnregisterEvent("LOOT_CLOSED");
    dummyFrame:UnregisterEvent("CHAT_MSG_LOOT");
    dummyFrame:UnregisterEvent("UI_ERROR_MESSAGE");
    LootAssistChoice = 0;
    print("Loot Assist Deactivated");
end

SLASH_LOOTASSISTON1 = '/lasson';
function SlashCmdList.LOOTASSISTON()
    LootFrame:UnregisterEvent("LOOT_OPENED");
    LootFrame:UnregisterEvent("LOOT_SLOT_CLEARED");

    dummyFrame:RegisterEvent("LOOT_READY");
    dummyFrame:RegisterEvent("LOOT_CLOSED");
    dummyFrame:RegisterEvent("CHAT_MSG_LOOT");
    dummyFrame:RegisterEvent("UI_ERROR_MESSAGE");
    LootAssistChoice = 1;
    print("Loot Assist Activated");
end

SLASH_LOOTASSISTCHECK1 = '/lasscheck';
function SlashCmdList.LOOTASSISTCHECK()
    print("LootAssistDefault = " .. LootAssistDefault .. " -- LootAssistChoice = " .. LootAssistChoice);
end

SLASH_LOOTASSISTDEFON1 = '/lassdefaulton';
function SlashCmdList.LOOTASSISTDEFON()
    LootAssistDefault=1;
    print("LootAssistDefault=1;")
end

SLASH_LOOTASSISTDEFOFF1 = '/lassdefaultoff';
function SlashCmdList.LOOTASSISTDEFOFF()
    LootAssistDefault=0;
    print("LootAssistDefault=0;")
end

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
function frameEventHandle(self,event,arg1,arg2)
 -- Keep attempting to loot until no more error message   
    if event == "UI_ERROR_MESSAGE" and (arg2=="That object is busy.") then
        for i=1, GetNumLootItems() do
            LootSlot(i);
        end
    end
 -- created the total list of items
    if event == "LOOT_READY" then
        _,MasterLooter = GetLootMethod() 
        if MasterLooter == 0 then -- If master loot is active, binds the window back to normal
            LootFrame:RegisterEvent("LOOT_OPENED");
            LootFrame:RegisterEvent("LOOT_SLOT_CLEARED");
            return
        end
        for i=1, GetNumLootItems() do
            if GetLootSlotLink(i) then
                local _,lootName,lootQuantity,_,locked=GetLootSlotInfo(i);
                if locked then
                --    print(GetLootSlotLink(i))
                else
                    lootTable[i]=lootName;
                    if GetLootSlotType(i) == 3 then --non coin currency
                        local CurrencyID = GetLootSlotLink(i):match("currency:(%d+)")
                        local _,CurrLootAmount,_,_,_,CurrLootMax = GetCurrencyInfo(CurrencyID)
                        CurrencyLoot[i] = {}
                        CurrencyLoot[i][1] = CurrencyID
                        CurrencyLoot[i][2] = lootName
                        CurrencyLoot[i][3] = CurrLootAmount
                        CurrencyLoot[i][4] = lootQuantity
                        CurrencyLoot[i][5] = 0
                        CurrencyLoot[i][6] = CurrLootMax
                    end
                end
            end
            LootSlot(i);
        end
    end
 -- tracks the loot you receive to compare to the total list later
    if event == "CHAT_MSG_LOOT" and type(arg1)=="string" and string.find(arg1,"You receive") then
        for key,value in pairs(lootTable) do
            if string.find(arg1, value, nil, true) then
                lootTable[key]=nil
            end
        end
    end
  -- Clean up. Prints out any items that could not be looted. 
    if event == "LOOT_CLOSED" then
        LootFrame:UnregisterEvent("LOOT_OPENED");
        LootFrame:UnregisterEvent("LOOT_SLOT_CLEARED");
        C_Timer.After(1.5,function ()
            for key,value in pairs(CurrencyLoot) do
                _,CurrencyLoot[key][5] = GetCurrencyInfo(CurrencyLoot[key][1]) --get new amount
                if (CurrencyLoot[key][5] > CurrencyLoot[key][3]) then
                    lootTable[key]=nil
                end;
            end
            for key,value in pairs(lootTable) do 
            	print("Can't loot: "..value) 
            end 
            lootTable = {};
        end);
    end
end
dummyFrame:SetScript("OnEvent",frameEventHandle);
------------------------------------------------------------------------------------------------------------------------
-- local function initialiseAddon()
--     print("hello?")
--     StaticPopupDialogs["This_is_your_first_time_loading_LootAssist"] = {
--         text = L["This is your first time loading LootAssist.'nDo you want to turn it on:"],
-- 
--         button1 = "Account wide",
--         button2 = "Character Only",
-- 
--         OnAccept = function()
--             SlashCmdList.LOOTASSISTDEFON()
--             SlashCmdList.LOOTASSISTON()
--             ReloadUI()
--         end,
-- 
--         OnCancel = function()
--             SlashCmdList.LOOTASSISTDEFOFF()
--             SlashCmdList.LOOTASSISTON()
--         end,
-- 
--         showAlert = 1,
--         timeout = 0,
--         exclusive = 1,
--         hideOnEscape = 0,
--         whileDead = 1,  
--     }
-- end
------------------------------------------------------------------------------------------------------------------------

-- Load up the saved settings
local MagicFrame=CreateFrame("Frame")
MagicFrame:RegisterEvent("PLAYER_LOGIN")

MagicFrame:SetScript("OnEvent", function(...)
--    if not LootAssistDefault then
--        print("check1")
--        initialiseAddon()
--        LootAssistDefault = 0 -- just to give them a default setting on first log in
--    end
--    if not LootAssistChoice then
--        print("check2")
--        LootAssistChoice = 0 -- just to give them a default setting on first log in
--    end
--
--    if LootAssistDefault == 0 then              -- Default off 
--        if LootAssistChoice == 0 then           -- Per Char off
--            SlashCmdList.LOOTASSISTOFF();
--        else                                    -- Per Char on
--            SlashCmdList.LOOTASSISTON();        
--        end
--    else                                        -- Default on
--        SlashCmdList.LOOTASSISTON();
--    end
end)
------------------------------------------------------------------------------------------------------------------------