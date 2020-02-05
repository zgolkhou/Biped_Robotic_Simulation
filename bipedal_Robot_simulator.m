function varargout = simulator(varargin)
% Biped simulator m-file for simulator.fig
% Uses: simulator.fig, animatef.m, simclosereq.m
% Olli Haavisto, 2004

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @simulator_OpeningFcn, ...
                   'gui_OutputFcn',  @simulator_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin & isstr(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before simulator is made visible.
function simulator_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to simulator (see VARARGIN)

% animation state stopped
set(handles.animation_axes, 'UserData', 0);
% slow down disabled
handles.slow = 1;
% timer object
handles.T = timer('TimerFcn', '%');
% initial sample time
handles.st = 0.01;
% converted data for animation
handles.converteddata = [];

% Choose default command line output for simulator
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = simulator_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in simbutton.
function simbutton_Callback(hObject, eventdata, handles)
% hObject    handle to simbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% evaluate biped parameter m-file
s = get(handles.bipedparamedit, 'String');
if length(s)>2
    if strcmp(s([end-1, end]), '.m')
        s = s(1:end-2);
    end;
end;
eval(s);

% evaluate additional parameters m-file
s = get(handles.additionalparamedit, 'String');
if length(s)>2
    if strcmp(s([end-1, end]), '.m')
        s = s(1:end-2);
    end;
end;
eval(s);

% disable all controls
set(gcf, 'Pointer', 'watch');
set(handles.simmodeledit, 'Enable', 'off');
set(handles.bipedparamedit, 'Enable', 'off');
set(handles.additionalparamedit, 'Enable', 'off');
set(handles.playbutton, 'Enable', 'off');
set(handles.pausebutton, 'Enable', 'off');
set(handles.stopbutton, 'Enable', 'off');
set(handles.animationslider, 'Enable', 'off');
set(handles.simtime, 'Enable', 'off');
set(handles.slowmenu, 'Enable', 'off');
set(handles.animationtime, 'Enable', 'off');
set(handles.simbutton, 'Enable', 'off');
set(handles.savebutton, 'Enable', 'off');
set(handles.loadbutton, 'Enable', 'off');
set(handles.savestatebutton, 'Enable', 'off');

% get the simulation file name
s = get(handles.simmodeledit, 'String');
if length(s)>4
    if strcmp(s([end-3: end]), '.mdl')
        s = s(1:end-4);
    end;
end;

simoptions = simset('SrcWorkspace', 'current');

tic;

%%% simulate the model %%%
sim(s, str2double(get(handles.simtime,'String')), simoptions);
%%%%%%%%%%%%%%%%%%%%%%%%%%

toc;

% get the simulation data
handles.data.state = qout;
handles.data.control = uout;
handles.gcstate = gcstateout;
handles.robot = eval(get_param([s, '/Biped model'], 'robot'));
handles.groundp = eval(get_param([s, '/Biped model'], 'groundp'));
handles.st = eval(get_param([s, '/Biped model'], 'st'));

% Update handles structure
guidata(hObject, handles);
% update playback
update_playback(handles);

set(handles.loadbutton, 'Enable', 'on');
set(handles.savestatebutton, 'Enable', 'on');

% done
beep;


function update_playback(handles)
% Updates playback buttons, simulation time, animation slider and
% draws the initial position.

% animation length
n = size(handles.data.state,1);

% update playbutton
set(handles.playbutton, 'Enable', 'on');
% update slider
set(handles.animationslider, 'Min', 0);
set(handles.animationslider, 'Max', (n-1)*handles.st);
set(handles.animationslider, 'SliderStep',...
    [handles.st,10*handles.st]/(n*handles.st));
set(handles.animationslider, 'Value', 0);
set(handles.animationslider, 'Enable', 'on');
% update time
s=['0.00/', num2str(get(handles.animationslider, 'Max'), '%.2f')];
set(handles.animationtime, 'String', s);
set(handles.animationtime, 'Enable', 'on');

% enable controls
set(handles.simtime, 'Enable', 'on');
set(handles.slowmenu, 'Enable', 'on');

set(handles.simmodeledit, 'Enable', 'on');
set(handles.bipedparamedit, 'Enable', 'on');
set(handles.additionalparamedit, 'Enable', 'on');
set(handles.simbutton, 'Enable', 'on');
set(handles.savebutton, 'Enable', 'on');
set(handles.figure1, 'Pointer', 'arrow');

handles.converteddata = [];

% update picture
set(handles.animation_axes, 'UserData', 3);
handles.converteddata = animatef(handles);
set(handles.animation_axes, 'UserData', 0);

% Update handles structure
guidata(handles.figure1, handles);

% --- Executes during object creation, after setting all properties.
function simtime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to simtime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

function simtime_Callback(hObject, eventdata, handles)
% hObject    handle to simtime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes on button press in playbutton.
function playbutton_Callback(hObject, eventdata, handles)
% hObject    handle to playbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% get slow down value
contents = get(handles.slowmenu,'String');
switch contents{get(handles.slowmenu,'Value')}
    case 'x 2'
        handles.slow=2;
    case 'x 5'
        handles.slow=5;
    case 'x 10'
        handles.slow=10;
    otherwise
        handles.slow=1;
end;

% Update handles structure
guidata(gcbo, handles);

% start new animation
set(handles.slowmenu, 'Enable', 'off');
set(handles.playbutton, 'Enable', 'off');
set(handles.stopbutton, 'Enable', 'on');
set(handles.pausebutton, 'Enable', 'on');
set(handles.simbutton, 'Enable', 'off');
handles.converteddata = animatef(handles);

% Update handles structure
guidata(hObject, handles);

% animation stopped or paused
set(handles.slowmenu, 'Enable', 'on');
set(handles.simbutton, 'Enable', 'on');

if get(handles.animation_axes, 'UserData')==0
    % stopped
    set(handles.playbutton, 'Enable', 'on');
    set(handles.stopbutton, 'Enable', 'off');
    set(handles.pausebutton, 'Enable', 'off');
else
    % paused
    set(handles.playbutton, 'Enable', 'on');
    set(handles.stopbutton, 'Enable', 'on');
    set(handles.pausebutton, 'Enable', 'off');
end;    
    
% --- Executes on button press in pausebutton.
function pausebutton_Callback(hObject, eventdata, handles)
% hObject    handle to pausebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.playbutton, 'Enable', 'on');
set(handles.pausebutton, 'Enable', 'off');
set(handles.animation_axes, 'UserData', 2);

% --- Executes on button press in stopbutton.
function stopbutton_Callback(hObject, eventdata, handles)
% hObject    handle to stopbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.playbutton, 'Enable', 'on');
set(handles.pausebutton, 'Enable', 'off');
set(handles.stopbutton, 'Enable', 'off');
set(handles.animation_axes, 'UserData', 0);

% --- Executes during object creation, after setting all properties.
function animationslider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to animationslider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

usewhitebg = 0;
if usewhitebg
    set(hObject,'BackgroundColor',[.9 .9 .9]);
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end;

% --- Executes on slider movement.
function animationslider_Callback(hObject, eventdata, handles)
% hObject    handle to animationslider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% round the value
val = get(hObject,'Value');
val = handles.st*round(val/handles.st);
set(hObject, 'Value', val);
% update time
s = [num2str(val, '%.2f'), '/', num2str(get(hObject, 'Max'), '%.2f')];
set(handles.animationtime, 'String', s);

% update picture
set(handles.animation_axes, 'UserData', 3);
set(handles.playbutton, 'Enable', 'on');
set(handles.pausebutton, 'Enable', 'off');
set(handles.stopbutton, 'Enable', 'on');
handles.converteddata = animatef(handles);
% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function slowmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slowmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

% --- Executes on selection change in slowmenu.
function slowmenu_Callback(hObject, eventdata, handles)
% hObject    handle to slowmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes during object creation, after setting all properties.
function bipedparamedit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bipedparamedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

function bipedparamedit_Callback(hObject, eventdata, handles)
% hObject    handle to bipedparamedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes during object creation, after setting all properties.
function additionalparamedit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to additionalparamedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

function additionalparamedit_Callback(hObject, eventdata, handles)
% hObject    handle to additionalparamedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes during object creation, after setting all properties.
function simmodeledit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to simmodeledit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

function simmodeledit_Callback(hObject, eventdata, handles)
% hObject    handle to simmodeledit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes on button press in savebutton.
function savebutton_Callback(hObject, eventdata, handles)
% hObject    handle to savebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

data = handles.data;
data.st = handles.st;
data.robot = handles.robot;
data.groundp = handles.groundp;
% move data to the base workspace
assignin('base', 'data', data);

% --- Executes on button press in loadbutton.
function loadbutton_Callback(hObject, eventdata, handles)
% hObject    handle to loadbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if evalin('base', 'exist(''data'')')
    handles.data.state = evalin('base','data.state');
    handles.data.control = evalin('base','data.control');
    handles.st = evalin('base','data.st');
    handles.robot = evalin('base', 'data.robot');
    handles.groundp = evalin('base', 'data.groundp');

    set(handles.savestatebutton, 'Enable', 'off');

    % Update handles structure
    guidata(hObject, handles);
    % update playback controls
    update_playback(handles);
else
    disp('No variable named ''data'' found.');
end;

% --- Executes on button press in savestatebutton.
function savestatebutton_Callback(hObject, eventdata, handles)
% hObject    handle to savestatebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% get time
time = round(get(handles.animationslider, 'Value')/handles.st+1);
% get current state
currentstate.coordinates = handles.data.state(time, 1:7);
currentstate.speeds = handles.data.state(time, 8:14);
currentstate.gcstate = handles.gcstate(time, :);
% move to the base workspace
assignin('base', 'currentstate', currentstate);