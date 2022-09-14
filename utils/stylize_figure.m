% stylize a MATLAB figure


function stylize_figure(fig, figureWidth, figureHeight, options)

    arguments
        fig (1,1) matlab.ui.Figure
        figureWidth (1,1) double {mustBePositive} = 6
        figureHeight (1,1) double {mustBePositive} = 4
        options.ax_font_name_axes (1,1) string = NIConstants.figureConfig.font.axes
        options.ax_font_name_label (1,1) string = NIConstants.figureConfig.font.label
        options.ax_font_name_title (1,1) string = NIConstants.figureConfig.font.title
        options.ax_font_size (1,1) double {mustBePositive} = max(figureHeight, 9)
        options.ax_font_title_scale (1,1) double {mustBePositive} = 1.2
        options.ax_font_weight (1,1) string {mustBeMember(options.ax_font_weight, ["normal", "bold"])} = "bold"
        options.ax_interpreter (1,1) {mustBeMember(options.ax_interpreter, ["latex", "tex", "none"])} = "latex"
        options.ax_box (1,1) logical = true
        options.ax_grid (1,3) logical = [false, false, false]
        options.ax_minor_grid (1,3) logical = [false, false, false]
        options.ax_color (1,3) double {mustBeInRange(options.ax_color, 0, 1)} = [0.3843 0.3961 0.4039]
        options.ax_tick (1,3) logical = [true, true, true]
        options.ax_tick_direction (1,1) {mustBeMember(options.ax_tick_direction, ["in", "out"])} = "out"
        options.ax_tick_length (1,1) double {mustBePositive} = 0.01
        options.ax_override_line_color (1,1) logical = true
        options.ax_linewidth (1,1) double {mustBePositive} = 1.0
        options.ax_override_line_width (1,1) logical = true
        options.ax_marker_size (1,1) double {mustBePositive} = 5
        options.ax_override_marker_size (1,1) logical = true
        options.legend_font_name (1,1) string = NIConstants.figureConfig.font.legend
        options.legend_font_size (1,1) double {mustBePositive} = 9
        options.legend_font_weight (1,1) string {mustBeMember(options.legend_font_weight, ["normal", "bold"])} = "bold"
        options.legend_interpreter (1,1) {mustBeMember(options.legend_interpreter, ["latex", "tex", "none"])} = "latex"
        options.legend_box (1,1) logical = false
        options.legend_location (1,1) string {mustBeMember(options.legend_location, ["best", "north", "south", ...
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
        stylize_axes(axes(i), font_name_axes=options.ax_font_name_axes, ...
            font_name_label=options.ax_font_name_label, ...
            font_name_title=options.ax_font_name_title, ...
            font_size=options.ax_font_size, ...
            font_title_scale=options.ax_font_title_scale, ...
            font_weight=options.ax_font_weight, ...
            interpreter=options.ax_interpreter, ...
            box=options.ax_box, ...
            grid=options.ax_grid, ...
            minor_grid=options.ax_minor_grid, ...
            ax_color=options.ax_color, ...
            tick=options.ax_tick, ...
            tick_direction=options.ax_tick_direction, ...
            tick_length=options.ax_tick_length, ...
            override_line_color=options.ax_override_line_color, ...
            linewidth=options.ax_linewidth, ...
            override_line_width=options.ax_override_line_width, ...
            marker_size=options.ax_marker_size, ...
            override_marker_size=options.ax_override_marker_size);
    end

    % get all the legends in the figure
    legends = findobj(fig, 'Type', 'Legend');
    for i = 1:length(legends)
        stylize_legend(legends(i), font_name=options.legend_font_name, ...
            font_size=options.legend_font_size, ...
            font_weight=options.legend_font_weight, ...
            interpreter=options.legend_interpreter, ...
            box=options.legend_box, ...
            location=options.legend_location);
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
        options.grid (1,3) logical = [false, false, false]
        options.minor_grid (1,3) logical = [false, false, false]
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
    ax.XGrid = options.grid(1);
    ax.YGrid = options.grid(2);
    ax.ZGrid = options.grid(3);
    ax.XMinorGrid = options.minor_grid(1);
    ax.YMinorGrid = options.minor_grid(2);
    ax.ZMinorGrid = options.minor_grid(3);
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