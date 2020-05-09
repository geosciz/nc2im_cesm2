begin

data_path = "/home/zhangc/cesm2_cmip6/im_data/"

ta = addfile(data_path+"ta.nc","r")
hus = addfile(data_path+"hus.nc","r")
sh = addfile(data_path+"phis.nc","r")

t3 = ta->ta
q3 = hus->hus

ps = ta->ps
p0 = ta->p0
hyam = ta->a
hybm = ta->b
hyai = ta->a_bnds
hybi = ta->b_bnds

phis = sh->PHIS

p3 = pres_hybrid_ccm(ps,p0,hyam,hybm)
print(dimsizes(p3))

tv = t3*(1.+q3*0.61)
print(dimsizes(tv))

z3 = cz2ccm(ps,phis,tv,p0,hyam,hybm,hyai(:,1),hybi(:,1))
print(dimsizes(z3))

end
