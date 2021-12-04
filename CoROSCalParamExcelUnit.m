classdef CoROSCalParamExcelUnit < handle
% This class defines a calibration parameter unit block in Excel and corresponding operations

    properties
        % Properties of Excel COM server objects
        Sheet % Parent sheet of Excel
        
        % Properties of current active calbration item
        Name = '' % string of active calibration name
        NameRange % Excel Range object where calibration name located
        FullDataRange % Excel Range object of full calibration data block
        FullDataValue % Numeric value of full data
        SelectedDataRange % Excel Range object of selected data range
        SelectedDataValue % Numeric value of data selected
        
        % Properties of calibration parameter info
        Dimension
        OriginalData
        DataType

    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        function obj = CoROSCalParamExcelUnit(tgtrng)
            obj.Sheet = tgtrng.Parent;
            % analyze selection and determine other properties
            val = tgtrng.Value;
            if ischar(val) % if select name cell
                obj.Name = val;
                obj.NameRange = tgtrng;
                obj.LocateFullDataBlock;
                obj.SelectedDataValue = obj.FullDataValue;
                obj.SelectedDataRange = obj.FullDataRange;
            else
                cell_tl = [tgtrng.Row, tgtrng.Column];
                b_name_located = obj.LocateName(cell_tl);
                if ~b_name_located
                    fprintf(2, '#CoROS# Error: Cannot locate a valid name cell with current selection, check Excel selection\n');
                    return;
                else
                    obj.LocateFullDataBlock;
                end
                if iscell(val) %if multiple cells
                    try
                        dataval = cell2mat(val);
                    catch
                        fprintf(2, '#CoROS# Error: Invalid cell(s) selected in Excel, should be consecutive numeric value\n');
                        return;
                    end
                elseif isnumeric(val) && ~isnan(val) % if target cell is one single number, trace back to locate its name
                    dataval = val;
                else
                    fprintf(2, '#CoROS# Error: Invalid cell(s) selected in Excel\n');
                    return;
                end
                obj.SelectedDataRange = tgtrng;
                obj.SelectedDataValue = dataval;
            end
        end
        
        
        % FUNCTION @LocateName
        % starting from current selection ([irow, jcol]), trace upwards and leftwards to a calibratin name cell
        function success = LocateName(obj, start_tl)
            irow = start_tl(1);
            jcol = start_tl(2);
            thisrng = obj.Sheet.Range(excelrc2addr([irow, jcol]));
            while isValidDataCell(thisrng) && (jcol>1) %leftwards
                jcol = jcol-1;
                thisrng = obj.Sheet.Range(excelrc2addr([irow, jcol]));
            end
            jcol = jcol+1;
            while ~ischar(thisrng.Value) && (irow > 1)
                irow = irow - 1;
                thisrng = obj.Sheet.Range(excelrc2addr([irow, jcol]));
            end
            val = thisrng.Value;
            if ischar(val)
                obj.Name = val;
                obj.NameRange = thisrng;
                success = true;
            else
                obj.Name = '';
                obj.NameRange = [];
                success = false;
            end
        end
        
        % locate calibration data block, starting from name (search down/right until no valid numeric block)
        function success = LocateFullDataBlock(obj)
            if isempty(obj.Name)
                success = false;
                return;
            end
            inamerow = obj.NameRange.Row;
            inamecol = obj.NameRange.Column;
            irow = inamerow+1;
            jcol = inamecol;
            thisrng = obj.Sheet.Range(excelrc2addr([irow, jcol]));
            if ~isValidDataCell(thisrng) % if the cell right under the name cell is empty, suppose no valid block exists, switch 'Raw Size' mode
                obj.FullDataValue = [];
                obj.FullDataRange = [];
                return;
            end
            while isValidDataCell(thisrng) %downwards
                irow = irow+1;
                thisrng = obj.Sheet.Range(excelrc2addr([irow, jcol]));
            end
            irow = irow-1; % reverse back to valid data cell
            thisrng = obj.Sheet.Range(excelrc2addr([irow, jcol]));
            while isValidDataCell(thisrng) %rightwards
                jcol = jcol+1;
                thisrng = obj.Sheet.Range(excelrc2addr([irow, jcol]));
            end
            jcol = jcol-1;
            obj.FullDataRange = obj.Sheet.Range(excelrc2addr([inamerow+1, inamecol],[irow, jcol]));
            dbrngval = obj.FullDataRange.Value;
            if iscell(dbrngval)
                obj.FullDataValue = cell2mat(dbrngval);
            else
                obj.FullDataValue = dbrngval;
            end
            success = true;
        end
        
        function ClearData(obj)
            obj.FullDataRange = []; % Excel Range object of full calibration data block
            obj.FullDataValue = []; % Numeric value of full data
            obj.SelectedDataRange = []; % Excel Range object of selected data range
            obj.SelectedDataValue = []; % Numeric value of data selected
            obj.Dimension  = [];
            obj.OriginalData  = [];
            obj.DataType  = '';
        end
        
        %
        function rng = getFullDataRange(obj)
            if isempty(obj.FullDataRange) % select range according to raw value (raw properties must be updated using UpdateRawValue)
                inamerow = obj.NameRange.Row;
                inamecol = obj.NameRange.Column;
                rng = obj.Sheet.Range(excelrc2addr([inamerow+1,inamecol],[inamerow+obj.Dimension(1), inamecol+obj.Dimension(2)-1]));
            else
                rng = obj.FullDataRange;
            end
        end
        
        function setFullValue(obj, value)
            rng = obj.getFullDataRange;
            rng.Value = value;
            obj.FullDataValue = value;
        end
        
        %-------------------------------------------------------------
        function tf = isValidJSONItem(obj, jsoncaltable)
            paraitem = jsoncaltable(strcmp({jsoncaltable.Name}', obj.Name));
            if isempty(paraitem)
                tf = false;
            else
                tf = true;
                obj.UpdateRawValue(paraitem);
            end
        end


        %-------------------------------------------------------------
        function UpdateRawValue(obj, jsonitem)
            % Copy raw data info (intepreted from json file)
            obj.Dimension = jsonitem.Dimension';
            obj.OriginalData = reshape(jsonitem.Value, obj.Dimension);
            obj.DataType = jsonitem.DataType;
        end
        
        %-------------------------------------------------------------
        function RefreshColor(obj)
            if isempty(obj.OriginalData)
                return;
            end
            if ~all(obj.Dimension==size(obj.FullDataValue))
                fprintf(2, 'The size of data block in Excel is inconsistent with the raw data\n');
                return;
            end
            ij_offset = [obj.NameRange.Row, obj.NameRange.Column-1];
            % Increased
            bmat_inc = obj.OriginalData < obj.FullDataValue - 0.000001; % logical index of increased element in matrix
            ClusterAndSetColor(bmat_inc, ij_offset, 255); %set red (255)
            bmat_dec = obj.OriginalData > obj.FullDataValue + 0.000001; % logical index of decreased element in matrix
            ClusterAndSetColor(bmat_dec, ij_offset, 12611584); %set light blue (12611584)
            bmat_equal = abs(obj.OriginalData - obj.FullDataValue)<eps;
            ClusterAndSetColor(bmat_equal, ij_offset, 0); % set default black
            
            function ClusterAndSetColor(bmat, ij_offset, colorcode)
                % cluster adjoining elements and create address range address string.
                
                % ij_offset: offset of data block (1,1) -> (1,1)+ij_offset in excel
                addrstrcell = {};
                sz = size(bmat);
                while any(bmat, 'all')
                    % cluster adjoining elements
                    [tl(1), tl(2)] = ind2sub(sz, find(bmat, 1, 'first')); %top-left subindex
                    i = tl(1); j = tl(2);
                    while bmat(tl(1), j) && j<sz(2)% rightwards
                        j = j+1;
                    end
                    while all(bmat(i, tl(2):j-1)) && i<sz(1) %downwards
                        i = i+1;
                    end
                    if j==sz(2)
                        jbound = sz(2);
                    else
                        jbound = j-1;
                    end
                    if i==sz(1)
                        ibound = sz(1);
                    else
                        ibound = i-1;
                    end
                    br = [ibound, jbound];
                    addrstrcell = [addrstrcell; excelrc2addr(tl+ij_offset, br+ij_offset)]; % store result
                    bmat(tl(1):br(1), tl(2):br(2)) = false; % set false and proceed next iteration
                end
                % Excel COM .Range(addr) property appears to fail if address string contains too many comma seperated fields
                for i=1:10:numel(addrstrcell)
                    addrstr = sprintf('%s,', addrstrcell{i:min(i+9,end)});
                    addrstr(end)='';
                    obj.Sheet.Range(addrstr).Font.Color = colorcode;
                end
            end
        end
        
        
        % FUNCTION @getSelectedSubIndex
        %Get subindex of current selection, left/right/top/bottom in data matrix, ZERO based
        function lrtb = getSelectedSubIndex(obj)
            if ~isempty(obj.Name)
                [nrow, ncol] = size(obj.SelectedDataValue);
                namerow = obj.NameRange.Row;
                namecol = obj.NameRange.Column;
                db_row = obj.SelectedDataRange.Row; %selection data block row
                db_col = obj.SelectedDataRange.Column; %selection data block column
                lrtb = [db_col-namecol, db_col-namecol+ncol-1, db_row-namerow-1, db_row-namerow-1+nrow-1];
            end
        end
        % FUNCTION @getDataBlockIndex
        %Get full data block index, left/right/top/bottom in data matrix, ZERO based
        function lrtb = getDataBlockIndex(obj)
            if ~isempty(obj.Name)
                sz = size(obj.FullDataValue);
                lrtb = [0, sz(2)-1, 0, sz(1)-1];
            end
        end
        
        % Insert enough rows to make space for data block
        function makeRoom(obj, nrow)
            if nargin<2 && ~isempty(obj.Dimension)
                nrow = obj.Dimension(1);
            end
            if isempty(obj.FullDataRange) && ~isempty(obj.NameRange)
                for i = 1:nrow
                    obj.NameRange.Offset.Item(2).EntireRow.Insert;
                end
            end
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
function tf = isValidDataCell(rng)
val = rng.Value;
tf = isnumeric(val) && ~isnan(val);
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





