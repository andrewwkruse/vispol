%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% creates a color wheel

classdef color_wheel
    properties
        fig
        ax
        pax
        im
        rgb
        alpha_channel
    end
    methods
        function obj = color_wheel(varargin)
            %%%%% creates a color_wheel class object and sets 
            %%%%% defaults
            sz_default = 512;
            xspline_default = [0, 5, 20, 40, 73, 77, 100];
            yspline_default = [0.0, 6.6, 13.7, 19.4, 26.4, 24.1, 0.0];
            %%%%%%%%%%%%
            p = inputParser;
            
            addParameter(p, 'xspline', xspline_default);
            addParameter(p, 'yspline', yspline_default);
            addParameter(p, 'size', sz_default);
            parse(p, varargin{:});
            
            xspline = p.Results.xspline;
            yspline = p.Results.yspline;
            sz = p.Results.size;
            
            obj.alpha_channel = zeros(sz, sz);
            M_array = zeros(sz, sz);
            h_array = zeros(sz, sz);
            obj.rgb = zeros(sz, sz);
            radius = sz / 2;
            fade_start = 0.995;
            fade_stop = 1.005;
            for x = 1:sz
                xdist = (x - 1) - radius;
                for y = 1:sz
                    ydist = (y - 1) - radius;
                    rdist = sqrt(xdist^2 + ydist^2)/radius;
                    if rdist <= fade_start
                        obj.alpha_channel(x,y) = 1;
                        M_array(x,y) = rdist * max(yspline);
                        h_array(x,y) = atan(ydist/xdist)*2;
                    elseif rdist > fade_start && rdist < fade_stop
                        obj.alpha_channel(x,y) = (-1 / ...
                            (fade_stop - fade_start))*(rdist - fade_stop);
                        M_array(x,y) = max(yspline);
                        h_array(x,y) = atan(ydist/xdist)*2;
                    end
                end
            end
            bounds = Jbounds(M_array, xspline, yspline);
            J_array = (bounds(:,:,2) + bounds(:,:,1)) ./ 2;
            obj.rgb = UCStosRGB(J_array, M_array, h_array);
        end
        function obj = create_fig(obj, varargin)
            %%%%%% defaults
            fig_num_default = -1; % -1 indicates new figure
            Rticks_default = linspace(0,1,5);
            Rlab_default = linspace(0,1,5);
            Tticks_default = linspace(0,330,12);
            Tlab_default = cat(2, linspace(0,150,6), linspace(0,150,6));
            %%%%%%%%
            p = inputParser;
            addParameter(p, 'fignum', fig_num_default);
            addParameter(p, 'RTick', Rticks_default);
            addParameter(p, 'RTickLabel', Rlab_default);
            addParameter(p, 'ThetaTick', Tticks_default);
            addParameter(p, 'ThetaTickLabel', Tlab_default);
            addParameter(p, 'visible', 'on');
            parse(p,varargin{:});
            p.Results.fignum

            fig_num = p.Results.fignum;
            
            if fig_num < 0 || mod(fig_num,1) ~= 0
                obj.fig = figure();
            else
                obj.fig = figure(fig_num);
            end
            
            if ~strcmp(p.Results.visible, 'on')
                set(obj.fig, 'visible', 'off');
            end
            obj.ax = gca();
            if isa(obj.ax, 'matlab.graphics.axis.PolarAxes')
                obj.ax = axes;
            end
            
            obj.pax = polaraxes;
            set(obj.pax, 'color', 'none');
            
            obj.im = image('Cdata', obj.rgb, 'Xdata', [0,1], ...
                            'Ydata', [0,1], 'Parent', obj.ax, ...
                            'AlphaData', obj.alpha_channel);
            set(obj.ax, 'Xlim', [0,1], 'YLim', [0,1], ...
                'DataAspectRatio', [1, 1, 1], 'visible', 'off');
            obj.pax.ThetaTick = p.Results.ThetaTick;
            obj.pax.ThetaTickLabel = p.Results.ThetaTickLabel;
            obj.pax.RTick = p.Results.RTick;
            obj.pax.RTickLabel = p.Results.RTickLabel;
            obj.pax.ThetaZeroLocation = 'top';
        end            
        
    end
end

