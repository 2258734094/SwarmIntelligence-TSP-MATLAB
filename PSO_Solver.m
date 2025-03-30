classdef PSO_Solver < handle    % 定义一个继承自handle的类，使对象可修改
    properties
        % 问题参数
        cityCoords    % 城市坐标矩阵 [n x 2]，每行表示一个城市的(x,y)坐标
        numCities     % 城市总数量
        
        % PSO算法参数
        numParticles  % 粒子群大小（种群数量）
        maxIter       % 最大迭代次数
        w            % 惯性权重，控制粒子保持原有速度的程度（范围：0.4~0.9）
        c1           % 个体学习因子，控制粒子向个体历史最优解学习的程度
        c2           % 社会学习因子，控制粒子向群体最优解学习的程度
        
        % 算法运行时的状态变量
        particles    % 粒子位置矩阵 [numParticles x numCities]，每行表示一个解（城市访问顺序）
        velocities   % 粒子速度矩阵，维度同particles
        pBest        % 每个粒子的历史最优解
        pBestFitness % 每个粒子的历史最优适应度值（路径长度）
        gBest        % 群体历史最优解
        gBestFitness % 群体历史最优适应度值
        fitnessHistory % 记录每次迭代的最优适应度，用于绘制收敛曲线
        UpdateCallback  % 更新回调函数
        
        % 添加暂停控制属性
        IsPaused    logical = false
        IsRunning   logical = false
    end
    
    methods
        % 构造函数：初始化PSO求解器
        function obj = PSO_Solver(cityCoords, params)
            % 输入参数：
            % cityCoords: 城市坐标矩阵
            % params: 可选的参数结构体，包含算法参数设置
            
            obj.cityCoords = cityCoords;
            obj.numCities = size(cityCoords, 1);
            
            % 设置算法参数，如果未提供则使用默认值
            if nargin < 2  % nargin表示输入参数的个数
                params = struct();  % 创建空结构体
            end
            % 使用辅助函数getParam获取参数值，如果参数不存在则使用默认值
            obj.numParticles = getParam(params, 'numParticles', 50);
            obj.maxIter = getParam(params, 'maxIter', 200);
            obj.w = getParam(params, 'w', 0.9);
            obj.c1 = getParam(params, 'c1', 2);
            obj.c2 = getParam(params, 'c2', 2);
            
            % 初始化粒子群
            obj.initParticles();
        end
        
        % 初始化粒子群
        function initParticles(obj)
            % 初始化粒子位置：每个粒子是城市序号的一个随机排列
            obj.particles = zeros(obj.numParticles, obj.numCities);
            for i = 1:obj.numParticles
                % randperm生成1到numCities的随机排列
                obj.particles(i,:) = randperm(obj.numCities);
            end
            
            % 初始化粒子速度：随机值，范围[-1,1]
            % rand生成[0,1]随机数，然后变换到[-1,1]
            obj.velocities = rand(obj.numParticles, obj.numCities) * 2 - 1;
            
            % 初始化个体最优位置和适应度
            obj.pBest = obj.particles;  % 初始时，当前位置即为最优位置
            obj.pBestFitness = inf(obj.numParticles, 1);  % 初始化为无穷大
            obj.gBestFitness = inf;
            
            % 计算每个粒子的初始适应度
            for i = 1:obj.numParticles
                fitness = obj.calcFitness(obj.particles(i,:));
                obj.pBestFitness(i) = fitness;
                % 更新全局最优
                if fitness < obj.gBestFitness
                    obj.gBestFitness = fitness;
                    obj.gBest = obj.particles(i,:);
                end
            end
            
            % 初始化收敛历史记录数组
            obj.fitnessHistory = zeros(obj.maxIter, 1);
        end
        
        % 计算适应度（路径总长度）
        function fitness = calcFitness(obj, route)
            % 输入参数：
            % route: 一维数组，表示城市访问顺序
            % 返回值：
            % fitness: 路径总长度
            
            % 根据访问顺序获取城市坐标
            coords = obj.cityCoords(route,:);
            % 计算相邻城市间的坐标差
            % 注意：需要首尾相连，所以添加起点坐标到终点
            diffs = diff([coords; coords(1,:)], 1, 1);
            % 计算欧氏距离：sqrt(dx^2 + dy^2)
            distances = sqrt(sum(diffs.^2, 2));
            % 总路径长度
            fitness = sum(distances);
        end
        
        % 主优化函数
        function [bestRoute, bestFitness, history] = optimize(obj)
            obj.IsRunning = true;
            bestSoFar = inf;
            
            try
                for iter = 1:obj.maxIter
                    % 检查暂停和停止状态
                    while obj.IsPaused && obj.IsRunning
                        pause(0.1);
                        drawnow;
                    end
                    
                    if ~obj.IsRunning
                        break;
                    end
                    
                    % 惯性权重线性递减策略
                    w_iter = obj.w - (obj.w - 0.4) * iter / obj.maxIter;
                    
                    % 更新每个粒子
                    for i = 1:obj.numParticles
                        % 生成随机数，用于速度更新公式
                        r1 = rand(1, obj.numCities);  % 个体认知部分的随机数
                        r2 = rand(1, obj.numCities);  % 社会认知部分的随机数
                        
                        % 更新速度：经典PSO速度更新公式
                        obj.velocities(i,:) = w_iter * obj.velocities(i,:) + ...
                            obj.c1 * r1 .* (obj.pBest(i,:) - obj.particles(i,:)) + ...
                            obj.c2 * r2 .* (obj.gBest - obj.particles(i,:));
                        
                        % 根据速度更新位置
                        % 使用排序映射方法：将连续值映射为离散的排列
                        [~, newPos] = sort(obj.particles(i,:) + obj.velocities(i,:));
                        obj.particles(i,:) = newPos;
                        
                        % 计算新位置的适应度
                        newFitness = obj.calcFitness(obj.particles(i,:));
                        
                        % 更新个体最优
                        if newFitness < obj.pBestFitness(i)
                            obj.pBestFitness(i) = newFitness;
                            obj.pBest(i,:) = obj.particles(i,:);
                            
                            % 更新全局最优
                            if newFitness < obj.gBestFitness
                                obj.gBestFitness = newFitness;
                                obj.gBest = obj.particles(i,:);
                            end
                        end
                    end
                    
                    % 更新全局最优解
                    if obj.gBestFitness < bestSoFar
                        bestSoFar = obj.gBestFitness;
                    end
                    
                    % 记录当前迭代的最优值（使用历史最优）
                    obj.fitnessHistory(iter) = bestSoFar;
                    
                    % 回调更新显示
                    if ~isempty(obj.UpdateCallback)
                        obj.UpdateCallback(obj.gBest, iter, bestSoFar);
                    end
                end
            catch ME
                obj.IsRunning = false;
                rethrow(ME);
            end
            
            obj.IsRunning = false;
            bestRoute = obj.gBest;
            bestFitness = obj.gBestFitness;
            history = obj.fitnessHistory;
        end
        
        % 添加暂停控制方法
        function pause(obj)
            obj.IsPaused = true;
        end
        
        function resume(obj)
            obj.IsPaused = false;
        end
        
        function stop(obj)
            obj.IsRunning = false;
            obj.IsPaused = false;
        end
    end
end

% 辅助函数：从结构体中获取参数值
function value = getParam(params, field, defaultValue)
    % 输入参数：
    % params: 参数结构体
    % field: 参数名称
    % defaultValue: 默认值
    
    % isfield检查结构体是否包含指定字段
    if isfield(params, field)
        value = params.(field);
    else
        value = defaultValue;
    end
end 