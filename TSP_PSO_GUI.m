classdef TSP_PSO_GUI < matlab.apps.AppBase
    % TSP问题的PSO求解器图形界面
    
    properties (Access = public)
        % GUI组件
        UIFigure           matlab.ui.Figure
        MainGrid          matlab.ui.container.GridLayout
        LeftPanel         matlab.ui.container.Panel
        RightPanel        matlab.ui.container.Panel
        
        % 数据输入控件
        DataPanel         matlab.ui.container.Panel
        LoadButton        matlab.ui.control.Button
        GenerateButton    matlab.ui.control.Button
        NumCitiesSpinner  matlab.ui.control.Spinner
        
        % PSO参数控件
        ParamPanel        matlab.ui.container.Panel
        ParticlesSpinner  matlab.ui.control.Spinner
        MaxIterSpinner    matlab.ui.control.Spinner
        WSpinner          matlab.ui.control.Spinner
        C1Spinner         matlab.ui.control.Spinner
        C2Spinner         matlab.ui.control.Spinner
        
        % 控制按钮
        StartButton       matlab.ui.control.Button
        PauseButton       matlab.ui.control.Button
        ResetButton       matlab.ui.control.Button
        
        % 显示组件
        RouteAxes         matlab.ui.control.UIAxes
        ConvergenceAxes   matlab.ui.control.UIAxes
        StatusLabel       matlab.ui.control.Label
        
        % 数据和算法对象
        CityCoords        % 城市坐标
        PSOSolver         % PSO求解器对象
        Visualizer        % 可视化对象
        
        % 运行状态
        IsRunning         logical
        IsPaused         logical
    end
    
    methods (Access = private)
        function createComponents(app)
            % 创建GUI组件
            
            % 创建主窗口
            app.UIFigure = uifigure('Name', 'TSP-PSO求解器');
            app.UIFigure.Position = [100 100 1200 700];
            
            % 创建网格布局
            app.MainGrid = uigridlayout(app.UIFigure, [1 2]);
            app.MainGrid.ColumnWidth = {'1x', '3x'};
            
            % 创建左侧面板（参数设置区）
            app.LeftPanel = uipanel(app.MainGrid);
            app.LeftPanel.Title = '参数设置';
            leftLayout = uigridlayout(app.LeftPanel, [7 1]);
            
            % 数据输入面板
            app.DataPanel = uipanel(leftLayout);
            app.DataPanel.Title = '数据输入';
            dataLayout = uigridlayout(app.DataPanel, [3 2]);
            
            % 添加数据输入控件
            label = uilabel(dataLayout);
            label.Text = '城市数量：';
            app.NumCitiesSpinner = uispinner(dataLayout);
            app.NumCitiesSpinner.Limits = [5 100];
            app.NumCitiesSpinner.Value = 20;
            
            app.GenerateButton = uibutton(dataLayout, 'Text', '随机生成');
            app.GenerateButton.ButtonPushedFcn = @(src,event) generateData(app);
            
            app.LoadButton = uibutton(dataLayout, 'Text', '加载TSP文件');
            app.LoadButton.ButtonPushedFcn = @(src,event) loadData(app);
            
            % PSO参数面板
            app.ParamPanel = uipanel(leftLayout);
            app.ParamPanel.Title = 'PSO参数';
            paramLayout = uigridlayout(app.ParamPanel, [5 2]);
            
            % 添加PSO参数控件
            labels = {'粒子数量：', '最大迭代：', '惯性权重：', '学习因子c1：', '学习因子c2：'};
            defaults = [50, 200, 0.9, 2.0, 2.0];
            limits = {[10 200], [50 1000], [0 1], [0 4], [0 4]};
            
            for i = 1:5
                label = uilabel(paramLayout);
                label.Text = labels{i};
                spinner = uispinner(paramLayout);
                spinner.Limits = limits{i};
                spinner.Value = defaults(i);
                
                switch i
                    case 1
                        app.ParticlesSpinner = spinner;
                    case 2
                        app.MaxIterSpinner = spinner;
                    case 3
                        app.WSpinner = spinner;
                    case 4
                        app.C1Spinner = spinner;
                    case 5
                        app.C2Spinner = spinner;
                end
            end
            
            % 控制按钮
            buttonLayout = uigridlayout(leftLayout, [1 3]);
            app.StartButton = uibutton(buttonLayout, 'Text', '开始');
            app.StartButton.ButtonPushedFcn = @(src,event) startOptimization(app);
            
            app.PauseButton = uibutton(buttonLayout, 'Text', '暂停');
            app.PauseButton.ButtonPushedFcn = @(src,event) pauseOptimization(app);
            app.PauseButton.Enable = 'off';
            
            app.ResetButton = uibutton(buttonLayout, 'Text', '重置');
            app.ResetButton.ButtonPushedFcn = @(src,event) resetOptimization(app);
            
            % 状态标签
            app.StatusLabel = uilabel(leftLayout);
            app.StatusLabel.Text = '就绪';
            app.StatusLabel.HorizontalAlignment = 'center';
            
            % 创建右侧面板（显示区）
            app.RightPanel = uipanel(app.MainGrid);
            app.RightPanel.Title = '优化过程';
            rightLayout = uigridlayout(app.RightPanel, [2 1]);
            
            % 创建路径显示和收敛曲线坐标轴
            app.RouteAxes = uiaxes(rightLayout);
            app.RouteAxes.Title.String = '当前最优路径';
            app.RouteAxes.XLabel.String = 'X坐标';
            app.RouteAxes.YLabel.String = 'Y坐标';
            
            app.ConvergenceAxes = uiaxes(rightLayout);
            app.ConvergenceAxes.Title.String = '收敛曲线';
            app.ConvergenceAxes.XLabel.String = '迭代次数';
            app.ConvergenceAxes.YLabel.String = '路径长度';
            
            % 初始化状态变量
            app.IsRunning = false;
            app.IsPaused = false;
        end
        
        function generateData(app)
            try
                numCities = app.NumCitiesSpinner.Value;
                app.CityCoords = DataInput.generateRandomData(numCities);
                
                % 创建新的可视化对象
                if ~isempty(app.Visualizer)
                    delete(app.Visualizer);
                end
                app.Visualizer = Visualization(app.CityCoords);
                app.Visualizer.setAxes(app.RouteAxes, app.ConvergenceAxes);
                
                app.StatusLabel.Text = sprintf('已生成%d个城市的随机数据', numCities);
            catch ME
                app.StatusLabel.Text = '生成数据失败';
                errordlg(ME.message, '错误');
            end
        end
        
        function loadData(app)
            try
                [filename, pathname] = uigetfile({'*.tsp', 'TSP Files (*.tsp)'});
                if filename ~= 0
                    [app.CityCoords, ~] = DataInput.readTSPFile(fullfile(pathname, filename));
                    app.NumCitiesSpinner.Value = size(app.CityCoords, 1);
                    
                    % 创建新的可视化对象
                    if ~isempty(app.Visualizer)
                        delete(app.Visualizer);
                    end
                    app.Visualizer = Visualization(app.CityCoords);
                    app.Visualizer.setAxes(app.RouteAxes, app.ConvergenceAxes);
                    
                    app.StatusLabel.Text = sprintf('已加载文件：%s', filename);
                end
            catch ME
                app.StatusLabel.Text = '加载文件失败';
                errordlg(ME.message, '错误');
            end
        end
        
        function updatePlot(app)
            if ~isempty(app.Visualizer)
                delete(app.Visualizer);
            end
            if ~isempty(app.CityCoords)
                app.Visualizer = Visualization(app.CityCoords);
                app.Visualizer.setAxes(app.RouteAxes, app.ConvergenceAxes);
            end
        end
        
        function startOptimization(app)
            if isempty(app.CityCoords)
                errordlg('请先生成或加载数据', '错误');
                return;
            end
            
            % 获取PSO参数
            params = struct();
            params.numParticles = app.ParticlesSpinner.Value;
            params.maxIter = app.MaxIterSpinner.Value;
            params.w = app.WSpinner.Value;
            params.c1 = app.C1Spinner.Value;
            params.c2 = app.C2Spinner.Value;
            
            % 创建PSO求解器前清理旧的实例
            if ~isempty(app.PSOSolver)
                delete(app.PSOSolver);
            end
            app.PSOSolver = PSO_Solver(app.CityCoords, params);
            
            % 设置更新回调
            app.StatusLabel.Text = sprintf('正在优化... (0/%d)', params.maxIter);
            app.PSOSolver.UpdateCallback = @(route, iter, fitness) ...
                updateProgress(app, route, iter, fitness);
            
            % 更新按钮状态
            app.StartButton.Enable = 'off';
            app.PauseButton.Enable = 'on';
            app.LoadButton.Enable = 'off';
            app.GenerateButton.Enable = 'off';
            
            % 设置运行状态
            app.IsRunning = true;
            app.IsPaused = false;
            app.PSOSolver.IsRunning = true;  % 设置PSO求解器的运行状态
            app.PSOSolver.IsPaused = false;  % 确保PSO求解器的暂停状态正确
            
            % 启动优化
            try
                [bestRoute, bestFitness, history] = app.PSOSolver.optimize();
                app.StatusLabel.Text = sprintf('优化完成，最优路径长度：%.2f', bestFitness);
            catch ME
                app.StatusLabel.Text = '优化过程出错';
                errordlg(sprintf('错误: %s', ME.message), '错误');
                resetOptimization(app);
            end
            
            % 恢复按钮状态
            app.StartButton.Enable = 'on';
            app.PauseButton.Enable = 'off';
            app.LoadButton.Enable = 'on';
            app.GenerateButton.Enable = 'on';
            app.IsRunning = false;
        end
        
        function pauseOptimization(app)
            % 暂停优化
            app.IsPaused = ~app.IsPaused;
            if app.IsPaused
                app.PauseButton.Text = '继续';
                app.StatusLabel.Text = '已暂停';
                app.PSOSolver.pause();  % 调用PSO求解器的暂停方法
            else
                app.PauseButton.Text = '暂停';
                app.StatusLabel.Text = '正在优化...';
                app.PSOSolver.resume();  % 调用PSO求解器的继续方法
            end
        end
        
        function resetOptimization(app)
            % 停止优化器
            if ~isempty(app.PSOSolver)
                app.PSOSolver.stop();
            end
            
            % 重置可视化
            if ~isempty(app.Visualizer)
                delete(app.Visualizer);
                app.Visualizer = [];
            end
            
            % 重置状态和按钮
            app.IsRunning = false;
            app.IsPaused = false;
            app.StartButton.Enable = 'on';
            app.PauseButton.Enable = 'off';
            app.LoadButton.Enable = 'on';
            app.GenerateButton.Enable = 'on';
            app.PauseButton.Text = '暂停';
            app.StatusLabel.Text = '就绪';
            
            % 重新初始化显示
            if ~isempty(app.CityCoords)
                app.Visualizer = Visualization(app.CityCoords);
                app.Visualizer.setAxes(app.RouteAxes, app.ConvergenceAxes);
            end
        end
        
        function updateProgress(app, route, iter, fitness)
            % 更新进度显示
            app.StatusLabel.Text = sprintf('正在优化... (%d/%d)', ...
                iter, app.MaxIterSpinner.Value);
            app.Visualizer.updateRoute(route, iter, fitness);
        end
    end
    
    methods (Access = public)
        function app = TSP_PSO_GUI
            % 构造函数
            createComponents(app);
            
            % 显示GUI
            app.UIFigure.Visible = 'on';
        end
        
        function delete(app)
            % 清理PSO求解器
            if ~isempty(app.PSOSolver)
                delete(app.PSOSolver);
            end
            
            % 清理可视化对象
            if ~isempty(app.Visualizer)
                delete(app.Visualizer);
            end
        end
    end
end 