classdef GA_Solver < BaseSolver
    properties
        % GA特有参数
        populationSize    % 种群大小
        crossoverRate    % 交叉率
        mutationRate     % 变异率
        eliteCount       % 精英数量
        
        % GA状态变量
        population       % 当前种群
        fitness         % 当前种群适应度
    end
    
    methods
        function obj = GA_Solver(cityCoords, params)
            % 调用父类构造函数
            obj = obj@BaseSolver(cityCoords);
            
            % 设置GA参数
            if nargin < 2
                params = struct();
            end
            obj.populationSize = getParam(params, 'populationSize', 100);
            obj.maxIter = getParam(params, 'maxIter', 200);
            obj.crossoverRate = getParam(params, 'crossoverRate', 0.8);
            obj.mutationRate = getParam(params, 'mutationRate', 0.1);
            obj.eliteCount = getParam(params, 'eliteCount', 2);
            
            % 初始化种群
            obj.initPopulation();
        end
        
        function initPopulation(obj)
            % 初始化种群
            obj.population = zeros(obj.populationSize, obj.numCities);
            obj.fitness = zeros(obj.populationSize, 1);
            
            % 随机生成初始种群
            for i = 1:obj.populationSize
                obj.population(i,:) = randperm(obj.numCities);
            end
            
            % 计算初始适应度
            for i = 1:obj.populationSize
                obj.fitness(i) = obj.calcFitness(obj.population(i,:));
            end
            
            % 初始化最优解和收敛历史
            [obj.bestFitness, idx] = min(obj.fitness);
            obj.bestSolution = obj.population(idx,:);
            obj.fitnessHistory = zeros(obj.maxIter, 1);
        end
        
        function child = crossover(obj, parent1, parent2)
            % 顺序交叉算子(OX)
            if rand() > obj.crossoverRate
                child = parent1;
                return;
            end
            
            % 随机选择交叉点
            n = length(parent1);
            points = sort(randperm(n, 2));
            start = points(1);
            finish = points(2);
            
            % 从parent1复制中间段
            child = zeros(1, n);
            child(start:finish) = parent1(start:finish);
            
            % 从parent2填充剩余位置
            remaining = setdiff(parent2, parent1(start:finish), 'stable');
            child(1:start-1) = remaining(1:start-1);
            child(finish+1:end) = remaining(start:end);
        end
        
        function child = mutate(obj, parent)
            % 交换变异
            child = parent;
            if rand() <= obj.mutationRate
                % 随机选择两个位置进行交换
                points = randperm(obj.numCities, 2);
                child(points) = child(fliplr(points));
            end
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
                    
                    % 保留精英
                    [sortedFitness, sortedIdx] = sort(obj.fitness);
                    elites = obj.population(sortedIdx(1:obj.eliteCount), :);
                    
                    % 创建新种群
                    newPopulation = zeros(size(obj.population));
                    newPopulation(1:obj.eliteCount, :) = elites;
                    
                    % 轮盘赌选择、交叉和变异
                    fitnessSum = sum(1./obj.fitness);
                    probabilities = (1./obj.fitness) / fitnessSum;
                    
                    for i = obj.eliteCount+1:2:obj.populationSize
                        % 选择父代
                        parent1Idx = rouletteWheel(probabilities);
                        parent2Idx = rouletteWheel(probabilities);
                        
                        % 交叉
                        child1 = obj.crossover(obj.population(parent1Idx,:), ...
                                            obj.population(parent2Idx,:));
                        child2 = obj.crossover(obj.population(parent2Idx,:), ...
                                            obj.population(parent1Idx,:));
                        
                        % 变异
                        child1 = obj.mutate(child1);
                        child2 = obj.mutate(child2);
                        
                        % 加入新种群
                        newPopulation(i,:) = child1;
                        if i+1 <= obj.populationSize
                            newPopulation(i+1,:) = child2;
                        end
                    end
                    
                    % 更新种群
                    obj.population = newPopulation;
                    
                    % 计算新种群适应度
                    for i = 1:obj.populationSize
                        obj.fitness(i) = obj.calcFitness(obj.population(i,:));
                    end
                    
                    % 更新最优解
                    [minFitness, minIdx] = min(obj.fitness);
                    if minFitness < obj.bestFitness
                        obj.bestFitness = minFitness;
                        obj.bestSolution = obj.population(minIdx,:);
                    end
                    
                    % 更新历史最优
                    if obj.bestFitness < bestSoFar
                        bestSoFar = obj.bestFitness;
                    end
                    obj.fitnessHistory(iter) = bestSoFar;
                    
                    % 回调更新显示
                    if ~isempty(obj.UpdateCallback)
                        obj.UpdateCallback(obj.bestSolution, iter, bestSoFar);
                    end
                end
            catch ME
                obj.IsRunning = false;
                rethrow(ME);
            end
            
            obj.IsRunning = false;
            bestRoute = obj.bestSolution;
            bestFitness = obj.bestFitness;
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

function idx = rouletteWheel(probabilities)
    % 轮盘赌选择
    r = rand();
    cumProb = cumsum(probabilities);
    idx = find(cumProb >= r, 1);
end 