# Run this in ./src
csv=./designseeds-v3.csv
dataname=designseeds-v3

mkdir ../data
mkdir ../data/${dataname}
mkdir ../data/${dataname}/trainvalset
dataset_path=../data/${dataname}/trainvalset/original
mkdir ${dataset_path}

trainset_path=../data/${dataname}/trainset
valset_path=../data/${dataname}/valset
mkdir ${valset_path}
mkdir ${valset_path}/original

# Data directory structure , ex) dataname=designseeds-v3
# 
# ./src/designseeds-v3.csv
# ./data
#   |
#   |-- designseeds-v3 
#			|
#			|-- trainset
# 			|		|-- original
#			|		|-- hueShift
#			|		|-- preproc
#			|		|-- preproc-288x432
#			|
#			|-- valset
# 					|-- original
#					|-- hueShift
#					|-- preproc
#					|-- preproc-288x432


# Download images
# python -u 01-design-seeds-download.py --csv ${csv} --dataset_path ${dataset_path}  2>&1 | tee 01.log

# Split validation set from the dataset.
# python -u 02-trainvalSplit.py --dataset_path ${dataset_path} --dataset_val_path ${valset_path}/original 2>&1 | tee 02.log
# mv ${dataset_path} ${trainset_path}/original # Rename trainvalset to trainset
rm -rf ../data/${dataname}/trainvalset


######## valset
dataset_path=${valset_path}/original
dataset_hueShift_path=${valset_path}/hueShift
dataset_preproc_path=${valset_path}/preproc
dataset_resize_path=${valset_path}/preproc-288x432

#python -u 04-data2img-palette.py --dataset_path ${dataset_path} --dataset_preproc_path ${dataset_preproc_path} 2>&1 | tee 04.log
#python -u 05-resizeDataset.py --dataset_path ${dataset_preproc_path}  --dataset_resize_path ${dataset_resize_path} 2>&1 | tee 05.log
python -u 03-hueShiftData.py --paletteset_path ${dataset_preproc_path} --dataset_path ${dataset_resize_path}  --dataset_hueshift_path ${dataset_hueShift_path} 2>&1 | tee 03.log

######## trainset
dataset_path=${trainset_path}/original
dataset_hueShift_path=${trainset_path}/hueShift
dataset_preproc_path=${trainset_path}/preproc
dataset_resize_path=${trainset_path}/preproc-288x432

#python -u 04-data2img-palette.py --dataset_path ${dataset_path} --dataset_preproc_path ${dataset_preproc_path} 2>&1 | tee 04.log
#python -u 05-resizeDataset.py --dataset_path ${dataset_preproc_path}  --dataset_resize_path ${dataset_resize_path} 2>&1 | tee 05.log
#python -u 03-hueShiftData.py --paletteset_path ${dataset_preproc_path} --dataset_path ${dataset_resize_path}  --dataset_hueshift_path ${dataset_hueShift_path} 2>&1 | tee 03.log
