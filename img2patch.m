function [patch_idx, patch_num] = img2patch(psize,xpatch_size, ypatch_size, xstep_size, ystep_size)
BlockX = (psize(2)-xpatch_size)/xstep_size+1;
BlockY = (psize(1)-ypatch_size)/ystep_size+1;
patch_num = BlockX*BlockY;
patch_idx = [];
for i=1:BlockX
    for j=1:BlockY
        temp_patch = zeros(psize(2),psize(1));
        temp_patch((j-1)*ystep_size+1:(j-1)*ystep_size+ypatch_size, (i-1)*xstep_size+1:(i-1)*xstep_size+xpatch_size) = 1;
        temp_idx = find(temp_patch==1);
        patch_idx = [patch_idx; temp_idx];
    end
end
