function [ RecordBytes, Parameter, OffsetBytes, OffsetBits, Items, Precision, OutputPrecision, MachineFormat, ItemBytes, ItemBits ] = MARSIS_E_GEO

RecordBytes = 215;

Parameter       = cell( 19, 1 );
Precision       = cell( 19, 1 );
OutputPrecision = cell( 19, 1 );
MachineFormat   = cell( 19, 1 );

Parameter{ 01 } =          'SCET_FRAME_WHOLE'; OffsetBytes( 01 ) = 000; OffsetBits( 01 ) = 0; Items( 01 ) = 01; Precision{ 01 } =  'uint32'; OutputPrecision{ 01 } =  'uint32'; MachineFormat{ 01 } = 'ieee-be'; ItemBytes( 01 ) = 4; ItemBits( 01 ) = 0;
Parameter{ 02 } =           'SCET_FRAME_FRAC'; OffsetBytes( 02 ) = 004; OffsetBits( 02 ) = 0; Items( 02 ) = 01; Precision{ 02 } =  'uint16'; OutputPrecision{ 02 } =  'uint16'; MachineFormat{ 02 } = 'ieee-be'; ItemBytes( 02 ) = 2; ItemBits( 02 ) = 0;
Parameter{ 03 } =   'GEOMETRY_EPHEMERIS_TIME'; OffsetBytes( 03 ) = 006; OffsetBits( 03 ) = 0; Items( 03 ) = 01; Precision{ 03 } = 'float64'; OutputPrecision{ 03 } = 'float64'; MachineFormat{ 03 } = 'ieee-be'; ItemBytes( 03 ) = 8; ItemBits( 03 ) = 0;
Parameter{ 04 } =            'GEOMETRY_EPOCH'; OffsetBytes( 04 ) = 014; OffsetBits( 04 ) = 0; Items( 04 ) = 23; Precision{ 04 } =    'char'; OutputPrecision{ 04 } =    'char'; MachineFormat{ 04 } = 'ieee-be'; ItemBytes( 04 ) = 1; ItemBits( 04 ) = 0;
Parameter{ 05 } =      'MARS_SOLAR_LONGITUDE'; OffsetBytes( 05 ) = 037; OffsetBits( 05 ) = 0; Items( 05 ) = 01; Precision{ 05 } = 'float64'; OutputPrecision{ 05 } = 'float64'; MachineFormat{ 05 } = 'ieee-be'; ItemBytes( 05 ) = 8; ItemBits( 05 ) = 0;
Parameter{ 06 } =         'MARS_SUN_DISTANCE'; OffsetBytes( 06 ) = 045; OffsetBits( 06 ) = 0; Items( 06 ) = 01; Precision{ 06 } = 'float64'; OutputPrecision{ 06 } = 'float64'; MachineFormat{ 06 } = 'ieee-be'; ItemBytes( 06 ) = 8; ItemBits( 06 ) = 0;
Parameter{ 07 } =              'ORBIT_NUMBER'; OffsetBytes( 07 ) = 053; OffsetBits( 07 ) = 0; Items( 07 ) = 01; Precision{ 07 } =  'uint32'; OutputPrecision{ 07 } =  'uint32'; MachineFormat{ 07 } = 'ieee-be'; ItemBytes( 07 ) = 4; ItemBits( 07 ) = 0;
Parameter{ 08 } =               'TARGET_NAME'; OffsetBytes( 08 ) = 057; OffsetBits( 08 ) = 0; Items( 08 ) = 06; Precision{ 08 } =    'char'; OutputPrecision{ 08 } =    'char'; MachineFormat{ 08 } = 'ieee-be'; ItemBytes( 08 ) = 1; ItemBits( 08 ) = 0;
Parameter{ 09 } = 'TARGET_SC_POSITION_VECTOR'; OffsetBytes( 09 ) = 063; OffsetBits( 09 ) = 0; Items( 09 ) = 03; Precision{ 09 } = 'float64'; OutputPrecision{ 09 } = 'float64'; MachineFormat{ 09 } = 'ieee-be'; ItemBytes( 09 ) = 8; ItemBits( 09 ) = 0;
Parameter{ 10 } =       'SPACECRAFT_ALTITUDE'; OffsetBytes( 10 ) = 087; OffsetBits( 10 ) = 0; Items( 10 ) = 01; Precision{ 10 } = 'float64'; OutputPrecision{ 10 } = 'float64'; MachineFormat{ 10 } = 'ieee-be'; ItemBytes( 10 ) = 8; ItemBits( 10 ) = 0;
Parameter{ 11 } =          'SUB_SC_LONGITUDE'; OffsetBytes( 11 ) = 095; OffsetBits( 11 ) = 0; Items( 11 ) = 01; Precision{ 11 } = 'float64'; OutputPrecision{ 11 } = 'float64'; MachineFormat{ 11 } = 'ieee-be'; ItemBytes( 11 ) = 8; ItemBits( 11 ) = 0;
Parameter{ 12 } =           'SUB_SC_LATITUDE'; OffsetBytes( 12 ) = 103; OffsetBits( 12 ) = 0; Items( 12 ) = 01; Precision{ 12 } = 'float64'; OutputPrecision{ 12 } = 'float64'; MachineFormat{ 12 } = 'ieee-be'; ItemBytes( 12 ) = 8; ItemBits( 12 ) = 0;
Parameter{ 13 } = 'TARGET_SC_VELOCITY_VECTOR'; OffsetBytes( 13 ) = 111; OffsetBits( 13 ) = 0; Items( 13 ) = 03; Precision{ 13 } = 'float64'; OutputPrecision{ 13 } = 'float64'; MachineFormat{ 13 } = 'ieee-be'; ItemBytes( 13 ) = 8; ItemBits( 13 ) = 0;
Parameter{ 14 } = 'TARGET_SC_RADIAL_VELOCITY'; OffsetBytes( 14 ) = 135; OffsetBits( 14 ) = 0; Items( 14 ) = 01; Precision{ 14 } = 'float64'; OutputPrecision{ 14 } = 'float64'; MachineFormat{ 14 } = 'ieee-be'; ItemBytes( 14 ) = 8; ItemBits( 14 ) = 0;
Parameter{ 15 } =   'TARGET_SC_TANG_VELOCITY'; OffsetBytes( 15 ) = 143; OffsetBits( 15 ) = 0; Items( 15 ) = 01; Precision{ 15 } = 'float64'; OutputPrecision{ 15 } = 'float64'; MachineFormat{ 15 } = 'ieee-be'; ItemBytes( 15 ) = 8; ItemBits( 15 ) = 0;
Parameter{ 16 } =     'LOCAL_TRUE_SOLAR_TIME'; OffsetBytes( 16 ) = 151; OffsetBits( 16 ) = 0; Items( 16 ) = 01; Precision{ 16 } = 'float64'; OutputPrecision{ 16 } = 'float64'; MachineFormat{ 16 } = 'ieee-be'; ItemBytes( 16 ) = 8; ItemBits( 16 ) = 0;
Parameter{ 17 } =        'SOLAR_ZENITH_ANGLE'; OffsetBytes( 17 ) = 159; OffsetBits( 17 ) = 0; Items( 17 ) = 01; Precision{ 17 } = 'float64'; OutputPrecision{ 17 } = 'float64'; MachineFormat{ 17 } = 'ieee-be'; ItemBytes( 17 ) = 8; ItemBits( 17 ) = 0;
Parameter{ 18 } =        'DIPOLE_UNIT_VECTOR'; OffsetBytes( 18 ) = 167; OffsetBits( 18 ) = 0; Items( 18 ) = 03; Precision{ 18 } = 'float64'; OutputPrecision{ 18 } = 'float64'; MachineFormat{ 18 } = 'ieee-be'; ItemBytes( 18 ) = 8; ItemBits( 18 ) = 0;
Parameter{ 19 } =      'MONOPOLE_UNIT_VECTOR'; OffsetBytes( 19 ) = 191; OffsetBits( 19 ) = 0; Items( 19 ) = 03; Precision{ 19 } = 'float64'; OutputPrecision{ 19 } = 'float64'; MachineFormat{ 19 } = 'ieee-be'; ItemBytes( 19 ) = 8; ItemBits( 19 ) = 0;
