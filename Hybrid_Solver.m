classdef Hybrid_Solver < BaseSolver
    properties
        % 混合算法参数
        psoRatio        % PSO占比
        psoSolver       % PSO求解器实例
        gaSolver        % GA求解器实例
        currentSolver   % 当前活动的求解器
    end
    
    methods
        function obj = Hybrid_Solver(cityCoords, params)
            % 调用父类构造函数
            obj = obj@BaseSolver(cityCoords);
            
            % 设置混合算法参数
            if nargin < 2
                params = struct();
            end
            obj.psoRatio = getParam(params, 'psoRatio', 0.5);
            obj.maxIter = getParam(params, 'maxIter', 200);
            
            % 计算PSO和GA的迭代次数
            psoIters = round(obj.maxIter * obj.psoRatio);
            gaIters = obj.maxIter - psoIters;
            
            % 创建PSO求解器
            psoParams = params;
            psoParams.maxIter = psoIters;
            obj.psoSolver = PSO_Solver(cityCoords, psoParams);
            
            % 创建GA求解器
            gaParams = params;
            gaParams.maxIter = gaIters;
            obj.gaSolver = GA_Solver(cityCoords, gaParams);
            
            % 初始化收敛历史
            obj.fitnessHistory = zeros(obj.maxIter, 1);
        end
        
        function [bestRoute, bestFitness, history] = optimize(obj)
            obj.IsRunning = true;
            bestSoFar = inf;
            currentIter = 1;
            
            try
                % 先运行PSO
                obj.currentSolver = obj.psoSolver;
                obj.currentSolver.UpdateCallback = @(route, iter, fitness) ...
                    obj.updateProgress(route, currentIter + iter - 1, fitness);
                [psoBestRoute, psoBestFitness, psoHistory] = obj.psoSolver.optimize();
                
                % 更新最优解
                bestRoute = psoBestRoute;
                bestFitness = psoBestFitness;
                currentIter = currentIter + length(psoHistory);
                
                % 如果被停止，直接返回
                if ~obj.IsRunning
                    history = obj.fitnessHistory(1:currentIter-1);
                    return;
                end
                
                % 将PSO的最优解注入到GA的初始种群中
                gaInitPop = obj.gaSolver.population;
                gaInitPop(1,:) = psoBestRoute;  % 替换第一个个体
                obj.gaSolver.population = gaInitPop;
                obj.gaSolver.initPopulation();  % 重新计算适应度
                
                % 运行GA
                obj.currentSolver = obj.gaSolver;
                obj.currentSolver.UpdateCallback = @(route, iter, fitness) ...
                    obj.updateProgress(route, currentIter + iter - 1, fitness);
                [gaBestRoute, gaBestFitness, gaHistory] = obj.gaSolver.optimize();
                
                % 更新最终结果
                if gaBestFitness < bestFitness
                    bestRoute = gaBestRoute;
                    bestFitness = gaBestFitness;
                end
                
            catch ME
                obj.IsRunning = false;
                rethrow(ME);
            end
            
            obj.IsRunning = false;
            history = obj.fitnessHistory;
        end
        
        function updateProgress(obj, route, iter, fitness)
            % 更新进度并调用外部回调
            obj.fitnessHistory(iter) = fitness;
            if ~isempty(obj.UpdateCallback)
                obj.UpdateCallback(route, iter, fitness);
            end
        end
        
        function pause(obj)
            % 暂停当前活动的求解器
            obj.IsPaused = true;
            if ~isempty(obj.currentSolver)
                obj.currentSolver.pause();
            end
        end
        
        function resume(obj)
            % 恢复当前活动的求解器
            obj.IsPaused = false;
            if ~isempty(obj.currentSolver)
                obj.currentSolver.resume();
            end
        end
        
        function stop(obj)
            % 停止所有求解器
            obj.IsRunning = false;
            obj.IsPaused = false;
            if ~isempty(obj.psoSolver)
                obj.psoSolver.stop();
            end
            if ~isempty(obj.gaSolver)
                obj.gaSolver.stop();
            end
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