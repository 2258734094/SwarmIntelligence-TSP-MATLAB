% 全面测试可视化模块的各项功能
clc;
clear;
close all;

%% 1. 基础测试准备
fprintf('=== 开始可视化模块测试 ===\n');

% 1.1 生成测试数据
fprintf('\n1.1 生成测试数据...\n');
numCities = 20;  % 城市数量
cityCoords = DataInput.generateRandomData(numCities, [0, 100]);
fprintf('已生成%d个城市的坐标数据\n', numCities);

% 1.2 创建可视化对象
fprintf('\n1.2 创建可视化对象...\n');
vis = Visualization(cityCoords);
fprintf('可视化对象创建成功\n');

% 1.3 初始化收敛数据
fprintf('\n1.3 初始化收敛数据...\n');
vis.convergenceData = zeros(1, 100);  % 预分配足够大的数组

%% 2. 测试不同类型的路径更新

% 2.1 测试随机路径
fprintf('\n2.1 测试随机路径更新...\n');
fprintf('将显示5个随机路径，每个持续1秒...\n');

for i = 1:5
    randomRoute = randperm(numCities);
    % 计算路径长度
    routeCoords = cityCoords(randomRoute,:);
    diffs = diff([routeCoords; routeCoords(1,:)], 1, 1);
    fitness = sum(sqrt(sum(diffs.^2, 2)));
    
    vis.updateRoute(randomRoute, i, fitness);
    pause(1);  % 暂停1秒
    fprintf('显示第%d个随机路径，路径长度：%.2f\n', i, fitness);
end

% 2.2 测试模拟优化过程
fprintf('\n2.2 测试模拟优化过程...\n');
fprintf('将模拟50次迭代的优化过程...\n');

% 初始化
currentRoute = randperm(numCities);
bestFitness = inf;
numIterations = 50;

% 模拟优化过程
for i = 1:numIterations
    % 随机交换两个城市
    if rand < 0.5
        swapIdx = randperm(numCities, 2);
        newRoute = currentRoute;
        newRoute(swapIdx) = newRoute(fliplr(swapIdx));
        
        % 计算新路径长度
        routeCoords = cityCoords(newRoute,:);
        diffs = diff([routeCoords; routeCoords(1,:)], 1, 1);
        newFitness = sum(sqrt(sum(diffs.^2, 2)));
        
        % 如果更好则接受新路径
        if newFitness < bestFitness
            currentRoute = newRoute;
            bestFitness = newFitness;
            fprintf('第%d次迭代，找到更优解：%.2f\n', i, bestFitness);
        end
    end
    
    % 更新显示
    vis.updateRoute(currentRoute, i, bestFitness);
    pause(0.1);  % 短暂暂停以便观察
end

%% 3. 测试图像保存功能
fprintf('\n3.1 测试图像保存功能...\n');

% 保存为不同格式
formats = {'.png', '.jpg', '.fig'};
for i = 1:length(formats)
    filename = ['test_result' formats{i}];
    vis.saveAnimation(filename);
    fprintf('已保存图像：%s\n', filename);
end

%% 4. 测试异常情况
fprintf('\n4. 测试异常情况处理...\n');

% 4.1 测试无效路径
fprintf('4.1 测试无效路径更新...\n');
try
    invalidRoute = 1:numCities+1;  % 创建一个无效路径
    vis.updateRoute(invalidRoute, 1, 100);
catch ME
    fprintf('预期的错误捕获：%s\n', ME.message);
end

%% 5. 清理资源
fprintf('\n5. 清理资源...\n');
delete(vis);
fprintf('可视化对象已清理\n');

% 删除测试生成的文件
for i = 1:length(formats)
    filename = ['test_result' formats{i}];
    if exist(filename, 'file')
        delete(filename);
        fprintf('删除测试文件：%s\n', filename);
    end
end

fprintf('\n=== 可视化模块测试完成 ===\n'); 