% 全面测试数据输入模块的功能
clc;    % 清除命令窗口
clear;  % 清除工作区变量
close all;  % 关闭所有图窗

%% 1. 测试随机数据生成功能
fprintf('=== 测试随机数据生成 ===\n');

% 1.1 测试默认参数
fprintf('\n1.1 使用默认参数生成数据：\n');
coords_default = DataInput.generateRandomData();
fprintf('生成的城市数量：%d\n', size(coords_default, 1));
fprintf('坐标范围：[%.1f, %.1f]\n', min(coords_default(:)), max(coords_default(:)));

% 1.2 测试自定义参数
fprintf('\n1.2 使用自定义参数生成数据：\n');
custom_cities = 15;
custom_range = [10, 80];
coords_custom = DataInput.generateRandomData(custom_cities, custom_range);
fprintf('生成的城市数量：%d\n', size(coords_custom, 1));
fprintf('坐标范围：[%.1f, %.1f]\n', min(coords_custom(:)), max(coords_custom(:)));

% 1.3 可视化随机生成的数据
figure('Name', '随机生成的数据对比');
subplot(1,2,1);
plot(coords_default(:,1), coords_default(:,2), 'bo', 'MarkerFaceColor', 'b');
title('默认参数生成的数据');
grid on;
xlabel('X坐标');
ylabel('Y坐标');

subplot(1,2,2);
plot(coords_custom(:,1), coords_custom(:,2), 'ro', 'MarkerFaceColor', 'r');
title('自定义参数生成的数据');
grid on;
xlabel('X坐标');
ylabel('Y坐标');

%% 2. 测试文件保存和读取功能
fprintf('\n=== 测试文件操作 ===\n');

% 2.1 保存为TSP文件
fprintf('\n2.1 测试数据保存：\n');
test_filename = 'test_cities.tsp';
try
    DataInput.saveToFile(coords_custom, test_filename);
    fprintf('成功保存数据到文件：%s\n', test_filename);
catch ME
    fprintf('保存文件失败：%s\n', ME.message);
end

% 2.2 读取TSP文件
fprintf('\n2.2 测试数据读取：\n');
try
    [coords_read, city_names] = DataInput.readTSPFile(test_filename);
    fprintf('成功读取文件：%s\n', test_filename);
    fprintf('读取的城市数量：%d\n', size(coords_read, 1));
catch ME
    fprintf('读取文件失败：%s\n', ME.message);
end

% 2.3 验证数据一致性
if exist('coords_read', 'var')
    fprintf('\n2.3 数据一致性验证：\n');
    coord_diff = sum(sum(abs(coords_custom - coords_read)));
    fprintf('原始数据与读取数据的总差异：%.10f\n', coord_diff);
    if coord_diff < 1e-10
        fprintf('验证通过：保存和读取的数据完全一致！\n');
    else
        fprintf('警告：数据存在差异！\n');
    end
    
    % 可视化对比
    figure('Name', '数据保存和读取对比');
    plot(coords_custom(:,1), coords_custom(:,2), 'bo-', 'LineWidth', 1.5, 'DisplayName', '原始数据');
    hold on;
    plot(coords_read(:,1), coords_read(:,2), 'rx--', 'LineWidth', 1.5, 'DisplayName', '读取的数据');
    title('原始数据与读取数据对比');
    grid on;
    legend('show');
    xlabel('X坐标');
    ylabel('Y坐标');
end

%% 3. 测试错误处理
fprintf('\n=== 测试错误处理 ===\n');

% 3.1 测试读取不存在的文件
fprintf('\n3.1 测试读取不存在的文件：\n');
try
    [~, ~] = DataInput.readTSPFile('nonexistent.tsp');
catch ME
    fprintf('预期的错误：%s\n', ME.message);
end

% 3.2 测试无效的参数
fprintf('\n3.2 测试无效的参数：\n');
try
    coords_invalid = DataInput.generateRandomData(-5);
catch ME
    fprintf('预期的错误：%s\n', ME.message);
end

%% 4. 清理测试文件
if exist(test_filename, 'file')
    delete(test_filename);
    fprintf('\n已删除测试文件：%s\n', test_filename);
end

fprintf('\n=== 测试完成 ===\n'); 