function [ p, err_o, chisqdof, res, kov, err_o_alt ] = ...
                         chisqfit( x, y, err, fun, start, ub, lb, options )
%CHISQFIT Fits function to data by minimizing Chi^2
%
%
%   [ p, err_o, chisqdof, res, kov, err_o_alt ] =
%                        chisqfit( x, y, err, fun, start, ub, lb, options )
%   
%
%  INPUT
%   
%   x - vector of independent variable. 
%   y - vector of dependent variable.
%   err - vector of error of y. If shorter than x, last known error will be
%         used for all following data.
%   fun - anonymous function ( e.g. @(q,x) q(1)*x+q(2)... ). q will be 
%         optimized so that the sum of weighted residues is minimal. Define
%         the parameter before defining the variable (always @(q,x), not
%         @(x,q)).
%   start - vector containing the start-values of the parameters to be
%           optimized, length=number of params; random if not specified
%   ub - vector specifing the upper bounds for each parameter; inf if empty
%   lb - vector specifing the upper bounds for each parameter; -inf if empty
%   options - optimset-defined options for lsqnonlin; default: 'Display','off'
%   
%   
%  OUTPUT
%
%   p - vector of optimized parameters
%   chisqof - minimized Chi^2/DoF
%   err_o - estimated uncertainty of fitted parameters
%   dof - Degrees of Freedom
%   res - residues, vector of same length as x,y,err
%   kov - covariance-matrix, for determining the correlation of the
%         parameters
%   err_o_alt - only ask for it if you need it (takes a long time to compute)!
%               Gives alternative estimates for errors of the parameters 
%               using Monte-Carlo generated pseudo random datasets.
%
%
%  EXAMPLE
%
%   fun=@(a,x) a(1)*1-a(2)*(x+2).^2+a(3)*x.^3;  % define anonymous function
%   q=10;
%   x=1:.1:q;                                   % set steps
%   q=length(x);
%   ya=fun([40 5 2 ],x);                        % generate data
%   y=ya+randn(1,q)*5;                          % wiggle a little
%   err=5;                                      % define error
%   start=[30 2 4];                             % define start-values
%   [p, err_o, chi, res, kov]=chisqfit(x,y,err,fun, start);    %fit
%
% 
%  AUTHOR
% 
%   Sebastian Pfitzner
%   pfitzseb @ physik . hu - berlin . de
%   last updated: 7.11.2013
% 
% 
%  THANKS TO
% 
%   John d'Errico, Jannick Weisshaupt

%% ------ erster Input-Check ----------------------------------------------
if nargin < 4
    error('Not enough input!')
end

%% ------ x und y berichtigen ---------------------------------------------
if length(x)<length(y)
    y=y(1:length(x));
    warning('y-data too long. Discarding additional values.')
elseif length(x)>length(y)
    x=x(1:length(y));
    warning('x-data too long. Discarding additional values.')
end

if length(x)~=length(y)
    error('X and Y are not of equal length!')
end

[a1, b1]=size(x);
if a1<b1,
   x=x';
end

[a1, b1]=size(y);
if a1<b1,
   y=y';
end

[a1, b1]=size(err);
if a1<b1,
   err=err';
end

%% ------ DoF berechnen ---------------------------------------------------
% moderatly huebsch inzwischen
fstr=func2str(fun);
param=tabulate(regexp(fstr,'\w+','match'));
mat=tabulate(regexp(fstr,[param{1,1} '\(\d+\)'],'match'));
pc=length(mat(:,1));
dof=length(x)-pc-1;        %DoF berechnen
fun=str2func(fstr);

%% ------ Input ueberpruefen, defaults setzen -------------------------------
if nargin < 8
    options=optimset('Display','off');
    if nargin < 7
        lb=-inf*ones([1,pc]);
        if nargin <6
            ub=inf*ones([1,pc]);
            if nargin <5
                start=randn(1,pc);
                disp([' [f]-> Start points not provided. Choosing random'...
                                       ' start points for nonlinear fit.'])
            end
        end
    end
end

%% ------- Startwerte-Vektoren: Groesse vergleichen -------------------------

if ~isequal(length(start),pc)
    disp(' [f]-> number of start points not equal to number of parameters!')
    if length(start)<pc
        start(end:pc)=start(end);
    elseif length(start)>pc
        start=start(1:pc);
    end
end

%% ------ Fehlerangaben berichtigen ---------------------------------------
if length(err)<length(y)
    disp([' [f]-> length(err)<length(y), filling undefined errors with'...
                                               ' last known uncertainty.'])
    err(end:length(y))=err(end);
elseif length(err)>length(y)
    disp(' [f]-> length(err)>length(y), ignoring additional errors.')
    err=err(1:length(y));
end

if any(err==0)
    warning(' [f]-> err_i = 0 found. Replacing with err_i=sqrt(y_i).')
    ind=find(err==0);
    err(ind)=sqrt(y(ind));
end

[a1, b1]=size(err);
if a1<b1,
   err=err';
end

%% ------ Nicht-Lineares Fitten -------------------------------------------
    tic
    [p, chisqdof]=fitten( x, y, err, fun, start, ub, lb, dof, options); % fit
    toc 
    res=y-fun(p,x);                             % Residuen
    [err_o, kov]=errorfit(x,y,err,fun,p); % Fehler der Fitparameter ausrechnen

% alternative Fehlerberechnung (Monte-Carlo)
    
    if nargout>5 || any(err_o==inf) || any(err_o==-inf) || any(isnan(err_o))
        noerr=250;
        p_fake=zeros(noerr,pc);
        for i=1:noerr
            y_fake=fun(p,x)+err.*randn(length(x),1);
            myfun=@(p) ((y_fake-fun(p,x))./err);
            p_fake(i,1:pc)=lsqnonlin(myfun,start,lb,ub, options);
            chisquared=sum(((y_fake-fun(p_fake(i,1:pc),x))./err).^2);
            p_fake(i,pc+1)=chisquared/dof;
        end
        err_o_alt=zeros(pc,1);
        for i=1:pc
            err_o_alt(i,1)=std(p_fake(:,i));
        end
        err_o_alt=err_o_alt';
        if any(err_o==inf) || any(err_o==-inf) || any(isnan(err_o))
            err_o=err_o_alt;
            warning([' [f]-> Encountered error in estimating uncertainties.' ...
            'err_o=(inf || -inf || nan). Using alternative method.'])
        end
    end
    
if chisqdof>5
    errmsg=[' [f]-> Fit failed. Adjust start points or function! Chi^2/DoF='...
                                                        num2str(chisqdof)];
    warning(errmsg)
elseif chisqdof<0.1
    errmsg=[' [f]-> Adjust errors! Chi^2/DoF=' num2str(chisqdof)];
    warning(errmsg)
end
end 


%% ------- Hilfsfunktionen ------------------------------------------------

function [p, chisqdof]=fitten( x, y, err, fun, start, ub, lb, dof,options)
myfun=@(p) ((y-fun(p,x))./err);
p=lsqnonlin(myfun,start,lb,ub,options);     % minimieren von Chi^2
chisquared=chi2(x,y,err,fun,p);
chisqdof=chisquared/dof;                    % um DoF korrigiertes Chi^2
end

function [chi] = chi2(x,y,err,fun,p)
chi=sum( ((fun(p,x)-y)./err).^2 );
end

function [perr, Kov] = errorfit(x,~,yerr,func,p)

N=length(p);
n = length(x);

funcvec = @(p) func(p,x);
tic
F = jacobianest(funcvec,p);
% F = jacobian(funcvec, p);
toc
G=zeros(n,N);
for i=1:N
    G(:,i) = F(:,i)./(yerr.^2);
end
Kov = (F'*G)^-1;
perr = sqrt(diag(Kov))';
end

function [jac,err] = jacobianest(fun,x0)
% gradest: estimate of the Jacobian matrix of a vector valued function 
%          of n variables
% usage: [jac,err] = jacobianest(fun,x0)
%
%
% Author: John D'Errico
% e-mail: woodchips@rochester.rr.com
% Release: 1.0
% Release date: 3/6/2007

% get the length of x0 for the size of jac
nx = numel(x0);

MaxStep = 100;
StepRatio = 2.0000001;

% was a string supplied?
if ischar(fun)
    fun = str2func(fun);
end

% get fun at the center point
f0 = fun(x0);
f0 = f0(:);
n = length(f0);
if n==0
    % empty begets empty
    jac = zeros(0,nx);
    err = jac;
    return
end

relativedelta = MaxStep*StepRatio .^(0:-1:-25);
nsteps = length(relativedelta);

% total number of derivatives we will need to take
jac = zeros(n,nx);
err = jac;
for i = 1:nx
    x0_i = x0(i);
    if x0_i ~= 0
        delta = x0_i*relativedelta;
    else
        delta = relativedelta;
    end

    % evaluate at each step, centered around x0_i
    % difference to give a second order estimate
    fdel = zeros(n,nsteps);
    for j = 1:nsteps
        fdif = fun(swapelement(x0,i,x0_i + delta(j))) - ...
            fun(swapelement(x0,i,x0_i - delta(j)));

        fdel(:,j) = fdif(:);
    end

    % these are pure second order estimates of the
    % first derivative, for each trial delta.
    derest = fdel.*repmat(0.5 ./ delta,n,1);

    % The error term on these estimates has a second order
    % component, but also some 4th and 6th order terms in it.
    % Use Romberg exrapolation to improve the estimates to
    % 6th order, as well as to provide the error estimate.

    % loop here, as rombextrap coupled with the trimming
    % will get complicated otherwise.
    for j = 1:n
        [der_romb,errest] = rombextrap(StepRatio,derest(j,:),[2 4]);

        % trim off 3 estimates at each end of the scale
        nest = length(der_romb);
        trim = [1:3, nest+(-2:0)];
        [der_romb,tags] = sort(der_romb);
        der_romb(trim) = [];
        tags(trim) = [];

        errest = errest(tags);

        % now pick the estimate with the lowest predicted error
        [err(j,i),ind] = min(errest);
        jac(j,i) = der_romb(ind);
    end
end

end % mainline function end

function vec = swapelement(vec,ind,val)
% swaps val as element ind, into the vector vec
vec(ind) = val;

end % sub-function end

function [der_romb,errest] = rombextrap(StepRatio,der_init,rombexpon)
% do romberg extrapolation for each estimate
%
%  StepRatio - Ratio decrease in step
%  der_init - initial derivative estimates
%  rombexpon - higher order terms to cancel using the romberg step
%
%  der_romb - derivative estimates returned
%  errest - error estimates
%  amp - noise amplification factor due to the romberg step

srinv = 1/StepRatio;

% do nothing if no romberg terms
nexpon = length(rombexpon);
rmat = ones(nexpon+2,nexpon+1);
% two romberg terms
rmat(2,2:3) = srinv.^rombexpon;
rmat(3,2:3) = srinv.^(2*rombexpon);
rmat(4,2:3) = srinv.^(3*rombexpon);

% qr factorization used for the extrapolation as well
% as the uncertainty estimates
[qromb,rromb] = qr(rmat,0);

% the noise amplification is further amplified by the Romberg step.
% amp = cond(rromb);

% this does the extrapolation to a zero step size.
ne = length(der_init);
rhs = vec2mat(der_init,nexpon+2,ne - (nexpon+2));
rombcoefs = rromb\(qromb'*rhs);
der_romb = rombcoefs(1,:)';

% uncertainty estimate of derivative prediction
s = sqrt(sum((rhs - rmat*rombcoefs).^2,1));
rinv = rromb\eye(nexpon+1);
cov1 = sum(rinv.^2,2); % 1 spare dof
errest = s'*12.7062047361747*sqrt(cov1(1));

end % rombextrap

function mat = vec2mat(vec,n,m)
% forms the matrix M, such that M(i,j) = vec(i+j-1)
[i,j] = ndgrid(1:n,0:m-1);
ind = i+j;
mat = vec(ind);
if n==1
    mat = mat';
end

end % vec2mat