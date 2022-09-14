% stylize a MATLAB figure


function stylize_figure(fig, figureWidth, figureHeight, options)

    arguments
        fig (1,1) matlab.ui.Figure
        figureWidth (1,1) double {mustBePositive} = 6
        figureHeight (1,1) double {mustBePositive} = 4
        options.ax.font_name_axes (1,1) string = NIConstants.figureConfig.font.axes
        options.ax.font_name_label (1,1) string = NIConstants.figureConfig.font.label
        options.ax.font_name_title (1,1) string = NIConstants.figureConfig.font.title
        options.ax.font_size (1,1) double {mustBePositive} = max(figureHeight, 9)
        options.ax.font_title_scale (1,1) double {mustBePositive} = 1.2
        options.ax.font_weight (1,1) string {mustBeMember(options.ax.font_weight, ["normal", "bold"])} = "bold"
        options.ax.interpreter (1,1) {mustBeMember(options.ax.interpreter, ["latex", "tex", "none"])} = "latex"
        options.ax.box (1,1) logical = true
        options.ax.ax_color (1,3) double {mustBeInRange(options.ax.ax_color, 0, 1)} = [0.3843 0.3961 0.4039]
        options.ax.tick (1,3) logical = [true, true, true]
        options.ax.tick_direction (1,1) {mustBeMember(options.ax.tick_direction, ["in", "out"])} = "out"
        options.ax.tick_length (1,1) double {mustBePositive} = 0.01
        options.ax.override_line_color (1,1) logical = true
        options.ax.linewidth (1,1) double {mustBePositive} = 1.0
        options.ax.override_line_width (1,1) logical = true
        options.ax.marker_size (1,1) double {mustBePositive} = 5
        options.ax.override_marker_size (1,1) logical = true
        options.legend.font_name (1,1) string = NIConstants.figureConfig.font.legend
        options.legend.font_size (1,1) double {mustBePositive} = 9
        options.legend.font_weight (1,1) string {mustBeMember(options.legend.font_weight, ["normal", "bold"])} = "bold"
        options.legend.interpreter (1,1) {mustBeMember(options.legend.interpreter, ["latex", "tex", "none"])} = "latex"
        options.legend.box (1,1) logical = false
        options.legend.location (1,1) string {mustBeMember(options.legend.location, ["best", "north", "south", ...
            "east", "west", "northeast", "northwest", "southeast", "southwest", "northoutside", ...
            "southoutside", "eastoutside", "westoutside", "northeastoutside", "northwestoutside", ...
            "southeastoutside", "southwestoutside"])} = "best"
    end

    % set the figure size
    set(fig, 'Units', 'inches');
    set(fig, 'Position', [0 0 figureWidth figureHeight]);

    % get all the axes in the figure
    axes = findall(fig, 'Type', 'axes');
    for i = 1:length(axes)
        stylize_axes(axes(i), font_name_axes=options.ax.font_name_axes, ...
            font_name_label=options.ax.font_name_label, ...
            font_name_title=options.ax.font_name_title, ...
            font_size=options.ax.font_size, ...
            font_title_scale=options.ax.font_title_scale, ...
            font_weight=options.ax.font_weight, ...
            interpreter=options.ax.interpreter, ...
            box=options.ax.box, ...
            ax_color=options.ax.ax_color, ...
            tick=options.ax.tick, ...
            tick_direction=options.ax.tick_direction, ...
            tick_length=options.ax.tick_length, ...
            override_line_color=options.ax.override_line_color, ...
            linewidth=options.ax.linewidth, ...
            override_line_width=options.ax.override_line_width, ...
            marker_size=options.ax.marker_size, ...
            override_marker_size=options.ax.override_marker_size);
    end

    % get all the legends in the figure
    legends = findobj(fig, 'Type', 'Legend');
    for i = 1:length(legends)
        stylize_legend(legends(i), font_name_axes=options.legend.font_name, ...
            font_size=options.legend.font_size, ...
            font_weight=options.legend.font_weight, ...
            interpreter=options.legend.interpreter, ...
            box=options.legend.box, ...
            location=options.legend.location);
    end

end


function stylize_axes(ax, options)

    arguments
        ax (1,1) matlab.graphics.axis.Axes
        options.font_name_axes (1,1) string = NIConstants.figureConfig.font.axes
        options.font_name_label (1,1) string = NIConstants.figureConfig.font.label
        options.font_name_title (1,1) string = NIConstants.figureConfig.font.title
        options.font_size (1,1) double {mustBePositive} = 9
        options.font_title_scale (1,1) double {mustBePositive} = 1.2
        options.font_weight (1,1) string {mustBeMember(options.font_weight, ["normal", "bold"])} = "bold"
        options.interpreter (1,1) {mustBeMember(options.interpreter, ["latex", "tex", "none"])} = "latex"
        options.box (1,1) logical = true
        options.ax_color (1,3) double {mustBeInRange(options.ax_color, 0, 1)} = [0.3843 0.3961 0.4039]
        options.tick (1,3) logical = [true, true, true]
        options.tick_direction (1,1) {mustBeMember(options.tick_direction, ["in", "out"])} = "out"
        options.tick_length (1,1) double {mustBePositive} = 0.01
        options.override_line_color (1,1) logical = true
        options.linewidth (1,1) double {mustBePositive} = 1.0
        options.override_line_width (1,1) logical = true
        options.marker_size (1,1) double {mustBePositive} = 5
        options.override_marker_size (1,1) logical = true
    end

    ax.FontName = options.font_name_axes;
    ax.FontSize = options.font_size;
    ax.FontWeight = options.font_weight;

    ax.XLabel.FontName = NIConstants.figureConfig.font.label;
    ax.YLabel.FontName = NIConstants.figureConfig.font.label;
    ax.ZLabel.FontName = NIConstants.figureConfig.font.label;

    ax.XLabel.FontSize = options.font_size;
    ax.YLabel.FontSize = options.font_size;
    ax.ZLabel.FontSize = options.font_size;

    ax.XLabel.FontWeight = options.font_weight;
    ax.YLabel.FontWeight = options.font_weight;
    ax.ZLabel.FontWeight = options.font_weight;

    ax.XLabel.Interpreter = options.interpreter;
    ax.YLabel.Interpreter = options.interpreter;
    ax.ZLabel.Interpreter = options.interpreter;

    ax.Title.FontName = NIConstants.figureConfig.font.title;
    ax.Title.FontSize = options.font_size * options.font_title_scale;
    ax.Title.FontWeight = options.font_weight;
    ax.Title.Interpreter = options.interpreter;

    ax.Box = options.box;
    ax.TickDir = options.tick_direction;
    ax.TickLength = [options.tick_length, options.tick_length];
    ax.XMinorTick = options.tick(1);
    ax.YMinorTick = options.tick(2);
    ax.ZMinorTick = options.tick(3);
    ax.XColor = options.ax_color;
    ax.YColor = options.ax_color;
    ax.ZColor = options.ax_color;
    ax.LineWidth = options.linewidth;

    lines = get(ax, 'Children');
    for i = 1:length(lines)
        if options.override_line_color
            lines(i).Color = NIConstants.figureConfig.colorSet.normal{i};
        end
        if options.override_line_width
            lines(i).LineWidth = options.linewidth;
        end
        if options.override_marker_size
            lines(i).MarkerSize = options.marker_size;
        end
        lines(i).MarkerFaceColor = lines(i).Color;
    end

end


function stylize_legend(legend, options)

    arguments
        legend (1,1) matlab.graphics.illustration.Legend
        options.font_name (1,1) string = NIConstants.figureConfig.font.legend
        options.font_size (1,1) double {mustBePositive} = 9
        options.font_weight (1,1) string {mustBeMember(options.font_weight, ["normal", "bold"])} = "bold"
        options.interpreter (1,1) {mustBeMember(options.interpreter, ["latex", "tex", "none"])} = "latex"
        options.box (1,1) logical = false
        options.location (1,1) string {mustBeMember(options.location, ["best", "north", "south", ...
            "east", "west", "northeast", "northwest", "southeast", "southwest", "northoutside", ...
            "southoutside", "eastoutside", "westoutside", "northeastoutside", "northwestoutside", ...
            "southeastoutside", "southwestoutside"])} = "best"
    end

    legend.FontName = options.font_name;
    legend.FontSize = options.font_size;
    legend.FontWeight = options.font_weight;
    legend.Interpreter = options.interpreter;
    legend.Box = options.box;
    legend.Location = options.location;

end