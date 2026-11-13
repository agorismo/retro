local Pixel = require("src.pixel")
local Cores = require("src.cores")

local Esteira = {}
Esteira.__index = Esteira

-- Proporções em relação à tela, para funcionar em qualquer resolução
local BELT_Y_RATIO = 0.5
local BELT_H_RATIO = 0.05
local PIECE_W_RATIO = 0.06
local PIECE_H_MULT = 1.6
local MISSED_LIMIT = 1.05

-- Sprite do retrovisor (16x12): 'a' = vidro, 'b' = moldura, 'c' = suporte
local GRADE_RETROVISOR = [[
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
]]

local PALETA_RETROVISOR = {
	a = Cores.vidro,
	b = Cores.metal,
	c = Cores.metalEscuro,
}

-- Textura da esteira: cada faixa de 4 pixels é um padrão repetido
local GRADE_ESTEIRA = [[
ccccccccccccccccccccccccccccccccc
dddddddddddddddddddddddddddddddd
]]

local PALETA_ESTEIRA = {
	c = Cores.esteira,
	d = Cores.esteiraLinha,
}

function Esteira.new(onMissed)
	local self = setmetatable({ onMissed = onMissed }, Esteira)
	self:configurar({
		intervalo = 1.5,
		velocidadeBase = 0.1,
		velocidadeMax = 0.25,
		aceleracao = 0.002,
	}, 1)
	self.tempoAnim = 0
	return self
end

-- cfg: parâmetros da fase; mult: multiplicador de lentidão dos upgrades
function Esteira:configurar(cfg, mult)
	self.intervalo = cfg.intervalo
	self.velocidadeBase = cfg.velocidadeBase * mult
	self.velocidadeMax = cfg.velocidadeMax * mult
	self.aceleracao = cfg.aceleracao * mult
	self:reset()
end

function Esteira:reset()
	self.pecas = {}
	self.timer = 0
	self.tempoDecorrido = 0
	self.velocidade = self.velocidadeBase
	self.tempoAnim = 0
end

function Esteira:update(dt)
	self.tempoDecorrido = self.tempoDecorrido + dt
	self.velocidade = math.min(
		self.velocidadeMax,
		self.velocidadeBase + self.tempoDecorrido * self.aceleracao
	)
	self.tempoAnim = self.tempoAnim + dt

	self.timer = self.timer + dt
	if self.timer >= self.intervalo then
		self.timer = self.timer - self.intervalo
		table.insert(self.pecas, { x = 0 })
	end

	for i = #self.pecas, 1, -1 do
		local p = self.pecas[i]
		p.x = p.x + self.velocidade * dt
		if p.x > MISSED_LIMIT then
			table.remove(self.pecas, i)
			if self.onMissed then
				self.onMissed()
			end
		end
	end
end

function Esteira:beltGeometry()
	local w, h = love.graphics.getWidth(), love.graphics.getHeight()
	local beltH = math.max(20, h * BELT_H_RATIO)
	local beltY = h * BELT_Y_RATIO
	return w, h, beltY, beltH
end

function Esteira:rect(p)
	local w, _, beltY, beltH = self:beltGeometry()
	local pieceW = w * PIECE_W_RATIO
	local pieceH = beltH * PIECE_H_MULT
	return p.x * w, beltY - (pieceH - beltH) / 2, pieceW, pieceH
end

function Esteira:pieceAt(mx, my)
	for i, p in ipairs(self.pecas) do
		local x, y, pw, ph = self:rect(p)
		if mx >= x and mx <= x + pw and my >= y and my <= y + ph then
			return i
		end
	end
	return nil
end

function Esteira:take(index)
	return table.remove(self.pecas, index)
end

function Esteira:draw()
	local w, _, beltY, beltH = self:beltGeometry()

	-- Suportes da esteira (pernas pixeladas)
	love.graphics.setColor(Cores.metalEscuro)
	for x = 0, w, w / 8 do
		love.graphics.rectangle("fill", x, beltY + beltH, 8, beltH * 0.6)
	end

	-- Corpo da esteira com rolagem animada
	local tamPixel = math.max(2, math.floor(beltH / 6))
	local deslocamento = math.floor(self.tempoAnim * self.velocidade * w / tamPixel) % 8
	love.graphics.setColor(Cores.esteira)
	love.graphics.rectangle("fill", 0, beltY, w, beltH)
	love.graphics.setColor(Cores.esteiraLinha)
	for x = -deslocamento * tamPixel, w, tamPixel * 8 do
		love.graphics.rectangle("fill", x, beltY, tamPixel * 2, beltH)
	end

	-- Bordas metálicas da esteira
	love.graphics.setColor(Cores.metal)
	love.graphics.rectangle("fill", 0, beltY, w, tamPixel)
	love.graphics.setColor(Cores.metalEscuro)
	love.graphics.rectangle("fill", 0, beltY + beltH - tamPixel, w, tamPixel)

	-- Peças com sprite de retrovisor
	local img = Pixel.obter("retrovisor", GRADE_RETROVISOR, PALETA_RETROVISOR)
	for _, p in ipairs(self.pecas) do
		local x, y, pw, ph = self:rect(p)
		local escala = math.max(1, math.floor(pw / img:getWidth()))
		local px = x + (pw - img:getWidth() * escala) / 2
		local py = y + (ph - img:getHeight() * escala) / 2
		love.graphics.setColor(1, 1, 1)
		Pixel.desenhar(img, px, py, escala)
	end
end

return Esteira