clc;
clear;
%% parameter setting
setTrackParam;
SC_param.mode = 2;
SC_param.lambda = 0.01;
SC_param.pos = 'ture';
RGBypatch_size = 16;
RGBxpatch_size = 24;
RGBystep_size = 8;
RGBxstep_size = 16;
Tpatch_size = 24;
Tstep_size = 16;
[RGBpatch_idx, RGBpatch_num] = img2patch(psize,RGBxpatch_size, RGBypatch_size, RGBxstep_size,RGBystep_size); 
[Tpatch_idx, Tpatch_num] = img2patch(psize,Tpatch_size, Tpatch_size, Tstep_size,Tstep_size);
duration = 0; tic; 
particles_geo=[0;0];
%% initial tracking
result = [];
initial_tracking; 
RGB_patchdict=reshape(RGB_TemplateDict(RGBpatch_idx,:),RGBypatch_size*RGBxpatch_size,RGBpatch_num*size(RGB_TemplateDict,2));
T_patchdict=reshape(T_TemplateDict(Tpatch_idx,:),Tpatch_size*Tpatch_size,Tpatch_num*size(T_TemplateDict,2));
RGB_patchdict=normalizeMat(RGB_patchdict);
T_patchdict=normalizeMat(T_patchdict);

%% tracking using proposed method
RGB_precoeff=[];
T_tempdict=[];
for i=1:size(T_patchdict,2)
    T_tempdict=[T_tempdict,repmat(T_patchdict(:,i),1,2)];
end
T_dict=T_tempdict;
RGB_reference=RGB_patchdict(:,1:8);
T_reference=T_dict(:,1:8);
templatenum=size(RGB_patchdict,2)/RGBpatch_num;
wsmax=[];
dmax=[];
tgt_diff=[];
com=[];
a1=[];
cons_error=[];
num=[];
RGB_m=0;
prob_dict=zeros(1,templatenum);

for f = str2num(firstframe)+EXEMPLAR_NUM:str2num(firstframe)+frameNum-1
    img_RGB = imread([dataPath 'visible\' num2str(f,'%05d') 'v.jpg']);
    img_T = imread([dataPath 'infrared\' num2str(f,'%05d') 'i.jpg']);
    if size(img_RGB,3)==3
        grayframe = rgb2gray(img_RGB);
    else
        grayframe = img_RGB;
        img_RGB = double(img_RGB)/255;
    end
    RGB_img = double(grayframe)/255;
    if size(img_T,3)==3
        grayframe = rgb2gray(img_T);
    else
        grayframe = img_T;
        img_T = double(img_T)/255;
    end
    T_img = double(grayframe)/255;
    % sampling
    particles_geo = sampling(result(end,:), opt.numsample, opt.affsig);
    RGBcandidates = warpimg(RGB_img, affparam2mat(particles_geo), psize);
    Tcandidates = warpimg(T_img, affparam2mat(particles_geo), psize);
    RGBcandidates = RGBcandidates.*(RGBcandidates>0);
    Tcandidates = Tcandidates.*(Tcandidates>0);
    RGBcandidates = reshape(RGBcandidates,psize(1)*psize(2), opt.numsample);
    Tcandidates = reshape(Tcandidates,psize(1)*psize(2), opt.numsample);
    % cropping patches
    RGBparticles_patches = RGBcandidates(RGBpatch_idx, :);
    Tparticles_patches = Tcandidates(Tpatch_idx, :);
    RGBparticles_patches = reshape(RGBparticles_patches,RGBxpatch_size*RGBypatch_size, RGBpatch_num*opt.numsample);
    Tparticles_patches = reshape(Tparticles_patches,Tpatch_size*Tpatch_size, Tpatch_num*opt.numsample);
    RGB_candi_patch_data= normalizeMat(RGBparticles_patches); 
    T_candi_patch_data= normalizeMat(Tparticles_patches);
    % sparse coding
    RGB_patch_coeff = SparseCoding(RGBpatch_num,RGB_candi_patch_data, RGB_patchdict, SC_param);
    T_patch_coeff = SparseCoding(Tpatch_num,T_candi_patch_data, T_patchdict, SC_param);
    RGB_patch_coeff =full(RGB_patch_coeff );
    T_patch_coeff =full(T_patch_coeff );
    T_tempcoeff=[];
    for i=1:size(T_patch_coeff,1)
        T_tempcoeff=[T_tempcoeff;repmat(T_patch_coeff(i,:),2,1)];
    end
    Tex_patch_coeff=T_tempcoeff;
    if isempty(RGB_precoeff) 
        RGB_ds=zeros(1,opt.numsample);
        T_ds=zeros(1,opt.numsample);
        RGB_d=zeros(1,opt.numsample);
        T_d=zeros(1,opt.numsample);
    else
        RGB_d=pdist2(RGB_precoeff',RGB_patch_coeff','cosine');
        T_d=pdist2(T_precoeff',Tex_patch_coeff','cosine');
        RGB_m=mean(RGB_d);
        T_m=mean(T_d);
        RGB_d=normalizeMat(RGB_d);
        T_d=normalizeMat(T_d);
        RGB_g=gmdistribution(RGB_m,0.1);
        T_g=gmdistribution(T_m,0.1);
        RGB_ds=pdf(RGB_g, RGB_d')';
        T_ds=pdf(T_g, T_d')';
    end
    [RGB_er , T_er , W_m ,W_s] = Recons_error(RGB_reference, T_reference,  RGB_patch_coeff, Tex_patch_coeff , opt.numsample , RGBpatch_num , RGB_patchdict, T_dict );
    error=RGB_er+T_er+0.104*W_m+0.8*RGB_ds+0.8*T_ds;
    [v,id]=sort(error);
    if isempty(RGB_precoeff) 
        RGB_precoeff=RGB_patch_coeff(:,id(1));
        T_precoeff=Tex_patch_coeff(:,id(1));
    end
    pre_particle_geo=particles_geo(:,id(1));
    
    %% template update
    if RGB_m>0.15
        RGB_precoeff=RGB_patch_coeff(:,id(1));
        T_precoeff=Tex_patch_coeff(:,id(1));
        if RGB_m>0.4&&RGB_m<0.5&& (RGB_ds(id(1))+T_ds(id(1)))<0.8&&W_m(id(1))<8
            RGB_target= warpimg(RGB_img, affparam2mat(pre_particle_geo), psize);
            RGB_target=reshape(RGB_target,psize(1)*psize(2), 1);
            RGB_target=RGB_target.*(RGB_target>0);
            RGB_target=reshape(RGB_target(RGBpatch_idx,:),RGBypatch_size*RGBxpatch_size,RGBpatch_num);
            RGB_target=normalizeMat(RGB_target);
            T_target= warpimg(T_img, affparam2mat(pre_particle_geo), psize);
            T_target=reshape(T_target,psize(1)*psize(2), 1);
            T_target=T_target.*(T_target>0);
            T_target=reshape(T_target(Tpatch_idx,:),Tpatch_size*Tpatch_size,Tpatch_num);
            T_target=normalizeMat(T_target);
            temp_target=[];
            RGB_reference=RGB_target;
            attenuation =1/templatenum;
            prob_dict=attenuation*prob_dict+(W_s(:,id(1)).^-1)'*reshape(T_precoeff,RGBpatch_num,templatenum);
            [ v ,dict_id ]=min(flip(prob_dict(2:templatenum)));
            dict_id = templatenum - dict_id + 1 ;
            [f dict_id ]
            prob_dict(dict_id )=min(prob_dict(find(prob_dict~=0)));
            RGB_patchdict(:,(dict_id-1)*RGBpatch_num+1:dict_id*RGBpatch_num)=RGB_target;
            T_patchdict(:,(dict_id-1)*Tpatch_num+1:dict_id*Tpatch_num)=T_target;
            for i=1:size(T_target,2)
                temp_target=[temp_target,repmat(T_target(:,i),1,2)];
            end
            T_reference=temp_target;
        end
    end
  
    %% draw result
    result = [result; affparam2mat(pre_particle_geo)']; 
    drawopt = drawtrackresult(drawopt,GT,firstframe, f, img_RGB, psize, result(end,:)',particles_geo);
    imwrite(frame2im(getframe(gcf)),sprintf('result/%s/Result/%05d.jpg',title,f));
end

% duration = duration + toc;      
% fprintf('%d frames took %.3f seconds : %.3ffps\n',f,duration,f/duration);
% fps = f/duration;
