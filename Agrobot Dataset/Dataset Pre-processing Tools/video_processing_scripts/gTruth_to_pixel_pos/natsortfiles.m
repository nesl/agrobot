function [B,ndx,dbg] = natsortfiles(A,rgx,varargin)
% Natural-order / alphanumeric sort of filenames or foldernames.
%
% (c) 2014-2022 Stephen Cobeldick
%
% Sorts text by character code and by number value. File/folder names, file
% extensions, and path directories (if supplied) are sorted separately to
% ensure that shorter names sort before longer names. For names without
% file extensions (i.e. foldernames, or filenames without extensions) use
% the 'noext' option. Use the 'xpath' option to ignore any filepath. Use
% the 'rmdot' option to remove the folder names "." and ".." from the array.
%
%%% Example:
% P = 'C:\SomeDir\SubDir';
% S = dir(fullfile(P,'*.txt'));
% S = natsortfiles(S);
% for k = 1:numel(S)
%     F = fullfile(P,S(k).name)
% end
%
%%% Syntax:
%  B = natsortfiles(A)
%  B = natsortfiles(A,rgx)
%  B = natsortfiles(A,rgx,<options>)
% [B,ndx,dbg] = natsortfiles(A,...)
%
% To sort the elements of a string/cell array use NATSORT (File Exchange 34464)
% To sort the rows of a string/cell/table use NATSORTROWS (File Exchange 47433)
%
%% File Dependency %%
%
% NATSORTFILES requires the function NATSORT (File Exchange 34464). Extra
% optional arguments are passed directly to NATSORT. See NATSORT for case-
% sensitivity, sort direction, number format matching, and other options.
%
%% Explanation %%
%
% Using SORT on filenames will sort any of char(0:45), including the
% printing characters ' !"#$%&''()*+,-', before the file extension
% separator character '.'. Therefore NATSORTFILES splits the file-name
% from the file-extension and sorts them separately. This ensures that
% shorter names come before longer names (just like a dictionary):
%
% >> F = {'test_new.m'; 'test-old.m'; 'test.m'};
% >> sort(F) % Note '-' sorts before '.':
% ans =
%     'test-old.m'
%     'test.m'
%     'test_new.m'
% >> natsortfiles(F) % Shorter names before longer:
% ans =
%     'test.m'
%     'test-old.m'
%     'test_new.m'
%
% Similarly the path separator character within filepaths can cause longer
% directory names to sort before shorter ones, as char(0:46)<'/' and
% char(0:91)<'\'. This example on a PC demonstrates why this matters:
%
% >> D = {'A1\B', 'A+/B', 'A/B1', 'A=/B', 'A\B0'};
% >> sort(D)
% ans =   'A+/B'  'A/B1'  'A1\B'  'A=/B'  'A\B0'
% >> natsortfiles(D)
% ans =   'A\B0'  'A/B1'  'A1\B'  'A+/B'  'A=/B'
%
% NATSORTFILES splits filepaths at each path separator character and sorts
% every level of the directory hierarchy separately, ensuring that shorter
% directory names sort before longer, regardless of the characters in the names.
% On a PC separators are '/' and '\' characters, on Mac and Linux '/' only.
%
%% Examples %%
%
% >> A = {'a2.txt', 'a10.txt', 'a1.txt'}
% >> sort(A)
% ans = 'a1.txt'  'a10.txt'  'a2.txt'
% >> natsortfiles(A)
% ans = 'a1.txt'  'a2.txt'  'a10.txt'
%
% >> B = {'test2.m'; 'test10-old.m'; 'test.m'; 'test10.m'; 'test1.m'};
% >> sort(B) % Wrong number order:
% ans =
%    'test.m'
%    'test1.m'
%    'test10-old.m'
%    'test10.m'
%    'test2.m'
% >> natsortfiles(B) % Shorter names before longer:
% ans =
%    'test.m'
%    'test1.m'
%    'test2.m'
%    'test10.m'
%    'test10-old.m'
%
%%% Directory Names:
% >> C = {'A2-old\test.m';'A10\test.m';'A2\test.m';'A1\test.m';'A1-archive.zip'};
% >> sort(C) % Wrong number order, and '-' sorts before '\':
% ans =
%    'A1-archive.zip'
%    'A10\test.m'
%    'A1\test.m'
%    'A2-old\test.m'
%    'A2\test.m'
% >> natsortfiles(C) % Shorter names before longer:
% ans =
%    'A1\test.m'
%    'A1-archive.zip'
%    'A2\test.m'
%    'A2-old\test.m'
%    'A10\test.m'
%
%% Input and Output Arguments %%
%
%%% Inputs (**=default):
% A   = Array of filenames or foldernames to be sorted. Can be the struct
%       returned by DIR, a string array, or a cell array of char row vectors.
% rgx = Optional regular expression to match number substrings.
%     = [] uses the default regular expression (see NATSORT).
% <options> can be supplied in any order:
%     = 'rmdot' removes the names "." and ".." from the output array.
%     = 'noext' for foldernames, or filenames without extensions.
%     = 'xpath' sorts by name only, excluding any preceding path.
% Any remaining <options> are passed directly to NATSORT.
%
%%% Outputs:
% B   = Array <A> sorted into alphanumeric order.
% ndx = NumericMatrix, indices such that B = A(ndx). The same size as <B>.
% dbg = CellArray, each cell contains the debug cell array of one level
%       of the path heirarchy, i.e. directory names, or filenames, or file
%       extensions. Helps debug the regular expression (see NATSORT).
%
% See also SORT NATSORT NATSORTROWS ARBSORT IREGEXP REGEXP
% DIR FILEPARTS FULLFILE NEXTNAME STRING CELLSTR SSCANF
%% Input Wrangling %%
%
fnh = @(c)cellfun('isclass',c,'char') & cellfun('size',c,1)<2 & cellfun('ndims',c)<3;
%
if isstruct(A)
	assert(isfield(A,'name'),...
		'SC:natsortfiles:A:StructMissingNameField',...
		'If first input <A> is a struct then it must have field <name>.')
	nmx = {A.name};
	assert(all(fnh(nmx)),...
		'SC:natsortfiles:A:NameFieldInvalidType',...
		'First input <A> field <name> must contain only character row vectors.')
	[fpt,fnm,fxt] = cellfun(@fileparts, nmx, 'UniformOutput',false);
	if isfield(A,'folder')
		fpt(:) = {A.folder};
		assert(all(fnh(fpt)),...
			'SC:natsortfiles:A:FolderFieldInvalidType',...
			'First input <A> field <folder> must contain only character row vectors.')
	end
elseif iscell(A)
	assert(all(fnh(A(:))),...
		'SC:natsortfiles:A:CellContentInvalidType',...
		'First input <A> cell array must contain only character row vectors.')
	[fpt,fnm,fxt] = cellfun(@fileparts, A(:), 'UniformOutput',false);
	nmx = strcat(fnm,fxt);
elseif ischar(A)
	[fpt,fnm,fxt] = cellfun(@fileparts, cellstr(A), 'UniformOutput',false);
	nmx = strcat(fnm,fxt);
else
	assert(isa(A,'string'),...
		'SC:natsortfiles:A:InvalidType',...
		'First input <A> must be a structure, a cell array, or a string array.');
	[fpt,fnm,fxt] = cellfun(@fileparts, cellstr(A(:)), 'UniformOutput',false);
	nmx = strcat(fnm,fxt);
end
%
varargin = cellfun(@ns1s2c, varargin, 'UniformOutput',false);
ixv = fnh(varargin); % char
txt = varargin(ixv); % char
xtx = varargin(~ixv); % not
%
trd = strcmpi(txt,'rmdot');
assert(nnz(trd)<2,...
	'SC:natsortfiles:rmdot:Overspecified',...
	'The "." and ".." folder handling "rmdot" is overspecified.')
%
tnx = strcmpi(txt,'noext');
assert(nnz(tnx)<2,...
	'SC:natsortfiles:noext:Overspecified',...
	'The file-extension handling "noext" is overspecified.')
%
txp = strcmpi(txt,'xpath');
assert(nnz(txp)<2,...
	'SC:natsortfiles:xpath:Overspecified',...
	'The file-path handling "xpath" is overspecified.')
%
chk = '(no|rm|x)(dot|ext|path)';
%
if nargin>1
	nsfChkRgx(rgx,chk)
	txt = [{rgx},txt(~(trd|tnx|txp))];
end
%
%% Path and Extension %%
%
% Path separator regular expression:
if ispc()
	psr = '[^/\\]+';
else % Mac & Linux
	psr = '[^/]+';
end
%
if any(trd) % Remove "." and ".." folder names
	ddx = strcmp(nmx,'.') | strcmp(nmx,'..');
	fxt(ddx) = [];
	fnm(ddx) = [];
	fpt(ddx) = [];
	nmx(ddx) = [];
end
%
if any(tnx) % No file-extension
	fnm = nmx;
	fxt = [];
end
%
if any(txp) % No file-path
	mat = reshape(fnm,1,[]);
else
	% Split path into {dir,subdir,subsubdir,...}:
	spl = regexp(fpt(:),psr,'match');
	nmn = 1+cellfun('length',spl(:));
	mxn = max(nmn);
	vec = 1:mxn;
	mat = cell(mxn,numel(nmn));
	mat(:) = {''};
	%mat(mxn,:) = fnm(:); % old behavior
	mat(logical(bsxfun(@eq,vec,nmn).')) =  fnm(:);  % TRANSPOSE bug loses type (R2013b)
	mat(logical(bsxfun(@lt,vec,nmn).')) = [spl{:}]; % TRANSPOSE bug loses type (R2013b)
end
%
if numel(fxt) % File-extension
	mat(end+1,:) = fxt(:);
end
%
%% Sort File Extensions, Names, and Paths %%
%
nmr = size(mat,1)*all(size(mat));
dbg = cell(1,nmr);
ndx = 1:numel(fnm);
%
for k = nmr:-1:1
	if nargout<3 % faster:
		[~,idx] = natsort(mat(k,ndx),txt{:},xtx{:});
	else % for debugging:
		[~,idx,gbd] = natsort(mat(k,ndx),txt{:},xtx{:});
		[~,idb] = sort(ndx);
		dbg{k} = gbd(idb,:);
	end
	ndx = ndx(idx);
end
%
% Return the sorted input array and corresponding indices:
%
if any(trd)
	tmp = find(~ddx);
	ndx = tmp(ndx);
end
%
ndx = ndx(:);
%
if ischar(A)
	B = A(ndx,:);
elseif any(trd)
	xsz = size(A);
	nsd = xsz~=1;
	if nnz(nsd)==1 % vector
		xsz(nsd) = numel(ndx);
		ndx = reshape(ndx,xsz);
	end
	B = A(ndx);
else
	ndx = reshape(ndx,size(A));
	B = A(ndx);
end
%
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%natsortfiles
function nsfChkRgx(rgx,chk)
chk = sprintf('^(%s)$',chk);
assert(~ischar(rgx)||isempty(regexpi(rgx,chk,'once')),...
	'SC:natsortfiles:rgx:OptionMixUp',...
	['Second input <rgx> must be a regular expression that matches numbers.',...
	'\nThe provided expression "%s" looks like an optional argument (inputs 3+).'],rgx)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%nsfChkRgx
function arr = ns1s2c(arr)
% If scalar string then extract the character vector, otherwise data is unchanged.
if isa(arr,'string') && isscalar(arr)
	arr = arr{1};
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%ns1s2c