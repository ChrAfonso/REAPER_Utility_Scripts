-- Add space between items (should be on one track)

local spaceBeats = 1 -- beats space
local bpm = reaper.GetProjectTimeSignature2(0)
local spaceTime = (60 / bpm) * spaceBeats

local count = reaper.CountSelectedMediaItems(0)

local items = {}
for i=0,count-1 do
  local item = reaper.GetSelectedMediaItem(0, i)
  items[i] = item
end

for i=0,count-1 do
  local item = items[i]
  
  local firstTake = reaper.GetMediaItemTake(item, 0)
  local _, name = reaper.GetSetMediaItemTakeInfo_String(firstTake, "P_NAME", "", false)
  
  local position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  reaper.SetMediaItemPosition(item, position + (spaceTime * i), false)
end

reaper.UpdateArrange()
