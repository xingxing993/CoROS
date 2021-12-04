function strout = coros_rmvtrailingF(strin)
strout = regexprep(strin, '(?<=\.\d+)F', '');