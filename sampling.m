function particles_geo = sampling(pre_result, numsample, affsig)
particles_geo = repmat(affparam2geom(pre_result(:)), [1,numsample]);
randomnum = randn(6,numsample);
particles_geo = particles_geo + (randomnum).*repmat(affsig(:),[1,numsample]);



