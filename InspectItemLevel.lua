--version 1.1.0
local Slots = {
	"Head","Neck","Shoulder","Back","Chest","Wrist",
	"Hands","Waist","Legs","Feet","Finger0","Finger1",
	"Trinket0","Trinket1"
}

local InspectCache = {}

local ILvlFrame = CreateFrame("Frame", "IlvlFrame")
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
	if InspectFrame and InspectFrame.unit then 
		local UnitIlevel = 0
		local cached = false
		
		UnitIlevel = self:GetItemLvL(InspectFrame.unit)
		if(UnitIlevel ~= nil) then
			InspectCache[GUID] = {time = GetTime(), ilevel = UnitIlevel}
		else
			if (InspectCache[GUID] ~= nil) then
				if(InspectCache[GUID].ilevel) then
					cached = true
					UnitIlevel = InspectCache[GUID].ilevel
				end
			end
		end
		if InspectFrame and InspectFrame.unit then
			ILvlFrame:SetParent(InspectFrame)
			ILvlFrame:SetPoint("BOTTOM", InspectFrame, "RIGHT", -45, 15)
			if(cached) then
				ILvlFrame.text:SetText(format("Cached ilvl: ".. tostring(UnitIlevel)))
			else
				ILvlFrame.text:SetText(format("ilvl: ".. tostring(UnitIlevel)))
			end
			
		end
	end
end

function ILvlFrame:PLAYER_TARGET_CHANGED()
	isCalculatingIlevel = false;
end

function ILvlFrame:GetItemLvL(unit)
	local total = 0;
	for i = 1, #Slots do
		local itemLink = GetInventoryItemLink(unit, GetInventorySlotInfo(("%sSlot"):format(Slots[i])));
		if (itemLink ~= nil) then
			local itemLevel = self:ScanForItemLevel(itemLink);
			if(itemLevel and itemLevel > 0) then
				total = total + itemLevel;
			end
		end
	end
	local mainHandSkipped = false
	local itemLink = GetInventoryItemLink(unit, GetInventorySlotInfo("MainHandSlot"));
	if (itemLink ~= nil) then
		local itemLevel = self:ScanForItemLevel(itemLink);
		if(itemLevel == 750) then
			mainHandSkipped = true
		else
			total = total + itemLevel + itemLevel
		end
	end
	local itemLink = GetInventoryItemLink(unit, GetInventorySlotInfo("SecondaryHandSlot"));
	if (itemLink ~= nil) then
		local itemLevel = self:ScanForItemLevel(itemLink);
		if(itemLevel == 750) then
			if(mainHandSkipped) then
				total = total + itemLevel + itemLevel
				print("Both weapons are 750 ilvl. Bug?")
			end
		else
			total = total + itemLevel + itemLevel
		end
	end
	if(total < 1) then
		return
	end
	return floor(total / 16)
end

function IlvlFrame:GetAvailableTooltip()
	for i=1, #GameTooltip.shoppingTooltips do
		if(not GameTooltip.shoppingTooltips[i]:IsShown()) then
			return GameTooltip.shoppingTooltips[i]
		end
	end
end

function ILvlFrame:ScanForItemLevel(itemLink)
	local tt = self:GetAvailableTooltip();
	tt:SetOwner(UIParent, "ANCHOR_NONE");
	tt:SetHyperlink(itemLink);
	tt:Show();

	local itemLevel = 0;
	for i = 2, tt:NumLines() do
		local text = _G[ tt:GetName() .."TextLeft"..i]:GetText();
		if(text and text ~= "") then
			local value = tonumber(text:match(ITEM_LEVEL:gsub( "%%d", "(%%d+)" )));
			if(value) then
				itemLevel = value;
			end
		end
	end
	tt:Hide();
	return itemLevel
end











