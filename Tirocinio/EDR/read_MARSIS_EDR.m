function MarsisEdr = read_MARSIS_EDR( EdrFile, ParameterName, StartRecord, StopRecord, SkipRecords )

if     ~isempty( strfind( EdrFile, '_AIS_'         ) ) && ~isempty( strfind( EdrFile, '_F.DAT' ) ), [ RecordBytes, Parameter, OffsetBytes, OffsetBits, Items, Precision, OutputPrecision, MachineFormat, ItemBytes, ItemBits ] = MARSIS_E_AIS;
elseif ~isempty( strfind( EdrFile, '_CAL_'         ) ) && ~isempty( strfind( EdrFile, '_F.DAT' ) ), [ RecordBytes, Parameter, OffsetBytes, OffsetBits, Items, Precision, OutputPrecision, MachineFormat, ItemBytes, ItemBits ] = MARSIS_E_CAL;
elseif ~isempty( strfind( EdrFile, '_RXO_'         ) ) && ~isempty( strfind( EdrFile, '_F.DAT' ) ), [ RecordBytes, Parameter, OffsetBytes, OffsetBits, Items, Precision, OutputPrecision, MachineFormat, ItemBytes, ItemBits ] = MARSIS_E_RXO;
elseif ~isempty( strfind( EdrFile, '_SS1_ACQ_CMP_' ) ) && ~isempty( strfind( EdrFile, '_F.DAT' ) ), [ RecordBytes, Parameter, OffsetBytes, OffsetBits, Items, Precision, OutputPrecision, MachineFormat, ItemBytes, ItemBits ] = MARSIS_E_SS1_ACQ_CMP;
elseif ~isempty( strfind( EdrFile, '_SS1_TRK_CMP_' ) ) && ~isempty( strfind( EdrFile, '_F.DAT' ) ), [ RecordBytes, Parameter, OffsetBytes, OffsetBits, Items, Precision, OutputPrecision, MachineFormat, ItemBytes, ItemBits ] = MARSIS_E_SS1_TRK_CMP;
elseif ~isempty( strfind( EdrFile, '_SS2_ACQ_CMP_' ) ) && ~isempty( strfind( EdrFile, '_F.DAT' ) ), [ RecordBytes, Parameter, OffsetBytes, OffsetBits, Items, Precision, OutputPrecision, MachineFormat, ItemBytes, ItemBits ] = MARSIS_E_SS2_ACQ_CMP;
elseif ~isempty( strfind( EdrFile, '_SS2_TRK_CMP_' ) ) && ~isempty( strfind( EdrFile, '_F.DAT' ) ), [ RecordBytes, Parameter, OffsetBytes, OffsetBits, Items, Precision, OutputPrecision, MachineFormat, ItemBytes, ItemBits ] = MARSIS_E_SS2_TRK_CMP;
elseif ~isempty( strfind( EdrFile, '_SS3_ACQ_CMP_' ) ) && ~isempty( strfind( EdrFile, '_F.DAT' ) ), [ RecordBytes, Parameter, OffsetBytes, OffsetBits, Items, Precision, OutputPrecision, MachineFormat, ItemBytes, ItemBits ] = MARSIS_E_SS3_ACQ_CMP;
elseif ~isempty( strfind( EdrFile, '_SS3_TRK_CMP_' ) ) && ~isempty( strfind( EdrFile, '_F.DAT' ) ), [ RecordBytes, Parameter, OffsetBytes, OffsetBits, Items, Precision, OutputPrecision, MachineFormat, ItemBytes, ItemBits ] = MARSIS_E_SS3_TRK_CMP;
elseif ~isempty( strfind( EdrFile, '_SS3_TRK_RAW_' ) ) && ~isempty( strfind( EdrFile, '_F.DAT' ) ), [ RecordBytes, Parameter, OffsetBytes, OffsetBits, Items, Precision, OutputPrecision, MachineFormat, ItemBytes, ItemBits ] = MARSIS_E_SS3_TRK_RAW;
elseif ~isempty( strfind( EdrFile, '_SS4_ACQ_CMP_' ) ) && ~isempty( strfind( EdrFile, '_F.DAT' ) ), [ RecordBytes, Parameter, OffsetBytes, OffsetBits, Items, Precision, OutputPrecision, MachineFormat, ItemBytes, ItemBits ] = MARSIS_E_SS4_ACQ_CMP;
elseif ~isempty( strfind( EdrFile, '_SS4_TRK_CMP_' ) ) && ~isempty( strfind( EdrFile, '_F.DAT' ) ), [ RecordBytes, Parameter, OffsetBytes, OffsetBits, Items, Precision, OutputPrecision, MachineFormat, ItemBytes, ItemBits ] = MARSIS_E_SS4_TRK_CMP;
elseif ~isempty( strfind( EdrFile, '_SS5_ACQ_CMP_' ) ) && ~isempty( strfind( EdrFile, '_F.DAT' ) ), [ RecordBytes, Parameter, OffsetBytes, OffsetBits, Items, Precision, OutputPrecision, MachineFormat, ItemBytes, ItemBits ] = MARSIS_E_SS5_ACQ_CMP;
elseif ~isempty( strfind( EdrFile, '_SS5_TRK_CMP_' ) ) && ~isempty( strfind( EdrFile, '_F.DAT' ) ), [ RecordBytes, Parameter, OffsetBytes, OffsetBits, Items, Precision, OutputPrecision, MachineFormat, ItemBytes, ItemBits ] = MARSIS_E_SS5_TRK_CMP;
elseif                                                    ~isempty( strfind( EdrFile, '_G.DAT' ) ), [ RecordBytes, Parameter, OffsetBytes, OffsetBits, Items, Precision, OutputPrecision, MachineFormat, ItemBytes, ItemBits ] = MARSIS_E_GEO;
else   error( 'read_MARSIS_EDR:FileTypeUnknown', 'File %s does not follow standard naming conventions, file type could not be determined.', EdrFile )
end

% The data product file is opened.
fid = fopen( EdrFile, 'r' );

if fid < 0
    error( 'read_MARSIS_EDR:MissingInputFile', ...
           'The required data product file %s could not be opened.', ...
            EdrFile )
end

% The length in bytes of the data product file is retrieved, and divided by
% the length of a file record in bytes to obtain the number of records in
% the file.

fseek( fid, 0, 'eof' );
FileBytes = ftell( fid );
FileRecords = FileBytes / RecordBytes;

if round( FileRecords ) ~= FileRecords
    fclose( fid );
    error( 'read_MARSIS_EDR:FractionalNumberOfRecords', ...
           'The data product file %s contains %f records, a non integer number of records.', ...
            EdrFile, FileRecords )
end

% If the only input argument is the name of a data product file, the
% function returns the number of records contained in that file.
if nargin == 1
    MarsisEdr = FileRecords;
    fclose( fid );
    return
end


% The name of the parameter to be extracted from the data product file is
% compared to the list of parameters in the data product, to determine its
% position in the list.
ParameterIndex = strcmp( Parameter, ParameterName );
ParameterIndex = find( ParameterIndex == 1 );

if isempty( ParameterIndex )
    fclose( fid );
    error( 'read_MARSIS_EDR:ParameterNotFound', ...
           'The parameter %s is not listed among those contained in a MARSIS RDR FRM data product.', ...
            ParameterName )
end

% If input values are not provided, default values are assigned to
% StartRecord, StopRecord and SkipRecords
if nargin < 3
    StartRecord = 1;
end

if nargin < 4
    StopRecord  = FileRecords;
end

if nargin < 5
    SkipRecords = 1;
end

% StartRecord, StopRecord and SkipRecords are checked for consistency.
if StartRecord < 1 || StartRecord > FileRecords
    fclose( fid );
    error( 'read_MARSIS_EDR:InvalidValueForStartRecord', ...
           'The first record to be extracted is record %g, which is outside the valid interval [ 1, %g ].', ...
            StartRecord, FileRecords )
end

if StopRecord  < 1 || StopRecord  > FileRecords
    fclose( fid );
    error( 'read_MARSIS_EDR:InvalidValueForStopRecord', ...
           'The last record to be extracted is record %g, which is outside the valid interval [ 1, %g ].', ...
            StopRecord, FileRecords )
end

if SkipRecords < 1 || SkipRecords > FileRecords
    fclose( fid );
    error( 'read_MARSIS_EDR:InvalidValueForSkipRecords', ...
           'The number of records to be skipped is %g, which is outside the valid interval [ 1, %g ].', ...
            SkipRecords, FileRecords )
end

if StopRecord  < StartRecord
    fclose( fid );
    error( 'read_MARSIS_EDR:StopRecordBeforeStartRecord', ...
           'The first record to be extracted is record %g and is greater than last record to be extracted, which is record %g.', ...
            StartRecord, StopRecord )
end

% the number of records to be extracted fromn the data product file is
% determined.
Records = length( StartRecord : SkipRecords : StopRecord );

if Records == 0
    fclose( fid );
    error( 'read_MARSIS_EDR:NoRecordsExtracted', ...
           'The combination of StartRecord = %g, StopRecord = %g, SkipRecords = %g does not allow the extraction of records from this data product file.', ...
            StartRecord, StopRecord, SkipRecords )
end

% The requested parameter is extracted from the data product file.

offset = ( StartRecord - 1 ) * RecordBytes + OffsetBytes( ParameterIndex );
fseek( fid, offset, 'bof' );

pad = fread( fid, OffsetBits( ParameterIndex ), 'ubit1', MachineFormat{ ParameterIndex } );

size          = [ Items( ParameterIndex ), Records ];
precision     = [ int2str( Items( ParameterIndex ) ), '*', Precision{ ParameterIndex }, '=>', OutputPrecision{ ParameterIndex } ];

if     ( ItemBytes( ParameterIndex ) >= 1 ) && ( ItemBits( ParameterIndex ) == 0 )
    skip      = ( SkipRecords - 1 ) * RecordBytes     + RecordBytes      - Items( ParameterIndex ) * ItemBytes( ParameterIndex );
elseif ( ItemBytes( ParameterIndex ) == 0 ) && ( ItemBits( ParameterIndex ) >= 1 )
    skip      = ( SkipRecords - 1 ) * RecordBytes * 8 + RecordBytes * 8  - Items( ParameterIndex ) *  ItemBits( ParameterIndex );
else
    error( 'read_MARSIS_EDR:WrongParameterFormat', ...
           'The parameter %s is described as being %g bytes long and %g bits long.', ...
            Parameter{ ParameterIndex }, ItemBytes( ParameterIndex ), ItemBits( ParameterIndex ) )
end

machineformat = MachineFormat{ ParameterIndex };

MarsisEdr = fread( fid, size, precision, skip, machineformat );

fclose( fid );
