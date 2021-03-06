function varargout = trackBall(varargin)
% TRACKBALL MATLAB code for trackBall.fig
%      TRACKBALL, by itself, creates a new TRACKBALL or raises the existing
%      singleton*.
%
%      H = TRACKBALL returns the handle to a new TRACKBALL or the handle to
%      the existing singleton*.
%
%      TRACKBALL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TRACKBALL.M with the given input arguments.
%
%      TRACKBALL('Property','Value',...) creates a new TRACKBALL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before trackBall_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to trackBall_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help trackBall

% Last Modified by GUIDE v2.5 30-Dec-2018 12:49:58

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @trackBall_OpeningFcn, ...
                   'gui_OutputFcn',  @trackBall_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before trackBall is made visible.
function trackBall_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to trackBall (see VARARGIN)


set(hObject,'WindowButtonDownFcn',{@my_MouseClickFcn,handles.axes1});
set(hObject,'WindowButtonUpFcn',{@my_MouseReleaseFcn,handles.axes1});
axes(handles.axes1);

handles.Cube=DrawCube(eye(3));

set(handles.axes1,'CameraPosition',...
    [0 0 5],'CameraTarget',...
    [0 0 -5],'CameraUpVector',...
    [0 1 0],'DataAspectRatio',...
    [1 1 1]);

set(handles.axes1,'xlim',[-3 3],'ylim',[-3 3],'visible','off','color','none');

% Choose default command line output for trackBall
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes trackBall wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = trackBall_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

function my_MouseClickFcn(obj,event,hObject)

handles=guidata(obj);
xlim = get(handles.axes1,'xlim');
ylim = get(handles.axes1,'ylim');
mousepos=get(handles.axes1,'CurrentPoint');
xmouse = mousepos(1,1);
ymouse = mousepos(1,2);

% the sphere that conatins the cube's radius:  
global sph_radius; 
sph_radius = 5; 

% when clicking, last quaternion is considered nule 
global this_quaternion; 
global last_quaternion; 

%last_quaternion = zeros(4); 
last_quaternion = this_quaternion; 

if xmouse > xlim(1) && xmouse < xlim(2) && ymouse > ylim(1) && ymouse < ylim(2)

    set(handles.figure1,'WindowButtonMotionFcn',{@my_MouseMoveFcn,hObject});
    
    %calculate mouse in 3D sphere
    mouse_in_sphere = Calculate_M_in_sphere(sph_radius, xmouse, ymouse) 
    this_quaternion = Vecs2quat(mouse_in_sphere, last_mouse_in_sphere) 
    
end
guidata(hObject,handles)

function my_MouseReleaseFcn(obj,event,hObject)
handles=guidata(hObject);
set(handles.figure1,'WindowButtonMotionFcn','');
guidata(hObject,handles);

function my_MouseMoveFcn(obj,event,hObject)
global last_mouse_in_sphere;  
global last_quaternion; 
global sph_radius; 
global this_quaternion; 
global mouse_in_sphere; 

handles=guidata(obj);
xlim = get(handles.axes1,'xlim');
ylim = get(handles.axes1,'ylim');
mousepos=get(handles.axes1,'CurrentPoint');
xmouse = mousepos(1,1);
ymouse = mousepos(1,2);
this_quaternion = zeros(4); 

if xmouse > xlim(1) && xmouse < xlim(2) && ymouse > ylim(1) && ymouse < ylim(2)
     
    % 1) first calculate mouse in sphere
     mouse_in_sphere = Calculate_M_in_sphere(sph_radius, xmouse, ymouse) 
  
    % 2) then obtain a quaternion with last mouse pos and this pos
    if(~isempty(last_mouse_in_sphere))
    this_quaternion = Vecs2quat(last_mouse_in_sphere, mouse_in_sphere) 
    end 
     
     % 3) compose this and last frame quats ---> "actual quaternion"
      if(last_quaternion(1) ~= 0 && last_quaternion(2) ~= 0 && last_quaternion(3) ~= 0 && last_quaternion(4) ~= 0  )
     this_quaternion = quatmultiply(this_quaternion', last_quaternion')'
      end 
      
     % 4) reset last frame quaternion once the calculations are finished 
     last_quaternion = this_quaternion
     % 4) reset last frame mouse pos once the calculations are finished 
     last_mouse_in_sphere = mouse_in_sphere  
 
     % (transform the quaternion to other parametrizations)  
     Update_All_Parametrizations_from_Quaternion(this_quaternion,handles, 0); 
     
     % 5) recalculate rot matrix from the actual quaternion
     R = Quat2RotMat(this_quaternion)
     handles.Cube = RedrawCube(R,handles.Cube);
     
       % actualize rotation matrix in GUI 
     set(handles.Matrix_1, 'String', R(1,1)); 
     set(handles.Matrix_2, 'String', R(1,2)); 
     set(handles.Matrix_3, 'String', R(1,3)); 
     set(handles.Matrix_4, 'String', R(2,1)); 
     set(handles.Matrix_5, 'String', R(2,2)); 
     set(handles.Matrix_6, 'String', R(2,3)); 
     set(handles.Matrix_7, 'String', R(3,1)); 
     set(handles.Matrix_8, 'String', R(3,2)); 
     set(handles.Matrix_9, 'String', R(3,3)); 
    
end
guidata(hObject,handles);

function h = DrawCube(R)

M0 = [    -1  -1 1;   %Node 1
    -1   1 1;   %Node 2
    1   1 1;   %Node 3
    1  -1 1;   %Node 4
    -1  -1 -1;  %Node 5
    -1   1 -1;  %Node 6
    1   1 -1;  %Node 7
    1  -1 -1]; %Node 8

M = (R*M0')';


x = M(:,1);
y = M(:,2);
z = M(:,3);


con = [1 2 3 4;
    5 6 7 8;
    4 3 7 8;
    1 2 6 5;
    1 4 8 5;
    2 3 7 6]';

x = reshape(x(con(:)),[4,6]);
y = reshape(y(con(:)),[4,6]);
z = reshape(z(con(:)),[4,6]);

c = 1/255*[255 248 88;
    0 0 0;
    57 183 225;
    57 183 0;
    255 178 0;
    255 0 0];

h = fill3(x,y,z, 1:6);

for q = 1:length(c)
    h(q).FaceColor = c(q,:);
end

function h = RedrawCube(R,hin)

h = hin;
c = 1/255*[255 248 88;
    0 0 0;
    57 183 225;
    57 183 0;
    255 178 0;
    255 0 0];

M0 = [    -1  -1 1;   %Node 1
    -1   1 1;   %Node 2
    1   1 1;   %Node 3
    1  -1 1;   %Node 4
    -1  -1 -1;  %Node 5
    -1   1 -1;  %Node 6
    1   1 -1;  %Node 7
    1  -1 -1]; %Node 8

M = (R*M0')';


x = M(:,1);
y = M(:,2);
z = M(:,3);


con = [1 2 3 4;
    5 6 7 8;
    4 3 7 8;
    1 2 6 5;
    1 4 8 5;
    2 3 7 6]';

x = reshape(x(con(:)),[4,6]);
y = reshape(y(con(:)),[4,6]);
z = reshape(z(con(:)),[4,6]);

for q = 1:6
    h(q).Vertices = [x(:,q) y(:,q) z(:,q)];
    h(q).FaceColor = c(q,:);
end


function quat_1_Callback(hObject, eventdata, handles)
% hObject    handle to quat_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of quat_1 as text
%        str2double(get(hObject,'String')) returns contents of quat_1 as a double


% --- Executes during object creation, after setting all properties.
function quat_1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to quat_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function quat_2_Callback(hObject, eventdata, handles)
% hObject    handle to quat_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of quat_2 as text
%        str2double(get(hObject,'String')) returns contents of quat_2 as a double


% --- Executes during object creation, after setting all properties.
function quat_2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to quat_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function quat_3_Callback(hObject, eventdata, handles)
% hObject    handle to quat_3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of quat_3 as text
%        str2double(get(hObject,'String')) returns contents of quat_3 as a double


% --- Executes during object creation, after setting all properties.
function quat_3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to quat_3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function quat_4_Callback(hObject, eventdata, handles)
% hObject    handle to quat_4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of quat_4 as text
%        str2double(get(hObject,'String')) returns contents of quat_4 as a double


% --- Executes during object creation, after setting all properties.
function quat_4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to quat_4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% call this function when you have a quaternion, previously calculated from any push
% button
function [] = Do_Rotation(q, handles)

 global last_quaternion; 
 global this_quaternion; 

q = q / norm(q); 

% Accumultaive rotations commented
% this_quaternion = q; 
% 
%      % 3) compose this and last frame quats ---> "actual quaternion"
%       if(last_quaternion(1) ~= 0 && last_quaternion(2) ~= 0 && last_quaternion(3) ~= 0 && last_quaternion(4) ~= 0  )
%      this_quaternion = quatmultiply(this_quaternion', last_quaternion')'
%       end 
%       
%      % 4) reset last frame quaternion once the calculations are finished 
%      last_quaternion = this_quaternion
%      
%      % 5) recalculate rot matrix from the actual quaternion
%      R = Quat2RotMat(this_quaternion)

     R = Quat2RotMat(q)
     handles.Cube = RedrawCube(R,handles.Cube);
     
     
       % actualize rotation matrix in GUI 
     set(handles.Matrix_1, 'String', R(1,1)); 
     set(handles.Matrix_2, 'String', R(1,2)); 
     set(handles.Matrix_3, 'String', R(1,3)); 
     set(handles.Matrix_4, 'String', R(2,1)); 
     set(handles.Matrix_5, 'String', R(2,2)); 
     set(handles.Matrix_6, 'String', R(2,3)); 
     set(handles.Matrix_7, 'String', R(3,1)); 
     set(handles.Matrix_8, 'String', R(3,2)); 
     set(handles.Matrix_9, 'String', R(3,3)); 


function [] = Update_All_Parametrizations_from_Quaternion(q, handles, flag)
        
        % 1) update quaternion in GUI) 
        if(flag ~= 1)
         set(handles.quat_1, 'String', q(1)); 
         set(handles.quat_2, 'String', q(2)); 
         set(handles.quat_3, 'String', q(3)); 
         set(handles.quat_4, 'String', q(4)); 
        end 

        % 2) quat to axis angle
        if(flag ~= 2)
        [axis, angle] = Quat_to_AxisAngle(q)
        axis = axis / norm(axis)
        angle = angle * 180 / pi
        
         set(handles.axis_angle_0, 'String', angle); 
         set(handles.axis_angle_1, 'String', axis(1)); 
         set(handles.axis_angle_2, 'String', axis(2)); 
         set(handles.axis_angle_3, 'String', axis(3)); 
        end 
        
        % 3) quat to angles
         if(flag ~= 3)
        angles = Quat_to_Euler_Angles(q)
        angles = angles * 180 / pi
        set(handles.angles_1, 'String', angles(1)); 
        set(handles.angles_2, 'String', angles(2)); 
        set(handles.angles_3, 'String', angles(3));
         end 
         
         
         
         
         if(flag ~= 4) 
         
        [axis, angle] = Quat_to_AxisAngle(q)
        vec = Axis_Angle_to_Rot_Vec(axis,angle) 
        
        set(handles.vector_1, 'String', vec(1)); 
        set(handles.vector_2, 'String', vec(2)); 
        set(handles.vector_3, 'String', vec(3)); 
             
         end 
         
         
         
        
        % 4) quat to rotation vector
        
        
        
        

% --- Executes on button press in quat_button.
function quat_button_Callback(hObject, eventdata, handles)
% hObject    handle to quat_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA) 

q = [0 0 0 0]'; 
s_1 = get(handles.quat_1,'String'); 
s_2 = get(handles.quat_2,'String'); 
s_3 = get(handles.quat_3,'String'); 
s_4 = get(handles.quat_4,'String'); 
q = [str2num(s_1) str2num(s_2) str2num(s_3) str2num(s_4)]'; 

% Update all other parametrizations 
Update_All_Parametrizations_from_Quaternion(q,handles, 1); 

% Rotate cube 
if(~isempty(q(1)) && ~isempty(q(2)) && ~isempty(q(3)) && ~isempty(q(4)))
    Do_Rotation(q, handles) 
    
end 

% --- Executes on button press in axis_angle_button.
function axis_angle_button_Callback(hObject, eventdata, handles)
% hObject    handle to axis_angle_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global actual_quaternion; 

q = [0 0 0 0]'; 

angle = get(handles.axis_angle_0,'String'); 
a_1 = get(handles.axis_angle_1,'String'); 
a_2 = get(handles.axis_angle_2,'String'); 
a_3 = get(handles.axis_angle_3,'String'); 

axis = [str2num(a_1) str2num(a_2) str2num(a_3)]
axis = axis / norm(axis) 
real_angle = str2num(angle)*pi/180; 
 
q = AxisAngle_to_Quat(axis, real_angle)

% Update all other parametrizations 
Update_All_Parametrizations_from_Quaternion(q,handles, 2); 


% Rotate cube 
 if(~isempty(q(1)) && ~isempty(q(2)) && ~isempty(q(3)) && ~isempty(q(4)))
    %actual_quaternion = q
    Do_Rotation(q, handles); 
    
 end 
 
 
% --- Executes on button press in euler_angles_button.
function euler_angles_button_Callback(hObject, eventdata, handles)
% hObject    handle to euler_angles_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


 global actual_quaternion; 

q = [0 0 0 0]'; 

a_1 = get(handles.angles_1,'String')
a_2 = get(handles.angles_2,'String')
a_3 = get(handles.angles_3,'String')
angles = [str2num(a_1) str2num(a_2) str2num(a_3)]; 
angles = angles * pi / 180

q = Euler_Angles_to_Quat(angles); 

% Update all other parametrizations 
Update_All_Parametrizations_from_Quaternion(q,handles, 3); 


% Rotate cube 
 if(~isempty(q(1)) && ~isempty(q(2)) && ~isempty(q(3)) && ~isempty(q(4)))
    %this_quaternion = q
    Do_Rotation(q, handles); 

 end 

 
% --- Executes on button press in vector_button.
function vector_button_Callback(hObject, eventdata, handles)
% hObject    handle to vector_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


 global this_quaternion; 
 global last_quaternion; 

q = [0 0 0 0]'; 

s_1 = get(handles.vector_1,'String')
s_2 = get(handles.vector_1,'String')
s_3 = get(handles.vector_1,'String')
vector = [str2num(s_1) str2num(s_2) str2num(s_3)]; 
vector = vector / norm(vector); 


q = Vecs2quat(vector', last_quaternion(2:4))
% Update all other parametrizations 
Update_All_Parametrizations_from_Quaternion(q,handles, 4); 


% Rotate cube 
 if(~isempty(q(1)) && ~isempty(q(2)) && ~isempty(q(3)) && ~isempty(q(4)))
    %this_quaternion = q
    Do_Rotation(this_quaternion, handles); 

 end 
 

% --- Executes on button press in reset_button.
function reset_button_Callback(hObject, eventdata, handles)
% hObject    handle to reset_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

 % reset GUI
         set(handles.quat_1, 'String', 'value'); 
         set(handles.quat_2, 'String', 'value'); 
         set(handles.quat_3, 'String', 'value'); 
         set(handles.quat_4, 'String', 'value'); 
     
         set(handles.axis_angle_0, 'String', 'value'); 
         set(handles.axis_angle_1, 'String', 'value'); 
         set(handles.axis_angle_2, 'String', 'value'); 
         set(handles.axis_angle_3, 'String','value'); 
    
         set(handles.angles_1, 'String', 'value'); 
         set(handles.angles_2, 'String', 'value'); 
         set(handles.angles_3, 'String', 'value');
         
         set(handles.vector_1, 'String', 'value'); 
         set(handles.vector_2, 'String', 'value'); 
         set(handles.vector_3, 'String', 'value');
         
     set(handles.Matrix_1, 'String', 'value'); 
     set(handles.Matrix_2, 'String', 'value'); 
     set(handles.Matrix_3, 'String', 'value'); 
     set(handles.Matrix_4, 'String', 'value'); 
     set(handles.Matrix_5, 'String', 'value'); 
     set(handles.Matrix_6, 'String', 'value'); 
     set(handles.Matrix_7, 'String', 'value'); 
     set(handles.Matrix_8, 'String', 'value'); 
     set(handles.Matrix_9, 'String', 'value'); 
     
     
     % reposition cube 
     R = eye(3)
     
 
    handles.Cube=RedrawCube(R,handles.Cube);
     
     
      

    
     
     
     
     
     
  






 









function axis_angle_3_Callback(hObject, eventdata, handles)
% hObject    handle to axis_angle_3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of axis_angle_3 as text
%        str2double(get(hObject,'String')) returns contents of axis_angle_3 as a double


% --- Executes during object creation, after setting all properties.
function axis_angle_3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axis_angle_3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function axis_angle_2_Callback(hObject, eventdata, handles)
% hObject    handle to axis_angle_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of axis_angle_2 as text
%        str2double(get(hObject,'String')) returns contents of axis_angle_2 as a double


% --- Executes during object creation, after setting all properties.
function axis_angle_2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axis_angle_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function axis_angle_1_Callback(hObject, eventdata, handles)
% hObject    handle to axis_angle_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of axis_angle_1 as text
%        str2double(get(hObject,'String')) returns contents of axis_angle_1 as a double


% --- Executes during object creation, after setting all properties.
function axis_angle_1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axis_angle_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function axis_angle_0_Callback(hObject, eventdata, handles)
% hObject    handle to axis_angle_0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of axis_angle_0 as text
%        str2double(get(hObject,'String')) returns contents of axis_angle_0 as a double


% --- Executes during object creation, after setting all properties.
function axis_angle_0_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axis_angle_0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function angles_1_Callback(hObject, eventdata, handles)
% hObject    handle to angles_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angles_1 as text
%        str2double(get(hObject,'String')) returns contents of angles_1 as a double


% --- Executes during object creation, after setting all properties.
function angles_1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angles_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function angles_2_Callback(hObject, eventdata, handles)
% hObject    handle to angles_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angles_2 as text
%        str2double(get(hObject,'String')) returns contents of angles_2 as a double


% --- Executes during object creation, after setting all properties.
function angles_2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angles_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in angles_3.
function angles_3_Callback(hObject, eventdata, handles)
% hObject    handle to angles_3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function angles_3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angles_3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


function vector_3_Callback(hObject, eventdata, handles)
% hObject    handle to vector_3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of vector_3 as text
%        str2double(get(hObject,'String')) returns contents of vector_3 as a double


% --- Executes during object creation, after setting all properties.
function vector_3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to vector_3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function vector_2_Callback(hObject, eventdata, handles)
% hObject    handle to vector_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of vector_2 as text
%        str2double(get(hObject,'String')) returns contents of vector_2 as a double


% --- Executes during object creation, after setting all properties.
function vector_2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to vector_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function vector_1_Callback(hObject, eventdata, handles)
% hObject    handle to vector_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of vector_1 as text
%        str2double(get(hObject,'String')) returns contents of vector_1 as a double


% --- Executes during object creation, after setting all properties.
function vector_1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to vector_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
