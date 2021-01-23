function [ coeff ] = SparseCoding( patch_num ,patch_data, patch_dict,SC_param )
coeff=[];
tempcoeff=[];
for i=0:patch_num-1
    coeff0=mexLasso(patch_data(:,1+i:patch_num:size(patch_data,2)) ,patch_dict(:,1+i:patch_num:size(patch_dict,2)) ,SC_param);
    coeff=[coeff;coeff0];
end
templatenum=size(patch_dict,2)/patch_num;
for i=1:templatenum
    tempcoeff=[tempcoeff;coeff(i:templatenum:size(coeff,1),:)];
end
coeff=tempcoeff;

