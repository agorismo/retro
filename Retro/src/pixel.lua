-- Desenha sprites pixel art a partir de grades de texto.
-- Cada caractere é um pixel; a letra indica a cor na paleta passada.
local Pixel = {}

local cache = {}

-- Converte uma grade em uma imagem reutilizável (feita uma vez só)
function Pixel.criar(grade, paleta)
	local linhas = {}
	for linha in grade:gmatch("[^\n]+") do
		linhas[#linhas + 1] = linha
	end

	local altura = #linhas
	local largura = 0
	for _, l in ipairs(linhas) do
		largura = math.max(largura, #l)
	end

	local dados = love.image.newImageData(largura, altura)
	for y, l in ipairs(linhas) do
		for x = 1, #l do
			local c = l:sub(x, x)
			local cor = paleta[c]
			if cor then
				dados:setPixel(x - 1, y - 1, cor[1], cor[2], cor[3], cor[4] or 1)
			end
		end
	end

	local img = love.graphics.newImage(dados)
	img:setFilter("nearest", "nearest")
	return img
end

-- Desenha um sprite ampliado por "escala" (ex.: 4 = cada pixel vira 4x4)
function Pixel.desenhar(img, x, y, escala, flip)
	escala = escala or 1
	local sx = flip and -escala or escala
	local ox = flip and img:getWidth() or 0
	love.graphics.draw(img, x + ox * escala, y, 0, sx, escala)
end

-- Retângulo com cantos de 1 pixel, no estilo pixel art
function Pixel.caixa(x, y, w, h, cor, borda)
	love.graphics.setColor(cor)
	love.graphics.rectangle("fill", x, y, w, h)
	if borda then
		love.graphics.setColor(borda)
		love.graphics.rectangle("line", x + 0.5, y + 0.5, w - 1, h - 1)
	end
end

-- Cache por nome, para não recriar sprites a cada frame
function Pixel.obter(nome, grade, paleta)
	if not cache[nome] then
		cache[nome] = Pixel.criar(grade, paleta)
	end
	return cache[nome]
end

function Pixel.limparCache()
	cache = {}
end

return Pixel