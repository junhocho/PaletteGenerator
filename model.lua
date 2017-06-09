-- Author: Junho Cho
local nn = require 'nn'

require 'cunn'
require 'cudnn' -- jh : cudnn.version check

local activation = nn.ELU

function definePaletteG(noise_dim, palette_num)
	-- 34 - 24 - 20 - 10 - 10 - 18
	-- Input dim = noise + palette =  10 (normal noise)  + 6 (binary) + 18 (lab) = 34
	local palette_dim = palette_num * 3
	local input_dim = noise_dim + palette_num + palette_dim
	local layer1_dim = 24
	local layer2_dim = 20
	local layer3_dim = 10
	local layer4_dim = 10
	local output_dim = palette_dim

	local palG = nn.Sequential()
	palG:add(nn.Linear(input_dim, layer1_dim))
	palG:add(activation())
	palG:add(nn.Linear(layer1_dim, layer2_dim))
	palG:add(activation())
	palG:add(nn.Linear(layer2_dim, layer3_dim))
	palG:add(activation())
	palG:add(nn.Linear(layer3_dim, layer4_dim))
	palG:add(activation())
	palG:add(nn.Linear(layer4_dim, output_dim))
	palG:add(nn.Tanh())

	--TODO  Residual for lock/hint
	-- palG
	-- input = - nn.Identity()
	--
	-- palG = nn.gModule({input}, {d5})


	for k,v in pairs(palG:findModules('nn.Linear')) do
		v.bias:zero()
		v.weight:normal(0.0, 0.02)
	end
	palG:cuda()
	return palG
end

function definePaletteD(palette_num) -- 18 - 10 - 10 -1
	local palette_dim = palette_num * 3
	local layer1_dim = 10
	local layer2_dim = 10
	local output_dim = 1

	local palD = nn.Sequential()
	palD:add(nn.Linear(palette_dim, layer1_dim))
	palD:add(activation())
	palD:add(nn.Linear(layer1_dim, layer2_dim))
	palD:add(activation())
	palD:add(nn.Linear(layer2_dim, output_dim))
	palD:add(nn.Sigmoid())
	for k,v in pairs(palD:findModules('nn.Linear')) do
		v.bias:zero()
		v.weight:normal(0.0, 0.02)
	end
	palD:cuda()
	return palD
end

