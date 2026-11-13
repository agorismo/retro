local settings = {
	resolution = { width = 1280, height = 720 },
	fullscreen = false,
	vsync = 1,   -- 1 = sincroniza com o Hz do monitor, 0 = desligado
	fpsCap = 0,  -- 0 = sem limite
}

local modes = {}

-- Lista todas as resoluções suportadas pelo monitor, da maior para a menor
function settings.loadModes()
	modes = love.window.getFullscreenModes()
	table.sort(modes, function(a, b)
		if a.width == b.width then
			return a.height > b.height
		end
		return a.width > b.width
	end)
	return modes
end

function settings.getModes()
	return modes
end

function settings.apply()
	love.window.setMode(settings.resolution.width, settings.resolution.height, {
		fullscreen = settings.fullscreen,
		fullscreentype = settings.fullscreen and "exclusive" or "desktop",
		vsync = settings.vsync,
		resizable = not settings.fullscreen,
		minwidth = 640,
		minheight = 360,
	})
end

return settings