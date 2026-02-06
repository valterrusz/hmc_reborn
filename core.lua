local addonName, addonTable = ...

-- Sound Database is in HMC_Sounds (loaded from sounds.lua)

-- Slash Command Handler
SLASH_HMC1 = "/hmc"
SlashCmdList["HMC"] = function(msg)
    local cmd = msg:lower():match("^%s*(.-)%s*$")
    
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

-- =========================================================================
-- Utils & Data
-- =========================================================================
local Groups = {}
local SortedCategories = {}

-- Image Mapping
local CategoryImages = {
    ["agi"] = "agi",
    ["damu"] = "damu",
    ["fantom"] = "fantom",
    ["gabi"] = "gabi",
    ["havas"] = "havas",
    ["hivatal"] = "polgarjeno",
    ["marika"] = "marika",
    ["orban"] = "orban",
    ["patkany"] = "patkany",
    ["pepsi"] = "pepsibela",
    ["pepsibela"] = "pepsibela",
    ["polgarmester"] = "polgarmester",
    ["szenny"] = "anettka2"
}

local function GetCategory(path)
    local p = path:lower()
    local parts = {}
    for part in string.gmatch(p, "[^\\]+") do
        table.insert(parts, part)
    end

    for i, part in ipairs(parts) do
        if part == "sounds" and parts[i+1] then
            local cat = parts[i+1]:gsub("^%l", string.upper)
            if cat == "Uncategorized" then return "Szenny" end
            return cat
        end
    end
    return "Szenny"
end

local function ProcessData()
    Groups = {}
    for name, path in pairs(HMC_Sounds) do
        local cat = GetCategory(path)
        if not Groups[cat] then Groups[cat] = {} end
        table.insert(Groups[cat], {name = name, path = path})
    end

    SortedCategories = {}
    for cat in pairs(Groups) do
        table.insert(SortedCategories, cat)
        table.sort(Groups[cat], function(a,b) return a.name < b.name end)
    end
    table.sort(SortedCategories)
end
ProcessData()

-- =========================================================================
-- Main Frame Construction
-- =========================================================================
local WINDOW_WIDTH = 800
local WINDOW_HEIGHT = 496
local SIDEBAR_WIDTH = 200

local f = CreateFrame("Frame", "HMC_MainFrame", UIParent, "PortraitFrameTemplate")
f:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
f:SetPoint("CENTER")
f:SetFrameStrata("HIGH")
f:SetMovable(true)
f:EnableMouse(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", f.StartMoving)
f:SetScript("OnDragStop", f.StopMovingOrSizing)
f:Hide()

f:SetPortraitToAsset("Interface\\AddOns\\hmc_reborn\\Images\\portrait.blp")
f.TitleContainer.TitleText:SetText("HMC Reborn")

-- Main Background
f.Bg = f:CreateTexture(nil, "BACKGROUND")
f.Bg:SetPoint("TOPLEFT", 2, -24)
f.Bg:SetPoint("BOTTOMRIGHT", -2, 2)
f.Bg:SetColorTexture(0.05, 0.05, 0.05, 1)

-- =========================================================================
-- Navigation Bar (Breadcrumbs)
-- =========================================================================
local navBar = CreateFrame("Frame", nil, f)
navBar:SetPoint("TOPLEFT", 70, -30) -- Moved right to clear portrait
navBar:SetPoint("RIGHT", -10, 0)
navBar:SetHeight(32)

-- Breadcrumb Styles
local function ApplyBreadcrumbStyle(btn, isHome)
    -- Background
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    
    if isHome then
        -- Red Gradient for Home
        bg:SetColorTexture(0.5, 0.1, 0.1, 1)
        bg:SetGradient("VERTICAL", CreateColor(0.8, 0.1, 0.1, 1), CreateColor(0.4, 0, 0, 1))
    else
        -- Transparent/Dark for others
        bg:SetColorTexture(0, 0, 0, 0) 
    end
    btn.Bg = bg
end

-- 1. HOME BUTTON
local homeBtn = CreateFrame("Button", nil, navBar)
homeBtn:SetSize(80, 32)
homeBtn:SetPoint("LEFT", 0, 0)
ApplyBreadcrumbStyle(homeBtn, true)

-- Home Text
local homeText = homeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
homeText:SetPoint("LEFT", 15, 0)
homeText:SetText("Home")
homeText:SetTextColor(1, 0.82, 0) -- Gold

-- Home Arrow removed to avoid overlap with separator


-- 2. SEPARATOR (Chevron)
local sep1 = navBar:CreateTexture(nil, "ARTWORK")
sep1:SetSize(32, 32)
sep1:SetPoint("LEFT", homeBtn, "RIGHT", -12, 0) -- Adjusted overlap for cleaner look
sep1:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")

-- 3. CATEGORY BREADCRUMB
local activeCatBtn = CreateFrame("Button", nil, navBar)
activeCatBtn:SetHeight(32)
activeCatBtn:SetPoint("LEFT", sep1, "RIGHT", -5, 0)
activeCatBtn:Hide()

local catText = activeCatBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
catText:SetPoint("LEFT", 10, 0)
catText:SetText("Category Name")

-- Dropdown Arrow for Category
local catArrow = activeCatBtn:CreateTexture(nil, "ARTWORK")
catArrow:SetSize(20, 20)
catArrow:SetPoint("LEFT", catText, "RIGHT", 5, 0)
catArrow:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow")

activeCatBtn:SetWidth(150) -- Will adapt

-- Function to update breadcrumbs
local function UpdateBreadcrumbs(category)
    if category then
        activeCatBtn:Show()
        sep1:Show()
        catText:SetText(category)
        
        local textWidth = catText:GetStringWidth()
        activeCatBtn:SetWidth(textWidth + 35) -- Text + Arrow + Padding
    else
        activeCatBtn:Hide()
        sep1:Hide() -- Hide separator when only Home is visible
    end
end

-- =========================================================================
-- Views Container
-- =========================================================================
-- 1. Home Grid View
local homeView = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
homeView:SetPoint("TOPLEFT", 10, -80) -- Moved down to avoid nav bar overlap
homeView:SetPoint("BOTTOMRIGHT", -30, 30)

local homeContent = CreateFrame("Frame", nil, homeView)
homeContent:SetSize(WINDOW_WIDTH - 40, 1)
homeView:SetScrollChild(homeContent)

-- 2. Detail View (Sidebar + Content)
local detailView = CreateFrame("Frame", nil, f)
detailView:SetPoint("TOPLEFT", 0, -80) -- Moved down to avoid nav bar overlap
detailView:SetPoint("BOTTOMRIGHT", 0, 0)
detailView:Hide()

-- Sidebar Background (Removed)
-- local detailSideBg = detailView:CreateTexture(nil, "ARTWORK")


-- Footer for Detail View (Copy Box)
local footerBar = CreateFrame("Frame", nil, detailView)
footerBar:SetPoint("BOTTOMLEFT", 10, 4) -- Adjusted for full width
footerBar:SetPoint("BOTTOMRIGHT", -6, 4)
footerBar:SetHeight(20)

local copyBox = CreateFrame("EditBox", nil, footerBar, "InputBoxTemplate")
copyBox:SetSize(400, 20)
copyBox:SetPoint("LEFT", 0, 0)
copyBox:SetAutoFocus(false)
copyBox:SetText("Select a sound to copy command")
copyBox:SetCursorPosition(0)

-- =========================================================================
-- Home Grid Implementation
-- =========================================================================
local GridButtons = {}

local function ShowHome()
    detailView:Hide()
    homeView:Show()
    
    UpdateBreadcrumbs(nil)
    
    -- Populate Grid if empty
    if #GridButtons == 0 then
        local xOffset = 0
        local yOffset = 0
        local col = 0
        local BUTTON_WIDTH = 180
        local BUTTON_HEIGHT = 85
        local GAP_X = 10
        local GAP_Y = 10
        
        for _, cat in ipairs(SortedCategories) do
            local btn = CreateFrame("Button", nil, homeContent, "BackdropTemplate")
            btn:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
            btn:SetPoint("TOPLEFT", xOffset, yOffset)
            
            -- Border (Using a rounded toast border)
            btn:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\FriendsFrame\\UI-Toast-Border",
                tile = true, tileSize = 16, edgeSize = 12,
                insets = { left = 5, right = 5, top = 5, bottom = 5 }
            })
            btn:SetBackdropColor(0, 0, 0, 1)
            btn:SetBackdropBorderColor(0.6, 0.6, 0.6)
            
            -- Background Image (Inset further to avoid bleeding over rounded corners)
            local bg = btn:CreateTexture(nil, "ARTWORK")
            bg:SetPoint("TOPLEFT", 6, -6)
            bg:SetPoint("BOTTOMRIGHT", -6, 6)
            local imgName = CategoryImages[cat:lower()] or "anettka2" 
            bg:SetTexture("Interface\\AddOns\\hmc_reborn\\Images\\" .. imgName .. ".blp")
            bg:SetTexCoord(0.1, 0.9, 0.2, 0.8)
            bg:SetAlpha(0.9)
            
            -- Dark Overlay
            local overlay = btn:CreateTexture(nil, "OVERLAY")
            overlay:SetAllPoints(bg)
            overlay:SetColorTexture(0, 0, 0, 0.3)
            
            -- Text
            local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            text:SetPoint("CENTER")
            text:SetText(cat)
            text:SetTextColor(1, 0.82, 0) -- Gold Text
            
            -- Highlight (Border Only - achieved by changing border color and removing overlay)
            -- We don't use a separate texture for border highlight, we just color the border.
            
            -- Hover Logic
            btn:SetScript("OnEnter", function()
                -- Blue Glow Border Color
                btn:SetBackdropBorderColor(0, 0.7, 1, 1) 
                overlay:SetColorTexture(0, 0, 0, 0) -- Brighten image
            end)
            btn:SetScript("OnLeave", function()
                btn:SetBackdropBorderColor(0.6, 0.6, 0.6)
                overlay:SetColorTexture(0, 0, 0, 0.3)
            end)
            
            -- Click
            btn:SetScript("OnClick", function()
                addonTable.ShowCategory(cat)
            end)
            
            table.insert(GridButtons, btn)
            
            col = col + 1
            if col >= 4 then
                col = 0
                xOffset = 0
                yOffset = yOffset - (BUTTON_HEIGHT + GAP_Y)
            else
                xOffset = xOffset + (BUTTON_WIDTH + GAP_X)
            end
        end
        homeContent:SetHeight(math.abs(yOffset) + BUTTON_HEIGHT + 20)
    end
end
homeBtn:SetScript("OnClick", ShowHome)

-- =========================================================================
-- Detail View Implementation
-- =========================================================================
-- =========================================================================
-- Detail View Implementation
-- =========================================================================
-- Note: Sidebar removed as per user request to only show chosen category content
-- Sidebar list of other categories is unnecessary with breadcrumb navigation.

local contentInset = CreateFrame("Frame", nil, detailView, "InsetFrameTemplate")
contentInset:SetPoint("TOPLEFT", 10, 0) -- Full width (was SIDEBAR_WIDTH + 10)
contentInset:SetPoint("BOTTOMRIGHT", -6, 26)

local contentScroll = CreateFrame("ScrollFrame", nil, contentInset, "UIPanelScrollFrameTemplate")
contentScroll:SetPoint("TOPLEFT", 5, -5)
contentScroll:SetPoint("BOTTOMRIGHT", -25, 5)

local contentFrame = CreateFrame("Frame", nil, contentScroll)
contentFrame:SetSize(WINDOW_WIDTH - 60, 1) -- Adjusted for full width
contentScroll:SetScrollChild(contentFrame)

local SoundButtons = {}
local ActiveSoundButtons = {}
local CurrentCategory = nil

local function AcquireSoundButton()
    local btn = table.remove(SoundButtons)
    if not btn then
        btn = CreateFrame("Button", nil, contentFrame, "BackdropTemplate")
        btn:SetSize(WINDOW_WIDTH - 70, 30) -- Full width buttons
        btn:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        btn:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
        btn:SetBackdropBorderColor(0.4, 0.4, 0.4)

        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
        btn.text:SetPoint("LEFT", 10, 0)
        
        -- Icon removed as per user request

        
        btn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.2, 0.2, 0.2, 1)
            self:SetBackdropBorderColor(1, 0.82, 0)
        end)
        btn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
            self:SetBackdropBorderColor(0.4, 0.4, 0.4)
        end)
    end
    btn:Show()
    table.insert(ActiveSoundButtons, btn)
    return btn
end

local function ReleaseSoundButtons()
    for i = #ActiveSoundButtons, 1, -1 do
        local btn = ActiveSoundButtons[i]
        btn:Hide()
        btn:SetScript("OnClick", nil)
        table.insert(SoundButtons, btn)
        ActiveSoundButtons[i] = nil
    end
end

addonTable.ShowCategory = function(category)
    CurrentCategory = category
    
    homeView:Hide()
    detailView:Show()
    
    UpdateBreadcrumbs(category)
    
    -- UpdateSidebar() -- Removed sidebar list
    
    ReleaseSoundButtons()
    local group = Groups[category]
    local yOffset = -5
    
    if group then
        for _, item in ipairs(group) do
            local btn = AcquireSoundButton()
            btn:SetPoint("TOPLEFT", 5, yOffset)
            btn.text:SetText(item.name)
            
            btn:SetScript("OnClick", function()
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
            
            yOffset = yOffset - 32
        end
    end
    contentFrame:SetHeight(math.abs(yOffset) + 10)
end

-- =========================================================================
-- Public API
-- =========================================================================
-- =========================================================================
-- Search Implementation
-- =========================================================================
local searchBox = CreateFrame("EditBox", "HMCSearchBox", navBar, "SearchBoxTemplate")
searchBox:SetSize(150, 20)
searchBox:SetPoint("RIGHT", -10, 0)
searchBox:SetAutoFocus(false)

local function PerformSearch(text)
    local query = text:lower()
    
    if query == "" then
        -- Clear search: Return to Home
        ShowHome()
        return
    end
    
    -- Switch to Detail View for results
    homeView:Hide()
    detailView:Show()
    UpdateBreadcrumbs("Search Results")
    -- UpdateSidebar() -- Sidebar is removed
    
    ReleaseSoundButtons()
    local yOffset = -5
    local count = 0
    
    -- Global Search across all sounds
    local results = {}
    for name, path in pairs(HMC_Sounds) do
        if string.find(name:lower(), query, 1, true) then
            table.insert(results, {name = name, path = path})
        end
    end
    
    -- Sort results
    table.sort(results, function(a,b) return a.name < b.name end)
    
    for _, item in ipairs(results) do
        local btn = AcquireSoundButton()
        btn:SetPoint("TOPLEFT", 5, yOffset)
        btn.text:SetText(item.name)
        
        btn:SetScript("OnClick", function()
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
        
        yOffset = yOffset - 32
        count = count + 1
        
        -- Cap results to avoid freezing if query is too generic (e.g. "a")? 
        -- Lua is fast enough for a few hundred sounds. typical addon limits ~500 items ok.
    end
    
    if count == 0 then
        -- feedback?
    end
    
    contentFrame:SetHeight(math.abs(yOffset) + 10)
end

searchBox:SetScript("OnTextChanged", function(self)
    SearchBoxTemplate_OnTextChanged(self)
    PerformSearch(self:GetText())
end)

addonTable.ShowUI = function()
    f:Show()
    ShowHome()
    searchBox:SetText("") -- Reset search on open
end

print("|cFF00FF00HMC Reborn|r loaded! Type /hmc to open.")
