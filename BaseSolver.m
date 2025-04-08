classdef BaseSolver < handle
    properties
        % 问题参数
        cityCoords    % 城市坐标矩阵 [n x 2]
        numCities     % 城市总数量
        
        % 通用参数
        maxIter       % 最大迭代次数
        
        % 回调和状态
        UpdateCallback  % 更新回调函数
        IsRunning      logical = false
        IsPaused       logical = false
        
        % 最优解记录
        bestSolution   % 全局最优解
        bestFitness    % 全局最优适应度
        fitnessHistory % 收敛历史记录
    end
    
    methods
        function obj = BaseSolver(cityCoords)
            % 构造函数
            obj.cityCoords = cityCoords;
            obj.numCities = size(cityCoords, 1);
        end
        
        function fitness = calcFitness(obj, route)
            % 计算路径长度（适应度）
            coords = obj.cityCoords(route,:);
            diffs = diff([coords; coords(1,:)], 1, 1);
            distances = sqrt(sum(diffs.^2, 2));
            fitness = sum(distances);
        end
        
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
    
    methods (Abstract)
        % 子类必须实现的方法
        [bestRoute, bestFitness, history] = optimize(obj)
    end
end 