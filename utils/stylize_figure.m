% stylize a MATLAB figure


function stylize_figure(fig, figureWidth, figureHeight, options)

    arguments
        fig (1,1) matlab.ui.Figure
        figureWidth (1,1) double {mustBePositive} = 6
        figureHeight (1,1) double {mustBePositive} = 4
        options.override_line_color (1,1) logical = false
    end

    % Set the figure size
    set(fig, 'Units', 'inches');
    set(fig, 'Position', [0 0 figureWidth figureHeight]);

    % estimate the font size from the figure size
    fontSize = max(figureHeight, 9);

    % get all the axes in the figure
    axes = findall(fig, 'Type', 'axes');
    for i = 1:length(axes)
        stylize_axes(axes(i), font_size=fontSize, ...
            override_line_color=options.override_line_color);
    end

    % check if the figure has a legend
    legends = findobj(fig, 'Type', 'Legend');
    if ~isempty(legends)
        for i = 1:length(legends)
            stylize_legend(legends(i), font_size=fontSize);
        end
    end

end


function stylize_axes(ax, options)

    arguments
        ax (1,1) matlab.graphics.axis.Axes
        options.font_size (1,1) double {mustBePositive} = 9
        options.override_line_color (1,1) logical = false
    end

    ax.FontName = NIConstants.figureConfig.font.axes;
    ax.FontSize = options.font_size;
    ax.FontWeight = 'bold';

    ax.XLabel.FontName = NIConstants.figureConfig.font.label;
    ax.YLabel.FontName = NIConstants.figureConfig.font.label;
    ax.ZLabel.FontName = NIConstants.figureConfig.font.label;

    ax.XLabel.FontSize = options.font_size;
    ax.YLabel.FontSize = options.font_size;
    ax.ZLabel.FontSize = options.font_size;

    ax.XLabel.FontWeight = 'bold';
    ax.YLabel.FontWeight = 'bold';
    ax.ZLabel.FontWeight = 'bold';

    ax.XLabel.Interpreter = 'latex';
    ax.YLabel.Interpreter = 'latex';
    ax.ZLabel.Interpreter = 'latex';

    ax.Title.FontName = NIConstants.figureConfig.font.title;
    ax.Title.FontSize = options.font_size * 1.25;
    ax.Title.FontWeight = 'bold';
    ax.Title.Interpreter = 'latex';

    ax.Box = 'on';
    ax.TickDir = 'out';
    ax.TickLength = [0.01 0.02];
    ax.XMinorTick = 'on';
    ax.YMinorTick = 'on';
    ax.ZMinorTick = 'on';
    ax.XColor = [0.3843    0.3961    0.4039];
    ax.YColor = [0.3843    0.3961    0.4039];
    ax.ZColor = [0.3843    0.3961    0.4039];
    ax.LineWidth = 1.0;

    lines = get(ax, 'Children');
    for i = 1:length(lines)
        if ~options.override_line_color
            lines(i).Color = NIConstants.figureConfig.colorSet.normal{i};
        end
        lines(i).LineWidth = 1;
        lines(i).MarkerSize = 4;
        lines(i).MarkerFaceColor = lines(i).Color;
    end

end


function stylize_legend(legend, options)

    arguments
        legend (1,1) matlab.graphics.illustration.Legend
        options.font_size (1,1) double {mustBePositive} = 9
    end

    legend.FontName = NIConstants.figureConfig.font.legend;
    legend.FontSize = options.font_size;
    legend.FontWeight = 'bold';
    legend.Interpreter = 'latex';
    legend.Box = 'off';
    legend.Location = 'northeast';

end