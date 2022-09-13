% stylize a MATLAB figure to look like a plot in a journal
%
%


function stylize_figure(fig, figureWidth, figureHeight)

    % Set the figure size
    set(fig, 'Units', 'inches');
    set(fig, 'Position', [0 0 figureWidth figureHeight]);

    % estimate the font size from the figure size
    fontSize = max(figureHeight, 9);

    % get all the axes in the figure
    axes = findall(fig, 'Type', 'axes');
    for i = 1:length(axes)
        stylize_axes(axes(i), fontSize);
    end

    % check if the figure has a legend
    legend = findobj(fig, 'Type', 'Legend');
    if ~isempty(legend)
        stylize_legend(legend, fontSize);
    end

end


function stylize_axes(ax, fontSize)

    ax.FontName = 'Yu Mincho';
    ax.FontSize = fontSize;
    ax.FontWeight = 'bold';

    ax.XLabel.FontName = 'Yu Mincho';
    ax.YLabel.FontName = 'Yu Mincho';
    ax.ZLabel.FontName = 'Yu Mincho';

    ax.XLabel.FontSize = fontSize;
    ax.YLabel.FontSize = fontSize;
    ax.ZLabel.FontSize = fontSize;

    ax.XLabel.FontWeight = 'bold';
    ax.YLabel.FontWeight = 'bold';
    ax.ZLabel.FontWeight = 'bold';

    ax.XLabel.Interpreter = 'latex';
    ax.YLabel.Interpreter = 'latex';
    ax.ZLabel.Interpreter = 'latex';

    ax.Title.FontName = 'Yu Mincho';
    ax.Title.FontSize = fontSize * 1.25;
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
        lines(i).Color = NIConstants.colorSet.normal{i};
        lines(i).LineWidth = 1;
        lines(i).MarkerSize = 4;
        lines(i).MarkerFaceColor = lines(i).Color;
    end

end


function stylize_legend(legend, fontSize)

    legend.FontName = 'Yu Mincho';
    legend.FontSize = fontSize;
    legend.FontWeight = 'bold';
    legend.Interpreter = 'latex';
    legend.Box = 'off';
    legend.Location = 'northeast';

end