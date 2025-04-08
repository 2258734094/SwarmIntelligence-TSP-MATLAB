classdef TSP_Solver_GUI < matlab.apps.AppBase
    % TSP问题的多算法求解器图形界面
    % 支持PSO、GA和混合算法
    
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
        DataStatusLabel   matlab.ui.control.Label
        
        % 算法选择控件
        AlgorithmPanel    matlab.ui.container.Panel
        AlgorithmDropDown matlab.ui.control.DropDown
        AlgorithmDescLabel matlab.ui.control.Label
        
        % 通用参数面板
        CommonParamPanel  matlab.ui.container.Panel
        MaxIterSpinner    matlab.ui.control.Spinner
        
        % PSO参数面板
        PSOParamPanel     matlab.ui.container.Panel
        ParticlesSpinner  matlab.ui.control.Spinner
        WSpinner          matlab.ui.control.Spinner
        C1Spinner         matlab.ui.control.Spinner
        C2Spinner         matlab.ui.control.Spinner
        
        % GA参数面板
        GAParamPanel      matlab.ui.container.Panel
        PopulationSpinner matlab.ui.control.Spinner
        CrossoverRateSpinner matlab.ui.control.Spinner
        MutationRateSpinner matlab.ui.control.Spinner
        EliteCountSpinner matlab.ui.control.Spinner
        
        % 混合算法参数面板
        HybridParamPanel  matlab.ui.container.Panel
        HybridRatioSpinner matlab.ui.control.Spinner
        
        % 控制按钮
        ControlPanel      matlab.ui.container.Panel
        StartButton       matlab.ui.control.Button
        PauseButton       matlab.ui.control.Button
        ResetButton       matlab.ui.control.Button
        
        % 显示组件
        RouteAxes         matlab.ui.control.UIAxes
        ConvergenceAxes   matlab.ui.control.UIAxes
        StatusLabel       matlab.ui.control.Label
        
        % 数据和算法对象
        CityCoords        % 城市坐标
        Solver           % 求解器对象
        Visualizer        % 可视化对象
        
        % 运行状态
        IsRunning         logical
        IsPaused         logical
    end
    
    methods (Access = private)
        function createComponents(app)
            % 创建主窗口
            app.UIFigure = uifigure('Name', 'TSP优化求解器');
            app.UIFigure.Position = [100 100 1400 900];
            
            % 创建主网格布局
            app.MainGrid = uigridlayout(app.UIFigure, [1 2]);
            app.MainGrid.ColumnWidth = {'1.2x', '3x'};
            app.MainGrid.RowHeight = {'1x'};
            app.MainGrid.RowSpacing = 10;
            
            % 创建左侧面板（参数设置区）
            app.LeftPanel = uipanel(app.MainGrid);
            app.LeftPanel.Title = '参数设置';
            leftLayout = uigridlayout(app.LeftPanel, [7 1]);
            leftLayout.RowHeight = {'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit'};
            leftLayout.RowSpacing = 15;
            
            % 数据输入面板
            app.DataPanel = uipanel(leftLayout);
            app.DataPanel.Title = '数据输入';
            dataLayout = uigridlayout(app.DataPanel, [3 2]);
            dataLayout.RowSpacing = 5;
            
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
            
            % 添加数据状态标签
            app.DataStatusLabel = uilabel(dataLayout);
            app.DataStatusLabel.Text = '未加载数据';
            app.DataStatusLabel.HorizontalAlignment = 'center';
            
            % 算法选择面板
            app.AlgorithmPanel = uipanel(leftLayout);
            app.AlgorithmPanel.Title = '算法选择';
            algoLayout = uigridlayout(app.AlgorithmPanel, [2 1]);
            algoLayout.RowSpacing = 5;
            
            % 添加算法选择控件
            label = uilabel(algoLayout);
            label.Text = '求解算法：';
            app.AlgorithmDropDown = uidropdown(algoLayout);
            app.AlgorithmDropDown.Items = {'PSO', 'GA', '混合算法'};
            app.AlgorithmDropDown.Value = 'PSO';
            app.AlgorithmDropDown.ValueChangedFcn = @(src,event) algorithmChanged(app);
            
            % 添加算法描述标签
            app.AlgorithmDescLabel = uilabel(algoLayout);
            app.AlgorithmDescLabel.Text = 'PSO：粒子群优化算法，适合快速收敛';
            app.AlgorithmDescLabel.WordWrap = 'on';
            
            % 通用参数面板
            app.CommonParamPanel = uipanel(leftLayout);
            app.CommonParamPanel.Title = '通用参数';
            commonLayout = uigridlayout(app.CommonParamPanel, [1 2]);
            
            label = uilabel(commonLayout);
            label.Text = '最大迭代：';
            app.MaxIterSpinner = uispinner(commonLayout);
            app.MaxIterSpinner.Limits = [50 1000];
            app.MaxIterSpinner.Value = 200;
            
            % PSO参数面板
            app.PSOParamPanel = uipanel(leftLayout);
            app.PSOParamPanel.Title = 'PSO参数';
            psoLayout = uigridlayout(app.PSOParamPanel, [4 2]);
            psoLayout.RowSpacing = 5;
            
            % 添加PSO参数控件
            labels = {'粒子数量：', '惯性权重：', '学习因子c1：', '学习因子c2：'};
            defaults = [50, 0.9, 2.0, 2.0];
            limits = {[10 200], [0 1], [0 4], [0 4]};
            
            for i = 1:4
                label = uilabel(psoLayout);
                label.Text = labels{i};
                spinner = uispinner(psoLayout);
                spinner.Limits = limits{i};
                spinner.Value = defaults(i);
                
                switch i
                    case 1
                        app.ParticlesSpinner = spinner;
                    case 2
                        app.WSpinner = spinner;
                    case 3
                        app.C1Spinner = spinner;
                    case 4
                        app.C2Spinner = spinner;
                end
            end
            
            % GA参数面板
            app.GAParamPanel = uipanel(leftLayout);
            app.GAParamPanel.Title = 'GA参数';
            app.GAParamPanel.Visible = 'off';
            gaLayout = uigridlayout(app.GAParamPanel, [4 2]);
            gaLayout.RowSpacing = 5;
            
            % 添加GA参数控件
            gaLabels = {'种群大小：', '交叉率：', '变异率：', '精英数量：'};
            gaDefaults = [100, 0.8, 0.1, 2];
            gaLimits = {[10 200], [0 1], [0 1], [0 10]};
            
            for i = 1:4
                label = uilabel(gaLayout);
                label.Text = gaLabels{i};
                spinner = uispinner(gaLayout);
                spinner.Limits = gaLimits{i};
                spinner.Value = gaDefaults(i);
                
                switch i
                    case 1
                        app.PopulationSpinner = spinner;
                    case 2
                        app.CrossoverRateSpinner = spinner;
                    case 3
                        app.MutationRateSpinner = spinner;
                    case 4
                        app.EliteCountSpinner = spinner;
                end
            end
            
            % 混合算法参数面板
            app.HybridParamPanel = uipanel(leftLayout);
            app.HybridParamPanel.Title = '混合算法参数';
            app.HybridParamPanel.Visible = 'off';
            hybridLayout = uigridlayout(app.HybridParamPanel, [1 2]);
            
            label = uilabel(hybridLayout);
            label.Text = 'PSO/GA比例：';
            app.HybridRatioSpinner = uispinner(hybridLayout);
            app.HybridRatioSpinner.Limits = [0 1];
            app.HybridRatioSpinner.Value = 0.5;
            
            % 控制按钮面板
            app.ControlPanel = uipanel(leftLayout);
            app.ControlPanel.Title = '控制';
            buttonLayout = uigridlayout(app.ControlPanel, [1 3]);
            buttonLayout.RowSpacing = 5;
            
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
            rightLayout.RowSpacing = 15;
            rightLayout.RowHeight = {'1.2x', '1x'};
            
            % 创建路径显示和收敛曲线坐标轴
            app.RouteAxes = uiaxes(rightLayout);
            app.RouteAxes.Title.String = '当前最优路径';
            app.RouteAxes.XLabel.String = 'X坐标';
            app.RouteAxes.YLabel.String = 'Y坐标';
            app.RouteAxes.FontSize = 10;
            
            app.ConvergenceAxes = uiaxes(rightLayout);
            app.ConvergenceAxes.Title.String = '收敛曲线';
            app.ConvergenceAxes.XLabel.String = '迭代次数';
            app.ConvergenceAxes.YLabel.String = '路径长度';
            app.ConvergenceAxes.FontSize = 10;
            
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
                
                app.DataStatusLabel.Text = sprintf('已生成%d个城市的随机数据', numCities);
            catch ME
                app.DataStatusLabel.Text = '生成数据失败';
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
                    
                    app.DataStatusLabel.Text = sprintf('已加载文件：%s', filename);
                end
            catch ME
                app.DataStatusLabel.Text = '加载文件失败';
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
            
            % 获取通用参数
            params = struct();
            params.maxIter = app.MaxIterSpinner.Value;
            
            % 根据选择的算法设置特定参数
            switch app.AlgorithmDropDown.Value
                case 'PSO'
                    params.numParticles = app.ParticlesSpinner.Value;
                    params.w = app.WSpinner.Value;
                    params.c1 = app.C1Spinner.Value;
                    params.c2 = app.C2Spinner.Value;
                    app.Solver = PSO_Solver(app.CityCoords, params);
                    
                case 'GA'
                    params.populationSize = app.PopulationSpinner.Value;
                    params.crossoverRate = app.CrossoverRateSpinner.Value;
                    params.mutationRate = app.MutationRateSpinner.Value;
                    params.eliteCount = app.EliteCountSpinner.Value;
                    app.Solver = GA_Solver(app.CityCoords, params);
                    
                case '混合算法'
                    % 混合算法参数
                    params.psoRatio = app.HybridRatioSpinner.Value;
                    % PSO参数
                    params.numParticles = app.ParticlesSpinner.Value;
                    params.w = app.WSpinner.Value;
                    params.c1 = app.C1Spinner.Value;
                    params.c2 = app.C2Spinner.Value;
                    % GA参数
                    params.populationSize = app.PopulationSpinner.Value;
                    params.crossoverRate = app.CrossoverRateSpinner.Value;
                    params.mutationRate = app.MutationRateSpinner.Value;
                    params.eliteCount = app.EliteCountSpinner.Value;
                    app.Solver = Hybrid_Solver(app.CityCoords, params);
            end
            
            % 设置更新回调
            app.StatusLabel.Text = sprintf('正在优化... (0/%d)', params.maxIter);
            app.Solver.UpdateCallback = @(route, iter, fitness) ...
                updateProgress(app, route, iter, fitness);
            
            % 更新按钮状态
            app.StartButton.Enable = 'off';
            app.PauseButton.Enable = 'on';
            app.LoadButton.Enable = 'off';
            app.GenerateButton.Enable = 'off';
            app.AlgorithmDropDown.Enable = 'off';
            
            % 设置运行状态
            app.IsRunning = true;
            app.IsPaused = false;
            app.Solver.IsRunning = true;
            app.Solver.IsPaused = false;
            
            % 启动优化
            try
                [bestRoute, bestFitness, history] = app.Solver.optimize();
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
            app.AlgorithmDropDown.Enable = 'on';
            app.IsRunning = false;
        end
        
        function pauseOptimization(app)
            % 暂停优化
            app.IsPaused = ~app.IsPaused;
            if app.IsPaused
                app.PauseButton.Text = '继续';
                app.StatusLabel.Text = '已暂停';
                app.Solver.pause();  % 调用PSO求解器的暂停方法
            else
                app.PauseButton.Text = '暂停';
                app.StatusLabel.Text = '正在优化...';
                app.Solver.resume();  % 调用PSO求解器的继续方法
            end
        end
        
        function resetOptimization(app)
            % 停止优化器
            if ~isempty(app.Solver)
                app.Solver.stop();
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
        
        function algorithmChanged(app)
            % 根据选择的算法显示/隐藏相应的参数面板
            switch app.AlgorithmDropDown.Value
                case 'PSO'
                    app.PSOParamPanel.Visible = 'on';
                    app.GAParamPanel.Visible = 'off';
                    app.HybridParamPanel.Visible = 'off';
                    app.AlgorithmDescLabel.Text = 'PSO：粒子群优化算法，适合快速收敛';
                    
                case 'GA'
                    app.PSOParamPanel.Visible = 'off';
                    app.GAParamPanel.Visible = 'on';
                    app.HybridParamPanel.Visible = 'off';
                    app.AlgorithmDescLabel.Text = 'GA：遗传算法，适合全局搜索';
                    
                case '混合算法'
                    app.PSOParamPanel.Visible = 'on';
                    app.GAParamPanel.Visible = 'on';
                    app.HybridParamPanel.Visible = 'on';
                    app.AlgorithmDescLabel.Text = '混合算法：结合PSO和GA的优势，先快速收敛后精细搜索';
            end
        end
    end
    
    methods (Access = public)
        function app = TSP_Solver_GUI
            % 构造函数
            createComponents(app);
            
            % 显示GUI
            app.UIFigure.Visible = 'on';
        end
        
        function delete(app)
            % 清理PSO求解器
            if ~isempty(app.Solver)
                delete(app.Solver);
            end
            
            % 清理可视化对象
            if ~isempty(app.Visualizer)
                delete(app.Visualizer);
            end
        end
    end
end 