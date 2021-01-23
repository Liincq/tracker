% simple tracking and collecting tracking results as templates
exemplars_stack = [];
%% read first frame
img_RGB = imread([dataPath 'visible\' firstframe 'v.jpg']);
img_T = imread([dataPath 'infrared\' firstframe 'i.jpg']);
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

RGB_TemplateDict=[];
T_TemplateDict=[];
RGB_template = warpimg(RGB_img, param0, psize);
T_template = warpimg(T_img, param0, psize);
RGB_template = RGB_template.*(RGB_template>0);
T_template = T_template.*(T_template>0);
RGB_TemplateDict=[RGB_TemplateDict,RGB_template(:)];
T_TemplateDict=[T_TemplateDict,T_template(:)];
drawopt=[];
rank1=zeros(1,opt.numsample);
rank2=zeros(1,opt.numsample);
%% simple tracking
for f = str2num(firstframe) : str2num(firstframe)+EXEMPLAR_NUM-1
    
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
    param.param0 = zeros(6,samp_num);
    param.param = zeros(6,samp_num);
    param.param0 = repmat(affparam2geom(param0), [1,samp_num]);
    rng('default');
    randMatrix = randn(6,samp_num); 
    param.param = param.param0 + randMatrix.*repmat(aff(:),[1,samp_num]);
    param.param0 = affparam2mat(param.param);
    RGB_wimgs = warpimg(RGB_img, param.param0, psize);
    T_wimgs = warpimg(T_img, param.param0, psize);
    RGB_wimgs =RGB_wimgs .*(RGB_wimgs>0 );
    T_wimgs =T_wimgs .*(T_wimgs >0);
    RGB_samp_img = reshape(RGB_wimgs, psize(1)*psize(2),samp_num);
    T_samp_img = reshape(T_wimgs, psize(1)*psize(2),samp_num);
    if f==str2num(firstframe)
        exemplars_stack=[RGB_TemplateDict';RGB_samp_img'];
    else
        dis=pdist2(param0',param.param0','euclidean');
        [v,idx]=max(dis);
        exemplars_stack=[exemplars_stack;RGB_samp_img(:,idx)'];
        RGB_TemplateDict=[RGB_TemplateDict ,RGB_samp_img(:,idx)];
        T_TemplateDict=[T_TemplateDict ,T_samp_img(:,idx)];
        result = [result; param0'];
    end
    exem_mean =mean(exemplars_stack);
    
    % PCA GMM
    [pca_coeff, pca_score, pca_latent]=pca(exemplars_stack);
    pca_mean = mean(pca_score);
    pca_cov=cov(pca_score);
    gmm = gmdistribution(pca_mean, pca_cov);
    particles_geo = sampling(param0', opt.numsample, aff);
    candidates = warpimg(RGB_img, affparam2mat(particles_geo), psize);
    candi_data = reshape(candidates, psize(1)*psize(2), opt.numsample);
    candi_data = candi_data.*(candi_data>0);
    candi_data0 = candi_data'-exem_mean;
    candi_pca = candi_data0*pca_coeff;
    pro = pdf(gmm, candi_pca);
    [v,idx] = max(pro);
    param0=affparam2mat(particles_geo(:,idx));
    T_temp_candi=warpimg(T_img, param0, psize);
    T_temp_candi = reshape(T_temp_candi, psize(1)*psize(2), 1);
    T_temp_candi = T_temp_candi.*(T_temp_candi>0);
    RGB_TemplateDict=[RGB_TemplateDict ,candi_data(:,idx)];
    T_TemplateDict=[T_TemplateDict , T_temp_candi];
    drawopt = drawtrackresult(drawopt,GT, firstframe,f, img_RGB, psize, param0,particles_geo); %
    pause(0.5);
end
    result = [result; param0'];