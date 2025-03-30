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
                    
                    % 跳过空行
                    if isempty(line)
                        continue;
                    end
                    
                    % 解析文件头信息
                    if contains(line, 'DIMENSION')
                        % 获取城市数量
                        parts = split(line, ':');
                        dimension = str2double(strtrim(parts{2}));
                        coords = zeros(dimension, 2);
                        cityNames = cell(dimension, 1);
                    elseif contains(line, 'NODE_COORD_SECTION')
                        % 开始读取坐标
                        readingCoords = true;
                        coordIndex = 1;
                    elseif readingCoords && coordIndex <= dimension
                        % 读取坐标数据
                        parts = split(strtrim(line));
                        if length(parts) >= 3
                            cityNames{coordIndex} = parts{1};
                            coords(coordIndex, :) = [str2double(parts{2}), str2double(parts{3})];
                            coordIndex = coordIndex + 1;
                        end
                    end
                end
                
                % 关闭文件
                fclose(fid);
                
                % 检查是否成功读取数据
                if isempty(coords)
                    error('未能成功读取坐标数据');
                end
                
            catch ME
                % 错误处理
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