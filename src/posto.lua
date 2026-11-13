local Pixel = require("src.pixel")
local Cores = require("src.cores")

local Posto = {}
Posto.__index = Posto

Posto.ZONA_INI = 0.4
Posto.ZONA_FIM = 0.55

local PERFEITO_BASE = 0.08
local OK_BASE = 0.2
local VEL_MARCADOR = 4
local DELAY_RESULTADO = 0.8

local CORES_RESULTADO = {
	perfeito = Cores.verde,
	ok = Cores.amarelo,
	defeito = Cores.vermelho,
}

function Posto.new(onConcluido)
	local self = setmetatable({
		onConcluido = onConcluido,
		zonaMult = 1,
		marcadorMult = 1,
	}, Posto)
	self:limpar()
	return self
end

function Posto:configurar(zonaMult, marcadorMult)
	self.zonaMult = zonaMult
	self.marcadorMult = marcadorMult
end

function Posto:limpar()
	self.peca = nil
	self.tempo = 0
	self.tempoFinal = 0
	self.parado = false
	self.resultado = nil
end

function Posto:ocupado()
	return self.peca ~= nil
end

function Posto:pegar(peca)
	if self.peca then
		return false
	end
	self:limpar()
	self.peca = peca
	return true
end

function Posto:marcador()
	return 0.5 + 0.5 * math.sin(self.tempo * VEL_MARCADOR * self.marcadorMult)
end

function Posto:apertar()
	if not self.peca or self.parado then
		return
	end
	self.parado = true
	local dist = math.abs(self:marcador() - 0.5)
	if dist <= PERFEITO_BASE * self.zonaMult then
		self.resultado = "perfeito"
	elseif dist <= OK_BASE then
		self.resultado = "ok"
	else
		self.resultado = "defeito"
	end
end

function Posto:update(dt)
	if not self.peca then
		return
	end
	if not self.parado then
		self.tempo = self.tempo + dt
	else
		self.tempoFinal = self.tempoFinal + dt
		if self.tempoFinal >= DELAY_RESULTADO then
			local r = self.resultado
			self:limpar()
			if self.onConcluido then
				self.onConcluido(r)
			end
		end
	end
end

-- Estação pixelada: bancada, luz de status e painel do minijogo
function Posto:draw()
	local w, h = love.graphics.getWidth(), love.graphics.getHeight()
	local x1 = self.ZONA_INI * w
	local x2 = self.ZONA_FIM * w
	local beltY = h * 0.5
	local faixaY = beltY - h * 0.15
	local faixaH = h * 0.3

	-- Área da estação
	love.graphics.setColor(Cores.chao[1], Cores.chao[2], Cores.chao[3], 0.6)
	love.graphics.rectangle("fill", x1, faixaY, x2 - x1, faixaH)
	love.graphics.setColor(Cores.laranja)
	love.graphics.rectangle("line", x1, faixaY, x2 - x1, faixaH)

	-- Luz de status no topo da estação
	local cor = self.peca and Cores.amarelo or Cores.cinza
	if self.parado and self.resultado then
		cor = CORES_RESULTADO[self.resultado]
	end
	love.graphics.setColor(cor)
	love.graphics.rectangle("fill", x1 + 8, faixaY + 8, 10, 10)

	love.graphics.setColor(Cores.branco)
	love.graphics.print("POSTO", x1 + 26, faixaY + 6)

	if not self.peca then
		return
	end

	-- Painel do minijogo
	local pw, ph = math.max(320, w * 0.35), 90
	local px, py = (w - pw) / 2, h * 0.78
	Pixel.caixa(px, py, pw, ph, Cores.preto, Cores.laranja)

	love.graphics.setColor(Cores.branco)
	local instrucao = self.parado and ("Resultado: " .. self.resultado)
		or "Pressione ESPAÇO ou clique na zona verde"
	love.graphics.printf(instrucao, px, py + 8, pw, "center")

	local bx, by = px + 20, py + 40
	local bw, bh = pw - 40, 16

	Pixel.caixa(bx, by, bw, bh, Cores.metalEscuro, Cores.metal)

	-- Zona aceitável (amarela)
	love.graphics.setColor(Cores.amarelo)
	love.graphics.rectangle("fill", bx + bw * (0.5 - OK_BASE), by, bw * OK_BASE * 2, bh)

	-- Zona perfeita (verde), afetada pelo upgrade
	local perf = PERFEITO_BASE * self.zonaMult
	love.graphics.setColor(Cores.verde)
	love.graphics.rectangle("fill", bx + bw * (0.5 - perf), by, bw * perf * 2, bh)

	-- Marcador pixelado
	love.graphics.setColor(Cores.branco)
	love.graphics.rectangle("fill", bx + bw * self:marcador() - 3, by - 4, 6, bh + 8)
end

return Posto