-- Shows the inline volume envelope for selected tracks

console = false

if console then
  reaper.ClearConsole()
end

function print(msg)
  if console then
    reaper.ShowConsoleMsg(msg)
  end
end

function getEnvAndChunk(track)
  local env = reaper.GetTrackEnvelopeByChunkName(track, "<VOLENV2")
  local retval, chunk = reaper.GetEnvelopeStateChunk(env, "", false)

  return env, chunk
end

reaper.Undo_BeginBlock()

local count = reaper.CountSelectedTracks(0)
local vislineTarget = nil
for i = 0,count-1 do
  print("Processing track " .. i .. "...\n")
  local track = reaper.GetSelectedTrack(0, i)
  
  -- check for volenv, add if not found
  local retval, trackChunk = reaper.GetTrackStateChunk(track, "", false)
  if not trackChunk:find("<VOLENV2") then
    print("No VOLENV in track chunk, adding it...")
    trackChunk = trackChunk:sub(1,-3)
    local nchunk = "<VOLENV2\nACT 1\nVIS 0 1 1\nLANEHEIGHT 0 0\nARM 1\nDEFSHAPE 0 -1 -1\nPT 0 1 0\n>"
    trackChunk = trackChunk .. nchunk .. "\n>"
    print("Writing track chunk: \n")
    print(trackChunk .. "\n")
    print("-----\n")
    reaper.SetTrackStateChunk(track, trackChunk, false)  
  end
  
  local env, chunk = getEnvAndChunk(track)
  
  local pointsFound = false
  if chunk ~= nil and chunk:find("PT %d %d %d") then
    pointsFound = true
  end
  
  if (chunk ~= nil and chunk:find("<VOLENV2") == 1) then
    print("Track " .. i .. " volume envelope chunk:\n")
    
    local transformed = ""
    local lines = chunk:gmatch("[^\n]*")
    local VISLINE = "^VIS %d %d %d"
    local ARMLINE = "^ARM"
    local ACTLINE = "^ACT"
    local ENDLINE = "^>"
    local PTLINE = "^PT" -- only beginning matters
    
    for line in lines do
      -- insert linebreak?
      if transformed == "" then
        lb = ""
      else
        lb = "\n"
      end
      
      -- only change VIS line
      
      if line:find(VISLINE) then
        -- only check VIS state for first selected track, after that apply the same for each
        if vislineTarget == nil then
          local elements = {}
          for token in line:gmatch("[^ ]+") do
            table.insert(elements, token)
          end
          if #elements == 4 then -- VIS visible lane ???
            local visible = elements[2]
            local lane = elements[3]
            
            -- Cycle: invisible -> lane -> inline
            if visible == "0" then
              vislineTarget = "VIS 1 1 " .. elements[4]
            elseif lane == "1" then
              vislineTarget = "VIS 1 0 " .. elements[4]
            else
              vislineTarget = "VIS 0 1 " .. elements[4]
            end
          end
        end
        
        line = vislineTarget
        print("+ " .. line .. "\n")
      elseif line:find(ARMLINE) and not pointsFound then
        line = "ARM 1"
        print("A " .. line .. "\n")
      elseif line:find(ACTLINE) and not pointsFound then
        line = "ACT 1"
        print("A " .. line .. "\n")
      elseif line:find(ENDLINE) then
        -- omit 
      else        
        print("  " .. line .. "\n")
      end
      transformed = transformed .. lb .. line
    end
    
    print("  >\n")
    
    local success = reaper.SetEnvelopeStateChunk(env, transformed .. "\n>", true)
    if not success then
      print("ERROR: Could not add envelope!\n")
    end
    
  end
end

reaper.TrackList_AdjustWindows(false)
reaper.UpdateArrange()

reaper.Undo_EndBlock("Toggle volume envelope state on selected tracks", 0)

