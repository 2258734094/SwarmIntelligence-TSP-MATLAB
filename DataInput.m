classdef DataInput < handle
    properties (Constant)
        % 定义常量属性
        DEFAULT_NUM_CITIES = 20    % 默认城市数量
        DEFAULT_RANGE = [0, 100]   % 默认坐标范围
    end
    
    methods (Static)  % 静态方法，不需要实例化即可调用
        function coords = generateRandomData(numCities, range)
            % 随机生成城市坐标
            % 输入参数：
            %   numCities: 城市数量
            %   range: 坐标范围 [min, max]
            % 输出：
            %   coords: 城市坐标矩阵 [numCities x 2]
            
            % 参数检查
            if nargin < 1
                numCities = DataInput.DEFAULT_NUM_CITIES;
            end
            if nargin < 2
                range = DataInput.DEFAULT_RANGE;
            end
            
            % 生成随机坐标
            minVal = range(1);
            maxVal = range(2);
            coords = minVal + (maxVal - minVal) * rand(numCities, 2);
        end
        
        function [coords, cityNames] = readTSPFile(filename)
            % 读取TSP文件
            % 输入参数：
            %   filename: TSP文件路径
            % 输出：
            %   coords: 城市坐标矩阵 [numCities x 2]
            %   cityNames: 城市名称元胞数组（如果文件中包含）
            
            try
                % 打开文件
                fid = fopen(filename, 'r');
                if fid == -1
                    error('无法打开文件：%s', filename);
                end
                
                % 初始化变量
                coords = [];
                cityNames = {};
                dimension = 0;
                readingCoords = false;
                
                % 逐行读取文件
                while ~feof(fid)
                    line = fgetl(fid);
                    line = strtrim(line);  % 去除首尾空格
                    
                    % 跳过空行和注释行
                    if isempty(line) || line(1) == '%'
                        continue;
                    end
                    
                    % 解析文件头信息
                    if contains(upper(line), 'DIMENSION')
                        parts = split(line, ':');
                        if length(parts) == 2
                            dimension = str2double(strtrim(parts{2}));
                        else
                            % 某些文件可能使用空格分隔
                            parts = split(strtrim(line));
                            dimension = str2double(parts{end});
                        end
                        coords = zeros(dimension, 2);
                        cityNames = cell(dimension, 1);
                    elseif contains(upper(line), 'NODE_COORD_SECTION')
                        readingCoords = true;
                        coordIndex = 1;
                    elseif readingCoords && ~contains(upper(line), 'EOF')
                        % 读取坐标数据
                        parts = split(strtrim(line));
                        if length(parts) >= 3
                            try
                                % 尝试读取数字
                                idx = str2double(parts{1});
                                x = str2double(parts{2});
                                y = str2double(parts{3});
                                
                                % 检查数值是否有效
                                if ~isnan(idx) && ~isnan(x) && ~isnan(y) && idx <= dimension
                                    coords(idx, :) = [x, y];
                                    cityNames{idx} = sprintf('City%d', idx);
                                end
                            catch
                                % 忽略无效行
                                continue;
                            end
                        end
                    end
                end
                
                % 关闭文件
                fclose(fid);
                
                % 检查数据有效性
                if isempty(coords) || any(any(coords == 0))
                    error('无法正确读取坐标数据');
                end
                
                % 删除强制归一化的代码，改为自适应坐标轴范围
                if ~isempty(coords)
                    % 计算坐标范围，用于设置显示范围
                    minCoords = min(coords);
                    maxCoords = max(coords);
                    % 添加10%的边距
                    margin = (maxCoords - minCoords) * 0.1;
                    % 更新坐标范围
                    coords_range = [minCoords - margin; maxCoords + margin];
                end
                
            catch ME
                if fid ~= -1
                    fclose(fid);
                end
                rethrow(ME);
            end
        end
        
        function saveToFile(coords, filename)
            % 将坐标数据保存为TSP格式文件
            % 输入参数：
            %   coords: 城市坐标矩阵 [numCities x 2]
            %   filename: 保存的文件名
            
            try
                fid = fopen(filename, 'w');
                if fid == -1
                    error('无法创建文件：%s', filename);
                end
                
                % 写入文件头
                fprintf(fid, 'NAME: %s\n', 'Generated_TSP');
                fprintf(fid, 'TYPE: TSP\n');
                fprintf(fid, 'DIMENSION: %d\n', size(coords, 1));
                fprintf(fid, 'EDGE_WEIGHT_TYPE: EUC_2D\n');
                fprintf(fid, 'NODE_COORD_SECTION\n');
                
                % 写入坐标数据
                for i = 1:size(coords, 1)
                    fprintf(fid, '%d %.4f %.4f\n', i, coords(i,1), coords(i,2));
                end
                
                % 写入文件结束标记
                fprintf(fid, 'EOF\n');
                
                % 关闭文件
                fclose(fid);
                
            catch ME
                if fid ~= -1
                    fclose(fid);
                end
                rethrow(ME);
            end
        end
    end
end 