function [ W_m,W_s,W_ss,A ] = Model_consis(  RGB_coeff, T_coeff ,numsample,RGBpatch_num )
W_temp=[];
RGB_temp=[];
sigma=0.2;
Q=[1,-1,0,0,0,0,0,0
    0,1,-1,0,0,0,0,0
    0,0,1,-1,0,0,0,0
    0,0,0,0,1,-1,0,0
    0,0,0,0,0,1,-1,0
    0,0,0,0,0,0,1,-1
    1,0,0,0,-1,0,0,0
    0,1,0,0,0,-1,0,0
    0,0,1,0,0,0,-1,0
    0,0,0,1,0,0,0,-1];
W_diff=RGB_coeff-T_coeff;

for j=1:RGBpatch_num
    W_temp=[W_temp;sum(W_diff(j:RGBpatch_num:size(W_diff),:))];
    RGB_temp=[RGB_temp;sum(RGB_coeff(j:RGBpatch_num:size(RGB_coeff),:))];
end

W_s=exp(-1*W_temp/(2*sigma));
W_ss=sum(W_s);
A=sum(Q*RGB_temp);
A=exp(-1*A/(2*sigma));
A_mean=mean(A);
gmm1=gmdistribution(A_mean,0.3);
A=pdf(gmm1, A')';
W_m=W_ss-0.6*A;
end

