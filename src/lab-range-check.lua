require 'image'

n = 100

range = torch.linspace(0,1,n)
rgb_image = torch.Tensor(3,1,n*n*n):fill(0)

for r = 1,n  do
	for g = 1,n  do
		for b = 1,n  do
			-- print(range[r])
			-- print(r..g..b)
			-- to_fill = rgb_image[{{}, 1, { (r-1)*n*n + (g-1)*n + (b-1)} + 1 }] 
			-- to_fill = rgb_image[{{}, {1}, { (r-1)*n*n + (g-1)*n + (b-1) + 1 }}] 
			-- print(#to_fill)
			-- = torch.Tensor{1,1,1}
			rgb_image[{{}, {1}, { (r-1)*n*n + (g-1)*n + (b-1) + 1 }}] = torch.Tensor{range[r],range[g],range[b]}:view(3,1,1)
		end
	end
end

lab_iamge = image.rgb2lab(rgb_image)
print(lab_iamge[1]:min())
print(lab_iamge[1]:max())
print(lab_iamge[2]:min())
print(lab_iamge[2]:max())
print(lab_iamge[3]:min())
print(lab_iamge[3]:max())
