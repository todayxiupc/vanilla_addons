local MAXRANGE = 55

local function setupFrames(self)
  self:SetParent(UIParent);
  self:SetWidth(272);
  self:SetHeight(28);
  self:SetFrameStrata("HIGH");
  self:SetPoint("CENTER", -86, -254)
  self:SetMovable(true)
  self:EnableMouse(true)
  self:RegisterForDrag("LeftButton")
  self:SetScript("OnDragStart", self.StartMoving)
  self:SetScript("OnDragStop", self.StopMovingOrSizing)

  self.bar = CreateFrame("Frame", self:GetName().."_bar")
  self.bar:SetParent(self);
  self.bar:SetFrameStrata("LOW");
  self.bar:EnableMouse(false)
  self.bar:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
  self.bar:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)
  self.bar:SetBackdrop({
      bgFile="Interface/DialogFrame/UI-DialogBox-Background",
      edgeFile="Interface/DialogFrame/UI-DialogBox-Border",
      tile=false, tileSize=16,
      edgeSize=15,
      insets={left=5, right=5, top=5, bottom=5}
  })
  self.bar:SetAlpha(1);

  -- TODO: Fixed gradient width
  local r, g, b = 0.7, 0, 0
  local a0, a1 = 0, 1
  self.bar.texture0 = self.bar:CreateTexture()
  self.bar.texture0:SetColorTexture(r, g, b)
  self.bar.texture0:SetGradientAlpha("HORIZONTAL",
                                     1, 1, 1, a0,
                                     1, 1, 1, a1)
  self.bar.texture0:SetAlpha(1)

  self.bar.texture1 = self.bar:CreateTexture()
  self.bar.texture1:SetColorTexture(r, g, b)
  self.bar.texture1:SetAlpha(a1)

  self.bar.texture2 = self.bar:CreateTexture()
  self.bar.texture2:SetColorTexture(r, g, b)
  self.bar.texture2:SetGradientAlpha("HORIZONTAL",
                                     1, 1, 1, a1,
                                     1, 1, 1, a0)
  self.bar.texture2:SetAlpha(1)

  self.cursors = {}

  local function new_cursor(tab, k)
    cursor = CreateFrame("Frame", self:GetName().."_cursor"..k)
    cursor:SetParent(self);
    cursor:ClearAllPoints()
    cursor:EnableMouse(false)
    cursor:SetFrameStrata("DIALOG");
    cursor:SetPoint("TOPLEFT", self.bar, "TOPLEFT", 0, 8)
    cursor:SetBackdrop({
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 15,
    })
    cursor:SetHeight(18);
    cursor:SetAlpha(1);
    cursor:Hide()

    cursor.text = cursor:CreateFontString(
      self:GetName().."_cursor"..k.."_text", "OVERLAY", "GameFontNormalLarge")
    cursor.text:SetPoint("CENTER")
    cursor.text:SetTextColor(1, 1, 1, 0.65)
    cursor.text:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    rawset(tab, k, cursor)
    return cursor
  end
  setmetatable(self.cursors, {__index=new_cursor})
end

function moveBg(self, range)
  local V, W = 50, 50
  local barBorderW, barBorderH = 8, 8
  local totalWidth = self:GetWidth() - barBorderW * 2
  local o = range[1]

  left = o.start / MAXRANGE * totalWidth
  right = o.stop / MAXRANGE * totalWidth
  middle = (left + right) / 2
  width = right - left

  -- Apply a minimal width and a bound constraint
  width = max(1, width)
  left = middle - width / 2
  right = middle + width / 2
  overflow_left = -min(0, left)
  overflow_right = -min(0, totalWidth - right)
  left = left + overflow_left - overflow_right
  right = right - overflow_right + overflow_left
  middle = (left + right) / 2

  self.bar.texture0:SetPoint("BOTTOMLEFT", self.bar, "BOTTOMLEFT",
                             barBorderW, barBorderH - 1)
  self.bar.texture0:SetPoint("TOPRIGHT", self.bar, "TOPLEFT",
                             barBorderW + left, -barBorderH)

  self.bar.texture1:SetPoint("BOTTOMLEFT", self.bar, "BOTTOMLEFT",
                             barBorderW + left, barBorderH - 1)
  self.bar.texture1:SetPoint("TOPRIGHT", self.bar, "TOPLEFT",
                             barBorderW + right, -barBorderH)

  self.bar.texture2:SetPoint("BOTTOMLEFT", self.bar, "BOTTOMLEFT",
                             barBorderW + right, barBorderH - 1)
  self.bar.texture2:SetPoint("TOPRIGHT", self.bar, "TOPRIGHT",
                               -barBorderW, -barBorderH)

end

function moveCursor(self, range)
  local left, right, middle, width, overflow_left, overflow_right, minWidth
  local barBorder = 4
  local totalWidth = self:GetWidth() - barBorder * 2

  for i, o in ipairs(range) do
    minWidth = 19 + (floor(log10(max(1, o.start))) + 1) * 8
    -- TODO: Should the full range be shown?
    --       Is it always a good idea? (UX speaking)

    left = o.start / MAXRANGE * totalWidth
    right = o.stop / MAXRANGE * totalWidth
    middle = (left + right) / 2
    width = right - left

    -- Apply a minimal width and a bound constraint
    -- TODO: Handle overlaps between cursors...
    width = max(minWidth, width)
    left = middle - width / 2
    right = middle + width / 2
    overflow_left = -min(0, left)
    overflow_right = -min(0, totalWidth - right)
    left = left + overflow_left - overflow_right
    right = right - overflow_right + overflow_left
    middle = (left + right) / 2

    self.cursors[i]:ClearAllPoints()
    self.cursors[i]:SetPoint("TOP", self, "TOPLEFT", middle + barBorder, -barBorder);
    self.cursors[i]:SetPoint("BOTTOM", self, "BOTTOMLEFT", middle + barBorder, barBorder);
    self.cursors[i]:SetWidth(width);
    -- self.cursors[i].text:SetText(o.start.."-"..o.stop);
    self.cursors[i].text:SetText(o.start.."+")
  end
  for i, _ in ipairs(self.cursors) do
    if i <= table.getn(range) then
      self.cursors[i]:Show()
    else
      self.cursors[i]:Hide()
    end
  end

end

local function help()
  print("| >>> ngorange, a wow-classic and wow-retail addon to approximate the target's distance");
  print('| Works on all targets');
  print("| The cursor track the distance to the target's hitbox using those informations:");
  print('| - Is the spell in range (works with all spells in your spellbook)');
  print('| - Is the item in range (works with all items in your bags that can be casted on a target)');
  print('| - Is the toy in range (works on wow-retail with all toys (not just the ones you own) that can be casted on a target)');
  print('| - Is your target close enough to be healed (40 yards) (works with all units in party/raid)');
  print("| The red background track the distance to the target's center using those informations:");
  print('| - Is your target close enough to be followed (28 yards) (works with all units)');
  print('| - Is your target close enough to be duelled with (10 yards) (works with all units)');
  print('|  ');
  print('| /ngorange help -> Print this message');
  print('| /ngorange reset -> Reset the spells and items monitored (useful when new spells or new items)');
  print("| /ngorange show -> Show what is monitored to approximate the target's hitbox distance");
  print("| /ngorange stats -> Show how many range-tests were performed so far");
  print('|  ');
  print('| Developped by ngo in august-2019 on wow-classic 1.13 and wow-retail 8.2.');
end

local function createStatsWatcher()
  local o = {}
  local timeAcc, testAcc, uselessTestAcc, updateAcc, startTime = 0, 0, 0, 0, nil

  o.onUpdate = function(count, countUseless)
    updateAcc = updateAcc + 1
    testAcc = testAcc + count
    uselessTestAcc = uselessTestAcc + countUseless
  end
  o.onStart = function()
    startTime = GetTime()
  end
  o.onStop = function()
    timeAcc = timeAcc + GetTime() - startTime
    startTime = nil
  end
  o.print = function()
    if startTime ~= nil then
      timeAcc = timeAcc + GetTime() - startTime
      startTime = GetTime()
    end
    if testAcc > 0 then
      fmt = ('| Range tracking duration %.1fsec, update count %d, \n'..
	       'test count %d, useless-test count %d(%.0f%%), \n'..
	       'test/update %.1f, test/sec %.1f, update/sec %.1f')
      print(string.format(fmt, timeAcc, updateAcc,
			  testAcc, uselessTestAcc, uselessTestAcc / testAcc * 100,
			  testAcc / updateAcc, testAcc / timeAcc, updateAcc / timeAcc));
    else
      print("Nothing to show yet");
    end
  end

  return o
end

local function closure()
  local self
  local has_target = UnitExists("target")
  local hitboxRangeInfos
  local hitboxRangeReducer
  local centroidRangeReducer = rangeLib.createReducer(rangeLib.createCentroidRangeInfos())
  local minDistanceBetweenUpdates = 1 / 30
  local lastUpdate = GetTime()
  local sw = createStatsWatcher()

  local function primeTests(force)
    if hitboxRangeReducer == nil or force == true then
      hitboxRangeInfos = rangeLib.createHitboxRangeInfos()
      hitboxRangeReducer = rangeLib.createReducerWithGUIDCache(hitboxRangeInfos)
    end
  end

  local function onSlash(msg)
    primeTests()
    if msg == 'reset' then
      print('ngorange tests reset');
      primeTests(true)
    elseif msg == 'show' then
      for k, v in ipairs(hitboxRangeInfos) do
        print('->', v);
      end
    elseif msg == 'stats' then
      sw.print()
    else
      help()
    end
  end

  local function onUpdate()
    if not has_target then
      return
    end
    local now = GetTime()
    if now - lastUpdate < minDistanceBetweenUpdates then
      return
    end
    lastUpdate = now
    -- ~57k tests per second will get the fps down to 25 from 60
    -- V0.4.0 (using toys)
    -- ~14000 test/second (~230 test/update)
    -- V0.5.0 (opti and update rate limitation)
    -- ~250 test/sec (~9 test/update)

    local r, count, countUseless = hitboxRangeReducer.reduce("target")
    moveCursor(self, rangeLib.clipRange(r, MAXRANGE))
    sw.onUpdate(count, countUseless)

    r, _, _ = centroidRangeReducer.reduce("target")
    moveBg(self, rangeLib.clipRange(r, MAXRANGE))
  end

  local function onEvent(_, event)
    if (event == "PLAYER_ENTERING_WORLD") then
      ngorange:UnregisterEvent("PLAYER_ENTERING_WORLD")
      ngorange:SetScript("OnUpdate", onUpdate);
    end
    if (event == "PLAYER_TARGET_CHANGED") then
      primeTests()
      has_target = UnitExists("target")
      if not has_target then
        for _, cursor in ipairs(self.cursors) do
          cursor:Hide()
        end
        self.bar.texture0:Hide()
        self.bar.texture1:Hide()
        self.bar.texture2:Hide()
	sw.onStop()
      else
        self.bar.texture0:Show()
        self.bar.texture1:Show()
        self.bar.texture2:Show()
	sw.onStart()
      end
    end
  end

  local function onLoad()
    self = ngorange

    self:SetScript("OnEvent", onEvent);
    self:RegisterEvent("PLAYER_TARGET_CHANGED")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")

    setupFrames(self)
    print("Welcome to ngorange. Commands: `/ngorange help`, `/ngorange show`, `/ngorange reset`.");
  end

  function LOL() -- global for debug
    print("********************");
    primeTests()
  end

  return onLoad, onSlash
end

function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

ngorangeOnLoad, ngorangeOnSlash = closure()
SLASH_NGORANGE1 = "/ngorange"
SlashCmdList["NGORANGE"] = ngorangeOnSlash
