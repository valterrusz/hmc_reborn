local addonName, addonTable = ...


-- Slash Command Handler
SLASH_HMC1 = "/hmc"
SlashCmdList["HMC"] = function(msg)
    local cmd = msg:lower():match("^%s*(.-)%s*$") -- Trim whitespace
    
    if cmd == "" or cmd == "ui" then
        addonTable.ShowUI()
    elseif HMC_Sounds[cmd] then
        local success = PlaySoundFile(HMC_Sounds[cmd], "Master")
        if not success then
             print("|cffff0000HMC Error:|r Could not play sound '" .. HMC_Sounds[cmd] .. "'")
        end
    else
        print("|cffff0000HMC:|r Sound '" .. cmd .. "' not found. Type /hmc for UI.")
    end
end

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
f.title:SetPoint("CENTER", f.TitleBg, "CENTER", 0, 0)
f.title:SetText("HMC Reborn")

-- Copy Box (EditBox)
local copyBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
copyBox:SetSize(530, 30)
copyBox:SetPoint("BOTTOM", 0, 10)
copyBox:SetAutoFocus(false)
copyBox:SetText("Select a sound to copy command")
copyBox:SetCursorPosition(0)

-- Containers
local CategoryFrame = CreateFrame("Frame", nil, f)
CategoryFrame:SetPoint("TOPLEFT", 10, -40)
CategoryFrame:SetPoint("BOTTOMRIGHT", -10, 50)

local SoundFrameWrapper = CreateFrame("Frame", nil, f)
SoundFrameWrapper:SetPoint("TOPLEFT", 10, -40)
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
end

local function ShowSounds(category)
    ReleaseButtons() -- Clear current list
    
    CategoryFrame:Hide()
    SoundFrameWrapper:Show()
    f.title:SetText("HMC Reborn - " .. category)
    
    local yOffset = -5
    local currentGroup = Groups[category]
    
    if currentGroup then
        for _, item in ipairs(currentGroup) do
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
                    PlaySoundFile(item.path, "Master")
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

backBtn:SetScript("OnClick", ShowCategories)

-- Render Category Blocks
local function InitCategories()
    local xOffset = 10
    local yOffset = -10
    local col = 0
    
    -- Special mappings for image names
    local ImageMapping = {
        ["Pepsi"] = "pepsibela"
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
