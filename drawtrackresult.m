function [drawopt,p] = drawtrackresult(drawopt,GT,firstframe, fno, frame, sz, param_mat,particles_geo)

if (isempty(drawopt))
  figure('position',[400 100 size(frame,2) size(frame,1)]); clf;                               
  set(gcf,'DoubleBuffer','on','MenuBar','none');
  colormap('gray');

  drawopt.curaxis = [];
  drawopt.curaxis.frm  = axes('position', [0.00 0 1.00 1.0]);
end

curaxis = drawopt.curaxis;
axes(curaxis.frm);      
imagesc(frame, [0,1]); 
rectangle('Position',GT(fno-str2num(firstframe)+1,:),'EdgeColor','b','LineWidth',2);
hold on;    

p = drawbox(sz, param_mat, 'Color','r', 'LineWidth',1.5);

text(10, 15, '#', 'Color','y', 'FontWeight','bold', 'FontSize',24);
text(30, 15, num2str(fno), 'Color','y', 'FontWeight','bold', 'FontSize',24);

axis equal tight off;
hold off;
drawnow;