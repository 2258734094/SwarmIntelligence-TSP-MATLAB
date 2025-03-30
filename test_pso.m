% 测试PSO求解器的主程序

% 1. 生成测试数据
numCities = 20;  % 设置城市数量
% 随机生成城市坐标，范围[0,100]
cityCoords = rand(numCities, 2) * 100;

% 2. 设置PSO参数
params = struct(...
    'numParticles', 50, ...   % 粒子数量
    'maxIter', 200, ...       % 最大迭代次数
    'w', 0.9, ...            % 初始惯性权重
    'c1', 2, ...             % 个体学习因子
    'c2', 2);                % 社会学习因子

% 3. 创建并运行PSO求解器
solver = PSO_Solver(cityCoords, params);
[bestRoute, bestFitness, history] = solver.optimize();

% 4. 可视化结果
figure;  % 创建新图窗

% 4.1 绘制最优路径
subplot(1,2,1);  % 创建子图1
% 绘制路径，'b-o'表示蓝色线条加圆圈标记
plot(cityCoords(bestRoute,1), cityCoords(bestRoute,2), 'b-o');
title('最优路径');  % 设置标题
grid on;  % 显示网格

% 4.2 绘制收敛曲线
subplot(1,2,2);  % 创建子图2
plot(1:length(history), history);
title('收敛曲线');
xlabel('迭代次数');  % X轴标签
ylabel('路径长度');  % Y轴标签
grid on;

% 5. 输出最优结果
fprintf('最优路径长度: %.2f\n', bestFitness); 