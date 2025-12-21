%# Copyright (C) 2025 Stefan Schloegl <schinzilord@octarisk.com>
%#
%# This program is free software; you can redistribute it and/or modify it under
%# the terms of the GNU General Public License as published by the Free Software
%# Foundation; either version 3 of the License, or (at your option) any later
%# version.
%#
%# This program is distributed in the hope that it will be useful, but WITHOUT
%# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
%# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
%# details.
%# -*- texinfo -*-
%# @deftypefn {Function File} {@var{retcode} =} plot_hist_var_with_regimes(@var{obj}, @var{para_object}, @var{path_reports})
%# Plot full historical monthly VaR (relative %) with regime color coding. 
%# Adds a separate regime legend with mean and std VaR.
%# @end deftypefn
function retcode = plot_hist_var_with_regimes(obj, para_object, path_reports)

  retcode = 1;

  % collect history
  hist_bv = [obj.hist_base_values];
  hist_var = [obj.hist_var_abs];        % 10-day VaR absolute
  hist_dates = [obj.hist_report_dates];

  if isempty(hist_dates)
    fprintf('plot: no history dates available for portfolio >>%s<<\n', obj.id);
    retcode = 0;
    return;
  end
  if isempty(hist_dates{1})
    hist_dates = {};
  end

  % optional cashflow (kept for compatibility)
  if isempty(obj.hist_cashflow)
    cashinoutflow = zeros(1,numel(hist_dates));
  else
    cashinoutflow = [obj.hist_cashflow];
  end

  % remove any dates on/after valuation date
  if (numel(hist_bv)>0 && numel(hist_var)>0 && numel(hist_dates)>0)
    valnum = datenum(datestr(para_object.valuation_date));
    idx_keep = datenum(hist_dates) < valnum;
    hist_var = hist_var(idx_keep);
    hist_bv = hist_bv(idx_keep);
    cashinoutflow = cashinoutflow(idx_keep);
    hist_dates = hist_dates(idx_keep);
  end

  % append current values
  if isempty(obj.current_cashflow)
    cashinoutflow = [zeros(1,numel(hist_dates)), 0];
  else
    cashinoutflow = [zeros(1,numel(hist_dates)), obj.current_cashflow];
  end
  hist_bv = [hist_bv, obj.value_base];
  hist_var = [hist_var, obj.varhd_abs];
  hist_dates = [hist_dates, datestr(para_object.valuation_date)];

  % basic checks
  if ~(numel(hist_bv)>1 && numel(hist_var)>1 && numel(hist_dates)>1)
    fprintf('plot: insufficient history for portfolio >>%s<<\n', obj.id);
    retcode = 0;
    return;
  end

  % compute VaR relative series (percent)
  hist_var_rel = 100 .* hist_var ./ abs(hist_bv);

  % convert date strings to datenum for continuous x-axis
  xdates = datenum(hist_dates);

  % detection parameters
  x_for_detect = hist_var_rel;
  use_log = all(x_for_detect > 0);
  detect_params = struct('minlen',5, 'penalty', 3.0, 'use_log', use_log);
  regimes = detect_regimes_bs_local(x_for_detect, detect_params);
  segs = regimes.segments;
  nseg = numel(segs);

  % ---------- Plot main time series with shaded regime bands and colored VaR per regime ----------
  hfig = figure('visible','off');
  clf;

  % create axes early (empty plots) to get axes handles
  [ax, ~, ~] = plotyy(xdates, NaN(size(xdates)), xdates, NaN(size(xdates)), @plot, @plot);
  hold(ax(1),'on'); hold(ax(2),'on');

  % prepare light colors for bands (repeating) and distinct colors for regime lines
  band_colors = [0.92 0.95 1.0; 0.95 0.98 0.95; 1.0 0.96 0.92; 0.98 0.95 0.98];
  nc = size(band_colors,1);
  % choose a palette for regime lines (distinct and printable)
  cmap = lines(max(nseg,3)); % ensure at least 3 colors

  % compute y-limits for background patches using base-value extent
  y1 = min(hist_bv); y2 = max(hist_bv);
  y_margin = 0.02 * (y2 - y1 + eps);
  py_bottom = y1 - y_margin;
  py_top = y2 + y_margin;

  % draw patches first on ax(1)
  for k = 1:nseg
    a = segs(k).start; b = segs(k).end;
    xstart = xdates(a);
    xend = xdates(b);
    cidx = mod(k-1,nc)+1;
    clr = band_colors(cidx,:);
    px = [xstart, xend, xend, xstart];
    py = [py_bottom, py_bottom, py_top, py_top];
    patch('XData',px,'YData',py,'FaceColor',clr,'EdgeColor','none','FaceAlpha',0.12,'Parent',ax(1));
  end

  % plot base value as a single line on left axis
  h_base = plot(ax(1), xdates, hist_bv, '-', 'color', [0.0859 0.4492 0.7617], 'markerfacecolor',[0.0859 0.4492 0.7617]);

  % plot VaR relative per-segment with distinct colors and markers
  h_var_lines = zeros(1,nseg);
  for k = 1:nseg
    a = segs(k).start; b = segs(k).end;
    xs = xdates(a:b);
    ys = hist_var_rel(a:b);
    % plot segment as one line so it's visibly distinct; add small overlap marker at boundaries
    h = plot(ax(2), xs, ys, '-o', 'color', cmap(k,:), 'linewidth', 1.2, ...
                         'markerfacecolor', cmap(k,:), 'markeredgecolor', cmap(k,:));
    h_var_lines(k) = h;
    hold(ax(2),'on');
  end

  % update patches if axis limits changed after plotting
  newylims = get(ax(1),'ylim');
  if abs(newylims(1)-py_bottom) > 1e-12 || abs(newylims(2)-py_top) > 1e-12
    ch = get(ax(1),'children');
    ispatch = arrayfun(@(h) strcmp(get(h,'type'),'patch'), ch);
    patch_handles = ch(ispatch);
    for ph = patch_handles(:)'
      set(ph,'YData',[newylims(1), newylims(1), newylims(2), newylims(2)]);
    end
  end

  % create regime legend entries (color box + text) for main plot
  legend_labels = cell(1,nseg);
  for k = 1:nseg
    seg = segs(k);
    sy = datestr(xdates(seg.start),'yyyy-mm');
    ey = datestr(xdates(seg.end),'yyyy-mm');
    mean_vr = mean(hist_var_rel(seg.start:seg.end));
    std_vr = std(hist_var_rel(seg.start:seg.end));
    legend_labels{k} = sprintf('r%d: %s..%s, mean=%.2g±%.2g%%', k, sy, ey, mean_vr, std_vr);
  end

  % axis labels, title and grid
  ylabel(ax(1), strcat('Base Value (', obj.currency,')'),'fontsize',10);
  ylabel(ax(2), 'VaR relative (in Pct)','fontsize',10);
  %title(sprintf('Historical Base Value and VaR relative %% with regimes - %s', obj.id));
  grid(ax(1),'on');

  % x-axis tick handling: yearly major ticks
  d0 = xdates(1); dN = xdates(end);
  yr_start = year(d0); yr_end = year(dN);
  year_ticks = datenum((yr_start:yr_end)', 1, 1);
  set(ax(1),'xtick',year_ticks);
  set(ax(1),'xticklabel',datestr(year_ticks,'yyyy'));
  set(ax(2),'xtick',year_ticks);
  set(ax(2),'xticklabel',{});
  margin = (xdates(end) - xdates(1)) * 0.02;
  set(ax(1),'xlim',[xdates(1)-margin, xdates(end)+margin]);
  set(ax(2),'xlim',[xdates(1)-margin, xdates(end)+margin]);

  % legend for regimes placed to the right (create invisible handles with the same colors)
  legend_handles = zeros(1,nseg);
  for k = 1:nseg
    % plot invisible line for legend; use NaN so nothing is drawn
    legend_handles(k) = plot(NaN, NaN, '-s', 'color', cmap(k,:), 'markerfacecolor', cmap(k,:));
    hold on;
  end
  hleg = legend(legend_handles, legend_labels, 'location', 'eastoutside');
  set(hleg,'box','off','FontSize',8);

  % save main figure
  fn1_png = strcat(path_reports, '/', obj.id, '_var_history_regimes.png');
  print(hfig, fn1_png, "-dpng", "-S1200,460");
  fn1_pdf = strcat(path_reports, '/', obj.id, '_var_history_regimes.pdf');
  print(hfig, fn1_pdf, "-dpdf", "-S1200,460");
  close(hfig);

  % ---------- Scatter plot VaR vs realized monthly losses (colored by regime) ----------
  N = numel(hist_bv);
  realized_losses = zeros(1,N-1);
  for k = 1:(N-1)
    realized_losses(k) = max(0, hist_bv(k) - hist_bv(k+1));
  end
  scale_factor = sqrt(20/10);
  hist_var_scaled = hist_var .* scale_factor;
  x_var = hist_var_scaled(1:end-1);
  y_loss = realized_losses;

  % assign each observation to regime (var at time t belongs to regime containing index t)
  reg_idx = zeros(1,numel(x_var));
  for k = 1:nseg
    a = segs(k).start; b = segs(k).end;
    sel = (1:numel(x_var)) >= a & (1:numel(x_var)) <= b;
    reg_idx(sel) = k;
  end
  reg_idx(reg_idx==0) = nseg;

  hsc = figure('visible','off');
  clf;
  hold on;
  for k = 1:nseg
    sel = find(reg_idx == k);
    if isempty(sel), continue; end
    scatter(x_var(sel), y_loss(sel), 40, repmat(cmap(k,:), numel(sel),1), 'filled', 'MarkerEdgeColor',[0.2 0.2 0.2]);
  end
  mx = max([x_var, y_loss])*1.02;
  plot([0, mx],[0,mx],'--','color',[0.6 0.6 0.6]);
  xlabel(strcat('Model VaR scaled to 20 days (', obj.currency, ')'));
  ylabel(strcat('Realized monthly loss (', obj.currency, ')'));
  %title('Scatter: Model VaR vs Realized monthly loss (colored by regime)');

  % reuse legend handles and labels for scatter
  legend(legend_labels,'location','bestoutside');

  % overall linear fit
  if numel(x_var) >= 3
    p = polyfit(x_var, y_loss, 1);
    xs = linspace(0, mx, 100);
    plot(xs, polyval(p,xs), '-', 'color', [0.85 0.33 0.10], 'linewidth',1.2);
    txt = sprintf('fit: y = %.3g x + %.3g', p(1), p(2));
    text(0.02, 0.92, txt, 'units','normalized');
  end

  fn2_png = strcat(path_reports, '/', obj.id, '_var_vs_realized_regimes_scatter.png');
  print(hsc, fn2_png, "-dpng", "-S900,520");
  fn2_pdf = strcat(path_reports, '/', obj.id, '_var_vs_realized_regimes_scatter.pdf');
  print(hsc, fn2_pdf, "-dpdf", "-S900,520");
  close(hsc);

end


% Helper Functions:

% ---------- Binary-segmentation detector (nested) ----------
function regimes = detect_regimes_bs_local(x, params)
    if nargin < 2, params = struct(); end
    if isfield(params,'minlen'), minlen = params.minlen; else minlen = 6; end
    if isfield(params,'penalty'), penalty = params.penalty; else penalty = 3.0; end
    if isfield(params,'use_log'), use_log = params.use_log; else use_log = true; end

    x = x(:)'; N = numel(x);
    if any(isnan(x)), error('detect_regimes_bs_local: input contains NaN. Clean before call.'); end
    if use_log
      if any(x <= 0), error('detect_regimes_bs_local: series has non-positive values for log transform'); end
      sx = log(x);
    else
      sx = x;
    end

    function c = segcost(a,b)
      len = b - a + 1;
      if len <= 1, c = Inf; return; end
      seg = sx(a:b);
      v = var(seg,1);
      if v <= 0, v = eps; end
      c = len * log(v);
    end

    stack = [1, N];
    cps = [];
    while ~isempty(stack)
      interval = stack(end,:);
      stack(end,:) = [];
      a = interval(1); b = interval(2);
      smin = a + minlen - 1;
      smax = b - minlen;
      if smin > smax, continue; end
      base_cost = segcost(a,b);
      best_delta = 0; best_s = -1;
      for s = smin:smax
        c1 = segcost(a,s);
        c2 = segcost(s+1,b);
        delta = base_cost - (c1 + c2);
        if delta > best_delta
          best_delta = delta; best_s = s;
        end
      end
      if best_delta > penalty
        cps = [cps, best_s];
        stack = [stack; [best_s+1, b]; [a, best_s]];
      end
    end

    cps = sort(cps);
    seg_starts = [1, cps+1];
    seg_ends = [cps, N];
    S = numel(seg_starts);
    segments = struct('start',cell(1,S),'end',cell(1,S),'n',cell(1,S),'mean',cell(1,S),'std',cell(1,S),'median',cell(1,S));
    for k = 1:S
      a = seg_starts(k); b = seg_ends(k);
      seg = sx(a:b);
      segments(k).start = a;
      segments(k).end = b;
      segments(k).n = b - a + 1;
      segments(k).mean = mean(seg);
      segments(k).std = std(seg,1);
      segments(k).median = median(seg);
      if use_log
        segments(k).mean_back = exp(segments(k).mean);
        segments(k).median_back = exp(segments(k).median);
      end
    end

    regimes.cp = cps;
    regimes.segments = segments;
    regimes.series = sx;
    regimes.params = struct('minlen',minlen,'penalty',penalty,'use_log',use_log);
end
