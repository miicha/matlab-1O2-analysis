function [params, p_err, chisq] = fitdata(model, x, y, err, start_in, fix)

    % model is a cell array from ui.models('key')
    
    % fix is a cell array containing variables to be fixed to their values
    % in start_in

    start = start_in;
    ubound = model{3};
    lbound = model{2};
    fix_ind = [];
    if nargin == 6 && ~isempty(fix)
        tmp = func2str(model{1});
        fix_ind = zeros(length(fix),1);
        for i = 1:length(fix)
            fix_ind(i) = find(strcmp(model{4}, fix{i})); % indices of coeffs that are fixed
            tmp = regexprep(tmp, [fix{i} ','], '', 'once');
            tmp = regexprep(tmp, ['(?<![\w])' fix{i} '(?![\(\w])'],...
                            num2str(start_in(fix_ind(i))));
        end
        start(fix_ind) = [];
        ubound(fix_ind) = [];
        lbound(fix_ind) = [];
        
        func = str2func(tmp);
    else
        func = model{1};
    end
    ft = fittype(func, 'independent', 't');
    fo = fitoptions('Method', 'NonlinearLeastSquares', 'lower', lbound,...
                    'upper', ubound, 'weights', 1./err,... % <- 1./err is important!
                    'StartPoint', start);
                            
    [fitobject, gof] = fit(x, y, ft, fo);
    
    params = zeros(length(start_in),1);
    params(fix_ind) = start_in(fix_ind);
    
    p_err = ones(length(start_in),1);
    p_err(fix_ind) = 0;

    chisq = sum(((feval(fitobject, x) - y)./err).^2)/(length(x)-length(start)-1);
    params(params == 0) = coeffvalues(fitobject);
    p_err(p_err == 1) = mean(abs(confint(fitobject) - [coeffvalues(fitobject); coeffvalues(fitobject)]), 1);


end

