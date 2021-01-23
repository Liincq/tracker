function [ RGB_er , T_er , W_m ,W_s] = Recons_error(RGB_reference, T_reference,  RGB_coeff, T_coeff , numsample , RGBpatch_num , RGB_patchdict, T_dict )
    [ W_m,W_s ,W_ss,A ]=Model_consis(  RGB_coeff, T_coeff ,numsample,RGBpatch_num );
    RGB_er1=sum(RGB_reference,2)-RGB_patchdict*RGB_coeff;
    RGB_er2=sum(RGB_patchdict(:,1:8),2)-RGB_patchdict*RGB_coeff;
    RGB_er=sum(RGB_er1.*RGB_er1)+0.6*sum(RGB_er2.*RGB_er2);
    T_er1=sum(T_reference,2)-T_dict*T_coeff;
    T_er2=sum(T_dict(:,1:8),2)-T_dict*T_coeff;
    T_er=sum(T_er1.*T_er1)+0.6*sum(T_er2.*T_er2);
end

