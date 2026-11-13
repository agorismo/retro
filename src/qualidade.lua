local Pixel = require("src.pixel")
local Cores = require("src.cores")

local Qualidade = {}
Qualidade.__index = Qualidade

local CORES = {
	perfeito = Cores.verde,
	ok = Cores.amarelo,
	defeito = Cores.vermelho,
}

function Qualidade.new()
	local self = setmetatable({}, Qualidade)
	self:reset()
	return self
end

function Qualidade:reset()
	self.perfeitos = 0
	self.ok = 0
	self.defeitos = 0
	self.perdidas = 0
	self.lucro = 0
	self.historico = {}
end

function Qualidade:registrar(resultado, valor)
	if resultado == "perfeito" then
		self.perfeitos = self.perfeitos + 1
	elseif resultado == "ok" then
		self.ok = self.ok + 1
	else
		self.defeitos = self.defeitos + 1
	end
	self.lucro = self.lucro + valor
	table.insert(self.historico, 1, resultado)
	if #self.historico > 10 then
		table.remove(self.historico)
	end
end

function Qualidade:perdida()
	self.perdidas = self.perdidas + 1
end

-- Painel estilo terminal industrial
function Qualidade:draw(meta)
	local w = love.graphics.getWidth()
	local pw, ph = 260, 200
	local px, py = w - pw - 10, 60

	Pixel.caixa(px, py, pw, ph, Cores.preto, Cores.laranja)

	love.graphics.setColor(Cores.laranja)
	love.graphics.print("CONTROLE DE QUALIDADE", px + 12, py + 10)

	love.graphics.setColor(Cores.branco)
	love.graphics.print("Perfeitos: " .. self.perfeitos, px + 12, py + 36)
	love.graphics.print("OK: " .. self.ok, px + 12, py + 56)
	love.graphics.print("Defeitos: " .. self.defeitos, px + 12, py + 76)
	love.graphics.print("Perdidas: " .. self.perdidas, px + 12, py + 96)

	love.graphics.setColor(Cores.amarelo)
	love.graphics.print("Lucro: R$ " .. self.lucro .. " / meta R$ " .. meta, px + 12, py + 122)

	for i, r in ipairs(self.historico) do
		love.graphics.setColor(CORES[r])
		love.graphics.rectangle("fill", px + 12 + (i - 1) * 22, py + 160, 16, 16)
	end
end

return Qualidade