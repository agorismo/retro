local settings = require("src.settings")
local Esteira = require("src.esteira")
local Posto = require("src.posto")
local Qualidade = require("src.qualidade")
local Economia = require("src.economia")
local Fases = require("src.fases")
local Cores = require("src.cores")
local Pixel = require("src.pixel")

local esteira, posto, qualidade
local estado = "menu" -- "menu", "jogando", "loja", "vitoria"
local tempoRestante = 0
local passouNaFase = false
local lojaPosFase = false
local resumoFase = ""
local msgLoja = ""
local modeIndex = 1
local fpsPresets = { 0, 30, 60, 75, 120, 144, 165, 240 }
local fpsIndex = 1
local frameStart = 0
local fonteTitulo, fonteTexto
local tempoTotal = 0

-- Sprite de moldura do botão e do ícone de dinheiro
local GRADE_MOEDA = [[
..yyyy..
.yyyyyy.
yyyoyyyy
yyyoyyyy
yyyyyyyy
yyyyyyyy
.yyyyyy.
..yyyy..
]]
local PALETA_MOEDA = { y = Cores.amarelo, o = Cores.laranjaEscuro }

local function faseAtual()
	return Fases.get(Economia.getFase())
end

local function corDaFase()
	return Cores.fases[Economia.getFase()] or Cores.laranja
end

local function currentModeIndex()
	local modes = settings.getModes()
	for i, m in ipairs(modes) do
		if m.width == settings.resolution.width and m.height == settings.resolution.height then
			return i
		end
	end
	return 1
end

local function cycleResolution(dir)
	local modes = settings.getModes()
	if #modes == 0 then return end
	modeIndex = (modeIndex - 1 + dir) % #modes + 1
	settings.resolution = { width = modes[modeIndex].width, height = modes[modeIndex].height }
	settings.apply()
end

local function criarObjetos()
	qualidade = Qualidade.new()
	posto = Posto.new(function(resultado)
		local valor = Economia.valorDe(resultado)
		Economia.ganhar(valor)
		qualidade:registrar(resultado, valor)
	end)
	esteira = Esteira.new(function()
		qualidade:perdida()
	end)
end

local function iniciarFase()
	local cfg = faseAtual()
	esteira:configurar(cfg, Economia.esteiraMult())
	posto:configurar(Economia.zonaMult(), Economia.marcadorMult())
	posto:limpar()
	qualidade:reset()
	tempoRestante = cfg.duracao
	estado = "jogando"
end

local function abrirLoja(posFase)
	estado = "loja"
	lojaPosFase = posFase
	msgLoja = ""
	if not posFase then
		resumoFase = ""
	end
end

local function finalizarFase()
	local cfg = faseAtual()
	passouNaFase = qualidade.lucro >= cfg.meta
	posto:limpar()

	if passouNaFase then
		resumoFase = string.format("Meta batida! Você fez R$ %d (meta R$ %d).", qualidade.lucro, cfg.meta)
		if Economia.getFase() >= Fases.total() then
			Economia.save()
			estado = "vitoria"
			return
		end
		Economia.setFase(Economia.getFase() + 1)
	else
		resumoFase = string.format("Meta não batida: R$ %d de R$ %d. Tente de novo.", qualidade.lucro, cfg.meta)
	end

	Economia.save()
	abrirLoja(true)
end

local function comprarPorIndice(n)
	local u = Economia.upgrades[n]
	local ok, motivo = Economia.comprar(u)
	if ok then
		msgLoja = "Comprado: " .. u.nome
	else
		msgLoja = "Não foi possível comprar: " .. motivo
	end
end

local function lojaRect(i)
	local w, h = love.graphics.getWidth(), love.graphics.getHeight()
	local rw = math.min(900, w * 0.6)
	local rh = 60
	local x = (w - rw) / 2
	local y = h * 0.3 + (i - 1) * (rh + 12)
	return x, y, rw, rh
end

-- Substitui o love.run padrão para poder limitar o FPS
function love.run()
	if love.load then love.load(love.arg.parseGameArguments(arg), arg) end
	if love.timer then love.timer.step() end

	return function()
		frameStart = love.timer.getTime()

		if love.event then
			love.event.pump()
			for name, a, b, c, d, e, f in love.event.poll() do
				if name == "quit" then
					if not love.quit or not love.quit() then
						return a or 0
					end
				end
				love.handlers[name](a, b, c, d, e, f)
			end
		end

		local dt = love.timer and love.timer.step() or 0
		if love.update then love.update(dt) end

		if love.graphics and love.graphics.isActive() then
			love.graphics.origin()
			love.graphics.clear(love.graphics.getBackgroundColor())
			if love.draw then love.draw() end
			love.graphics.present()
		end

		if settings.fpsCap > 0 then
			local remaining = 1 / settings.fpsCap - (love.timer.getTime() - frameStart)
			if remaining > 0 then love.timer.sleep(remaining) end
		end
	end
end

function love.load()
	settings.loadModes()
	settings.apply()
	modeIndex = currentModeIndex()

	fonteTitulo = love.graphics.newFont(48)
	fonteTexto = love.graphics.newFont(16)
	love.graphics.setBackgroundColor(Cores.fundo)

	Economia.load()
	criarObjetos()
end

function love.update(dt)
	tempoTotal = tempoTotal + dt
	if estado ~= "jogando" then return end

	esteira:update(dt)
	posto:update(dt)

	tempoRestante = tempoRestante - dt
	if tempoRestante <= 0 then
		tempoRestante = 0
		finalizarFase()
	end
end

-- Fundo: piso quadriculado e faixa colorida no topo com a cor da fase
local function drawFundo()
	local w, h = love.graphics.getWidth(), love.graphics.getHeight()
	local tam = math.max(16, math.floor(h / 30))

	love.graphics.setColor(Cores.fundo)
	love.graphics.rectangle("fill", 0, 0, w, h)

	love.graphics.setColor(Cores.chao[1], Cores.chao[2], Cores.chao[3], 0.5)
	for y = h * 0.8, h, tam do
		for x = 0, w, tam * 2 do
			local deslocamento = ((math.floor(y / tam) % 2) == 0) and 0 or tam
			love.graphics.rectangle("fill", x + deslocamento, y, tam, tam)
		end
	end

	local c = corDaFase()
	love.graphics.setColor(c[1], c[2], c[3], 0.9)
	love.graphics.rectangle("fill", 0, 0, w, 6)
end

-- Botão pixelado com destaque ao passar o mouse
local function desenharBotao(texto, x, y, w, h, destacado)
	local cor = destacado and corDaFase() or Cores.metalEscuro
	Pixel.caixa(x, y, w, h, Cores.preto, cor)
	love.graphics.setColor(destacado and Cores.branco or Cores.cinza)
	love.graphics.printf(texto, x, y + h / 2 - 8, w, "center")
end

local function drawMenu()
	local w, h = love.graphics.getWidth(), love.graphics.getHeight()
	drawFundo()
	local cfg = faseAtual()
	local c = corDaFase()

	love.graphics.setFont(fonteTitulo)
	love.graphics.setColor(c)
	love.graphics.printf("FÁBRICA DE RETROVISORES", 0, h * 0.18, w, "center")

	-- Retrovisor flutuando como logo
	local img = Pixel.obter("retrovisor", [[
....bbbbbbbbbb..
...baaaaaaaaaab.
..baaaaaaaaaaab.
..baaaaaaaaaaab.
..baaaaaaaaaaab.
..baaaaaaaaaaab.
..bbbbbbbbbbbbb.
.....bcccc.......
.....bcccc.......
.....bcccc.......
.....bccccc......
....bbbbbbbb.....
]], { a = Cores.vidro, b = Cores.metal, c = Cores.metalEscuro })
	local escala = 6
	local bob = math.sin(tempoTotal * 2) * 6
	Pixel.desenhar(img, w / 2 - img:getWidth() * escala / 2, h * 0.32 + bob, escala)

	love.graphics.setFont(fonteTexto)
	love.graphics.setColor(Cores.branco)
	love.graphics.printf(
		string.format("Fase %d de %d: %s", Economia.getFase(), Fases.total(), cfg.nome),
		0, h * 0.55, w, "center"
	)
	love.graphics.setColor(Cores.amarelo)
	love.graphics.printf("Dinheiro: R$ " .. Economia.getDinheiro(), 0, h * 0.6, w, "center")

	local bw, bh = 260, 44
	desenharBotao("JOGAR", w / 2 - bw / 2, h * 0.68, bw, bh, true)
	desenharBotao("LOJA (L)", w / 2 - bw / 2, h * 0.68 + 56, bw, bh, false)

	love.graphics.setColor(Cores.cinza)
	love.graphics.printf("DEL: apagar progresso | ESC: sair", 0, h * 0.92, w, "center")
end

local function drawLoja()
	local w, h = love.graphics.getWidth(), love.graphics.getHeight()
	drawFundo()

	love.graphics.setFont(fonteTitulo)
	love.graphics.setColor(corDaFase())
	love.graphics.printf("LOJA", 0, h * 0.05, w, "center")

	love.graphics.setFont(fonteTexto)
	love.graphics.setColor(Cores.amarelo)
	love.graphics.printf("Dinheiro: R$ " .. Economia.getDinheiro(), 0, h * 0.17, w, "center")

	if resumoFase ~= "" then
		love.graphics.setColor(Cores.verde)
		love.graphics.printf(resumoFase, 0, h * 0.21, w, "center")
	end

	for i, u in ipairs(Economia.upgrades) do
		local x, y, rw, rh = lojaRect(i)
		local nivel = Economia.nivel(u.id)

		Pixel.caixa(x, y, rw, rh, Cores.preto, Cores.metalEscuro)

		-- Barra de nível pixelada
		for n = 1, u.max do
			local cor = n <= nivel and Cores.verde or Cores.metalEscuro
			love.graphics.setColor(cor)
			love.graphics.rectangle("fill", x + 14 + (n - 1) * 14, y + 44, 10, 8)
		end

		love.graphics.setColor(Cores.branco)
		love.graphics.print(i .. ". " .. u.nome, x + 14, y + 8)
		love.graphics.setColor(Cores.cinza)
		love.graphics.print(u.desc, x + 14 + 14 * u.max + 10, y + 36)

		local custoTxt = nivel >= u.max and "MÁXIMO" or ("R$ " .. Economia.custo(u))
		love.graphics.setColor(Cores.amarelo)
		love.graphics.printf(custoTxt, x, y + 20, rw - 14, "right")
	end

	local y = h * 0.3 + #Economia.upgrades * 72 + 10
	love.graphics.setColor(Cores.branco)
	love.graphics.printf(msgLoja, 0, y, w, "center")

	local continuar
	if not lojaPosFase then
		continuar = "ENTER: menu"
	elseif passouNaFase then
		continuar = "ENTER: próxima fase"
	else
		continuar = "ENTER: tentar de novo"
	end
	love.graphics.setColor(Cores.cinza)
	love.graphics.printf("1-4 ou clique: comprar | " .. continuar .. " | ESC: menu", 0, h - 40, w, "center")
end

local function drawVitoria()
	local w, h = love.graphics.getWidth(), love.graphics.getHeight()
	drawFundo()

	love.graphics.setFont(fonteTitulo)
	love.graphics.setColor(Cores.amarelo)
	love.graphics.printf("PARABÉNS!", 0, h * 0.25, w, "center")

	love.graphics.setFont(fonteTexto)
	love.graphics.setColor(Cores.branco)
	love.graphics.printf("Você concluiu todas as fases.", 0, h * 0.42, w, "center")
	love.graphics.printf("Dinheiro final: R$ " .. Economia.getDinheiro(), 0, h * 0.47, w, "center")

	love.graphics.setColor(Cores.cinza)
	love.graphics.printf("ENTER ou clique: voltar ao menu", 0, h * 0.6, w, "center")
end

local function drawGame()
	local cfg = faseAtual()
	drawFundo()
	esteira:draw()
	posto:draw()
	qualidade:draw(cfg.meta)

	love.graphics.setFont(fonteTexto)
	love.graphics.setColor(Cores.branco)
	love.graphics.print(string.format("%s | Tempo: %d s", cfg.nome, math.ceil(tempoRestante)), 10, 56)

	local h = love.graphics.getHeight()
	love.graphics.setColor(Cores.cinza)
	love.graphics.print("Clique na peça na zona do POSTO ou ESPAÇO para montar | R: reiniciar fase | ESC: menu", 10, h - 24)
end

local function drawInfo()
	local fpsLabel = settings.fpsCap == 0 and "sem limite" or tostring(settings.fpsCap)
	love.graphics.setFont(fonteTexto)
	love.graphics.setColor(Cores.cinza)
	love.graphics.print(
		string.format(
			"%dx%d | %s | vsync: %s | FPS cap: %s | FPS atual: %d",
			settings.resolution.width,
			settings.resolution.height,
			settings.fullscreen and "tela cheia" or "janela",
			settings.vsync == 1 and "on" or "off",
			fpsLabel,
			love.timer.getFPS()
		),
		10, 10
	)
	love.graphics.print("[ / ]: resolução | F11: tela cheia | V: vsync | F: FPS cap", 10, 30)
end

function love.draw()
	if estado == "menu" then
		drawMenu()
	elseif estado == "loja" then
		drawLoja()
	elseif estado == "vitoria" then
		drawVitoria()
	else
		drawGame()
	end
	drawInfo()
end

function love.mousepressed(x, y, button)
	if button ~= 1 then return end

	if estado == "menu" then
		local w, h = love.graphics.getWidth(), love.graphics.getHeight()
		local bw, bh = 260, 44
		local bx = w / 2 - bw / 2
		if x >= bx and x <= bx + bw then
			if y >= h * 0.68 and y <= h * 0.68 + bh then
				iniciarFase()
			elseif y >= h * 0.68 + 56 and y <= h * 0.68 + 56 + bh then
				abrirLoja(false)
			end
		end

	elseif estado == "loja" then
		for i = 1, #Economia.upgrades do
			local rx, ry, rw, rh = lojaRect(i)
			if x >= rx and x <= rx + rw and y >= ry and y <= ry + rh then
				comprarPorIndice(i)
				return
			end
		end

	elseif estado == "jogando" then
		if posto:ocupado() then
			posto:apertar()
			return
		end
		local index = esteira:pieceAt(x, y)
		if index then
			local p = esteira.pecas[index]
			if p.x >= Posto.ZONA_INI and p.x <= Posto.ZONA_FIM then
				posto:pegar(esteira:take(index))
			end
		end

	elseif estado == "vitoria" then
		Economia.setFase(1)
		estado = "menu"
	end
end

function love.keypressed(key)
	if key == "[" then
		cycleResolution(-1)
		return
	elseif key == "]" then
		cycleResolution(1)
		return
	elseif key == "f11" then
		settings.fullscreen = not settings.fullscreen
		settings.apply()
		Pixel.limparCache()
		return
	elseif key == "v" then
		settings.vsync = settings.vsync == 1 and 0 or 1
		settings.apply()
		return
	elseif key == "f" then
		fpsIndex = fpsIndex % #fpsPresets + 1
		settings.fpsCap = fpsPresets[fpsIndex]
		return
	end

	if estado == "menu" then
		if key == "return" or key == "kpenter" or key == "space" then
			iniciarFase()
		elseif key == "l" then
			abrirLoja(false)
		elseif key == "delete" then
			Economia.resetarTudo()
		elseif key == "escape" then
			love.event.quit()
		end

	elseif estado == "jogando" then
		if key == "escape" then
			estado = "menu"
		elseif key == "space" then
			posto:apertar()
		elseif key == "r" then
			iniciarFase()
		end

	elseif estado == "loja" then
		if key == "escape" then
			estado = "menu"
		elseif key == "return" or key == "kpenter" then
			if lojaPosFase then
				iniciarFase()
			else
				estado = "menu"
			end
		else
			local n = tonumber(key)
			if n and Economia.upgrades[n] then
				comprarPorIndice(n)
			end
		end

	elseif estado == "vitoria" then
		if key == "return" or key == "kpenter" or key == "escape" then
			Economia.setFase(1)
			estado = "menu"
		end
	end
end