
require 'nn'
require 'nngraph'
require 'image'
require 'cunn'
require 'cudnn'
require 'optim'

cmd = torch.CmdLine()
cmd:text()
cmd:text('Train Colorization model.')
cmd:text()
cmd:text('Options')

cmd:option('-dataset', 'designseeds-v3-train.t7', 'prepDataset: dataset.t7 input required')

cmd:option('-model_name', '', 'will save checkpoints in checkpoints/model_name/ ')
cmd:option('-img_h', 288, 'image height')
cmd:option('-img_w', 432, 'image width')

cmd:option('-palette_space', 'lab', 'give palette info in rgb|lab space')
cmd:option('-norm_input_output', true, 'pre and de process images in -1~+1. Use TanH at output of G')


cmd:text()

opt = cmd:parse(arg or {})
print(opt)


display = require 'display'

require 'model'
local utils = require 'src.utils'


-- Batch
local imgBatch = {} -- imgBatch.input ,GT, res , batchsize

assert(opt.dataset ~= '', 'give argument of -dataset')

imgBatch = torch.load(opt.dataset)
print(imgBatch.name .. ' dataset loaded, # of imgs:' .. imgBatch.imgNum)
print('method: '..imgBatch.method)

batchsize = 200 --opt.batchsize
imgBatch.batchsize = batchsize  -- opt.batchsize
imgBatch.res = {288, 432}
res = imgBatch.res
-- print(imgBatch.res)


local TrainBatchMethod = {loadpath = imgBatch.method,
							loadPaletteOnly = true,  -- Load palette only. Do not load imgs
							res = imgBatch.res,  -- unrelated
							crop = nil ,--unrelated
							do_resize = false, --unrelated
							augmentation = true, -- unrelated
							labcache = false,--  opt.labcache,
							palette_space = 'lab' --  opt.palette_space
						}
imgBatch.batchmethod = TrainBatchMethod

local noise_dim = 10
local palette_num = 6
local palette_dim  = palette_num * 3
local PalG_input_dim = noise_dim + palette_num + palette_dim

PalG = definePaletteG(noise_dim, palette_num)
PalD = definePaletteD(palette_num)

thetaPalG, gradThetaPalG = PalG:getParameters()
thetaPalD, gradThetaPalD = PalD:getParameters()

local iter_start = 1
local iter_end = 2000000



-- =============
-- Define loss function and feval functions
-- ============
local fliplabel = true
real_label = fliplabel and 0 or 1
fake_label = fliplabel and 1 or 0
loss1 = nn.AbsCriterion():cuda()
advloss = nn.BCECriterion():cuda()
-- ================
-- Generator loss1 and loss2
-- ===============
opt.PalG_advloss = true
opt.PalG_loss1 = true
opt.PalG_lambda = 1

-- ======= ADAM hyperparameters =======
local optim_statePalG = {
	learningRate = 0.0002,
	beta1 = 0.5,
}
local optim_statePalD = {
	learningRate = 0.0002,
	beta1 = 0.5,
}


local ErrPalDReal, ErrPalDFake, ErrPalDTotal
local PalG_hint, PalG_input, PalG_GT, PalG_output
-- ======= feval ===================
-- Discriminator : PalD
-- =============
feval_PalD_ = function(thetaPalD)
	-- TODO bias to zero???
	gradThetaPalD:zero()

	-- Discriminator trained on real_palette
	local output = PalD:forward(PalG_GT) -- PalG_GT as real_palette
	local label = torch.FloatTensor(output:size()):fill(real_label):cuda()

	ErrPalDReal = advloss:forward(output, label)
	local df_do = advloss:backward(output, label)
	PalD:backward(PalG_GT, df_do)

	-- Discriminator trained on fake_palette
	local output = PalD:forward(PalG_output) -- PalG_output as fake_palette
	label:fill(fake_label)
	ErrPalDFake = advloss:forward(output, label)
	local df_do = advloss:backward(output, label)
	PalD:backward(PalG_output, df_do)

	ErrPalDTotal = (ErrPalDReal + ErrPalDFake)/2
end
feval_PalD = function () return ErrPalDTotal, gradThetaPalD end


-- Generator : PalG
-- =============

feval_PalG_ = function(thetaPalG)
	gradThetaPalG:zero()
	-- advloss

	local df_dg = torch.zeros(PalG_output:size()):cuda()
	if opt.PalG_advloss then
		local output = PalD.output -- just computed in feval_PalD
		local label = torch.FloatTensor(output:size()):fill(real_label):cuda()
		ErrPalGadvloss  = advloss:forward(output, label) -- compute gradient of fake_output to real_label
		local df_do = advloss:backward(output, label)
		df_dg = PalD:updateGradInput(PalG_output, df_do) -- this adversarial gradient will update to Generator
	else
		ErrPalGadvloss = 0
	end

	-- loss1
	local dJ_dh_x = torch.zeros(PalG_output:size()):cuda()
	if opt.PalG_loss1 then
		ErrPalGloss1 = loss1:forward(PalG_output, PalG_GT)
		dJ_dh_x = loss1:backward(PalG_output, PalG_GT)
	else
		ErrPalGloss1 = 0
	end

	-- Total loss
	PalG:backward(PalG_input, df_dg +  dJ_dh_x:mul(opt.PalG_lambda))
end
feval_PalG = function () return Err_PalG_advloss, gradThetaPalG end
-- TODO J should be Err_PalG_advloss + opt.PalG_lambda * Err_PalG_loss1?

-- ===========================
-- Loss checking
-- ========================
ErrPalGloss1_log = loaded_log or {} -- TODO rename loaded log
ErrPalGadvloss_log = loaded_lossADVlog or {}
ErrPalDReal_log = loaded_ErrRlog or  {}
ErrPalDFake_log = loaded_ErrFlog or {}
ErrPalDTotal_log = loaded_lossDlog or  {}

plotconfig_ErrPalGloss1 = {
	win = 11,
	title = 'lambda : '..opt.PalG_lambda ..  ' / PalG loss output : iter / batchsize '..batchsize,
	labels = {'iter','loss1'},
	ylabels = 'ratio'
}
plotconfig_ErrPalGadvloss = {
	win=13,
	title = 'loss G',
	labels = {'iter','advloss'},
	ylabels = 'ratio'
}
plotconfig_ErrPalDReal = {
	win=14,
	title = 'Error D Real',
	labels = {'iter','Err'},
	ylabels = 'ratio'
}
plotconfig_ErrPalDFake = {
	win=15,
	title = 'Error D Fake',
	labels = {'iter','Err'},
	ylabels = 'ratio'
}
plotconfig_ErrPalDTotal = {
	win=12,
	title = 'Total Error D',
	labels = {'iter','Err'},
	ylabels = 'ratio'
}
-- =======================
-- Visualization
-- =====================

local winIdx = 0
local pad_w = 5
local set_w = 3* math.floor(res[1]/6) + pad_w -- 2 palettes
local visImgSet = torch.Tensor(3, res[1], 7 * set_w  ):fill(0) -- 5 for boundary
function Visualize(iter)
	local img_PalG_hint_palette = utils.genImgPalette(PalG_hint[1]:double(), lock[1]:double(), hint[1]:double() )
	local img_PalG_GT_palette = utils.genImgPalette(PalG_GT[1]:double())
	local img_PalG_output_palette = utils.genImgPalette(PalG_output[1]:double())
	local vis_img = img_PalG_hint_palette
	vis_img = torch.cat(vis_img, img_PalG_output_palette, 3)
	vis_img = torch.cat(vis_img, img_PalG_GT_palette, 3)
	vis_img = torch.cat(vis_img, torch.Tensor(3, res[1], pad_w):fill(0), 3)
	vis_img = vis_img:clamp(0,1)
	visImgSet[{{}, {}, {set_w*winIdx+1 , set_w*(winIdx+1) }}]	= vis_img:clone() -- copy vis_img to index
	display.image(visImgSet , {win=10, title=winIdx..': iter '..iter}) -- gcd(20,7) = 1
	winIdx = (winIdx + 1)%7

end

-- ======================
-- Training
-- =====================
for iter = iter_start, iter_end do
	utils.setBatch(imgBatch, nil, TrainBatchMethod) -- changed

	local noise = torch.Tensor(batchsize, noise_dim):normal(0, 0.1) -- Define noise in norm(0, 0.1) as vector of (batchsize, 10)
	-- ==========
	-- lock : desired fix value
	-- hint : including lock. but if not locked color is added with noise
	-- ==========
	-- For Ex)
	-- GT		 	5		7		8		6		9
	-- lock 	 	0		1 		1		0		0
	-- hint			1		1		1		0		0
	-- noise 		0.1		0.2		-0.1	0.3		-0.2
	-- noise_ 		0.1		0		0		0		0     -- Applied only on hint
	-- inputlocked	0		7		8		0		0
	-- inputhint	5.1		7		8		0		0
	-- ==========
	-- dataset palette is (batchsize, 18)
	-- add noise to palette
	-- or either lock palette
	-- ==========
	lock = torch.ByteTensor(batchsize, palette_num):bernoulli(0.1) -- n x 6
	hint = torch.ByteTensor(batchsize, palette_num):bernoulli(0.1) -- n x 6
	hint:maskedFill(lock, 1)

	local lock_temp = lock:view(batchsize * palette_num, 1)
	local lock_lab = torch.cat({lock_temp, lock_temp, lock_temp}):resize(batchsize, palette_num*3) -- n x 18
	local hint_temp = hint:view(batchsize * palette_num, 1)
	local hint_lab = torch.cat({hint_temp, hint_temp, hint_temp}):resize(batchsize, palette_num*3) -- n x 18

	local palette_GT = imgBatch.input2:clone():double()
	local palette_hint = palette_GT:clone()
	palette_hint:maskedFill(1 - hint_lab, 0) -- n x 18
	local palette_noise = palette_GT:clone():normal(0, 0.05)
	palette_noise:maskedFill(1 - hint_lab, 0) -- noise only on unlocked and unhint
	palette_noise:maskedFill(lock_lab, 0)
	palette_hint = palette_hint + palette_noise


	PalG_hint = palette_hint
	PalG_input = torch.cat({noise, lock:double(), palette_hint}):cuda() -- batchsize x (10+6+18)
	PalG_GT = palette_GT:cuda()

	-- ===== Forward Pass to generate fake_output
	PalG_output = PalG:forward(PalG_input)
	-- Compute discriminator loss
	feval_PalD_()
	-- compute  generator loss
	feval_PalG_()

	-- Optimize D first then G
	optim.adam(feval_PalD, thetaPalD, optim_statePalD) -- prints loss before backward
	optim.adam(feval_PalG, thetaPalG, optim_statePalG) -- prints loss before backward

	table.insert(ErrPalGloss1_log, {iter , ErrPalGloss1})
	table.insert(ErrPalGadvloss_log, {iter , ErrPalGadvloss})
	table.insert(ErrPalDReal_log, {iter , ErrPalDReal})
	table.insert(ErrPalDFake_log, {iter , ErrPalDFake})
	table.insert(ErrPalDTotal_log, {iter , ErrPalDTotal})

	if iter%500 == 1 then
		print(iter..'loss1 : '..ErrPalGloss1)
		plotconfig_ErrPalGloss1.win = display.plot(ErrPalGloss1_log, plotconfig_ErrPalGloss1)
		plotconfig_ErrPalGadvloss.win = display.plot(ErrPalGadvloss_log, plotconfig_ErrPalGadvloss)
		plotconfig_ErrPalDReal.win = display.plot(ErrPalDReal_log, plotconfig_ErrPalDReal)
		plotconfig_ErrPalDFake.win = display.plot(ErrPalDFake_log, plotconfig_ErrPalDFake)
		plotconfig_ErrPalDTotal.win = display.plot(ErrPalDTotal_log, plotconfig_ErrPalDTotal)
		Visualize(iter)
	end
end






