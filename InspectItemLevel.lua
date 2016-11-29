--version 1.1.1
local Slots = {
	"Head","Neck","Shoulder","Back","Chest","Wrist",
	"Hands","Waist","Legs","Feet","Finger0","Finger1",
	"Trinket0","Trinket1", "MainHand", "SecondaryHand"
}

local InspectCache = {}

local ILvlFrame = CreateFrame("Frame", "IlvlFrame")
local lastInspectReady
local inspecting = false
local InspectGUID

ILvlFrame:RegisterEvent("INSPECT_READY")
ILvlFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

ILvlFrame:ClearAllPoints()
ILvlFrame:SetHeight(300)
ILvlFrame:SetWidth(1000)
ILvlFrame.text = ILvlFrame:CreateFontString(nil, "BACKGROUND", "PVPInfoTextFont")
ILvlFrame.text:SetAllPoints()
ILvlFrame.text:SetTextHeight(13)
ILvlFrame:SetAlpha(1)

ILvlFrame:SetScript("OnEvent", function(self, event_name, ...)
	if self[event_name] then
		return self[event_name](self, event_name, ...)
	end
end)

function ILvlFrame:INSPECT_READY(event, GUID)	
	ILvlFrame.text:SetText(format("ilvl: ??"))
	lastInspectReady = GetTime()
	InspectGUID = GUID
	inspecting = true
	
end

function ILvlFrame:intializeItemLevelInspection()

	if InspectFrame and InspectFrame.unit then 
		local UnitIlevel = 0
		if not InspectCache[InspectGUID] or InspectCache[InspectGUID].time > 800 then
			UnitIlevel = self:GetItemLvL(InspectFrame.unit)
			InspectCache[InspectGUID] = {time = GetTime()}
			InspectCache[InspectGUID].ilevel = UnitIlevel
		else
			UnitIlevel = InspectCache[InspectGUID].ilevel
		end
		if InspectFrame and InspectFrame.unit then
			ILvlFrame:SetParent(InspectFrame)
			ILvlFrame:SetPoint("BOTTOM", InspectFrame, "RIGHT", -45, 15)
			print("setText"..tostring(UnitIlevel))
			ILvlFrame.text:SetText(format("ilvl: ".. tostring(UnitIlevel)))
			
		end
	end
end

function ILvlFrame:PLAYER_TARGET_CHANGED()
	isCalculatingIlevel = false;
end

function ILvlFrame:GetItemLvL(unit)
	local total, item = 0, 0;
	for i = 1, #Slots do
		local itemLink = GetInventoryItemLink(unit, GetInventorySlotInfo(("%sSlot"):format(Slots[i])));
		if (itemLink ~= nil) then
			local itemLevel = self:ScanForItemLevel(itemLink);
	
			if(itemLevel and itemLevel > 0) then
				item = item + 1;
				total = total + itemLevel;
			end
		end
	end
	if(total < 1) then
		return
	end
	return floor(total / item)
end

function IlvlFrame:GetAvailableTooltip()
	for i=1, #GameTooltip.shoppingTooltips do
		if(not GameTooltip.shoppingTooltips[i]:IsShown()) then
			return GameTooltip.shoppingTooltips[i]
		end
	end
end

--randomly some items dont give the correct ItemLevel a second inspectiong seems to give the correct value
function ILvlFrame:ScanForItemLevel(itemLink)
	local tt = self:GetAvailableTooltip();
	tt:SetOwner(UIParent, "ANCHOR_NONE");
	tt:SetHyperlink(itemLink);
	tt:Show();
	
	local itemLevel = 0;
	for i = 2, tt:NumLines() do
		local text = _G[ tt:GetName() .."TextLeft"..i]:GetText();
		if(text and text ~= "") then
		--print(itemLink..",  "..tt:GetName()..", ".. text)
			local value = tonumber(text:match(ITEM_LEVEL:gsub( "%%d", "(%%d+)" )));
			if(value) then
				itemLevel = value;
			end
		end
	end
	tt:Hide();
	print(itemLink.." : "..itemLevel..",   "..select(4,GetItemInfo(itemLink)))
	return itemLevel
end

--needs a delay to make sure all INSPECT_READY has finished calling
local function onUpdate(self,elapsed)
	if (inspecting) then
		if(GetTime() - lastInspectReady > .5) then
		inspecting = false
		ILvlFrame:intializeItemLevelInspection()
		end
	end
end

ILvlFrame:SetScript("OnUpdate", onUpdate)