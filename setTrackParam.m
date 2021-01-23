% setTrackParam 
%% *************************************************************
% title = 'afterrain'; 
% title = 'aftertree';

%% *************************************************************
dataPath = ['F:/tracking dataset/newRGBT234/' title '/'];
frames = dir([dataPath 'visible\*.jpg']);
firstframe = frames(1).name(1:5);
frameNum = size(dir([dataPath 'visible\*.jpg']),1);
GT=load(['F:/tracking dataset/newRGBT234/' title '/visible.txt']);
%% *************************************************************
switch (title)           %affsig = [center_x center_y width rotation aspect_ratio skew]     
    case 'afterrain'; p = [156 75 24 45 0.0]; % 
        EXEMPLAR_NUM = 6;
        opt = struct('numsample', 500, 'affsig',[4,5,0.0008,0.0,0.01,0]);
        aff = [1, 1, .0001, 0.0001, .0001, 0.00001];
        samp_num = 10; 

    case 'aftertree'; p = [404 83 20 46 0.0]; 
        EXEMPLAR_NUM = 5;
        opt = struct('numsample', 600, 'affsig', [4,4,0.006,0.0,0.0005,0]);
        aff =[0.00001, 0.01, .0001, 0, .0001, 0];
        samp_num = 10;
        
    
    otherwise  
        error(['unknown title ' title]);
end

psize = [40, 40];
param0 = [p(1), p(2), p(3)/psize(1), p(5), p(4)/p(3), 0]';   
param0 = affparam2mat(param0); 

if ~isdir(['result\' ,title])
    mkdir('result\',title);
end
if ~isdir(['result\' ,title,'\Dict'])
    mkdir(['result\' ,title,'\Dict']);
end
if ~isdir(['result\' ,title,'\Result'])
    mkdir(['result\' ,title,'\Result']);
end