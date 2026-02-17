--$Name: Equirectangular_panos$
--$Name(ru): Равноугольные панорамы$
--$Version: 0.0.4.1$
--$Author: Lucky Ook$
--$Author(ru): Lucky Ook$

require "sprite"
require "timer"
require "click"

declare 'cubicPointer' (pixels.new ("res/cursors/cursor_dot.png"))
declare 'pxl' (false)
declare 't' (0)
declare 'fps' (0)
declare 'old_ticks' (0)
declare 'panosource' (false)
declare 'panoview' (false)
declare 'greedsource' (false)
declare 'deg2rad' (false)
declare 'ratioUp' (0)
declare 'ratioRight'(0)
declare 'cam_heading' (60) --поворот (рыскание)
declare 'cam_pitch' (90) --наклон (тангаж)
declare 'cam_roll' (0) --крен (в процессе добавления функционала)
declare 'cam_fov' (40) --угол зрения - уменьшение приближает, увеличение отдаляет.
declare 'step_w' (1) -- шаг рендера по ширине - чем больше, тем быстрее за счёт качества
declare 'step_h' (1) -- шаг рендера по высоте - чем больше, тем быстрее за счёт качества
declare 'src_width' (false)
declare 'src_height' (false) 
declare 'dest_width' (false)
declare 'dest_height' (false)
declare 'tk' (0)
declare 'theta_fac' (false)
declare 'phi_fac' (false)
declare 'offsetX' (0)
declare 'offsetY' (0)
declare 'setPoint' (false)
declare 'pointX' (0)
declare 'pointY' (0)

local mpi = math.pi
local msin = math.sin
local mcos = math.cos
local mtan = math.tan
local matan2 = math.atan2
local mmax = math.max
local mmin = math.min
local macos = math.acos
local mfloor = math.floor
local mrad = math.rad

function click:filter(press, btn, x, y, px, py)
	setPoint = press
	pointX, pointY = px, py
	return press and px -- ловим только нажатия на картинку
end

function game:timer()
	if setPoint and pointX and pointY then
		local panX, panY = instead.mouse_pos();
		panX = panX - offsetX
		panY = panY - offsetY
		if panX > 0 and panX < dest_width and panY > 0 and panY < dest_height then
			cam_heading = (cam_heading - 0.5 * (panX - pointX)*0.08);
			cam_pitch = cam_pitch + 0.5 * (panY - pointY)*0.08;
			cam_pitch = mmin(179,mmax(1,cam_pitch));
		else
			setPoint = false
			timer:stop()
		end
	else
		timer:stop()
	end
	std.nop()
end

local function pict_draw()
local rad_pitch = cam_pitch * deg2rad
local rad_heading = cam_heading * deg2rad
local rad_roll = cam_roll * deg2rad

local sin_roll = msin(rad_roll)
local cos_roll = mcos(rad_roll)

local sin_pitch = msin(rad_pitch)
local cos_pitch = mcos(rad_pitch)

local sin_heading = msin(rad_heading)
local cos_heading = mcos(rad_heading)

-- пока остановился тут

local camDirX = sin_pitch * sin_heading;
local camDirY = cos_pitch;
local camDirZ = sin_pitch * cos_heading;

local camUpX = ratioUp * msin((cam_pitch - 90.0)* deg2rad) * sin_heading;
local camUpY = ratioUp * mcos((cam_pitch - 90.0)* deg2rad);
local camUpZ = ratioUp * msin((cam_pitch - 90.0)* deg2rad) * cos_heading;

local camRightX = ratioRight * msin((cam_heading - 90.0)* deg2rad);
local camRightY = 0.0;
local camRightZ = ratioRight * mcos((cam_heading - 90.0)* deg2rad);

local camPlaneOriginX = camDirX + 0.5 * camUpX - 0.5 * camRightX;
local camPlaneOriginY = camDirY + 0.5 * camUpY - 0.5 * camRightY;
local camPlaneOriginZ = camDirZ + 0.5 * camUpZ - 0.5 * camRightZ;
-- render image
	for i = 0, dest_height, step_h do
	local fy = i / dest_height;
	
		for j = 0, dest_width, step_w do
		local fx = j / dest_width;

		local rayX = camPlaneOriginX + fx * camRightX - fy * camUpX;
		local rayY = camPlaneOriginY + fx * camRightY - fy * camUpY;
		local rayZ = camPlaneOriginZ + fx * camRightZ - fy * camUpZ;
		local rayNorm = 1.0 / ((rayX*rayX) + (rayY*rayY) + (rayZ*rayZ))^0.5;
--		local rayNorm = 1.0 / math.sqrt((rayX*rayX) + (rayY*rayY) + (rayZ*rayZ));
		local theta = macos(rayY * rayNorm);
		local phi = matan2(rayZ, rayX) + mpi;
		local theta_i = mfloor(theta_fac * theta);
		local phi_i = mfloor(phi_fac * phi);
--		panosource:copy(phi_i, theta_i, step_w, step_h, panoview, j, i);
		panoview:val(j, i,panosource:val(phi_i, theta_i));
--		panoview:fill(j, i, step_w, step_h, panosource:val(phi_i, theta_i));
--		panoview:circleAA(j, i, mmax(step_h/2, 1), panosource:val(phi_i, theta_i))
--		panoview:fill_circle(j, i, mmax(step_h/2, 1), panosource:val(phi_i, theta_i))
--		panoview:lineAA(j, i, math.random(j, j+step_h+step_h), math.random(i, i+step_w+step_w), panosource:val(phi_i, theta_i))
--		panoview:fill_triangle(j, i, j, math.random(i, i+step_w+step_w), math.random(j, j+step_h+step_h), i, panosource:val(phi_i, theta_i))
		end
	end
	if setPoint and pointX and pointY then
		cubicPointer:blend(panoview, pointX-4 or 0, pointY-3 or 0)
	end
end

function start()
   deg2rad = mpi/180
   panoview = pixels.new (400, 320)
   panosource = pixels.new 'panos/2.jpg'
   dest_width, dest_height = panoview:size()
   src_width, src_height = panosource:size()
   theta_fac = src_height / mpi;
   phi_fac = (src_width - 3) * 0.5  / mpi; --   это коэффициент для устранения шва на краях панорамы
   ratioUp = 2.0 * mtan(cam_fov* deg2rad / 2.0);
   ratioRight = ratioUp * 1.33;
   place("zoom_in", me());
   place("zoom_out", me());
--   place("roll_left", me());
--   place("roll_right", me());
end

menu {
	nam = "zoom_in",
	disp = "Приблизить",
	dsc = "{Приблизить}",
	act = function()
		cam_fov = cam_fov - 5;
		ratioUp = 2.0 * mtan(cam_fov* deg2rad / 2.0);
		ratioRight = ratioUp * 1.33;
	end,
};

menu {
	nam = "zoom_out",
	disp = "Отдалить",
	dsc = "{Отдалить}",
	act = function()
		cam_fov = cam_fov + 5;
		ratioUp = 2.0 * mtan(cam_fov* deg2rad / 2.0);
		ratioRight = ratioUp * 1.33;
	end,
};

-- Добавляем меню для управления креном
menu {
    nam = "roll_left",
    disp = "Крен влево",
    dsc = "{Повернуть влево}",
    act = function()
        cam_roll = cam_roll - 5
    end,
}

menu {
    nam = "roll_right",
    disp = "Крен вправо",
    dsc = "{Повернуть вправо}",
    act = function()
        cam_roll = cam_roll + 5
    end,
}

room {
	onenter = function()
		local pano = pixels.new 'panos/2.jpg'
		local greedsource = pixels.new 'panos/3.png'
		pano:copy(panosource, 0, 0)
		greedsource:blend(panosource, 0,0)
	end,
	nam = "main",
	disp = "Интро",
	title = "",
	onclick = function(s, press, btn, x, y, px, py)
		offsetX = x - px
		offsetY = y - py
		timer:set(50)
	end,
	pic = function()
		pict_draw();
		return panoview:sprite()
	end,
	way = {'main', 'no greed', 'greed'};
	}
	
room {
	onenter = function()
		local pano = pixels.new 'panos/2.jpg'
		pano:copy(panosource, 0, 0)
	end,
	nam = "no greed",
	disp = "Без сетки",
	title = "",
	onclick = function(s, press, btn, x, y, px, py)
		offsetX = x - px
		offsetY = y - py
		timer:set(50)
	end,
	pic = function()
		pict_draw();
		return panoview:sprite()
	end,
	way = {'main', 'no greed', 'greed' };
	}

room {
	onenter = function()
		local pano = pixels.new 'panos/3.png'
		pano:copy(panosource, 0, 0)
	end,
	nam = "greed",
	disp = "Сетка",
	title = "",
	onclick = function(s, press, btn, x, y, px, py)
		offsetX = x - px
		offsetY = y - py
		timer:set(50)
	end,
	pic = function()
		pict_draw();
		return panoview:sprite()
	end,
	way = {'main', 'no greed', 'greed' };
	}
