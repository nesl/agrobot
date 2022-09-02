function natsortfiles_test()
% Test function for NATSORTFILES.
%
% (c) 2014-2022 Stephen Cobeldick
%
% See also NATSORTFILES TESTFUN NATSORT_TEST NATSORTROWS_TEST
fnh = @natsortfiles;
chk = testfun(fnh);
%
c2s = @(c)struct('name',cellstr(c));
rmf = @(s)rmfield(s,setdiff(fieldnames(s),'name'));
%
try pad(strings()); iss=true; catch iss=false; warning('No string class.'), end %#ok<CTCH,WNTAG>
%
%% Mfile Examples %%
%
A =         {'a2.txt','a10.txt','a1.txt'};
chk(A, fnh, {'a1.txt','a2.txt','a10.txt'})
chk(A, fnh, {'a1.txt','a2.txt','a10.txt'}, [3,1,2]) % not in help
B =         {'test2.m';'test10-old.m';'test.m';'test10.m';'test1.m'};
chk(B, fnh, {'test.m';'test1.m';'test2.m';'test10.m';'test10-old.m'})
chk(B, fnh, {'test.m';'test1.m';'test2.m';'test10.m';'test10-old.m'}, [3;5;1;4;2]) % not in help
C =         {'A2-old\test.m';'A10\test.m';'A2\test.m';'A1\test.m';'A1-archive.zip'};
chk(C, fnh, {'A1\test.m';'A1-archive.zip';'A2\test.m';'A2-old\test.m';'A10\test.m'})
chk(C, fnh, {'A1\test.m';'A1-archive.zip';'A2\test.m';'A2-old\test.m';'A10\test.m'}, [4;5;3;1;2]) % not in help
D =         {'A1\B','A+/B','A/B1','A=/B','A\B0'};
chk(D, fnh, {'A\B0','A/B1','A1\B','A+/B','A=/B'})
chk(D, fnh, {'A\B0','A/B1','A1\B','A+/B','A=/B'}, [5,3,1,2,4]) % not in help
F =         {'test_new.m';'test-old.m';'test.m'};
chk(F, fnh, {'test.m';'test-old.m';'test_new.m'})
chk(F, fnh, {'test.m';'test-old.m';'test_new.m'}, [3;2;1]) % not in help
%
%% HTML Examples %%
%
A =         {'a2.txt','a10.txt','a1.txt'};
chk(A, fnh, {'a1.txt','a2.txt','a10.txt'})
chk(A, fnh, @i, [3,1,2]) % Not in HTML
chk(A, fnh, @i, [3,1,2], {{'a',2;'a',10;'a',1},{'.txt';'.txt';'.txt'}}) % not in HTML
chk(A, fnh, @i,      @i, {{'a',2;'a',10;'a',1},{'.txt';'.txt';'.txt'}}) % not in HTML
%
fnm = 'natsortfiles_test';
unzip(sprintf('%s.zip',fnm))
Q = {'A_1.txt';'A_1-new.txt';'A_1_new.txt';'A_2.txt';'A_3.txt';'A_10.txt';'A_100.txt';'A_200.txt'};
S = dir(fullfile('.',fnm,'A*.txt'));
chk(rmf(S), fnh, c2s(Q))
%
B =                      {'1.3.txt','1.10.txt','1.2.txt'};
chk(B,              fnh, {'1.2.txt','1.3.txt','1.10.txt'}, [3,1,2]) % index not in HTML
chk(B, '\d+\.?\d*', fnh, {'1.10.txt','1.2.txt','1.3.txt'}, [2,3,1]) % index not in HTML
%
chk({'natsort_doc.html','natsortrows_doc.html','..','.'}, [], 'rmdot', fnh, ...
	{'natsort_doc.html','natsortrows_doc.html'})
%
C =                               {'1.9','1.10','1.2'};
chk(C, '\d+\.?\d*',          fnh, {'1.2','1.9','1.10'}, [3,1,2]) % index not in HTML
chk(C, '\d+\.?\d*', 'noext', fnh, {'1.10','1.2','1.9'}, [2,3,1]) % index not in HTML
%
D =                      {'B/3.txt','A/1.txt','B/100.txt','A/20.txt'};
chk(D,              fnh, {'A/1.txt','A/20.txt','B/3.txt','B/100.txt'}, [2,4,1,3]) % index not in HTML
chk(D, [], 'xpath', fnh, {'A/1.txt','B/3.txt','A/20.txt','B/100.txt'}, [2,1,4,3]) % index not in HTML
%
E =                         {'B.txt','10.txt','1.txt','A.txt','2.txt'};
chk(E, [],  'descend', fnh, {'B.txt','A.txt','10.txt','2.txt','1.txt'})
chk(E, [], 'char<num', fnh, {'A.txt','B.txt','1.txt','2.txt','10.txt'})
%
F =         {'abc2xyz.txt','abc2xy99.txt','abc10xyz.txt','abc1xyz.txt'};
chk(F, fnh, {'abc1xyz.txt','abc2xy99.txt','abc2xyz.txt','abc10xyz.txt'}, [4,2,1,3])  % index not in HTML
chk(F, fnh, {'abc1xyz.txt','abc2xy99.txt','abc2xyz.txt','abc10xyz.txt'}, [4,2,1,3], ...index not in HTML
	{{'abc',2,'xyz',[];'abc',2,'xy',99;'abc',10,'xyz',[];'abc',1,'xyz',[]},...
	{          '.txt';          '.txt';           '.txt';          '.txt'}})
%
chk({'test_ccc.m';'test-aaa.m';'test.m';'test.bbb.m'}, fnh,... G
	{'test.m';'test-aaa.m';'test.bbb.m';'test_ccc.m'}, [3;2;4;1]) % index not in HTML
chk({'test2.m';'test10-old.m';'test.m';'test10.m';'test1.m'}, fnh,... H
	{'test.m';'test1.m';'test2.m';'test10.m';'test10-old.m'}, [3;5;1;4;2]) % index not in HTML
chk({'A2-old\test.m';'A10\test.m';'A2\test.m';'AXarchive.zip';'A1\test.m'}, fnh,... I
	{'A1\test.m';'A2\test.m';'A2-old\test.m';'A10\test.m';'AXarchive.zip'}, [5;3;1;2;4]) % index not in HTML
%
J = {'1.23V.csv','-1V.csv','+1.csv','010V.csv','1.200V.csv'};
chk(J, fnh,...
	{'1.23V.csv','1.200V.csv','010V.csv','+1.csv','-1V.csv'}, [1,5,4,3,2]) % index not in HTML
chk(J, '[-+]?\d+\.?\d*', fnh,...
	{'-1V.csv','+1.csv','1.200V.csv','1.23V.csv','010V.csv'}, [2,3,5,1,4]) % index not in HTML
%
%% Numeric XOR Alphabetic %%
%
K = {'100','00','20','1','0','2'}; L = {num2cell(str2double(K(:))),cell(6,0)};
chk(K, fnh, ...
	{'00','0','1','2','20','100'}, [2,5,4,6,3,1], L)
chk(K, [], 'num<char', fnh, ...
	{'00','0','1','2','20','100'}, [2,5,4,6,3,1], L)
chk(K, [], 'char<num', fnh, ...
	{'00','0','1','2','20','100'}, [2,5,4,6,3,1], L)
chk(K, [], 'ascend', fnh, ...
	{'00','0','1','2','20','100'}, [2,5,4,6,3,1], L)
chk(K, [], 'descend', fnh, ...
	{'100','20','2','1','00','0'}, [1,3,6,4,2,5], L)
K = {'00','0','000','0','00','0'}; L = {num2cell(str2double(K(:))),cell(6,0)};
chk(K, fnh, ...
	{'00','0','000','0','00','0'}, [1,2,3,4,5,6], L)
chk(K, [], 'num<char', fnh, ...
	{'00','0','000','0','00','0'}, [1,2,3,4,5,6], L)
chk(K, [], 'char<num', fnh, ...
	{'00','0','000','0','00','0'}, [1,2,3,4,5,6], L)
chk(K, [], 'ascend', fnh, ...
	{'00','0','000','0','00','0'}, [1,2,3,4,5,6], L)
chk(K, [], 'descend', fnh, ...
	{'00','0','000','0','00','0'}, [1,2,3,4,5,6], L)
%
K = {'BA','B','BAA','B','AA','A','CA','A','C'}; L = {K(:),cell(9,0)};
chk(K, fnh, ...
	{'A','A','AA','B','B','BA','BAA','C','CA'}, [6,8,5,2,4,1,3,9,7], L)
chk(K, [], 'num<char', fnh, ...
	{'A','A','AA','B','B','BA','BAA','C','CA'}, [6,8,5,2,4,1,3,9,7], L)
chk(K, [], 'char<num', fnh, ...
	{'A','A','AA','B','B','BA','BAA','C','CA'}, [6,8,5,2,4,1,3,9,7], L)
chk(K, [], 'ascend', fnh, ...
	{'A','A','AA','B','B','BA','BAA','C','CA'}, [6,8,5,2,4,1,3,9,7], L)
chk(K, [], 'descend', fnh, ...
	{'CA','C','BAA','BA','B','B','AA','A','A'}, [7,9,3,1,2,4,5,6,8], L)
%
%% DIR Structure %%
%
S = dir(fullfile('.',fnm,'A*.xyz')); % zero files
chk(rmf(S), fnh, c2s(cell(0,1)))
chk(reshape(rmf(S),0,0,2), fnh, c2s(cell(0,0,2)))
chk(reshape(rmf(S),1,0,2), fnh, c2s(cell(1,0,2)))
chk(reshape(rmf(S),2,0,2), fnh, c2s(cell(2,0,2)))
chk(reshape(rmf(S),3,0,2), fnh, c2s(cell(3,0,2)))
chk(reshape(rmf(S),4,0,2), fnh, c2s(cell(4,0,2)))
chk(reshape(rmf(S),5,0,2), fnh, c2s(cell(5,0,2)))
chk(reshape(rmf(S),6,0,2), fnh, c2s(cell(6,0,2)))
chk(reshape(rmf(S),7,0,2), fnh, c2s(cell(7,0,2)))
chk(reshape(rmf(S),8,0,2), fnh, c2s(cell(8,0,2)))
chk(reshape(rmf(S),9,0,2), fnh, c2s(cell(9,0,2)))
chk(reshape(rmf(S),0,0,2), [],  'ascend', fnh, c2s(cell(0,0,2)))
chk(reshape(rmf(S),1,0,2), [],  'ascend', fnh, c2s(cell(1,0,2)))
chk(reshape(rmf(S),2,0,2), [],  'ascend', fnh, c2s(cell(2,0,2)))
chk(reshape(rmf(S),3,0,2), [],  'ascend', fnh, c2s(cell(3,0,2)))
chk(reshape(rmf(S),4,0,2), [],  'ascend', fnh, c2s(cell(4,0,2)))
chk(reshape(rmf(S),5,0,2), [],  'ascend', fnh, c2s(cell(5,0,2)))
chk(reshape(rmf(S),0,0,2), [], 'descend', fnh, c2s(cell(0,0,2)))
chk(reshape(rmf(S),1,0,2), [], 'descend', fnh, c2s(cell(1,0,2)))
chk(reshape(rmf(S),2,0,2), [], 'descend', fnh, c2s(cell(2,0,2)))
chk(reshape(rmf(S),3,0,2), [], 'descend', fnh, c2s(cell(3,0,2)))
chk(reshape(rmf(S),4,0,2), [], 'descend', fnh, c2s(cell(4,0,2)))
chk(reshape(rmf(S),5,0,2), [], 'descend', fnh, c2s(cell(5,0,2)))
%
S = dir(fullfile('.',fnm,'A*3*.txt')); % one file
chk(rmf(S), fnh, c2s({'A_3.txt'}))
chk(rmf(S), [],  'ascend', fnh, c2s({'A_3.txt'}))
chk(rmf(S), [], 'descend', fnh, c2s({'A_3.txt'}))
chk(rmf(S), [], 'rmdot',  'ascend', fnh, c2s({'A_3.txt'}))
chk(rmf(S), [], 'rmdot', 'descend', fnh, c2s({'A_3.txt'}))
%
S = dir(fullfile('.',fnm,'A*new.txt')); % two files
chk(rmf(S), fnh, c2s({'A_1-new.txt';'A_1_new.txt'}))
chk(rmf(S), [],  'ascend', fnh, c2s({'A_1-new.txt';'A_1_new.txt'}))
chk(rmf(S), [], 'descend', fnh, c2s({'A_1_new.txt';'A_1-new.txt'}))
%
S = dir(fullfile('.',fnm,'A*0.txt')); % three files
chk(rmf(S), fnh, c2s({'A_10.txt';'A_100.txt';'A_200.txt'}))
chk(rmf(S), [],  'ascend', fnh, c2s({'A_10.txt';'A_100.txt';'A_200.txt'}))
chk(rmf(S), [], 'descend', fnh, c2s({'A_200.txt';'A_100.txt';'A_10.txt'}))
%
S = dir(fullfile('.',fnm,'A*.txt')); % eight files
chk(reshape(rmf(S),1,8).', fnh, reshape(c2s(Q),8,1))
chk(reshape(rmf(S),2,4).', fnh, reshape(c2s(Q),4,2))
chk(reshape(rmf(S),4,2).', fnh, reshape(c2s(Q),2,4))
chk(reshape(rmf(S),8,1).', fnh, reshape(c2s(Q),1,8))
chk(reshape(rmf(S),1,8).', [],  'ascend', fnh, reshape(c2s(Q),8,1))
chk(reshape(rmf(S),2,4).', [],  'ascend', fnh, reshape(c2s(Q),4,2))
chk(reshape(rmf(S),4,2).', [],  'ascend', fnh, reshape(c2s(Q),2,4))
chk(reshape(rmf(S),8,1).', [],  'ascend', fnh, reshape(c2s(Q),1,8))
chk(reshape(rmf(S),1,8).', [], 'descend', fnh, reshape(c2s(Q(end:-1:1)),8,1))
chk(reshape(rmf(S),2,4).', [], 'descend', fnh, reshape(c2s(Q(end:-1:1)),4,2))
chk(reshape(rmf(S),4,2).', [], 'descend', fnh, reshape(c2s(Q(end:-1:1)),2,4))
chk(reshape(rmf(S),8,1).', [], 'descend', fnh, reshape(c2s(Q(end:-1:1)),1,8))
%
%% Dot Folder Names %%
%
S = dir(fullfile('.',fnm,'*'));
chk(rmf(S), fnh, c2s([{'.';'..'};Q]))
chk(rmf(S), [], 'rmdot', fnh, c2s(Q))
chk(rmf(S), [], 'rmdot',  'ascend', fnh, c2s(Q))
chk(rmf(S), [],  'ascend', 'rmdot', fnh, c2s(Q))
chk(rmf(S), [], 'rmdot', 'descend', fnh, c2s(Q(end:-1:1)))
chk(rmf(S), [], 'descend', 'rmdot', fnh, c2s(Q(end:-1:1)))
%
T =         {'...txt','txt.txt','','.','..txt','..','.','_.txt'};
chk(T, fnh, {'','.','.','..','..txt','...txt','_.txt','txt.txt'},[3,4,7,6,5,1,8,2])
chk(T, [], 'rmdot', fnh, {'','..txt','...txt','_.txt','txt.txt'},[3,5,1,8,2])
%
chk(T(:), fnh, {'';'.';'.';'..';'..txt';'...txt';'_.txt';'txt.txt'},[3;4;7;6;5;1;8;2])
chk(T(:), [], 'rmdot', fnh, {'';'..txt';'...txt';'_.txt';'txt.txt'},[3;5;1;8;2])
%
%% Orientation %%
%
chk({}, fnh, {}, []) % empty!
chk({}, [],  'ascend', fnh, {}, []) % empty!
chk({}, [], 'descend', fnh, {}, []) % empty!
chk(cell(0,2,0), fnh, cell(0,2,0), nan(0,2,0)) % empty!
chk(cell(0,2,1), fnh, cell(0,2,1), nan(0,2,1)) % empty!
chk(cell(0,2,2), fnh, cell(0,2,2), nan(0,2,2)) % empty!
chk(cell(0,2,3), fnh, cell(0,2,3), nan(0,2,3)) % empty!
chk(cell(0,2,4), fnh, cell(0,2,4), nan(0,2,4)) % empty!
chk(cell(0,2,5), fnh, cell(0,2,5), nan(0,2,5)) % empty!
chk(cell(0,2,6), fnh, cell(0,2,6), nan(0,2,6)) % empty!
chk(cell(0,2,7), fnh, cell(0,2,7), nan(0,2,7)) % empty!
chk(cell(0,2,8), fnh, cell(0,2,8), nan(0,2,8)) % empty!
chk(cell(0,2,9), fnh, cell(0,2,9), nan(0,2,9)) % empty!
chk(cell(0,2,0), [],  'ascend', fnh, cell(0,2,0), nan(0,2,0)) % empty!
chk(cell(0,2,1), [],  'ascend', fnh, cell(0,2,1), nan(0,2,1)) % empty!
chk(cell(0,2,2), [],  'ascend', fnh, cell(0,2,2), nan(0,2,2)) % empty!
chk(cell(0,2,3), [],  'ascend', fnh, cell(0,2,3), nan(0,2,3)) % empty!
chk(cell(0,2,4), [],  'ascend', fnh, cell(0,2,4), nan(0,2,4)) % empty!
chk(cell(0,2,5), [],  'ascend', fnh, cell(0,2,5), nan(0,2,5)) % empty!
chk(cell(0,2,6), [],  'ascend', fnh, cell(0,2,6), nan(0,2,6)) % empty!
chk(cell(0,2,7), [],  'ascend', fnh, cell(0,2,7), nan(0,2,7)) % empty!
chk(cell(0,2,8), [],  'ascend', fnh, cell(0,2,8), nan(0,2,8)) % empty!
chk(cell(0,2,9), [],  'ascend', fnh, cell(0,2,9), nan(0,2,9)) % empty!
chk(cell(0,2,0), [], 'descend', fnh, cell(0,2,0), nan(0,2,0)) % empty!
chk(cell(0,2,1), [], 'descend', fnh, cell(0,2,1), nan(0,2,1)) % empty!
chk(cell(0,2,2), [], 'descend', fnh, cell(0,2,2), nan(0,2,2)) % empty!
chk(cell(0,2,3), [], 'descend', fnh, cell(0,2,3), nan(0,2,3)) % empty!
chk(cell(0,2,4), [], 'descend', fnh, cell(0,2,4), nan(0,2,4)) % empty!
chk(cell(0,2,5), [], 'descend', fnh, cell(0,2,5), nan(0,2,5)) % empty!
chk(cell(0,2,6), [], 'descend', fnh, cell(0,2,6), nan(0,2,6)) % empty!
chk(cell(0,2,7), [], 'descend', fnh, cell(0,2,7), nan(0,2,7)) % empty!
chk(cell(0,2,8), [], 'descend', fnh, cell(0,2,8), nan(0,2,8)) % empty!
chk(cell(0,2,9), [], 'descend', fnh, cell(0,2,9), nan(0,2,9)) % empty!
%
chk({'1';'10';'20';'2'}, fnh,...
	{'1';'2';'10';'20'}, [1;4;2;3])
chk({'2','10','8';'#','a',' '}, fnh,...
	{'2','10','#';'8',' ','a'}, [1,3,2;5,6,4])
%
%% Index Stability %%
%
rmf = @(s,r,c)repmat({s},r,c);
chk(rmf('',1,0), fnh, rmf('',1,0), 1:0,  cell(1,0))
chk(rmf('',1,1), fnh, rmf('',1,1), 1:1, {cell(1,0),cell(1,0)})
chk(rmf('',1,2), fnh, rmf('',1,2), 1:2, {cell(2,0),cell(2,0)})
chk(rmf('',1,3), fnh, rmf('',1,3), 1:3, {cell(3,0),cell(3,0)})
chk(rmf('',1,4), fnh, rmf('',1,4), 1:4, {cell(4,0),cell(4,0)})
chk(rmf('',1,5), fnh, rmf('',1,5), 1:5, {cell(5,0),cell(5,0)})
chk(rmf('',1,6), fnh, rmf('',1,6), 1:6, {cell(6,0),cell(6,0)})
chk(rmf('',1,7), fnh, rmf('',1,7), 1:7, {cell(7,0),cell(7,0)})
chk(rmf('',1,8), fnh, rmf('',1,8), 1:8, {cell(8,0),cell(8,0)})
chk(rmf('',1,9), fnh, rmf('',1,9), 1:9, {cell(9,0),cell(9,0)})
chk(rmf('',1,0), [],  'ascend', fnh, rmf('',1,0), 1:0,  cell(1,0))
chk(rmf('',1,1), [],  'ascend', fnh, rmf('',1,1), 1:1, {cell(1,0),cell(1,0)})
chk(rmf('',1,2), [],  'ascend', fnh, rmf('',1,2), 1:2, {cell(2,0),cell(2,0)})
chk(rmf('',1,3), [],  'ascend', fnh, rmf('',1,3), 1:3, {cell(3,0),cell(3,0)})
chk(rmf('',1,4), [],  'ascend', fnh, rmf('',1,4), 1:4, {cell(4,0),cell(4,0)})
chk(rmf('',1,5), [],  'ascend', fnh, rmf('',1,5), 1:5, {cell(5,0),cell(5,0)})
chk(rmf('',1,6), [],  'ascend', fnh, rmf('',1,6), 1:6, {cell(6,0),cell(6,0)})
chk(rmf('',1,7), [],  'ascend', fnh, rmf('',1,7), 1:7, {cell(7,0),cell(7,0)})
chk(rmf('',1,8), [],  'ascend', fnh, rmf('',1,8), 1:8, {cell(8,0),cell(8,0)})
chk(rmf('',1,9), [],  'ascend', fnh, rmf('',1,9), 1:9, {cell(9,0),cell(9,0)})
chk(rmf('',1,0), [], 'descend', fnh, rmf('',1,0), 1:0,  cell(1,0))
chk(rmf('',1,1), [], 'descend', fnh, rmf('',1,1), 1:1, {cell(1,0),cell(1,0)})
chk(rmf('',1,2), [], 'descend', fnh, rmf('',1,2), 1:2, {cell(2,0),cell(2,0)})
chk(rmf('',1,3), [], 'descend', fnh, rmf('',1,3), 1:3, {cell(3,0),cell(3,0)})
chk(rmf('',1,4), [], 'descend', fnh, rmf('',1,4), 1:4, {cell(4,0),cell(4,0)})
chk(rmf('',1,5), [], 'descend', fnh, rmf('',1,5), 1:5, {cell(5,0),cell(5,0)})
chk(rmf('',1,6), [], 'descend', fnh, rmf('',1,6), 1:6, {cell(6,0),cell(6,0)})
chk(rmf('',1,7), [], 'descend', fnh, rmf('',1,7), 1:7, {cell(7,0),cell(7,0)})
chk(rmf('',1,8), [], 'descend', fnh, rmf('',1,8), 1:8, {cell(8,0),cell(8,0)})
chk(rmf('',1,9), [], 'descend', fnh, rmf('',1,9), 1:9, {cell(9,0),cell(9,0)})
chk(rmf('X.Y',1,0), fnh, rmf('X.Y',1,0), 1:0, cell(1,0))
chk(rmf('X.Y',1,1), fnh, rmf('X.Y',1,1), 1:1, {rmf('X',1,1),rmf('.Y',1,1)})
chk(rmf('X.Y',1,2), fnh, rmf('X.Y',1,2), 1:2, {rmf('X',2,1),rmf('.Y',2,1)})
chk(rmf('X.Y',1,3), fnh, rmf('X.Y',1,3), 1:3, {rmf('X',3,1),rmf('.Y',3,1)})
chk(rmf('X.Y',1,4), fnh, rmf('X.Y',1,4), 1:4, {rmf('X',4,1),rmf('.Y',4,1)})
chk(rmf('X.Y',1,5), fnh, rmf('X.Y',1,5), 1:5, {rmf('X',5,1),rmf('.Y',5,1)})
chk(rmf('X.Y',1,6), fnh, rmf('X.Y',1,6), 1:6, {rmf('X',6,1),rmf('.Y',6,1)})
chk(rmf('X.Y',1,7), fnh, rmf('X.Y',1,7), 1:7, {rmf('X',7,1),rmf('.Y',7,1)})
chk(rmf('X.Y',1,8), fnh, rmf('X.Y',1,8), 1:8, {rmf('X',8,1),rmf('.Y',8,1)})
chk(rmf('X.Y',1,9), fnh, rmf('X.Y',1,9), 1:9, {rmf('X',9,1),rmf('.Y',9,1)})
chk(rmf('X.Y',1,0), [],  'ascend', fnh, rmf('X.Y',1,0), 1:0, cell(1,0))
chk(rmf('X.Y',1,1), [],  'ascend', fnh, rmf('X.Y',1,1), 1:1, {rmf('X',1,1),rmf('.Y',1,1)})
chk(rmf('X.Y',1,2), [],  'ascend', fnh, rmf('X.Y',1,2), 1:2, {rmf('X',2,1),rmf('.Y',2,1)})
chk(rmf('X.Y',1,3), [],  'ascend', fnh, rmf('X.Y',1,3), 1:3, {rmf('X',3,1),rmf('.Y',3,1)})
chk(rmf('X.Y',1,4), [],  'ascend', fnh, rmf('X.Y',1,4), 1:4, {rmf('X',4,1),rmf('.Y',4,1)})
chk(rmf('X.Y',1,5), [],  'ascend', fnh, rmf('X.Y',1,5), 1:5, {rmf('X',5,1),rmf('.Y',5,1)})
chk(rmf('X.Y',1,6), [],  'ascend', fnh, rmf('X.Y',1,6), 1:6, {rmf('X',6,1),rmf('.Y',6,1)})
chk(rmf('X.Y',1,7), [],  'ascend', fnh, rmf('X.Y',1,7), 1:7, {rmf('X',7,1),rmf('.Y',7,1)})
chk(rmf('X.Y',1,8), [],  'ascend', fnh, rmf('X.Y',1,8), 1:8, {rmf('X',8,1),rmf('.Y',8,1)})
chk(rmf('X.Y',1,9), [],  'ascend', fnh, rmf('X.Y',1,9), 1:9, {rmf('X',9,1),rmf('.Y',9,1)})
chk(rmf('X.Y',1,0), [], 'descend', fnh, rmf('X.Y',1,0), 1:0, cell(1,0))
chk(rmf('X.Y',1,1), [], 'descend', fnh, rmf('X.Y',1,1), 1:1, {rmf('X',1,1),rmf('.Y',1,1)})
chk(rmf('X.Y',1,2), [], 'descend', fnh, rmf('X.Y',1,2), 1:2, {rmf('X',2,1),rmf('.Y',2,1)})
chk(rmf('X.Y',1,3), [], 'descend', fnh, rmf('X.Y',1,3), 1:3, {rmf('X',3,1),rmf('.Y',3,1)})
chk(rmf('X.Y',1,4), [], 'descend', fnh, rmf('X.Y',1,4), 1:4, {rmf('X',4,1),rmf('.Y',4,1)})
chk(rmf('X.Y',1,5), [], 'descend', fnh, rmf('X.Y',1,5), 1:5, {rmf('X',5,1),rmf('.Y',5,1)})
chk(rmf('X.Y',1,6), [], 'descend', fnh, rmf('X.Y',1,6), 1:6, {rmf('X',6,1),rmf('.Y',6,1)})
chk(rmf('X.Y',1,7), [], 'descend', fnh, rmf('X.Y',1,7), 1:7, {rmf('X',7,1),rmf('.Y',7,1)})
chk(rmf('X.Y',1,8), [], 'descend', fnh, rmf('X.Y',1,8), 1:8, {rmf('X',8,1),rmf('.Y',8,1)})
chk(rmf('X.Y',1,9), [], 'descend', fnh, rmf('X.Y',1,9), 1:9, {rmf('X',9,1),rmf('.Y',9,1)})
chk(rmf('9.Y',1,0), fnh, rmf('9.Y',1,0), 1:0, cell(1,0))
chk(rmf('9.Y',1,1), fnh, rmf('9.Y',1,1), 1:1, {rmf(9,1,1),rmf('.Y',1,1)})
chk(rmf('9.Y',1,2), fnh, rmf('9.Y',1,2), 1:2, {rmf(9,2,1),rmf('.Y',2,1)})
chk(rmf('9.Y',1,3), fnh, rmf('9.Y',1,3), 1:3, {rmf(9,3,1),rmf('.Y',3,1)})
chk(rmf('9.Y',1,4), fnh, rmf('9.Y',1,4), 1:4, {rmf(9,4,1),rmf('.Y',4,1)})
chk(rmf('9.Y',1,5), fnh, rmf('9.Y',1,5), 1:5, {rmf(9,5,1),rmf('.Y',5,1)})
chk(rmf('9.Y',1,6), fnh, rmf('9.Y',1,6), 1:6, {rmf(9,6,1),rmf('.Y',6,1)})
chk(rmf('9.Y',1,7), fnh, rmf('9.Y',1,7), 1:7, {rmf(9,7,1),rmf('.Y',7,1)})
chk(rmf('9.Y',1,8), fnh, rmf('9.Y',1,8), 1:8, {rmf(9,8,1),rmf('.Y',8,1)})
chk(rmf('9.Y',1,9), fnh, rmf('9.Y',1,9), 1:9, {rmf(9,9,1),rmf('.Y',9,1)})
chk(rmf('9.Y',1,0), [],  'ascend', fnh, rmf('9.Y',1,0), 1:0, cell(1,0))
chk(rmf('9.Y',1,1), [],  'ascend', fnh, rmf('9.Y',1,1), 1:1, {rmf(9,1,1),rmf('.Y',1,1)})
chk(rmf('9.Y',1,2), [],  'ascend', fnh, rmf('9.Y',1,2), 1:2, {rmf(9,2,1),rmf('.Y',2,1)})
chk(rmf('9.Y',1,3), [],  'ascend', fnh, rmf('9.Y',1,3), 1:3, {rmf(9,3,1),rmf('.Y',3,1)})
chk(rmf('9.Y',1,4), [],  'ascend', fnh, rmf('9.Y',1,4), 1:4, {rmf(9,4,1),rmf('.Y',4,1)})
chk(rmf('9.Y',1,5), [],  'ascend', fnh, rmf('9.Y',1,5), 1:5, {rmf(9,5,1),rmf('.Y',5,1)})
chk(rmf('9.Y',1,6), [],  'ascend', fnh, rmf('9.Y',1,6), 1:6, {rmf(9,6,1),rmf('.Y',6,1)})
chk(rmf('9.Y',1,7), [],  'ascend', fnh, rmf('9.Y',1,7), 1:7, {rmf(9,7,1),rmf('.Y',7,1)})
chk(rmf('9.Y',1,8), [],  'ascend', fnh, rmf('9.Y',1,8), 1:8, {rmf(9,8,1),rmf('.Y',8,1)})
chk(rmf('9.Y',1,9), [],  'ascend', fnh, rmf('9.Y',1,9), 1:9, {rmf(9,9,1),rmf('.Y',9,1)})
chk(rmf('9.Y',1,0), [], 'descend', fnh, rmf('9.Y',1,0), 1:0, cell(1,0))
chk(rmf('9.Y',1,1), [], 'descend', fnh, rmf('9.Y',1,1), 1:1, {rmf(9,1,1),rmf('.Y',1,1)})
chk(rmf('9.Y',1,2), [], 'descend', fnh, rmf('9.Y',1,2), 1:2, {rmf(9,2,1),rmf('.Y',2,1)})
chk(rmf('9.Y',1,3), [], 'descend', fnh, rmf('9.Y',1,3), 1:3, {rmf(9,3,1),rmf('.Y',3,1)})
chk(rmf('9.Y',1,4), [], 'descend', fnh, rmf('9.Y',1,4), 1:4, {rmf(9,4,1),rmf('.Y',4,1)})
chk(rmf('9.Y',1,5), [], 'descend', fnh, rmf('9.Y',1,5), 1:5, {rmf(9,5,1),rmf('.Y',5,1)})
chk(rmf('9.Y',1,6), [], 'descend', fnh, rmf('9.Y',1,6), 1:6, {rmf(9,6,1),rmf('.Y',6,1)})
chk(rmf('9.Y',1,7), [], 'descend', fnh, rmf('9.Y',1,7), 1:7, {rmf(9,7,1),rmf('.Y',7,1)})
chk(rmf('9.Y',1,8), [], 'descend', fnh, rmf('9.Y',1,8), 1:8, {rmf(9,8,1),rmf('.Y',8,1)})
chk(rmf('9.Y',1,9), [], 'descend', fnh, rmf('9.Y',1,9), 1:9, {rmf(9,9,1),rmf('.Y',9,1)})
%
V = {'x';'z';'y';'';'z';'';'x';'y'};
chk(V, fnh,...
	{'';'';'x';'x';'y';'y';'z';'z'},[4;6;1;7;3;8;2;5])
chk(V, [], 'ascend', fnh,...
	{'';'';'x';'x';'y';'y';'z';'z'},[4;6;1;7;3;8;2;5])
chk(V, [], 'descend', fnh,...
	{'z';'z';'y';'y';'x';'x';'';''},[2;5;3;8;1;7;4;6])
%
W = {'2x';'2z';'2y';'2';'2z';'2';'2x';'2y'};
chk(W, fnh,...
	{'2';'2';'2x';'2x';'2y';'2y';'2z';'2z'},[4;6;1;7;3;8;2;5])
chk(W, [], 'ascend', fnh,...
	{'2';'2';'2x';'2x';'2y';'2y';'2z';'2z'},[4;6;1;7;3;8;2;5])
chk(W, [], 'descend', fnh,...
	{'2z';'2z';'2y';'2y';'2x';'2x';'2';'2'},[2;5;3;8;1;7;4;6])
%
%% Extension and Separator Characters %%
%
chk({'A.x3','','A.x20','A.x','A','A.x1'}, fnh,...
	{'','A','A.x','A.x1','A.x3','A.x20'}, [2,5,4,6,1,3])
chk({'A=.z','A.z','A..z','A-.z','A#.z'}, fnh,...
	{'A.z','A#.z','A-.z','A..z','A=.z'}, [2,5,4,3,1])
chk({'A~/B','A/B','A#/B','A=/B','A-/B'}, fnh,...
	{'A/B','A#/B','A-/B','A=/B','A~/B'}, [2,3,5,4,1])
%
X = {'1.10','1.2'};
chk(X, '\d+\.?\d*', fnh,...
	{'1.2','1.10'}, [2,1], {{1;1},{'.',10;'.',2}})
chk(X, '\d+\.?\d*', 'noext', fnh,...
	{'1.10','1.2'}, [1,2], {{1.1;1.2}})
%
Y = {'1.2','2.2','20','2','2.10','10','1','2.00','1.10'};
chk(Y, '\d+\.?\d*', fnh,...
	{'1','1.2','1.10','2','2.00','2.2','2.10','10','20'},[7,1,9,4,8,2,5,6,3])
chk(Y, '\d+\.?\d*', 'noext', fnh,...
	{'1','1.10','1.2','2','2.00','2.10','2.2','10','20'},[7,9,1,4,8,5,2,6,3])
chk(Y, '\d+\.?\d*', 'noext', 'ascend', fnh,...
	{'1','1.10','1.2','2','2.00','2.10','2.2','10','20'},[7,9,1,4,8,5,2,6,3])
chk(Y, '\d+\.?\d*', 'noext', 'descend', fnh,...
	{'20','10','2.2','2.10','2','2.00','1.2','1.10','1'},[3,6,2,5,4,8,1,9,7])
%
%% Other Implementation Examples %%
%
% <https://blog.codinghorror.com/sorting-for-humans-natural-sort-order/>
chk({'z1.txt','z10.txt','z100.txt','z101.txt','z102.txt','z11.txt','z12.txt','z13.txt','z14.txt','z15.txt','z16.txt','z17.txt','z18.txt','z19.txt','z2.txt','z20.txt','z3.txt','z4.txt','z5.txt','z6.txt','z7.txt','z8.txt','z9.txt'}, fnh,...
	{'z1.txt','z2.txt','z3.txt','z4.txt','z5.txt','z6.txt','z7.txt','z8.txt','z9.txt','z10.txt','z11.txt','z12.txt','z13.txt','z14.txt','z15.txt','z16.txt','z17.txt','z18.txt','z19.txt','z20.txt','z100.txt','z101.txt','z102.txt'})
%
% <https://blog.jooq.org/2018/02/23/how-to-order-file-names-semantically-in-java/>
chk({'C:\temp\version-1.sql','C:\temp\version-10.1.sql','C:\temp\version-10.sql','C:\temp\version-2.sql','C:\temp\version-21.sql'}, fnh,...
	{'C:\temp\version-1.sql','C:\temp\version-2.sql','C:\temp\version-10.sql','C:\temp\version-10.1.sql','C:\temp\version-21.sql'})
%
% <http://www.davekoelle.com/alphanum.html>
chk({'z1.doc','z10.doc','z100.doc','z101.doc','z102.doc','z11.doc','z12.doc','z13.doc','z14.doc','z15.doc','z16.doc','z17.doc','z18.doc','z19.doc','z2.doc','z20.doc','z3.doc','z4.doc','z5.doc','z6.doc','z7.doc','z8.doc','z9.doc'}, fnh, ...
	{'z1.doc','z2.doc','z3.doc','z4.doc','z5.doc','z6.doc','z7.doc','z8.doc','z9.doc','z10.doc','z11.doc','z12.doc','z13.doc','z14.doc','z15.doc','z16.doc','z17.doc','z18.doc','z19.doc','z20.doc','z100.doc','z101.doc','z102.doc'})
%
% <https://sourcefrog.net/projects/natsort/>
chk({'rfc1.txt';'rfc2086.txt';'rfc822.txt'}, fnh,...
	{'rfc1.txt';'rfc822.txt';'rfc2086.txt'})
%
% <https://www.strchr.com/natural_sorting>
chk({'picture 1.png','picture 10.png','picture 100.png','picture 11.png','picture 2.png','picture 21.png','picture 2_10.png','picture 2_9.png','picture 3.png','picture 3b.png','picture A.png'}, fnh,...
	{'picture 1.png','picture 2.png','picture 2_9.png','picture 2_10.png','picture 3.png','picture 3b.png','picture 10.png','picture 11.png','picture 21.png','picture 100.png','picture A.png'})
%
% <https://github.com/sourcefrog/natsort>
chk({'rfc1.txt','rfc2086.txt','rfc822.txt'}, fnh,...
	{'rfc1.txt','rfc822.txt','rfc2086.txt'})
%
% <https://www.php.net/manual/en/function.natsort.php>
chk({'img12.png', 'img10.png', 'img2.png', 'img1.png'}, fnh,...
	{'img1.png', 'img2.png', 'img10.png', 'img12.png'})
%
% <http://www.naturalordersort.org/>
chk({'Picture1.jpg';'Picture10.jpg';'Picture11.jpg';'Picture12.jpg';'Picture2.jpg';'Picture3.jpg';'Picture4.jpg';'Picture5.jpg';'Picture6.jpg';'Picture7.jpg';'Picture8.jpg';'Picture9.jpg'}, fnh,...
	{'Picture1.jpg';'Picture2.jpg';'Picture3.jpg';'Picture4.jpg';'Picture5.jpg';'Picture6.jpg';'Picture7.jpg';'Picture8.jpg';'Picture9.jpg';'Picture10.jpg';'Picture11.jpg';'Picture12.jpg'})
%
rmdir(fnm,'s')
%
chk() % display summary
%
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%natsortfiles_test