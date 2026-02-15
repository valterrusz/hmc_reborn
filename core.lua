local addonName, addonTable = ...


-- Addon Communication Setup
local COMM_PREFIX = "HMCR"
local Success = C_ChatInfo.RegisterAddonMessagePrefix(COMM_PREFIX)

-- Play Sound & Broadcast Logic
local lastPlayedTime = 0
local function PlaySoundEntry(key, source)
    if source == "self" then
        local now = GetTime()
        if (now - lastPlayedTime) < 3 then
            print("|cffff0000HMC:|r Cooldown active (" .. math.ceil(3 - (now - lastPlayedTime)) .. "s)")
            return
        end
        lastPlayedTime = now
    end

    if HMC_Sounds[key] then
        -- 1. Play locally
        local success = PlaySoundFile(HMC_Sounds[key], "Master")
        if not success and source == "self" then
             print("|cffff0000HMC Error:|r Could not play sound '" .. key .. "'")
        end

        -- 2. Broadcast if initiated by self and in group
        if source == "self" then
            local channel = nil
            if IsInRaid() then
                channel = "RAID"
            elseif IsInGroup() then
                channel = "PARTY"
            end

            if channel then
                C_ChatInfo.SendAddonMessage(COMM_PREFIX, key, channel)
            end
        end
    elseif source == "self" then
        print("|cffff0000HMC:|r Sound '" .. key .. "' not found. Type /hmc for UI.")
    end
end

-- Slash Command Handler
SLASH_HMC1 = "/hmc"
SlashCmdList["HMC"] = function(msg)
    local cmd = msg:lower():match("^%s*(.-)%s*$") -- Trim whitespace
    
    if cmd == "" or cmd == "ui" then
        addonTable.ShowUI()
    else
        PlaySoundEntry(cmd, "self")
    end
end

-- Event Handler for Incoming Messages
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:SetScript("OnEvent", function(self, event, prefix, message, channel, sender)
    if prefix == COMM_PREFIX then
        -- Avoid playing own messages (already played locally)
        local myName = UnitName("player") .. "-" .. GetRealmName()
        if sender == UnitName("player") or sender == myName then return end

        PlaySoundEntry(message, "remote")
    end
end)

-- UI Construction
local f = CreateFrame("Frame", "HMC_MainFrame", UIParent, "BasicFrameTemplateWithInset")
f:SetSize(600, 500) -- Made wider for blocks
f:SetPoint("CENTER")
f:SetFrameStrata("HIGH")
f:SetMovable(true)
f:EnableMouse(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", f.StartMoving)
f:SetScript("OnDragStop", f.StopMovingOrSizing)
f:Hide()
f.TitleBg:SetHeight(30)
f.TitleBg:SetColorTexture(0.2, 0.2, 0.2, 1)
f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
f.title:SetPoint("TOP", f, "TOP", 0, -5)
f.title:SetText("HMC Reborn")

-- Search Box
local searchBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
searchBox:SetSize(200, 30)
searchBox:SetPoint("TOP", 0, -30)
searchBox:SetAutoFocus(false)
searchBox:SetTextInsets(5, 5, 0, 0)
searchBox:SetFontObject("ChatFontNormal")
searchBox.Instructions = searchBox:CreateFontString(nil, "OVERLAY", "GameFontDisable")
searchBox.Instructions:SetPoint("LEFT", 5, 0)
searchBox.Instructions:SetText("Search sounds...")

searchBox:SetScript("OnEditFocusGained", function(self) self.Instructions:Hide() end)
searchBox:SetScript("OnEditFocusLost", function(self) 
    if self:GetText() == "" then self.Instructions:Show() end 
end)

-- Copy Box (EditBox)
local copyBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
copyBox:SetSize(530, 30)
copyBox:SetPoint("BOTTOM", 0, 10)
copyBox:SetAutoFocus(false)
copyBox:SetText("Select a sound to copy command")
copyBox:SetCursorPosition(0)

-- Containers
local CategoryFrame = CreateFrame("Frame", nil, f)
CategoryFrame:SetPoint("TOPLEFT", 10, -70)
CategoryFrame:SetPoint("BOTTOMRIGHT", -10, 50)

local SoundFrameWrapper = CreateFrame("Frame", nil, f)
SoundFrameWrapper:SetPoint("TOPLEFT", 10, -70)
SoundFrameWrapper:SetPoint("BOTTOMRIGHT", -10, 50)
SoundFrameWrapper:Hide()

-- ScrollFrame for Sounds
local scroll = CreateFrame("ScrollFrame", nil, SoundFrameWrapper, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", 0, -30) -- Leave room for Back button
scroll:SetPoint("BOTTOMRIGHT", -25, 0)

local content = CreateFrame("Frame", nil, scroll)
content:SetSize(550, 1) 
scroll:SetScrollChild(content)

-- Back Button
local backBtn = CreateFrame("Button", nil, SoundFrameWrapper, "UIPanelButtonTemplate")
backBtn:SetSize(80, 24)
backBtn:SetPoint("TOPLEFT", 0, 0)
backBtn:SetText("Back")

-- Helper: Extract Category from Path
local function GetCategory(path)
    -- Manual split to handle backslashes correctly
    local p = path:lower()
    local parts = {}
    for part in string.gmatch(p, "[^\\]+") do
        table.insert(parts, part)
    end

    for i, part in ipairs(parts) do
        if part == "sounds" and parts[i+1] then
            -- Capitalize first letter of category for display
            return parts[i+1]:gsub("^%l", string.upper)
        end
    end
    return "Uncategorized"
end

-- Process Sounds into Groups
local Groups = {}
for name, path in pairs(HMC_Sounds) do
    local cat = GetCategory(path)
    if not Groups[cat] then Groups[cat] = {} end
    table.insert(Groups[cat], {name = name, path = path})
end

-- Sort Groups and Items
local SortedCategories = {}
for cat in pairs(Groups) do
    table.insert(SortedCategories, cat)
    table.sort(Groups[cat], function(a,b) return a.name < b.name end)
end
table.sort(SortedCategories)

-- Button Pool
local ButtonPool = {}
local ActiveButtons = {}

local function AcquireButton()
    local btn = table.remove(ButtonPool)
    if not btn then
        btn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        btn:SetSize(530, 24)
        btn:SetNormalFontObject("GameFontHighlightSmall")
        btn:SetHighlightFontObject("GameFontHighlight")
    end
    btn:Show()
    table.insert(ActiveButtons, btn)
    return btn
end

local function ReleaseButtons()
    for i = #ActiveButtons, 1, -1 do
        local btn = ActiveButtons[i]
        btn:Hide()
        btn:SetScript("OnClick", nil) -- Clear click handlers
        table.insert(ButtonPool, btn)
        ActiveButtons[i] = nil
    end
end

-- State Management Functions
local function ShowCategories()
    SoundFrameWrapper:Hide()
    CategoryFrame:Show()
    f.title:SetText("HMC Reborn")
    ReleaseButtons() -- Clean up sound list when leaving
    searchBox:SetText("")
    searchBox:ClearFocus()
end

local function UpdateSoundList(list)
    ReleaseButtons() -- Clear current list
    
    local yOffset = -5
    
    if list then
        for _, item in ipairs(list) do
            local btn = AcquireButton()
            btn:SetPoint("TOPLEFT", 0, yOffset)
            btn:SetText(item.name)
            
            btn:SetScript("OnClick", function(self)
                if IsShiftKeyDown() then
                    local editBox = ChatEdit_ChooseBoxForSend()
                    if editBox then
                        ChatEdit_ActivateChat(editBox)
                        editBox:Insert("/hmc " .. item.name)
                    end
                else
                    PlaySoundEntry(item.name, "self")
                    
                    copyBox:SetText("/hmc " .. item.name)
                    copyBox:SetCursorPosition(0)
                    copyBox:HighlightText()
                    copyBox:SetFocus()
                end
            end)
            
            yOffset = yOffset - 26
        end
    end
    content:SetHeight(math.abs(yOffset) + 20)
end

local function ShowSounds(category)
    CategoryFrame:Hide()
    SoundFrameWrapper:Show()
    f.title:SetText("HMC Reborn - " .. category)
    
    UpdateSoundList(Groups[category])
end

-- Search Logic
searchBox:SetScript("OnTextChanged", function(self)
    local query = self:GetText():lower()
    
    if query == "" then
        self.Instructions:Show()
        if SoundFrameWrapper:IsShown() and f.title:GetText() == "HMC Reborn - Search Results" then
            ShowCategories()
        end
        return
    end
    
    self.Instructions:Hide()
    
    CategoryFrame:Hide()
    SoundFrameWrapper:Show()
    f.title:SetText("HMC Reborn - Search Results")
    
    local matches = {}
    for name, path in pairs(HMC_Sounds) do
        if name:lower():find(query, 1, true) then
            table.insert(matches, {name = name, path = path})
        end
    end
    table.sort(matches, function(a,b) return a.name < b.name end)
    
    UpdateSoundList(matches)
end)

searchBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
    self:SetText("")
    ShowCategories()
end)

backBtn:SetScript("OnClick", ShowCategories)

-- Render Category Blocks
local function InitCategories()
    local xOffset = 10
    local yOffset = -10
    local col = 0
    
    -- Special mappings for image names
    local ImageMapping = {
        ["Pepsi"] = "pepsibela",
        ["Hivatal"] = "polgarjeno",
        ["Uncategorized"] = "anettka2"
    }
    
    for _, cat in ipairs(SortedCategories) do
        local btn = CreateFrame("Button", nil, CategoryFrame, "BackdropTemplate")
        btn:SetSize(180, 80)
        btn:SetPoint("TOPLEFT", xOffset, yOffset)
        
        -- Default Backdrop (fallback)
        btn:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        
        -- Try to load texture
        local imageName = ImageMapping[cat] or cat:lower()
        local texturePath = "Interface\\AddOns\\hmc_reborn\\Images\\" .. imageName .. ".blp"
        
        -- Background Texture
        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetTexture(texturePath)
        bg:SetTexCoord(0.1, 0.9, 0.1, 0.9) -- Slight zoom to avoid borders if needed
        bg:SetAlpha(0.8)
        
        -- Dark Overlay for text readability
        local overlay = btn:CreateTexture(nil, "ARTWORK")
        overlay:SetAllPoints()
        overlay:SetColorTexture(0, 0, 0, 0.5) -- 50% black overlay
        
        -- Hover effect
        btn:SetScript("OnEnter", function(self) 
            self:SetBackdropBorderColor(1, 0.8, 0, 1)
            overlay:SetColorTexture(0, 0, 0, 0.3) -- Lighten overlay on hover
        end)
        btn:SetScript("OnLeave", function(self) 
            self:SetBackdropBorderColor(1, 1, 1, 1)
            overlay:SetColorTexture(0, 0, 0, 0.5) -- Restore overlay
        end)
        
        -- Text
        local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        text:SetPoint("CENTER")
        text:SetText(cat)
        
        -- Click
        btn:SetScript("OnClick", function()
            ShowSounds(cat)
        end)
        
        -- Grid Layout (3 columns)
        col = col + 1
        if col >= 3 then
            col = 0
            xOffset = 10
            yOffset = yOffset - 90
        else
            xOffset = xOffset + 190
        end
    end
end

InitCategories()

addonTable.ShowUI = function()
    f:Show()
    ShowCategories()
end

print("|cFF00FF00HMC Reborn|r loaded! Type /hmc to open.")
