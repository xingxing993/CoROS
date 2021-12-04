classdef CoROSExcelInterface < handle
    
    properties
        % Properties of Excel COM server objects
        ExcelApp % COM Handle of excel application
        Workbook % Current workbook in Excel
        JSON % Table that describes properties of all calibration parameters, imported from JSON
        ActiveCalParams
        CurrentActiveIndex = 1; % The current active calibration parameter under processing

    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        function obj = CoROSExcelInterface(wbk, json)
            obj.ExcelApp = wbk.Parent;
            obj.Workbook = wbk;
            obj.JSON = json;
            %obj.ActiveCalParam
        end
        
        %---------------------------------------------------
        function JSONtoCalSheet(obj)
            sht = obj.Workbook.Sheets.Add;
            sht.Cells.Font.Name = 'Arial';
            sht.Range('A1:B1').Value = {'Model:' obj.JSON.ModelName};
            sht.Range('A2:B2').Value = {'Version:',obj.JSON.TimeVersion};
            irow = 4;
            for i=1:numel(obj.JSON.ParameterTable)
                paraitem = obj.JSON.ParameterTable(i);
                rng = sht.Range(excelrc2addr([irow, 1])); rng.Value = paraitem.DataID;
                rng = sht.Range(excelrc2addr([irow, 2])); rng.Value = paraitem.Name;
                rng.Font.Bold = true;
                rng = sht.Range(excelrc2addr([irow+1, 2], [irow+paraitem.Dimension(1), paraitem.Dimension(2)+1]));
                rng.Value = reshape(paraitem.Value, paraitem.Dimension');
                irow = irow + paraitem.Dimension(1) + 2;
            end
        end

        %----------------------------------------------------
        % splits current selection uopn differnt context, and return cell{} of Range-s
        function arbitrateCurrentSelection(obj)
            if isempty(obj.Workbook)
                errordlg('Make sure connect an active Excel file first');
                return;
            end
            name_cur_seltn_wbk = obj.Workbook.Parent.Selection.Parent.Parent.Name; % Name of the workbook where current selection in
            if ~strcmp(name_cur_seltn_wbk, obj.Workbook.Name)
                errordlg('Make sure the connected Excel file is current actively selected');
                return;
            end
            addrstr = obj.ExcelApp.Selection.Address;
            ccnt = obj.ExcelApp.Selection.Columns.Count;
            sht = obj.Workbook.Activesheet;
            if (ccnt < 2000) && (obj.ExcelApp.Selection.Count == 1) %if only one cell selected
                rngs = {obj.ExcelApp.Selection};
            elseif contains(addrstr, ',') % multiple discrete ranges selected
                addrs = regexp(addrstr, ',', 'split');
                rngs = cellfun(@(addr)sht.Range(addr), addrs, 'UniformOutput', false);
            else % selected should be a big monoblock of cells
                if ccnt > 2000 % Entire sheet selected
                    selrng = sht.UsedRange;
                else
                    selrng = obj.ExcelApp.Selection;
                end
                rngvals = selrng.Value;
                b_isnumericblock = all(cellfun(@(s)isnumeric(s)&&~isnan(s), rngvals));
                if b_isnumericblock % if selected a block of numeric data, should be part of one single calibration parameter
                    rngs = {selrng};
                else
                    b_varnamelikecells = cellfun(@(s)ischar(s)&&isvarname(s), rngvals); % find all cells containing string and is varaiable name like
                    nr_sel = selrng.Rows.Count; % number of selected row
                    nc_sel = selrng.Columns.Count; % number of selected column
                    r0_sel = selrng.Item(1).Row; % top cell row
                    c0_sel = selrng.Item(1).Column; % left cell column
                    [ir, ic] = ind2sub([nr_sel, nc_sel], find(b_varnamelikecells)); % rows of [i, j] index of variable name like cell
                    rngs = cell(numel(ir), 1);
                    for i=1:numel(ir)
                        rngs{i} = sht.Range(excelrc2addr([ir(i), ic(i)] + [r0_sel-1, c0_sel-1]));
                    end
                end
            end
            % create CoROSCalParamExcelUnit objects
            obj.ActiveCalParams = [];
            for i=1:numel(rngs)
                tmpcpobj = CoROSCalParamExcelUnit(rngs{i});
                if tmpcpobj.isValidJSONItem(obj.JSON.ParameterTable) % only those whose name matches in JSON are taken as valid calibration parameter
                    obj.ActiveCalParams = [obj.ActiveCalParams; tmpcpobj];
                end
            end
        end
        
        function calparaunit = getCurrentCalParam(obj)
            calparaunit = obj.ActiveCalParams(obj.CurrentActiveIndex);
        end
    end
end




%------------------------------------------------------------------------------
function addrstr = excelrc2addr(tl, br)
% Convert numeric corrdinate to string of alphabet range expression of excel
% Numeric expression input could be one cell coordinate (Top-Left) or two cell
% coorodinates (Top-Left, Bottom-Right)
if nargin<2
    br=tl;
end
addrstr = [dec2base27(tl(2)), int2str(tl(1))];
if nargin>1
    br_exp = [dec2base27(br(2)), int2str(br(1))]; %string expression of bottom-right cell
    addrstr = [addrstr,':',br_exp];
end
end


%------------------------------------------------------------------------------
function s = dec2base27(d)

%   DEC2BASE27(D) returns the representation of D as a string in base 27,
%   expressed as 'A'..'Z', 'AA','AB'...'AZ', and so on. Note, there is no zero
%   digit, so strictly we have hybrid base26, base27 number system.  D must be a
%   negative integer bigger than 0 and smaller than 2^52.
%
%   Examples
%       dec2base(1) returns 'A'
%       dec2base(26) returns 'Z'
%       dec2base(27) returns 'AA'
%-----------------------------------------------------------------------------

d = d(:);
if d ~= floor(d) || any(d(:) < 0) || any(d(:) > 1/eps)
    error('MATLAB:xlswrite:Dec2BaseInput',...
        'D must be an integer, 0 <= D <= 2^52.');
end
[num_digits, begin] = calculate_range(d);
s = index_to_string(d, begin, num_digits);
% Supportive functions
    function string = index_to_string(index, first_in_range, digits)
        
        letters = 'A':'Z';
        working_index = index - first_in_range;
        outputs = cell(1,digits);
        [outputs{1:digits}] = ind2sub(repmat(26,1,digits), working_index);
        string = fliplr(letters([outputs{:}]));
    end
%----------------------------------------------------------------------
    function [digits, first_in_range] = calculate_range(num_to_convert)
        
        digits = 1;
        first_in_range = 0;
        current_sum = 26;
        while num_to_convert > current_sum
            digits = digits + 1;
            first_in_range = current_sum;
            current_sum = first_in_range + 26.^digits;
        end
    end
end





