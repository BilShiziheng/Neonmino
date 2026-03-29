-- core/profile.lua
local profile = {}

local Storage = require("core.storage")
local SFX = require("core.sfx")

local currentProfile = nil
local configPath = "profile.lua"

local defaultProfile = {
    name = "Player",  -- 改成英文
    exp = 0,
    totalLines = 0,
    totalPieces = 0,
    totalGames = 0,
    maxCombo = 0,
    maxScore = 0,
    playTime = 0,
    achievements = {},
}

local expShown = 0
local expIncrease = 0
local expIncreaseTimer = 0
local expIncreaseMaxTime = 0
local levelupTimer = 0
local levelupMaxTime = 3

function profile.load()
	if currentProfile == nil then
    	currentProfile = Storage.load(configPath, defaultProfile)
		expShown = currentProfile.exp
	end
    return currentProfile
end

function profile.save()
	Storage.save(configPath)
end

function profile.get()
    return profile.load()
end

-- levels
local function levelAllExp(level)
	--	now level x costs 100 * x * x exp
	local x = level
	return x * (x + 1) * (2 * x + 1) / 6 * 100
end
local function levelExp(level)
	return levelAllExp(level) - levelAllExp(level - 1)
end
local function getLevel(allExp)
	local level, step = 0, 1
	while levelAllExp(level) <= allExp do
		level = level + step
		step = step * 2
	end
	while step >= 1 do
		if levelAllExp(level - step) > allExp then
			level = level - step
		end
		step = step / 2
	end
	lastExp, lastRes = allExp, level
	return level
end
local function toLeveled(allExp)
	local level = getLevel(allExp)
	return level, allExp - levelAllExp(level - 1), levelExp(level)
end
--[[
local function levelText(allExp)
	return string.format("Lv.%d %d/%d EXP", toLeveled(allExp))
end
]]

-- hmm
function profile.addExp(amount)
    currentProfile.exp = currentProfile.exp + amount
	expIncrease = expIncrease + amount
	expIncreaseMaxTime = math.log(1 + expIncrease / 100)
	expIncreaseTimer = expIncreaseMaxTime
    profile.save()
end

function profile.recordGame(score, lines, pieces, combo)
    currentProfile.totalGames = currentProfile.totalGames + 1
    currentProfile.totalLines = currentProfile.totalLines + (lines or 0)
    currentProfile.totalPieces = currentProfile.totalPieces + (pieces or 0)
    if (score or 0) > currentProfile.maxScore then
        currentProfile.maxScore = score or 0
    end
    if (combo or 0) > currentProfile.maxCombo then
        currentProfile.maxCombo = combo or 0
    end
    profile.save()
end

function profile.setName(name)
    if name and name ~= "" then
        currentProfile.name = name
        profile.save()
    end
end

function profile.update(dt)
	levelupTimer = levelupTimer - dt
	if expIncreaseTimer > 0 then
    	local oldLevel = getLevel(expShown)
		local ot = expIncreaseMaxTime - expIncreaseTimer
		expIncreaseTimer = expIncreaseTimer - dt
		local nt = expIncreaseMaxTime - expIncreaseTimer
		local increase = math.min(expIncrease, math.ceil(100 * math.exp(nt)) - math.ceil(100 * math.exp(ot)))
		expIncrease = expIncrease - increase
		expShown = expShown + increase
		local newLevel = getLevel(expShown)
		local leveledUp = oldLevel < newLevel
		if leveledUp then
			if levelupTimer > 2.75 then
				-- nothing
			elseif levelupTimer > 2 then
				levelupTimer = levelupMaxTime - (levelupTimer - 2) / 3
			else
				levelupTimer = levelupMaxTime
			end
			SFX.play("levelup")
		end
	end
end

function profile.draw(within)
	if currentProfile == nil then return end
	
	if within ~= "result" and within ~= "menu" and within ~= "select" then
		expShown = expShown + expIncrease
		expIncreaseTimer = 0
		expIncrease = 0
		levelupTimer = -2
		return
	end
	
	love.graphics.setColor(1, 1, 1, 0.3)
	love.graphics.rectangle("fill", 0, 0, 290, 80)
	
	-- avatar
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.rectangle("fill", 10, 10, 60, 60)

	local left, width = 80, 200
	local level, exp, limit = toLeveled(expShown)
	local prog = exp / limit

	-- username
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setFont(mediumFont)
	love.graphics.printf(currentProfile.name, left, 10 + (35 - mediumFont:getHeight()) / 2, width, "left")
	
	-- level
	if levelupTimer > 0 then
		local t
		if levelupTimer > 2.75 then
			t = (3 - levelupTimer) / 0.25
		else
			t = math.pow(math.min(1, levelupTimer), 2)
		end
		local r, g, b = 0, 0.8, 1
		r = r * t + 1 * (1 - t)
		g = g * t + 1 * (1 - t)
		b = b * t + 1 * (1 - t)
    	love.graphics.setColor(r, g, b, 1)
	else
    	love.graphics.setColor(1, 1, 1, 1)
	end
	love.graphics.printf(string.format("Lv.%d", level), left, 10 + (35 - mediumFont:getHeight()) / 2, width, "right")

	-- experience
	if levelupTimer > 0 then
		local cr, cg, cb, dl = 0, 0.6, 1, 1
		if levelupTimer > 2.75 then
			local t = (levelupTimer - 2.75) / 0.25
			cr, cg, cb = 1 - t, 1 - 0.4 * t, 1
		elseif levelupTimer > 2 then
			local t = (levelupTimer - 2) / 0.75
			cr, cg, cb = t, 0.6 + 0.4 * t, 1
		elseif levelupTimer > 0.5 then
			-- nothing
		else
			local t = (levelupTimer - 0) / 0.5
			cr, cg, cb, dl = 0, 0.6 * t, 1 * t, t
		end
		love.graphics.setColor(cr, cg, cb, 1)
		love.graphics.rectangle("fill", left, 50, width, 20)
		love.graphics.setColor(1, 1, 1, dl)
		love.graphics.setFont(smallFont)
		love.graphics.printf("LEVEL UP!", left, 50 + (20 - smallFont:getHeight()) / 2, width, "center")
	else
		local pl, pr = 1, prog
		if levelupTimer > -1 then
			pl = levelupTimer / -1
			pr = levelupTimer / -1 * prog
		end
		love.graphics.setColor(0, 0.6, 1, 1)
		love.graphics.rectangle("fill", left, 50, width * pr, 20)
		love.graphics.setColor(0, 0, 0, 1)
		love.graphics.rectangle("fill", left + width * pr, 50, width * (1 - pr), 20)
		love.graphics.setColor(1, 1, 1, pl)
		love.graphics.setFont(smallFont)
		love.graphics.printf(string.format("%d/%d EXP", exp, limit), left, 50 + (20 - smallFont:getHeight()) / 2, width, "center")
	end
	
	-- increase
	if expIncrease > 0 then
		love.graphics.setColor(0, 1, 0, 1)
		love.graphics.printf(string.format("+%d", expIncrease), 300, 50 + (20 - smallFont:getHeight()) / 2, width, "left")
	end
end

return profile