function [B,ndx,dbg] = natsort(A,rgx,varargin)
% Natural-order / alphanumeric sort strings or character vectors or categorical.
%
% (c) 2012-2022 Stephen Cobeldick
%
% Sorts text by character code and by number value. By default matches
% integer substrings and performs a case-insensitive ascending sort.
% Options to select the number format, sort order, case sensitivity, etc.
%
%%% Example:
% >> X = ["x2", "x10", "x1"];
% >> sort(X) % for comparison.
% ans =   "x1"  "x10"  "x2"
% >> natsort(X)
% ans =   "x1"  "x2"  "x10"
%
%%% Syntax:
%  B = natsort(A)
%  B = natsort(A,rgx)
%  B = natsort(A,rgx,<options>)
% [B,ndx,dbg] = natsort(A,...)
%
% To sort any file-names or folder-names use NATSORTFILES (File Exchange 47434)
% To sort the rows of a string/cell/table use NATSORTROWS (File Exchange 47433)
%
%% Number Format %%
%
% The **default regular expression '\d+' matches consecutive digit
% characters, i.e. integer numbers. Specifying the optional regular
% expression allows the numbers to include a +/- sign, decimal point,
% decimal fraction digits, exponent E-notation, character quantifiers,
% or lookarounds. For information on defining regular expressions:
% <http://www.mathworks.com/help/matlab/matlab_prog/regular-expressions.html>
% For example, to match leading/trailing whitespace prepend/append '\s*'.
%
% The number substrings are parsed by SSCANF into numeric values, using
% either the **default format '%f' or the user-supplied format specifier.
%
% This table shows examples of some regular expression patterns for common
% notations and ways of writing numbers, together with suitable SSCANF formats:
%
% Regular       | Number Substring | Number Substring              | SSCANF
% Expression:   | Match Examples:  | Match Description:            | Format Specifier:
% ==============|==================|===============================|==================
% **        \d+ | 0, 123, 4, 56789 | unsigned integer              | %f  %i  %u  %lu
% --------------|------------------|-------------------------------|------------------
%      [-+]?\d+ | +1, 23, -45, 678 | integer with optional +/- sign| %f  %i  %d  %ld
% --------------|------------------|-------------------------------|------------------
%     \d+\.?\d* | 012, 3.45, 678.9 | integer or decimal            | %f
% (\d+|Inf|NaN) | 123, 4, NaN, Inf | integer, Inf, or NaN          | %f
%  \d+\.\d+E\d+ | 0.123e4, 5.67e08 | exponential notation          | %f
% --------------|------------------|-------------------------------|------------------
%  0X[0-9A-F]+  | 0X0, 0X3E7, 0XFF | hexadecimal notation & prefix | %x  %i
%    [0-9A-F]+  |   0,   3E7,   FF | hexadecimal notation          | %x
% --------------|------------------|-------------------------------|------------------
%  0[0-7]+      | 012, 03456, 0700 | octal notation & prefix       | %o  %i
%   [0-7]+      |  12,  3456,  700 | octal notation                | %o
% --------------|------------------|-------------------------------|------------------
%  0B[01]+      | 0B1, 0B101, 0B10 | binary notation & prefix      | %b   (not SSCANF)
%    [01]+      |   1,   101,   10 | binary notation               | %b   (not SSCANF)
% --------------|------------------|-------------------------------|------------------
%
%% Debugging Output Array %%
%
% The third output is a cell array <dbg>, for checking the numbers
% matched by the regular expression <rgx> and converted to numeric
% by the SSCANF format. The rows of <dbg> are linearly indexed from <A>.
%
% >> [~,~,dbg] = natsort(X)
% dbg =
%    'x'    [ 2]
%    'x'    [10]
%    'x'    [ 1]
%
%% Examples %%
%
%%% Multiple integers (e.g. release version numbers):
% >> A = {'v10.6', 'v9.10', 'v9.5', 'v10.10', 'v9.10.20', 'v9.10.8'};
% >> sort(A) % for comparison.
% ans =   'v10.10'  'v10.6'  'v9.10'  'v9.10.20'  'v9.10.8'  'v9.5'
% >> natsort(A)
% ans =   'v9.5'  'v9.10'  'v9.10.8'  'v9.10.20'  'v10.6'  'v10.10'
%
%%% Integer, decimal, NaN, or Inf numbers, possibly with +/- signs:
% >> B = {'test+NaN', 'test11.5', 'test-1.4', 'test', 'test-Inf', 'test+0.3'};
% >> sort(B) % for comparison.
% ans =   'test' 'test+0.3' 'test+NaN' 'test-1.4' 'test-Inf' 'test11.5'
% >> natsort(B, '[-+]?(NaN|Inf|\d+\.?\d*)')
% ans =   'test' 'test-Inf' 'test-1.4' 'test+0.3' 'test11.5' 'test+NaN'
%
%%% Integer or decimal numbers, possibly with an exponent:
% >> C = {'0.56e007', '', '43E-2', '10000', '9.8'};
% >> sort(C) % for comparison.
% ans =   ''  '0.56e007'  '10000'  '43E-2'  '9.8'
% >> natsort(C, '\d+\.?\d*(E[-+]?\d+)?')
% ans =   ''  '43E-2'  '9.8'  '10000'  '0.56e007'
%
%%% Hexadecimal numbers (with '0X' prefix):
% >> D = {'a0X7C4z', 'a0X5z', 'a0X18z', 'a0XFz'};
% >> sort(D) % for comparison.
% ans =   'a0X18z'  'a0X5z'  'a0X7C4z'  'a0XFz'
% >> natsort(D, '0X[0-9A-F]+', '%i')
% ans =   'a0X5z'  'a0XFz'  'a0X18z'  'a0X7C4z'
%
%%% Binary numbers:
% >> E = {'a11111000100z', 'a101z', 'a000000000011000z', 'a1111z'};
% >> sort(E) % for comparison.
% ans =   'a000000000011000z'  'a101z'  'a11111000100z'  'a1111z'
% >> natsort(E, '[01]+', '%b')
% ans =   'a101z'  'a1111z'  'a000000000011000z'  'a11111000100z'
%
%%% Case sensitivity:
% >> F = {'a2', 'A20', 'A1', 'a10', 'A2', 'a1'};
% >> natsort(F, [], 'ignorecase') % default
% ans =   'A1'  'a1'  'a2'  'A2'  'a10'  'A20'
% >> natsort(F, [], 'matchcase')
% ans =   'A1'  'A2'  'A20'  'a1'  'a2'  'a10'
%
%%% Sort order:
% >> G = {'2', 'a', '', '3', 'B', '1'};
% >> natsort(G, [], 'ascend') % default
% ans =   ''   '1'  '2'  '3'  'a'  'B'
% >> natsort(G, [], 'descend')
% ans =   'B'  'a'  '3'  '2'  '1'  ''
% >> natsort(G, [], 'num<char') % default
% ans =   ''   '1'  '2'  '3'  'a'  'B'
% >> natsort(G, [], 'char<num')
% ans =   ''   'a'  'B'  '1'  '2'  '3'
%
%%% UINT64 numbers (with full precision):
% >> natsort({'a18446744073709551615z', 'a18446744073709551614z'}, [], '%lu')
% ans =       'a18446744073709551614z'  'a18446744073709551615z'
%
%% Input and Output Arguments %%
%
%%% Inputs (**=default):
% A   = Array to be sorted into alphanumeric order. Can be a string
%       array, or a cell array of character row vectors, or a categorical
%       array, or any other array type which can be converted by CELLSTR.
% rgx = Optional regular expression to match number substrings.
%     = [] uses the default regular expression '\d+'** to match integers.
% <options> can be entered in any order, as many as required:
%     = Sort direction: 'descend'/'ascend'**
%     = NaN/number order: 'NaN<num'/'num<NaN'**
%     = Character/number order: 'char<num'/'num<char'**
%     = Character case handling: 'matchcase'/'ignorecase'**
%     = SSCANF conversion format: '%x', '%li', '%b', '%f'**, etc.
%     = Function handle of a function that sorts text. It must return as
%       its 2nd output the sort indices. It must accept as its 1st input
%       a cell array of char vectors (the array to be sorted), followed
%       by zero or more optional arguments in any order:
%       a) The sort direction 'descend'/'ascend'**.
%       b) The case sensitivity 'matchcase'/'ignorecase'**.
%
%%% Outputs:
% B   = Array <A> sorted into alphanumeric order. The same size as <A>.
% ndx = NumericArray, such that B = A(ndx).       The same size as <A>.
% dbg = CellArray of the parsed characters and number values. Each row
%       corresponds to one input element of <A>, in linear-index order.
%
% See also SORT NATSORTFILES NATSORTROWS ARBSORT IREGEXP REGEXP
% COMPOSE STRING STRINGS CATEGORICAL CELLSTR SSCANF
%% Input Wrangling %%
%
fnh = @(c)cellfun('isclass',c,'char') & cellfun('size',c,1)<2 & cellfun('ndims',c)<3;
%
if iscell(A)
	assert(all(fnh(A(:))),...
		'SC:natsort:A:CellInvalidContent',...
		'First input <A> cell array must contain only character row vectors.')
	B = A(:);
elseif ischar(A) % Convert char matrix:
	B = cellstr(A);
else % Convert string, categorical, datetime, etc.:
	B = cellstr(A(:));
end
%
chk = '(match|ignore)case|(de|a)scend(ing)?|(char|nan|num)[<>](char|nan|num)|%[a-z]+';
%
if nargin<2 || isnumeric(rgx)&&isequal(rgx,[])
	rgx = '\d+';
elseif ischar(rgx)
	assert(ndims(rgx)<3 && size(rgx,1)==1,...
		'SC:natsort:rgx:NotCharVector',...
		'Second input <rgx> character row vector must have size 1xN.') %#ok<ISMAT>
	nsChkRgx(rgx,chk)
else
	rgx = ns1s2c(rgx);
	assert(ischar(rgx),...
		'SC:natsort:rgx:InvalidType',...
		'Second input <rgx> must be a character row vector or a string scalar.')
	nsChkRgx(rgx,chk)
end
%
varargin = cellfun(@ns1s2c, varargin, 'UniformOutput',false);
ixv = fnh(varargin); % char
txt = varargin(ixv); % char
xtx = varargin(~ixv); % not
%
% Character case:
tcm = strcmpi(txt,'matchcase');
tcx = strcmpi(txt,'ignorecase')|tcm;
% Sort direction:
tdd = strcmpi(txt,'descend');
tdx = strcmpi(txt,'ascend')|tdd;
% Char/num order:
ttn = strcmpi(txt,'char<num');
ttx = strcmpi(txt,'num<char')|ttn;
% NaN/num order:
ton = strcmpi(txt,'NaN<num');
tox = strcmpi(txt,'num<NaN')|ton;
% SSCANF format:
tsf = ~cellfun('isempty',regexp(txt,'^%([bdiuoxfeg]|l[diuox])$'));
%
nsAssert(txt, ~(tcx|tdx|ttx|tox|tsf))
nsAssert(txt, tcx,  'CaseMatching', 'case sensitivity')
nsAssert(txt, tdx, 'SortDirection', 'sort direction')
nsAssert(txt, ttx,  'CharNumOrder', 'number<->character')
nsAssert(txt, tox,   'NanNumOrder', 'number<->NaN')
nsAssert(txt, tsf,  'sscanfFormat', 'SSCANF format')
%
% SSCANF format:
if any(tsf)
	fmt = txt{tsf};
else
	fmt = '%f';
end
%
xfh = cellfun('isclass',xtx,'function_handle');
assert(nnz(xfh)<2,...
	'SC:natsort:option:FunctionHandleOverspecified',...
	'The function handle option may only be specified once.')
assert(all(xfh),...
	'SC:natsort:option:InvalidType',...
	'Optional arguments must be character row vectors, string scalars, or a function handle.')
if any(xfh)
	txfh = xtx{xfh};
end
%
%% Identify and Convert Numbers %%
%
[nbr,spl] = regexpi(B(:), rgx, 'match','split', txt{tcx});
%
if numel(nbr)
	tmp = [nbr{:}];
	if strcmp(fmt,'%b')
		tmp = regexprep(tmp,'^0[Bb]','');
		vec = cellfun(@(s)pow2(numel(s)-1:-1:0)*sscanf(s,'%1d'),tmp);
	else
		vec = sscanf(sprintf(' %s','0',tmp{:}),fmt);
		vec = vec(2:end); % SSCANF wrong data class bug (R2009b and R2010b)
	end
	assert(numel(vec)==numel(tmp),...
		'SC:natsort:sscanf:TooManyValues',...
		'The "%s" format must return one value for each input number.',fmt)
else
	vec = [];
end
%
%% Allocate Data %%
%
% Determine lengths:
nmx = numel(B);
lnn = cellfun('length',nbr);
lns = cellfun('length',spl);
mxs = max(lns);
%
% Allocate data:
idn = logical(bsxfun(@le,1:mxs,lnn).'); % TRANSPOSE lost class bug (R2013b)
ids = logical(bsxfun(@le,1:mxs,lns).'); % TRANSPOSE lost class bug (R2013b)
arn = zeros(mxs,nmx,class(vec));
ars =  cell(mxs,nmx);
ars(:) = {''};
ars(ids) = [spl{:}];
arn(idn) = vec;
%
%% Debugging Array %%
%
if nargout>2
	mxw = 0;
	%for k = 1:nmx
	%	mxw = max(mxw,numel(nbr{k})+nnz(~cellfun('isempty',spl{k})));
	%end
	dbg = cell(nmx,mxw);
	for k = 1:nmx
		tmp = spl{k};
		if any(idn(:,k)) % Empty array allocation bug (R2009b)
			tmp(2,1:end-1) = num2cell(arn(idn(:,k),k));
		end
		tmp(cellfun('isempty',tmp)) = [];
		dbg(k,1:numel(tmp)) = tmp;
	end
end
%
%% Sort Columns %%
%
if ~any(tcm) % ignorecase
	ars = lower(ars);
end
%
if any(ttn) % char<num
	% Determine max character code:
	mxc = 'X';
	tmp = warning('off','all');
	mxc(1) = Inf;
	warning(tmp)
	mxc(mxc==0) = 255; % Octave
	% Append max character code to the split text:
	%ars(idn) = strcat(ars(idn),mxc); % slower than loop
	for k = reshape(find(idn),1,[])
		ars{k}(1,end+1) = mxc;
	end
end
%
idn(isnan(arn)) = ~any(ton); % NaN<num
%
if any(xfh) % External text-sorting function
	[~,ndx] = txfh(ars(mxs,:),txt{tcx|tdx});
	for k = mxs-1:-1:1
		[~,idx] = sort(arn(k,ndx),txt{tdx});
		ndx = ndx(idx);
		[~,idx] = sort(idn(k,ndx),txt{tdx});
		ndx = ndx(idx);
		[~,idx] = txfh(ars(k,ndx),txt{tdx|tcx});
		ndx = ndx(idx);
	end
elseif any(tdd)
	[~,ndx] = sort(nsGroups(ars(mxs,:)),'descend');
	for k = mxs-1:-1:1
		[~,idx] = sort(arn(k,ndx),'descend');
		ndx = ndx(idx);
		[~,idx] = sort(idn(k,ndx),'descend');
		ndx = ndx(idx);
		[~,idx] = sort(nsGroups(ars(k,ndx)),'descend');
		ndx = ndx(idx);
	end
else
	[~,ndx] = sort(ars(mxs,:)); % ascend
	for k = mxs-1:-1:1
		[~,idx] = sort(arn(k,ndx),'ascend');
		ndx = ndx(idx);
		[~,idx] = sort(idn(k,ndx),'ascend');
		ndx = ndx(idx);
		[~,idx] = sort(ars(k,ndx)); % ascend
		ndx = ndx(idx);
	end
end
%
%% Outputs %%
%
if ischar(A)
	ndx = ndx(:);
	B = A(ndx,:);
else
	ndx = reshape(ndx,size(A));
	B = A(ndx);
end
%
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%natsort
function grp = nsGroups(vec)
% Groups in a cell array of char vectors, equivalent to [~,~,grp]=unique(vec);
[vec,idx] = sort(vec);
grp = cumsum([true(1,numel(vec)>0),~strcmp(vec(1:end-1),vec(2:end))]);
grp(idx) = grp;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%nsGroups
function nsAssert(inp,inx,ids,opt)
% Throw an error if an option is overspecified or unsupported.
tmp = sprintf('The provided options:%s',sprintf(' "%s"',inp{inx}));
if nargin>2
	assert(nnz(inx)<2,...
		sprintf('SC:natsort:option:%sOverspecified',ids),...
		'The %s option may only be specified once.\n%s',opt,tmp)
else
	assert(~any(inx),...
		'SC:natsort:option:InvalidOptions',...
		'Invalid options provided. Check the help and option spelling!\n%s',tmp)
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%nsAssert
function nsChkRgx(rgx,chk)
chk = sprintf('^(%s)$',chk);
assert(isempty(regexpi(rgx,chk,'once')),...
	'SC:natsort:rgx:OptionMixUp',...
	['Second input <rgx> must be a regular expression that matches numbers.',...
	'\nThe provided input "%s" looks like an optional argument (inputs 3+).'],rgx)
if isempty(regexpi('0',rgx,'once'))
	warning('SC:natsort:rgx:SanityCheck',...
		['Second input <rgx> must be a regular expression that matches numbers.',...
		'\nThe provided regular expression does not match the digit "0", which\n',...
		'may be acceptable (e.g. if literals, quantifiers, or lookarounds are used).'...
		'\nThe provided regular expression: "%s"'],rgx)
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%nsChkRgx
function arr = ns1s2c(arr)
% If scalar string then extract the character vector, otherwise data is unchanged.
if isa(arr,'string') && isscalar(arr)
	arr = arr{1};
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%ns1s2c