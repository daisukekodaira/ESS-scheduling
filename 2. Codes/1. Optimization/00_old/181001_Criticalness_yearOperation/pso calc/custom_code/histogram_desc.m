function histogram_desc(flag,load,f_name)

global_var_declare;

unit = g_steps/g_s_period;

if flag == 1 
    for i = 0:g_s_period-1  % i = 1:24
        P1 = get(0,'SCreenSize');
        hist = figure('Position',P1);
        h = histogram(load(1+unit*i:unit*(i+1),:),'Normalization','probability');
        h.BinWidth = 0.25;
        h.BinLimits = [-1 g_line_capacity+2];
        title(['Predicted load histogram during ',num2str(i),':00~',num2str(i+1),':00']);
        xlabel('Load [MW]');
        ylabel('Probability');
        set(gca,'FontSize',20);

        mkdir(f_name);
        fpath = pwd;
        fname = sprintf('%dh~%dh.tif',i,i+1);
        saveas(hist, fullfile(fpath, '/', f_name, fname), 'tif');
        close(hist);
    end
end

end