function postcode_process(buildInfo)
% buildInfo - build information for my model.


% TODO:
% Compatible with variable spaces other than Data Dictionary
% Compatible with storage classes other than Simulink.Parameter
% Use more intrinsic way rather than PostCodeGenCommand to generate the mapping table


fprintf('# POST CODE GEN - REMOVE "_main.cpp" FILES\n');
mainfileidx = contains({buildInfo.Src.Files.FileName}', '_main.c');
buildInfo.Src.Files(mainfileidx) = [];



% Analyze generated code.
fprintf('# POST CODE GEN - FINISHED\n');

