load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/cd_string.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/popRemap.ncl"

begin

data_dir  = "/home/zhangc/senariomip_cmip6/"
data_time = "2015-01-01_00:00:00"

ta = addfile(data_dir+"ta_"+data_time+".nc","r")

time = ta->time
lon  = ta->lon
lat  = ta->lat

T = ta->ta
