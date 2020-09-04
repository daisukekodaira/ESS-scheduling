%----------------------------------------------------
% Input:(y,highest, lowest)
% "y": What you descriped for each steps
% "highest": Highest value of Y axis
% "lowest": Lowest value of Y axis
%----------------------------------------------------

function graph_desc(y, load_train, name)
    global_var_declare;
    f_title = {char(strcat('Predicted train load (', name, ')')'), ...
                   char(strcat('Optimized predicted load (', name, ')'))};
    
    % x and y axis arrange -------------------------------
    t = datetime([2017  01  01  00  00  00]);
    t.Format = 'DD:HH:mm';
    for i = 1:size(load_train,1)
        t(i+1) = t(i) + minutes(24*60/size(load_train,1));
    end
    t = char(t);
    times_num = datenum(t, 'DD:HH:MM');    % 2min: 721*8
                                                                         % 15min: 
    f(1) = figure;
%     f(2) = figure;    
    
    % -----------------------------------------------------------
    for i = 1:size(f,2)
        figure(f(i));
        xlabel('time');
        ylabel('MW');
        yyaxis right;
        ylim([-0.5, 105]);    
        ylabel('SOC [%]');
%         ylim([-0.5, max(y(7).data)+1]);    
%         ylabel('criticalness');
        yyaxis left;
        set(gca,'FontSize',20);
        xlim([times_num(1) times_num(end)]);  % 2min: 721*1 -> 720*1
                                                                          % 15min: 97*1 -> 96*1
        
        ylim([-1*max(g_ESS_capacity), max(max(g_predLoad))+6]);    
        xData = linspace(times_num(1),times_num(end),7);
        set(gca,'Xtick',xData);
        hold on;
        datetick('x','HH:MM','keeplimits','keepticks')
    end
    times_num(end) = [];
    % -----------------------------------------------------
    
    % heatmap of predicted load--------------------------------
    for i = 1:size(f,2)
            [heat_y] = heatmap_desc(load_train); % 2min: 720*72  -> 111*24
                                                                                % 15min: 96*68 -> 111*24
            figure(f(i));
            unit = (xData(end) - xData(1))/g_s_period;
            xlim_MW = ([xData(1)+unit/2 xData(end)-unit/2]);
            ylim_MW = 0:0.1:11;
            imagesc(xlim_MW, ylim_MW, heat_y);
            set(gca, 'YDir', 'normal');
            map(:,2) = flipud(transpose([g_color_depth:(1-g_color_depth)/10:1]));
            map(:,3) = flipud(transpose([g_color_depth:(1-g_color_depth)/10:1]));
            map(:,1) = 1;
            colormap(map);
     end
    % -----------------------------------------------------------

    % Plot lines ----------------------------------------------------------
    for i = 1:size(y,2)
        if y(i).descrp(1) == 1
            plt(f(1),y,i,times_num);
        end
        if y(i).descrp(2) == 1
            plt(f(2),y,i,times_num);
        end        
    end
    % -------------------------------------------------------------------
    
    % Label of figures ----------------------------------------------
    for i = 1:size(f,2)
        set(0,'CurrentFigure',f(i));
        title(f_title(i));
        if i == 1
            L = legend('show');
            L.FontSize = 12;
        end
    end
    % -----------------------------------------------------------


end

function plt(f, y, i, times_num)  % f = fig
    set(0,'CurrentFigure',f);
    if strcmp(y(i).yaxis, 'left')
        yyaxis left;
    else
        yyaxis right;
    end
    p = plot(times_num, y(i).data,'LineWidth',4);
    p.DisplayName = y(i).name;
    p.Color = y(i).color;       
    p.LineStyle = y(i).linestyle;
    p.Marker = 'none';            
end