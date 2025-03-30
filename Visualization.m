classdef Visualization < handle
    properties
        % 图形句柄
        routeAxes      % 路径图坐标轴句柄
        convergenceAxes % 收敛曲线坐标轴句柄
        routePlot      % 路径图线条句柄
        convergencePlot % 收敛曲线句柄
        cityPlot       % 城市点图句柄
        
        % 数据
        cityCoords     % 城市坐标
        bestRoute      % 当前最优路径
        convergenceData % 收敛历史数据
        
        % 显示参数
        routeColor = 'b'    % 路径颜色
        cityColor = 'r'     % 城市点颜色
        lineWidth = 1.5     % 线条宽度
        markerSize = 8      % 标记点大小
    end
    
    methods
        function obj = Visualization(cityCoords)
            % 构造函数
            % 输入参数：
            %   cityCoords: 城市坐标矩阵 [n x 2]
            
            obj.cityCoords = cityCoords;
            obj.convergenceData = [];
        end
        
        function setAxes(obj, routeAxes, convergenceAxes)
            % 新增方法：设置坐标轴
            obj.routeAxes = routeAxes;
            obj.convergenceAxes = convergenceAxes;
            
            % 清除现有图形
            cla(obj.routeAxes);
            cla(obj.convergenceAxes);
            
            % 设置网格
            grid(obj.routeAxes, 'on');
            grid(obj.convergenceAxes, 'on');
            
            % 绘制初始城市点
            obj.cityPlot = plot(obj.routeAxes, ...
                              obj.cityCoords(:,1), ...
                              obj.cityCoords(:,2), ...
                              'o', ...
                              'MarkerSize', obj.markerSize, ...
                              'MarkerFaceColor', obj.cityColor, ...
                              'MarkerEdgeColor', obj.cityColor);
            
            % 设置路径图的坐标轴范围
            minCoords = min(obj.cityCoords);
            maxCoords = max(obj.cityCoords);
            margin = (maxCoords - minCoords) * 0.1;
            xlim(obj.routeAxes, [minCoords(1)-margin(1), maxCoords(1)+margin(1)]);
            ylim(obj.routeAxes, [minCoords(2)-margin(2), maxCoords(2)+margin(2)]);
            
            % 保持坐标轴比例一致
            axis(obj.routeAxes, 'equal');
        end
        
        function updateRoute(obj, route, iteration, fitness)
            % 更新路径显示
            % 输入参数：
            %   route: 当前最优路径
            %   iteration: 当前迭代次数
            %   fitness: 当前适应度值（路径长度）
            
            % 更新最优路径
            obj.bestRoute = route;
            
            % 获取路径坐标
            routeCoords = obj.cityCoords(route,:);
            % 添加起点坐标以闭合路径
            routeCoords = [routeCoords; routeCoords(1,:)];
            
            % 更新路径图
            if ishandle(obj.routePlot)
                % 更新现有路径
                set(obj.routePlot, 'XData', routeCoords(:,1), ...
                                 'YData', routeCoords(:,2));
            else
                % 创建新路径
                obj.routePlot = plot(obj.routeAxes, ...
                                   routeCoords(:,1), ...
                                   routeCoords(:,2), ...
                                   '-', ...
                                   'Color', obj.routeColor, ...
                                   'LineWidth', obj.lineWidth);
            end
            
            % 更新标题显示当前路径长度
            title(obj.routeAxes, sprintf('当前最优路径 (长度: %.2f)', fitness));
            
            % 预分配收敛数据数组（如果尚未分配）
            if isempty(obj.convergenceData)
                obj.convergenceData = inf(1000, 1);  % 预分配足够大的空间
            end
            
            % 更新收敛数据
            if iteration == 1
                obj.convergenceData(iteration) = fitness;
            else
                obj.convergenceData(iteration) = min(fitness, obj.convergenceData(iteration-1));
            end
            
            % 更新收敛曲线
            if ishandle(obj.convergencePlot)
                % 更新现有曲线
                set(obj.convergencePlot, 'XData', 1:iteration, ...
                                       'YData', obj.convergenceData(1:iteration));
            else
                % 创建新曲线
                obj.convergencePlot = plot(obj.convergenceAxes, ...
                                         1:iteration, ...
                                         obj.convergenceData(1:iteration), ...
                                         '-', ...
                                         'Color', obj.routeColor, ...
                                         'LineWidth', obj.lineWidth);
            end
            
            % 自动调整收敛曲线的Y轴范围（添加错误检查）
            validData = obj.convergenceData(1:iteration);
            if ~isempty(validData)
                yMin = min(validData);
                yMax = max(validData);
                if yMin == yMax
                    % 如果最小值等于最大值，设置一个小的范围
                    margin = yMin * 0.1;
                    if margin == 0
                        margin = 1;  % 如果值为0，使用固定边距
                    end
                    ylim(obj.convergenceAxes, [yMin-margin, yMax+margin]);
                else
                    margin = (yMax - yMin) * 0.1;  % 添加10%的边距
                    ylim(obj.convergenceAxes, [yMin-margin, yMax+margin]);
                end
            end
            
            % 强制刷新图形
            drawnow;
        end
        
        function saveAnimation(obj, filename)
            % 保存当前图形为图片
            % 输入参数：
            %   filename: 保存的文件名（支持.png, .jpg等格式）
            
            if nargin < 2
                filename = 'tsp_result.png';
            end
            
            % 获取当前图形的句柄
            fig = ancestor(obj.routeAxes, 'figure');
            saveas(fig, filename);
            fprintf('图形已保存至：%s\n', filename);
        end
        
        function delete(obj)
            % 清理图形对象
            if ishandle(obj.routePlot)
                delete(obj.routePlot);
            end
            if ishandle(obj.convergencePlot)
                delete(obj.convergencePlot);
            end
            if ishandle(obj.cityPlot)
                delete(obj.cityPlot);
            end
        end
    end
end 