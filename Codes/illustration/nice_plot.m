function fig = nice_plot(varargin)
    % NICE_PLOT Plots Continuous Glucose Monitoring (CGM) data from workspace variables.
    %
    % Syntax:
    %   nice_plot(cgmStruct)   - Pass a struct containing time/glucose fields
    %   nice_plot(cgmTable)    - Pass a table or timetable
    %   nice_plot(t, g)        - Pass separate time (t) and glucose (g) vectors
    %   nice_plot(g)           - Pass glucose vector only (15-min sampling inferred)

    % 1. Extract Time (t), Glucose (g), and Time Format flag
    [t, g, isSampleIndex] = parse_cgm_input(varargin{:});

    % 2. Create Figure Window
    fig = figure('Name', 'CGM Data Trace', ...
                 'Color', 'w', ...
                 'Position', [150, 150, 1000, 500]);
    hold on;

    % 3. Plot CGM Trace
    plot(t, g, 'LineWidth', 2, 'Color', [0, 0.4470, 0.7410], ...
         'DisplayName', 'CGM Glucose');

    % 4. Formatting, Labels & Title
    title('Continuous Glucose Monitoring (CGM) Trace', ...
          'FontSize', 14, 'FontWeight', 'bold');
    ylabel('Glucose (mg/dL)', 'FontSize', 12, 'FontWeight', 'bold');

    % Smart X-Axis Labeling & Formatting
    if isdatetime(t)
        xlabel('Time (Date & Time)', 'FontSize', 12, 'FontWeight', 'bold');
        xtickformat('MMM dd, HH:mm');
    elseif isduration(t)
        xlabel('Elapsed Time (hh:mm)', 'FontSize', 12, 'FontWeight', 'bold');
    elseif isSampleIndex
        % Display formatted x-axis based on total duration of sample indices
        totalHours = max(t) * (15 / 60);
        if totalHours > 48
            xlabel('Elapsed Time (Days)', 'FontSize', 12, 'FontWeight', 'bold');
            % Convert sample indices into elapsed days for clear ticks
            t_days = (t - 1) * (15 / (60 * 24));
            clf(fig); hold on;
            plot(t_days, g, 'LineWidth', 2, 'Color', [0, 0.4470, 0.7410], 'DisplayName', 'CGM Glucose');
            title('Continuous Glucose Monitoring (CGM) Trace', 'FontSize', 14, 'FontWeight', 'bold');
            ylabel('Glucose (mg/dL)', 'FontSize', 12, 'FontWeight', 'bold');
            xlabel('Elapsed Time (Days)', 'FontSize', 12, 'FontWeight', 'bold');
            t = t_days;
        else
            xlabel('Elapsed Time (Hours)', 'FontSize', 12, 'FontWeight', 'bold');
            t_hours = (t - 1) * (15 / 60);
            clf(fig); hold on;
            plot(t_hours, g, 'LineWidth', 2, 'Color', [0, 0.4470, 0.7410], 'DisplayName', 'CGM Glucose');
            title('Continuous Glucose Monitoring (CGM) Trace', 'FontSize', 14, 'FontWeight', 'bold');
            ylabel('Glucose (mg/dL)', 'FontSize', 12, 'FontWeight', 'bold');
            xlabel('Elapsed Time (Hours)', 'FontSize', 12, 'FontWeight', 'bold');
            t = t_hours;
        end
    else
        xlabel('Time', 'FontSize', 12, 'FontWeight', 'bold');
    end

    % Set limits and axes styling
    xLimits = [min(t), max(t)];
    xlim(xLimits);
    minY = max(0, min(g) - 20);
    maxY = max(250, max(g) + 20);
    ylim([minY, maxY]);

    grid on;
    set(gca, 'GridLineStyle', ':', 'GridColor', [0.5 0.5 0.5], ...
             'GridAlpha', 0.5, 'FontSize', 11, 'LineWidth', 1);
    box on;

    legend('Location', 'northeastoutside', 'FontSize', 10);
    hold off;
end

%% Helper Function to Flexibly Parse Workspace Inputs
function [t, g, isSampleIndex] = parse_cgm_input(varargin)
    isSampleIndex = false;

    if nargin == 0
        error('Please pass a workspace variable or vectors (e.g., nice_plot(cgmData) or nice_plot(t, g)).');
        
    elseif nargin == 2
        % Direct vectors passed: nice_plot(t, g)
        t = varargin{1}(:);
        g = varargin{2}(:);
        return;
    end

    data = varargin{1};

    % Single numeric vector passed: nice_plot(g)
    if isnumeric(data) && isvector(data)
        g = data(:);
        t = (1:length(g))';
        isSampleIndex = true;
        return;
    end

    % Table or Timetable input
    if istable(data) || istimetable(data)
        if istimetable(data)
            t = data.Properties.RowTimes;
        end
        data = table2struct(data, 'ToScalar', true);
    end

    % Struct input
    if isstruct(data)
        fields = fieldnames(data);
        
        % Unencapsulate nested structs
        if length(fields) == 1 && isstruct(data.(fields{1}))
            data = data.(fields{1});
        end

        timeKeys    = {'Time', 'time', 'Timestamp', 'timestamp', 't', 'datetime', 'Date'};
        glucoseKeys = {'Glucose', 'glucose', 'CGM', 'cgm', 'GlucoseValue', 'g', 'BG'};

        t = [];
        g = [];

        for i = 1:length(timeKeys)
            if isfield(data, timeKeys{i})
                t = data.(timeKeys{i});
                break;
            end
        end

        for i = 1:length(glucoseKeys)
            if isfield(data, glucoseKeys{i})
                g = data.(glucoseKeys{i});
                break;
            end
        end

        if isempty(g)
            error('Could not auto-identify a glucose variable in the input.');
        end

        if isempty(t)
            warning('Time variable not found. Converting sample indices to elapsed time using 15-min interval.');
            t = (1:length(g))';
            isSampleIndex = true;
        end
    else
        error('Unsupported variable type. Input must be a struct, table, timetable, or vector(s).');
    end

    t = t(:);
    g = g(:);
    
    % Convert MATLAB datenum to datetime if necessary
    if isnumeric(t) && ~isSampleIndex && max(t) > 700000
        t = datetime(t, 'ConvertFrom', 'datenum');
    end
end