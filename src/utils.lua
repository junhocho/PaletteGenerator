require 'image'
cjson = require 'cjson'

local M = {}

function gtAB_inputLA0B0_pair(imgPath, batchmethod)

	local res = batchmethod.res
	local w_img = res[2] -- 96 -- 288 -- 96 -- 384
	local h_img = res[1] -- 96 -- 288 -- 96 -- 384

	-- local img = image.lena() --jh: Too BIG Mistake. Never loaded different image.
	local img, labimg
	if batchmethod.labcache then
		local labPath = imgPath:gsub('.jpg','.t7')
		img = torch.load(labPath) -- cache rgb2lab of imgPath for speedup
	else
		img = image.load(imgPath)
	end
	local c = img:size(1)
	local h = img:size(2)
	local w = img:size(3)

	-- Augmentation
	if batchmethod.augmentation == true and torch.rand(1)[1] < 0.5 then
		img = image.hflip(img)
	end

	-- For design seeds
	if h > w then
		img = img:transpose(2,3)
		h = img:size(2)
		w = img:size(3)
	end

	if c == 1 then
		img = image.lena()
		print("load BW image. load Lena instead")
	elseif w < w_img or h < h_img then
		img = image.lena()
		print("Image has too low resolution. Load Lena istead")
	end


	if not batchmethod.crop then
		img = img
	else
		img = M.crop(img, res, batchmethod.crop)
	end

	if batchmethod.labcache then
		labimg = img
	else
		labimg = image.rgb2lab(img)
	end

	if batchmethod.do_resize then
		img = image.scale(img, res[2], res[1])
		labimg = image.scale(labimg, res[2], res[1])
	end


	local AB = labimg[{{2,3},{},{}}]:clone()
	local LA0B0 = labimg[{{2,3},{},{}}]:fill(0)
	-- local A0B0 = AB:clone():fill(0)

	-- debugger.enter()
	-- display.image(BW)
	-- display.image(img)
	return AB , labimg
end

-- This is for recolorize task. LAB can be hueShifted image.
function gtAB_inputLAB_pair(GTimgPath,  batchmethod)

	local res = batchmethod.res
	local w_img = res[2] -- 96 -- 288 -- 96 -- 384
	local h_img = res[1] -- 96 -- 288 -- 96 -- 384

	-- imgPath : /path/to/image/Flora/1-abcdef+280.jpg
	-- +280 can be anything +0 ~ + 240 step of 20
	local hue = string.match(GTimgPath, "+%d+.")
	local source_hue
	if batchmethod.source_orig then
		source_hue = 0
	else
		source_hue = math.random(0,17)*20  -- Source Hue is picked random.
	end


	-- print('target hue :'..hue..' / source hue :'..source_hue)
	local imgPath_input1 = GTimgPath:gsub(hue, "+"..source_hue..".")

	local img, labimg, img_input1, LAB_input1
	if batchmethod.labcache then
		local labPath = GTimgPath:gsub('.jpg','.t7')
		local labPath_input1 = imgPath_input1:gsub('.jpg','.t7')
		img = torch.load(labPath) -- cache rgb2lab of imgPath for speedup
		img_input1 = torch.load(labPath_input1)
	else
		img = image.load(GTimgPath)
		img_input1 = image.load(imgPath_input1)
	end
	local c = img:size(1)
	local h = img:size(2)
	local w = img:size(3)

	-- Augmentation
	if batchmethod.augmentation == true and torch.rand(1)[1] < 0.5 then
		img = image.hflip(img)
		img_input1 = image.hflip(img_input1)
	end

	-- For design seeds
	if h > w then
		img = img:transpose(2,3)
		img_input1 = img_input1:transpose(2,3)
		h = img:size(2)
		w = img:size(3)
	end

	if c == 1 then
		-- img = image.lena()
		-- print("load BW image. load Lena instead")
		error('image has only one channel.')
	elseif w < w_img or h < h_img then
		-- img = image.lena()
		-- print("Image has too low resolution. Load Lena istead")
		error("Image has too low resolution")
	end

	if not batchmethod.crop then
		img = img
	else
		img, Xmin, Ymin = M.crop(img, res, batchmethod.crop)
		img_input1 = M.crop(img, res, {Xmin, Ymin})
	end

	if batchmethod.do_resize then
		img = image.scale(img, res[2], res[1])
		img_input1 = image.scale(img_input1, res[2], res[1])
	end

	if batchmethod.labcache then
		GT_LAB = img
		Source_LAB = img_input1
	else
		GT_LAB = image.rgb2lab(img)
		Source_LAB = image.rgb2lab(img_input1)
	end
	local GT_AB = GT_LAB[{{2,3},{},{}}]	-- local L = labimg[1]

	return GT_AB , Source_LAB --GT, input1
end


-- This is for recolorize task. LAB can be hueShifted image.
function gtLAB_dummy_pair(GTimgPath, batchmethod)

	local res = batchmethod.res
	local w_img = res[2] -- 96 -- 288 -- 96 -- 384
	local h_img = res[1] -- 96 -- 288 -- 96 -- 384

	-- imgPath : /path/to/image/Flora/1-abcdef+280.jpg
	local hue = string.match(GTimgPath, "+%d+.")
	assert(hue == '+00.', 'this is not original image')

	local img  -- TODO remove labimg useless param
	if batchmethod.labcache then
		local labPath = GTimgPath:gsub('.jpg','.t7')
		img = torch.load(labPath) -- cache rgb2lab of imgPath for speedup
	else
		img = image.load(GTimgPath)
	end
	local c = img:size(1)
	local h = img:size(2)
	local w = img:size(3)

	-- Augmentation
	if batchmethod.augmentation == true and torch.rand(1)[1] < 0.5 then
		img = image.hflip(img)
	end

	-- For design seeds
	if h > w then
		img = img:transpose(2,3)
		h = img:size(2)
		w = img:size(3)
	end

	if c == 1 then
		error('image has only one channel.')
	elseif w < w_img or h < h_img then
		error("Image has too low resolution")
	end

	if batchmethod.do_resize then
		img = image.scale(img, res[2], res[1])
	end
	
	if batchmethod.labcache then
		GT_LAB = img
	else
		GT_LAB = image.rgb2lab(img)
	end
	-- display.image(GT_LAB)
	-- print(#GT_LAB)
	-- local GT_AB = GT_LAB[{{2,3},{},{}}]	-- local L = labimg[1]
	return GT_LAB, GT_LAB:clone():fill(0)  --GT, dummy input
end




-- crop `img` with (res_x, res_y). If res_y not given crop with (res_x, res_x)
function M.crop(img, res, cropmethod)
	local w_img = res[2] -- res_x
	local h_img = res[1] -- res_y or res_x
	local h = img:size(2)
	local w = img:size(3)
	local Xmin, Ymin
	if cropmethod == 'rand' then
		Xmin = math.floor(torch.uniform(0,w - w_img))
		Ymin = math.floor(torch.uniform(0,h - h_img))
	elseif cropmethod == 'center' then
		Xmin = (w - w_img) / 2
		Ymin = (h - h_img) / 2
	elseif type(cropmethod) == 'table'  then
		assert(#cropmethod==2, 'table should be size of 2 of x,y coordinate')
		Xmin = math.floor(cropmethod[1])
		Ymin = math.floor(cropmethod[2])
		assert(Xmin < w - w_img, 'Xmin should be less than '..w-w_img.." but got "..Xmin.." instead.")
		assert(Ymin < h - h_img, 'Ymin should be less than '..h-h_img.." but got "..Ymin.." instead.")
	else
		error('not prpoer crop_method: '..cropmethod)
	end

	local Xmax = Xmin + w_img
	local Ymax = Ymin + h_img
	local img = image.crop(img, Xmin, Ymin, Xmax, Ymax)
	return img, Xmin, Ymin
end

-- indices : either nil or table of indices {1,2,3,4}. If nil, random minibatch, if indices, load images
-- 	of given indices
-- method is table of { loadpath = nil|'anno', crop = nil|center|'rand'|{x,y}, augmentation = true|false }
function M.setBatch(B, indices)
	local batchmethod = B.batchmethod
	local inputImg_paths = {}
	-- if indices given, set batch with indices or random minibatch selection
	local assignIdx
	if indices then
		assert(#indices == B.batchsize, 'indices of setBatch has to be same size of batchsize')
		assignIdx = function (i) return indices[i] end
	else
		assignIdx = function () return  math.random(1, B.imgNum) end -- math.floor(torch.uniform(1, B.imgNum + 1)) end
	end

	-- ================================== 
	-- Palette  Batch
	-- =================================
	if batchmethod.loadpath == 'anno' then
		local imgidx = assignIdx(1)  -- math.floor(torch.uniform(1, B.imgNum + 1))
		inputImg_paths[1] = paths.concat(B.path, B.annotation[imgidx].img_path) -- 1 to imgNum
		if batchmethod.palette_space == 'rgb' then
			B.input2 = torch.cat(B.annotation[imgidx].palette):view(1,18)
			for i = 2, B.batchsize do
				local imgidx = assignIdx(i) -- math.floor(torch.uniform(1, B.imgNum + 1))
				inputImg_paths[i] = paths.concat(B.path,B.annotation[imgidx].img_path) -- 1 to imgNum
				local p
				p = torch.cat(B.annotation[imgidx].palette):view(1,18)
				B.input2 = torch.cat(B.input2, p, 1)
			end
			B.input2 = B.input2:cuda()/255.0 -- ubyute by python preprocess
		elseif batchmethod.palette_space == 'lab' then
			B.input2 = torch.cat(B.annotation[imgidx].palette_lab):view(1,18)
			for i = 2, B.batchsize do
				local imgidx = assignIdx(i) -- math.floor(torch.uniform(1, B.imgNum + 1))
				inputImg_paths[i] = paths.concat(B.path,B.annotation[imgidx].img_path) -- 1 to imgNum
				local p
				p = torch.cat(B.annotation[imgidx].palette_lab):view(1,18)
				B.input2 = torch.cat(B.input2, p, 1)
			end
			-- print(B.input2)
			-- print(B.input2:view(B.batchsize, 6, 1, 3):permute(1,4,3,2))
			if opt.norm_input_output then 
				M.preprocess(B.input2:view(B.batchsize, 6, 1, 3):permute(1,4,3,2)) --B.input2:view(B.batchsize, 3, 1, 6))
				B.input2 = B.input2:view(B.batchsize, 18):cuda()
			end
			-- print(B.input2)
			-- print('----;;;;')
		end
		assert(B.input2:numel() == 18*B.batchsize, 'palette input size is wrong')
		-- print(B.input2)
	else
		for i = 1, B.batchsize do
			local imgidx = assignIdx(i) -- math.floor(torch.uniform(1, B.imgNum + 1))
			-- print('imgidx: ' .. imgidx) -- debug
			inputImg_paths[i] = B.imgPaths[imgidx] -- 1 to imgNum
		end
	end

	-- ================================== 
	-- Images Batch
	-- B.GT   &  B.input
	-- =================================
	if not batchmethod.loadPaletteOnly then 
		local GT, input -- input is BW
		local h, w, input_c, gt_c

		local task  = B.task  --'lab'
		local get_pair
		if task  == 'recolorize' then -- TODO rename colorspace to opt.task
			get_pair = gtAB_inputLAB_pair
			input_c = 3
			gt_c = 2
		elseif task  == 'colorize' then
			get_pair = gtAB_inputLA0B0_pair
			input_c = 3 -- now add AB channel filled with 0
			gt_c = 2
		elseif task == 'discrimate' then
			get_pair = gtLAB_dummy_pair
			input_c = 3
			gt_c = 3
		else
			error('unknow task: '..task)
		end
		-- local pair_method =  {augmentation = method.augmentaion, crop = method.crop , labcache = method.labcache}
		GT, input = get_pair(inputImg_paths[1],  batchmethod)

		h = GT:size(2)
		w = GT:size(3) -- input size is same

		B.GT = GT:clone():view(1, gt_c, h, w)
		-- if task == 'discrimate' then display.image(B.GT[1]) end
		B.input = input:clone():view(1, input_c, h , w)

		for i=2, B.batchsize do -- concat to SRPatch and LRPatch
			GT, input = get_pair(inputImg_paths[i],  batchmethod)

			B.GT = torch.cat(B.GT,  GT:clone():view(1, gt_c, h, w), 1)
			B.input= torch.cat(B.input, input:clone():view(1, input_c, h, w), 1)
			-- print(inputImg_paths[i]) -- debug
		end
		B.GT = B.GT:cuda()
		B.input= B.input:cuda()
	end
	return inputImg_paths
end


function M.prepImageNetClass(ImageNetPath, classname)
	local imgPaths = {}
	local imgNum = 0
	local dir = classname
	if not classname then dir = 'n01560419' end
	print(dir)
	local c = 1
	for file in paths.iterfiles(paths.concat(ImageNetPath, dir)) do
		-- if c > 1300 then break end
		local imPath = paths.concat(ImageNetPath, dir, file)
		local img = image.load(imPath)
		if img:size(1) == 3 and img:size(2) > 288 and img:size(3) > 288 then  -- TODO global resolution
			imgNum = imgNum + 1
			imgPaths[imgNum] = imPath
			c = c+1
			print(imgNum)
		end
		-- print(dir)
	end
	return imgPaths, imgNum
end


function M.prepImageNet(ImageNetPath)
	local imgPaths = {}
	local imgNum = 0
	for dir in paths.iterdirs(ImageNetPath) do
		local c = 1
		for file in paths.iterfiles(paths.concat(ImageNetPath, dir)) do
			if c > 100 then break end
			local imPath = paths.concat(ImageNetPath, dir, file)
			local img = image.load(imPath)
			if img:size(1) == 3 and img:size(2) > 288 and img:size(3) > 288 then  -- TODO global resolution
				imgNum = imgNum + 1
				imgPaths[imgNum] = imPath
				c = c+1
				print(imgNum)
			end
			-- print(dir)
		end
	end
	return imgPaths, imgNum
end

function M.prepPlaces(PlacesPath)
	local imgPaths = {}
	local imgNum = 0
	print('places2')
	for dir in paths.iterdirs(PlacesPath) do
		for dir2 in paths.iterdirs(paths.concat(PlacesPath, dir)) do
			local c = 1
			for file in paths.iterfiles(paths.concat(PlacesPath, dir, dir2)) do
				if c > 100 then break end
				local imPath = paths.concat(PlacesPath, dir, dir2, file)
				local img = image.load(imPath)
				if img:size(1) == 3 and img:size(2) == 256 and img:size(3) == 256 then  -- TODO global resolution
					imgNum = imgNum + 1
					imgPaths[imgNum] = imPath
					c = c+1
					print(imgNum, imPath)
				end
				-- print(dir)
			end
		end
	end
	return imgPaths, imgNum
end

function M.prepDataset(datasetPath)
	local imgPaths = {}
	local imgNum = 0
	local c = 0
	for file in paths.iterfiles(datasetPath) do
		c = c + 1
		local imPath = paths.concat(datasetPath, file)
		imgPaths[c] = imPath
		print(c , imPath)
	end
	imgNum = c
	return imgPaths, imgNum
end


function M.read_json(path)
	local file = io.open(path, 'r')
	local text = file:read()
	file:close()
	local info = cjson.decode(text)
	return info
end


function M.write_json(path, j)
	cjson.encode_sparse_array(true, 2, 10)
	local text = cjson.encode(j)
	local file = io.open(path, 'w')
	file:write(text)
	file:close()
end

function M.getAnnotation(json_path)
	local file = io.open(json_path, 'r')
	local text = file:read()
	file:close()
	local gt = cjson.decode(text)
	-- gt['2'].color_pallete['1'].b

	-- print(gt['2'])
	-- print(#gt)

	local annotation = {}
	local c = 1
	for k,v in pairs(gt) do
		k = tonumber(k)
		annotation[k] = {}
		annotation[k].img_path = v.img_path

		local palette = {}
		local palette_lab = {}
		for k2, v2 in pairs(v.color_palette) do  -- pallete : Typo of palette when dumping from python code. Fix here
			local rgb = torch.DoubleTensor{tonumber(v2.r), tonumber(v2.g), tonumber(v2.b)}
			palette[tonumber(k2)] = rgb
			-- palette_lab[tonumber(k2)] = image.rgb2lab(rgb:view(3,1,1)):view(3)
		end

		for k2, v2 in pairs(v.color_palette_lab) do  -- pallete : Typo of palette when dumping from python code. Fix here
			local lab = torch.DoubleTensor{tonumber(v2.l), tonumber(v2.a), tonumber(v2.b)}
			palette_lab[tonumber(k2)] = lab
		end

		annotation[k].palette = palette
		annotation[k].palette_lab = palette_lab
		c = c+1
	end
	return annotation
end

local L_min = 0
local L_max = 100
local a_min = -86.181257511044
local a_max = 98.235151439515
local b_min = -107.86174725207
local b_max = 94.475781784008

function M.preprocess(labimg)
	assert(labimg:dim()==4, 'labimg should be form of dim-4 batch of imgs, not'..labimg:dim())

	local L,a,b
	if labimg:size(2) == 3 then
		L = labimg[{ {}, {1} , {} , {}  }]
		a = labimg[{ {}, {2} , {} , {}  }]
		b = labimg[{ {}, {3} , {} , {}  }]
		L:mul(2):add(-L_min):add(-L_max):mul(1/(L_max - L_min))
	elseif labimg:size(2) == 2 then
		a = labimg[{ {}, {1} , {} , {}  }]
		b = labimg[{ {}, {2} , {} , {}  }]
	else
		error('wrong dim : ' ..labimg:size(1))
	end
	a:mul(2):add(-a_min):add(-a_max):mul(1/(a_max - a_min))
	b:mul(2):add(-b_min):add(-b_max):mul(1/(b_max - b_min))

	-- min <= x <= max    -->   -1 <= y <= 1
	-- y = (2*x - min - max)/(max - min )

	return labimg
end

function M.preprocess_pxl(pxl) -- pxl size : (n, 18)
	assert(pxl:dim()==1, 'labimg should be form of dim-1 batch of imgs, not'..pxl:dim())
	assert(pxl:size()==18, 'pxl is not 6 colors')

	local L,a,b
	L = pxl[1]
	a = pxl[2]
	b = pxl[3]
	L:mul(2):add(-L_min):add(-L_max):mul(1/(L_max - L_min))
	a:mul(2):add(-a_min):add(-a_max):mul(1/(a_max - a_min))
	b:mul(2):add(-b_min):add(-b_max):mul(1/(b_max - b_min))

	-- min <= x <= max    -->   -1 <= y <= 1
	-- y = (2*x - min - max)/(max - min )

	return pxl
end

function M.deprocess(lab_norm)
	assert(lab_norm:dim()==3, 'labimg should be form of dim-3 batch of imgs, not'..lab_norm:dim())

	--   -1 <= y <= 1  -->  min <= x <= max
	-- x = ( (max - min)*y + min + max )/2
	lab_norm[1]:mul( L_max - L_min ):add(L_min):add(L_max):mul(0.5)
	lab_norm[2]:mul( a_max - a_min ):add(a_min):add(a_max):mul(0.5)
	lab_norm[3]:mul( b_max - b_min ):add(b_min):add(b_max):mul(0.5)

	return lab_norm
end

function M.genImgPalette(palette, lock, hint) -- palette is (1,18) 
	-- lock, hint is optional. (1,6)
	local raw_palette = palette:squeeze()
	local h = math.floor(opt.img_h/6)
	local w = h -- math.floor(opt.img_h/6)

	local h_blank = opt.img_h%6

	assert(raw_palette:numel() == 18, 'palette seems not 18-dim vector ')
	colors = {}
	for i = 1,6 do
		local temp  = raw_palette[{{3*i-2,3*i}}]
		-- print(temp)
		-- temp = temp:repeatTensor(h,w,1)
		-- temp = temp:permute(3,1,2) -- temp:size() is (3,72,72)
		temp = temp:view(3,1,1)
		if opt.norm_input_output then
			M.deprocess(temp)
		end
		if opt.palette_space == 'lab' then
			temp = image.lab2rgb(temp)
		end
		local c = temp:repeatTensor(1,h,w):clone()
		if hint and hint[i]==1 then -- color yellow
			c[{{},{},{w}}]:fill(0)
			c[{{1},{},{w}}]:fill(1)
			c[{{2},{},{w}}]:fill(1)
		end
		if lock and lock[i]==1 then -- color red
			c[{{},{},{w}}]:fill(0)
			c[{{1},{},{w}}]:fill(1)
		end
		colors[i] = c
	end
	local img_palette = colors[1]
	for i = 2,6 do
		img_palette = torch.cat(img_palette, colors[i], 2)
	end

	if h_blank > 0 then
		local img_blank = torch.Tensor(3, h_blank, w):fill(1)
		img_palette = torch.cat(img_palette, img_blank, 2)
	end
	return img_palette
end

return M
