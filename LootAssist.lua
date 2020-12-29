local MasterLooter = nil
local lootTable = {};
local CurrencyLoot = {};

LootAssist = LibStub("AceAddon-3.0"):NewAddon("LootAssist","AceConsole-3.0","AceEvent-3.0")

local version = "v4.0"
local LootAssist = LootAssist
-- local L = LibStub("AceLocale-3.0"):GetLocale("LootAssist",true)
local debug = false;
local superdebug = false;

local dummyFrame=CreateFrame("FRAME");

------------------------------------------------------------------
-- /lassdefaultoff	Account Default off
-- /lassdefaulton	Account Default on
-- /lassoff			Character specific off
-- /lasson			Character specific on
-- /lasscheck		Check current settings
-- /lootassist
------------------------------------------------------------------

function LootAssist:OnInitialize() -- Called when the addon is first loaded (but not yet enabled)
    self:RegisterChatCommand("lootassist"       ,"LootAssistDump");
    self:RegisterChatCommand("lassdefaultoff"   ,"LootAssistDefaultOff");
    self:RegisterChatCommand("lassdefaulton"    ,"LootAssistDefaultOn");
    self:RegisterChatCommand("lasson"           ,"LootAssistOn");
    self:RegisterChatCommand("lassoff"          ,"LootAssistOff");
    self:RegisterChatCommand("lasscheck"        ,"LootAssistCheck");
    self:RegisterChatCommand("reinstall"        ,"FirstRun");
end

function LootAssist:FirstRun()

    StaticPopupDialogs["First_time_running_character"] = {
        text = "Load by Default deactivated for your Account. What about this character?",
        button1 = OKAY,
        button2 = "Off",
        OnAccept = function()
            LootAssist:LootAssistDefaultOff()
            LootAssist:LootAssistOn()
        end,
        OnCancel = function ()   
            LootAssist:LootAssistDefaultOff()
            LootAssist:LootAssistOff()
        end,        
        showAlert = 1,
        timeout = 0,
        exclusive = 1,
        hideOnEscape = 0,
        whileDead = 1,  
    }    

    StaticPopupDialogs["First_time_running_account"] = {
        text = "This is the your first time running LootAssist. Would you like to activate it for your entire Account?",
        button1 = OKAY,
        button2 = "No",
        OnAccept = function()
            LootAssist:LootAssistDefaultOn()
            LootAssist:LootAssistOn()
        end,
        OnCancel = function ()
            StaticPopup_Show( "First_time_running_character" )
        end,        

        showAlert = 1,
        timeout = 0,
        exclusive = 1,
        hideOnEscape = 0,
        whileDead = 1,  
    }

    StaticPopup_Show( "First_time_running_account" )
end

function LootAssist:LootAssistDump(arg)
    arg = string.lower(arg)
    if arg=="debug" then
        if debug then
            self:Print("Debug Disabled");
            debug=false
            superdebug=false
        else
            self:Print("Debug Enabled");
            debug=true
            superdebug=false
        end
    elseif arg=="superdebug" then
        if superdebug then
            self:Print("Super Debug Disabled");
            debug=false
            superdebug=false
        else
            self:Print("Super Debug abled");
            debug=true
            superdebug=true
        end 
    elseif arg=="extrahelp" or arg=="help" then
        self:Print("Slash Command for /lootassist :");
        self:Print("defaultoff -- Account Wide Loading Off");
        self:Print("defaulton -- Account Wide Loading On");
        self:Print("off -- Character Loading Off");
        self:Print("on -- Character Loading On");
        self:Print("check -- shows current settings");
    elseif arg=="defaulton" then
        self:Print("Load as Default Activated");
        LootAssist:LootAssistDefaultOn()
    elseif arg=="defaultoff" then
        self:Print("Load as Default Deactivated");
        LootAssist:LootAssistDefaultOff()
    elseif arg=="on" then
        LootAssist:LootAssistOn()
        self:Print("Activated");
    elseif arg=="off" then
        LootAssist:LootAssistOff()
        self:Print("Deactivated");
    elseif arg=="check" then
        LootAssist:LootAssistCheck()
    else
        self:Print("L.usage");
        -- InterfaceOptionsFrame_OpenToCategory(LootAssist.panel);
    end
end

function LootAssist:LootAssistDefaultOn() LootAssistDefault=1; end

function LootAssist:LootAssistDefaultOff() LootAssistDefault=0; end

function LootAssist:LootAssistOn()
    LootFrame:UnregisterEvent("LOOT_OPENED");
    LootFrame:UnregisterEvent("LOOT_SLOT_CLEARED");

    dummyFrame:RegisterEvent("LOOT_READY");
    dummyFrame:RegisterEvent("LOOT_CLOSED");
    dummyFrame:RegisterEvent("CHAT_MSG_LOOT");
    dummyFrame:RegisterEvent("UI_ERROR_MESSAGE");
    LootAssistChoice = 1;   
end

function LootAssist:LootAssistOff()
    LootFrame:RegisterEvent("LOOT_OPENED");
    LootFrame:RegisterEvent("LOOT_SLOT_CLEARED");

    dummyFrame:UnregisterEvent("LOOT_READY");
    dummyFrame:UnregisterEvent("LOOT_CLOSED");
    dummyFrame:UnregisterEvent("CHAT_MSG_LOOT");
    dummyFrame:UnregisterEvent("UI_ERROR_MESSAGE");
    LootAssistChoice = 0;
end

function LootAssist:LootAssistCheck()
    if      LootAssistDefault == 1 and LootAssistChoice == 1 then 
        self:Print("is enabled on this character and on the account by default.");
    elseif  LootAssistDefault == 1 and LootAssistChoice == 0 then
        self:Print("is disabled on this character but enabled on the account by default.");
    elseif  LootAssistDefault == 0 and LootAssistChoice == 1 then
        self:Print("is enabled on this character but disabled on the account by default.");
    elseif  LootAssistDefault == 0 and LootAssistChoice == 0 then
        self:Print("is disabled on this character and on the account by default.");
    end
end

------------------------------------------------------------------------------------------------------------------------
function frameEventHandle(self,event,arg1,arg2)
 -- Keep attempting to loot until no more error message   
    if event == "UI_ERROR_MESSAGE" and (arg2=="That object is busy.") then
        local iTried=0;
        for i=1, GetNumLootItems() do
            LootSlot(i);
            
            iTried = iTried+1;
            if iTried==7 then 
                break
            end
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

------------------------------------------------------------------------------------------------------------------------
-- Load up the saved settings
local MagicFrame=CreateFrame("Frame")
MagicFrame:RegisterEvent("PLAYER_LOGIN")

MagicFrame:SetScript("OnEvent", function(...)

    if LootAssistDefault == nil and LootAssistChoice == nil then 
        LootAssist:FirstRun()
    end

    if LootAssistDefault == nil then 
        LootAssistDefault = 0 -- just to give them a default setting on first log in
    end
    if LootAssistChoice == nil then
        LootAssistChoice = 0 -- just to give them a default setting on first log in
    end

    if LootAssistDefault == 0 then              -- Default off 
        if LootAssistChoice == 0 then           -- Per Char off
            LootAssist:LootAssistOff();
            LootAssist:Print("Disabled Account Wide");
        else                                    -- Per Char on
            LootAssist:LootAssistOn();
            LootAssist:Print("Enabled per Character");        
        end
    else                                        -- Default on
        LootAssist:LootAssistOn();
        LootAssist:Print("Enabled by Default");
    end
end)
------------------------------------------------------------------------------------------------------------------------
