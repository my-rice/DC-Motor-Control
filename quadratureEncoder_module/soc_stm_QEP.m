classdef soc_stm_QEP < realtime.internal.SourceSampleTime ...
		& coder.ExternalDependency %...
% 		& matlab.system.mixin.Propagates ...
% 		& matlab.system.mixin.CustomIcon
	
	% SOC_STM_QEP Quadrature Encoder for STM32 Nucleo
    %
	% Configures Timer of STM32 Nucleo-F767ZI, Nucleo-F401RE
    % and Nucleo-F411RE hardware in encoder mode 3 to
	% decode and count quadrature encoded pulses applied on following input pins:
    %
    % STM Nucleo-F767ZI Board
    %       TIM3 = Encoder timer (internal)
    %       PB_4 = Encoder A
    %       PB_5 = Encoder B and 
    %       PA_4 = Encoder Index.
    % 
    % STM Nucleo-F401RE and STM Nucleo-F411RE Board
    %       TIM1 = Encoder timer (internal)
    %       PA_8 = Encoder A
    %       PA_9 = Encoder B and 
    %       PA_4 = Encoder Index.
    % 
    % The output EncoderCount is pulse count when a pulse signal comes from an optical
	% encoder mounted on a rotating machine, IndexCount is last encoder count
	% when an index pulse is received and ValidIndex is high after reciveing
	% the first index pulse.
	
	% Copyright 2019-2021 The MathWorks, Inc.
	%#codegen
	%#ok<*EMCA>
	
	properties
		% Public, tunable properties.
	end
	
	properties (Nontunable)
		% Public, non-tunable properties.
	end
	
	properties (Access = private)
		% Pre-computed constants.
	end
	
	methods
		% Constructor
		function obj = soc_stm_QEP(varargin)
			setProperties(obj,nargin,varargin{:});
		end
	end
	
	methods (Access=protected)
		function setupImpl(~)
			if isempty(coder.target)
				% Place simulation setup code here
			else
				% Call C-function implementing device initialization
				coder.cinclude('soc_stm_encoder.h');
				coder.ceval('initEncoder');
			end
		end
		
		function [EncoderCount,IndexCount,ValidIndex] = stepImpl(~)
			EncoderCount = uint16(0);
			IndexCount = uint16(0);
			ValidIndex = uint16(0);
			if isempty(coder.target)
				% Place simulation output code here
			else
				% Call C-function implementing device output
				EncoderCount = coder.ceval('getEncoderCount');
				ValidIndex = coder.ceval('getIndexCount',coder.wref(IndexCount));
			end
		end
		
		function releaseImpl(~)
			if isempty(coder.target)
				% Place simulation termination code here
			else
				% Call C-function implementing device termination
				coder.ceval('releaseEncoder');
			end
		end
	end
	
	methods (Access=protected)
		%% Define output properties
		function num = getNumInputsImpl(~)
			num = 0;
		end
		
		function num = getNumOutputsImpl(~)
			num = 3;
		end
		
		function flag = isOutputSizeLockedImpl(~,~)
			flag = true;
		end
		
		function varargout = isOutputFixedSizeImpl(~,~)
			varargout{1} = true;
			varargout{2} = true;
			varargout{3} = true;
		end
		
% 		function flag = isOutputComplexityLockedImpl(~,~)
% 			flag = true;
% 		end
		
		function varargout = isOutputComplexImpl(~)
			varargout{1} = false;
			varargout{2} = false;
			varargout{3} = false;
		end
		
		function varargout = getOutputSizeImpl(~)
			varargout{1} = [1,1];
			varargout{2} = [1,1];
			varargout{3} = [1,1];
		end
		
		function varargout = getOutputDataTypeImpl(~)
			varargout{1} = 'uint16';
			varargout{2} = 'uint16';
			varargout{3} = 'uint16';
		end
		
		function icon = getIconImpl(~)
			% Define a string as the icon for the System block in Simulink.
			icon = 'STM32 NUCLEO QEP';
		end
	end
	
	methods (Static, Access=protected)
		function simMode = getSimulateUsingImpl(~)
			simMode = 'Interpreted execution';
		end
		
		function isVisible = showSimulateUsingImpl
			isVisible = false;
		end
		
		function sts = getSampleTimeImpl(obj)
			if isequal(obj.SampleTime, -1) || isequal(obj.SampleTime, [-1, 0])
				sts = matlab.system.SampleTimeSpecification('Type', 'Inherited');
			elseif isequal(obj.SampleTime, [0, 1])
				sts = matlab.system.SampleTimeSpecification('Type', 'Fixed In Minor Step');
			else
				if numel(obj.SampleTime) == 1
					sampleTime = obj.SampleTime;
					offset = 0;
				else
					sampleTime = obj.SampleTime(1);
					offset = obj.SampleTime(2);
				end
				sts = matlab.system.SampleTimeSpecification('Type', 'Discrete', ...
					'SampleTime', sampleTime, 'Offset', offset);
			end
		end
    end
    
    methods(Static, Access=protected)
        function header = getHeaderImpl()
            header = matlab.system.display.Header(mfilename('class'),...
                'ShowSourceLink', false, ...
                'Title','SOC_STM_QEP', ...
                'Text', ['Quadrature Encoder for STM32 Nucleo.' newline newline ...
                'STM32 Nucleo-F767ZI, Nucleo-F401RE and Nucleo-F411RE hardware in encoder mode 3 to ' ...
                'decode and count quadrature encoded pulses applied on following input pins:' newline newline ...
                'STM Nucleo-F767ZI board' newline...
                '       PB_4 = Encoder A' newline ...
                '       PB_5 = Encoder B and' newline ...
                '       PA_4 = Encoder Index' newline newline ...
                'STM Nucleo-F401RE and STM Nucleo-F411RE boards' newline...
                '       PA_8 = Encoder A' newline ...
                '       PA_9 = Encoder B and' newline ...
                '       PA_4 = Encoder Index' newline newline ...
                'The output EncoderCount is pulse count when a pulse signal comes from an optical ' ...
                'encoder mounted on a rotating machine, IndexCount is last encoder count ' ...
                'when an index pulse is received and ValidIndex is high after reciveing ' ...
                'the first index pulse.']);
        end
    end
	
	methods (Static)
		function name = getDescriptiveName()
			name = 'STM32 NUCLEO QEP';
		end
		
		function b = isSupportedContext(context)
			b = context.isCodeGenTarget('rtw');
		end
		
		function updateBuildInfo(buildInfo, context)
			if context.isCodeGenTarget('rtw')
				% Update buildInfo
				srcDir = fullfile(fileparts(mfilename('fullpath')),'src');
				includeDir = fullfile(fileparts(mfilename('fullpath')),'include');
				addIncludePaths(buildInfo,includeDir);
				addSourceFiles(buildInfo,'soc_stm_encoder.cpp',srcDir);
			end
		end
	end
end

% LocalWords:  ZI
