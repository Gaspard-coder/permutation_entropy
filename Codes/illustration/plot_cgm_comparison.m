function fig = plot_cgm_comparison(healthyInput, diabeticInput)
% PLOT_CGM_COMPARISON Plots two CGM data sources (Healthy vs. Diabetic) on the same graph.
%
% Syntax:
%   plot_cgm_comparison(healthyData, diabeticData)
%
% Inputs:
%   healthyData  - Struct, Table/Timetable, or Glucose vector for healthy control
%   diabeticData - Struct, Table/Timetable, or Glucose vector for diabetic subject

% 1. Parse both CGM inputs
[t_h, g_h, isSample_h] = parse_single_cgm(healthyInput);
[t_d, g_d, isSample_d] = parse_single_cgm(diabeticInput);

% 2. Normalize Time Vectors to standard units if needed
[t_h, xLabelStr_h] = format_time_axis(t_h, isSample_h);
[t_d, xLabelStr_d] = format_time_axis(t_d, isSample_d);

% Choose x-axis label based on healthy source (or default to 'Time')
xLabelStr = xLabelStr_h;
if isempty(xLabelStr)
    xLabelStr = xLabelStr_d;
end

% 3. Create Figure Window
fig = figure('Name', 'CGM Comparison: Healthy vs. Diabetic', ...
    'Color', 'w', ...
    'Position', [150, 150, 1050, 550]);
hold on;

% 4. Plot Target Glucose Range Band (70 - 180 mg/dL)
all_t = [t_h; t_d];
xMin = min(all_t);
xMax = max(all_t);

%patch([xMin xMax xMax xMin], [70 70 180 180], [0.85 0.95 0.85], ...
%    'EdgeColor', 'none', 'FaceAlpha', 0.4, 'DisplayName', 'Target Range (70-180 mg/dL)');

% Add reference lines for standard boundaries
%yline(70,  '--', '70 mg/dL (Hypo Limit)', 'Color', [0.8 0.2 0.2], 'LineWidth', 1, 'HandleVisibility', 'off');
%yline(180, '--', '180 mg/dL (Hyper Limit)', 'Color', [0.8 0.4 0.0], 'LineWidth', 1, 'HandleVisibility', 'off');

% 5. Plot CGM Traces
% Healthy Control: Blue
plot(t_h, g_h, 'LineWidth', 2, 'Color', [0.13, 0.55, 1], ...
    'DisplayName', 'Healthy Subject');

% Diabetic Subject: Crimson Red
plot(t_d, g_d, 'LineWidth', 2, 'Color', [0.85, 0.15, 0.15], ...
    'DisplayName', 'Diabetic Subject');

% 6. Formatting, Labels & Title
% title('Continuous Glucose Monitoring (CGM) Comparison', ...
%     'FontSize', 14, 'FontWeight', 'bold');
ylabel('Glucose (mg/dL)', 'FontSize', 15, 'FontWeight', 'bold');
xlabel(xLabelStr, 'FontSize', 15, 'FontWeight', 'bold');

if isdatetime(t_h)
    xtickformat('MMM dd, HH:mm');
end

% Dynamic axis limits
xlim([xMin, xMax]);
all_g = [g_h; g_d];
minY = max(0, min(all_g) - 20);
maxY = max(250, max(all_g) + 20);
ylim([minY, maxY]);

% Styling
grid on;
set(gca, 'GridLineStyle', ':', 'GridColor', [0.5 0.5 0.5], ...
    'GridAlpha', 0.5, 'FontSize', 11, 'LineWidth', 1);
box on;
legend('Location', 'northeastoutside', 'FontSize', 12);
hold off;
end

%% Helper Function: Format Time Axis
function [t_out, xLabelStr] = format_time_axis(t, isSampleIndex)
xLabelStr = 'Time';
t_out = t;

if isdatetime(t)
    xLabelStr = 'Time (Date & Time)';
elseif isduration(t)
    xLabelStr = 'Elapsed Time (hh:mm)';
elseif isSampleIndex
    totalHours = max(t) * (15 / 60);
    if totalHours > 48
        t_out = (t - 1) * (15 / (60 * 24)); % Convert to Days
        xLabelStr = 'Elapsed Time (Days)';
    else
        t_out = (t - 1) * (15 / 60);       % Convert to Hours
        xLabelStr = 'Elapsed Time (Hours)';
    end
end
end

%% Helper Function: Parse Single CGM Source
function [t, g, isSampleIndex] = parse_single_cgm(data)
isSampleIndex = false;

% 1. Cell array input {t, g}
if iscell(data) && length(data) == 2
    t = data{1}(:);
    g = data{2}(:);
    return;
end

% 2. Single numeric vector (glucose values only)
if isnumeric(data) && isvector(data)
    g = data(:);
    t = (1:length(g))';
    isSampleIndex = true;
    return;
end

% 3. Table or Timetable input
if istable(data) || istimetable(data)
    if istimetable(data)
        t = data.Properties.RowTimes;
    end
    data = table2struct(data, 'ToScalar', true);
end

% 4. Struct input
if isstruct(data)
    fields = fieldnames(data);
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
        t = (1:length(g))';
        isSampleIndex = true;
    end
else
    error('Unsupported variable type. Input must be a struct, table, timetable, vector, or {t, g} cell array.');
end

t = t(:);
g = g(:);

% Convert MATLAB datenum to datetime if needed
if isnumeric(t) && ~isSampleIndex && max(t) > 700000
    t = datetime(t, 'ConvertFrom', 'datenum');
end
end