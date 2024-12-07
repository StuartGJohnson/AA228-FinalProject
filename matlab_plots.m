load policy_2cp_1200_hist.mat
figure(); histogram(policy2cp1200stats.mapchecks,'Normalization','probability')
title('Probability of occurence of MapCheck count during route')
ylabel('Prob')
xlabel('MapCheck count')
print -dpng MapCheckHist.png

figure(); histogram(policy2cp1200stats.steps,'Normalization','probability')
title('Probability of occurence of route steps')
xlabel('Step count (minimum is 18)')
ylabel('Prob')
print -dpng RouteStepsHist.png

sum(policy2cp1200stats.steps>18*2.0)/1000
sum(policy2cp1200stats.steps>18*1.5)/1000

load policy_2cp_1200_hist.mat
fah = double(array_hist);
figure();imagesc(fah'/sum(fah(:)))
% add start and finish
% Draw a red square
rectangle('Position', [8.5, 9.5, 1, 1], 'FaceColor', 'red', 'EdgeColor', 'none');
% Draw a green square
rectangle('Position', [9.5, 9.5, 1, 1], 'FaceColor', 'green', 'EdgeColor', 'none');

text(3-0.4,7,'CP2','Color', 'yellow', 'FontSize', 11)
text(7-0.4,3,'CP1','Color', 'yellow', 'FontSize', 11)

axis('xy')
colorbar()
axis('equal')
axis off
title('Frequency of true position at MapCheck')
print -dpng MapCheckPosition.jpg
