classdef PSO_Solver < BaseSolver
    properties
        % PSO特有参数
        numParticles  % 粒子群大小
        w            % 惯性权重
        c1           % 个体学习因子
        c2           % 社会学习因子
        
        % PSO状态变量
        particles    % 粒子位置矩阵
        velocities   % 粒子速度矩阵
        pBest        % 个体历史最优解
        pBestFitness % 个体历史最优适应度
        gBest        % 群体历史最优解
        gBestFitness % 群体历史最优适应度
    end
    
    methods
        function obj = PSO_Solver(cityCoords, params)
            % 调用父类构造函数
            obj = obj@BaseSolver(cityCoords);
            
            % 设置PSO参数
            if nargin < 2
                params = struct();
            end
            obj.numParticles = getParam(params, 'numParticles', 50);
            obj.maxIter = getParam(params, 'maxIter', 200);
            obj.w = getParam(params, 'w', 0.9);
            obj.c1 = getParam(params, 'c1', 2);
            obj.c2 = getParam(params, 'c2', 2);
            
            % 初始化粒子群
            obj.initParticles();
        end
        
        function initParticles(obj)
            % 初始化粒子位置
            obj.particles = zeros(obj.numParticles, obj.numCities);
            for i = 1:obj.numParticles
                obj.particles(i,:) = randperm(obj.numCities);
            end
            
            % 初始化粒子速度
            obj.velocities = rand(obj.numParticles, obj.numCities) * 2 - 1;
            
            % 初始化个体最优位置和适应度
            obj.pBest = obj.particles;
            obj.pBestFitness = inf(obj.numParticles, 1);
            obj.gBestFitness = inf;
            
            % 计算初始适应度
            for i = 1:obj.numParticles
                fitness = obj.calcFitness(obj.particles(i,:));
                obj.pBestFitness(i) = fitness;
                if fitness < obj.gBestFitness
                    obj.gBestFitness = fitness;
                    obj.gBest = obj.particles(i,:);
                end
            end
            
            % 初始化收敛历史记录
            obj.fitnessHistory = zeros(obj.maxIter, 1);
        end
        
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
                    
                    % 惯性权重线性递减
                    w_iter = obj.w - (obj.w - 0.4) * iter / obj.maxIter;
                    
                    % 更新每个粒子
                    for i = 1:obj.numParticles
                        % 速度更新
                        r1 = rand(1, obj.numCities);
                        r2 = rand(1, obj.numCities);
                        obj.velocities(i,:) = w_iter * obj.velocities(i,:) + ...
                            obj.c1 * r1 .* (obj.pBest(i,:) - obj.particles(i,:)) + ...
                            obj.c2 * r2 .* (obj.gBest - obj.particles(i,:));
                        
                        % 位置更新
                        [~, newPos] = sort(obj.particles(i,:) + obj.velocities(i,:));
                        obj.particles(i,:) = newPos;
                        
                        % 适应度计算和更新
                        newFitness = obj.calcFitness(obj.particles(i,:));
                        if newFitness < obj.pBestFitness(i)
                            obj.pBestFitness(i) = newFitness;
                            obj.pBest(i,:) = obj.particles(i,:);
                            
                            if newFitness < obj.gBestFitness
                                obj.gBestFitness = newFitness;
                                obj.gBest = obj.particles(i,:);
                            end
                        end
                    end
                    
                    % 更新历史最优
                    if obj.gBestFitness < bestSoFar
                        bestSoFar = obj.gBestFitness;
                    end
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
    end
end

% 辅助函数
function value = getParam(params, field, defaultValue)
    if isfield(params, field)
        value = params.(field);
    else
        value = defaultValue;
    end
end 