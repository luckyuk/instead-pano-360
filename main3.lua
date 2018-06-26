require "sprite"
require "timer"
require "click"

sprite.direct(false)

declare 'pxl' (false)
declare 't' (0)
declare 'fps' (0)
declare 'old_ticks' (0)
declare 'panosource' (false)
declare 'panoview' (false)
declare 'deg2rad' (false)
declare 'ratioUp' (0)
declare 'ratioRight'(0)
declare 'cam_heading' (60) --поворот
declare 'cam_pitch' (90) --наклон
declare 'cam_fov' (40) --угол зрения - уменьшение приближает, увеличение отдаляет.
declare 'step_w' (1) -- шаг рендера по ширине - чем больше, тем быстрее за счёт качества
declare 'step_h' (1) -- шаг рендера по высоте - чем больше, тем быстрее за счёт качества
declare 'src_width' (false)
declare 'src_height' (false) 
declare 'dest_width' (false)
declare 'dest_height' (false)
declare 'PosLastX' (0)
declare 'PosLastY' (0)
declare 'tk' (0)
declare 'theta_fac' (false)
declare 'phi_fac' (false)

local mpi = math.pi
local msin = math.sin
local mcos = math.cos
local mtan = math.tan
local matan2 = math.atan2
local mmax = math.max
local mmin = math.min
local macos = math.acos
local mfloor = math.floor

function game:timer()
local x,y = instead.mouse_pos();
	if x >0 and x < dest_width and y > 0 and y < dest_height then
		cam_heading = cam_heading - (x - PosLastX);
		cam_pitch = cam_pitch + 0.5 * (y - PosLastY);
		cam_pitch = mmin(180,mmax(0,cam_pitch));
		if PosLastX ~= x or PosLastY ~= y then
			tk = 0;
			step_w = 4;
			step_h = 4;
			PosLastX = x;
			PosLastY = y;
			pict_draw();
		else
			if tk == 0 then
				step_w = 2;
				step_h = 2;
				pict_draw();
				tk = 1;
			elseif tk == 1 then
				step_w = 1;
				step_h = 1;
				pict_draw();
				tk = 2;
			end;
		end;
	else
		if tk ~= 2 then
			step_w = 1;
			step_h = 1;
			pict_draw();
			tk = 2;
		end;
	end;
PosLastX = x;
PosLastY = y;
--   fps = (1000/(instead.ticks() - old_ticks))
--   print (fps)
--   old_ticks = instead.ticks()
end

function pict_draw()
local camDirX = msin(cam_pitch* deg2rad) * msin(cam_heading* deg2rad);
local camDirY = mcos(cam_pitch* deg2rad);
local camDirZ = msin(cam_pitch* deg2rad) * mcos(cam_heading* deg2rad);
local camUpX = ratioUp * msin((cam_pitch - 90.0)* deg2rad) * msin(cam_heading* deg2rad);
local camUpY = ratioUp * mcos((cam_pitch - 90.0)* deg2rad);
local camUpZ = ratioUp * msin((cam_pitch - 90.0)* deg2rad) * mcos(cam_heading* deg2rad);
local camRightX = ratioRight * msin((cam_heading - 90.0)* deg2rad);
local camRightY = 0.0;
local camRightZ = ratioRight * mcos((cam_heading - 90.0)* deg2rad);
local camPlaneOriginX = camDirX + 0.5 * camUpX - 0.5 * camRightX;
local camPlaneOriginY = camDirY + 0.5 * camUpY - 0.5 * camRightY;
local camPlaneOriginZ = camDirZ + 0.5 * camUpZ - 0.5 * camRightZ;
-- render image
	for i = 0, dest_height, step_h do
		if i == 50 or i == 150 or i == 250 or i == 350 or i == 450 or i == 550 then stead.busy(true) end;
		for j = 0, dest_width, step_w do
		local fx = j / dest_width;
		local fy = i / dest_height;
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
--		panoview:val(j, i,panosource:val(phi_i, theta_i));
		panoview:fill(j, i, step_w, step_h, panosource:val(phi_i, theta_i));
--		panoview:circleAA(j, i, mmax(step_h/2, 1), panosource:val(phi_i, theta_i))
--		panoview:fill_circle(j, i, mmax(step_h/2, 1), panosource:val(phi_i, theta_i))
--		panoview:lineAA(j, i, math.random(j, j+step_h+step_h), math.random(i, i+step_w+step_w), panosource:val(phi_i, theta_i))
--		panoview:fill_triangle(j, i, j, math.random(i, i+step_w+step_w), math.random(j, j+step_h+step_h), i, panosource:val(phi_i, theta_i))
		end
		if stead.busy then stead.busy(false) end;
	end
   panoview:draw_spr(sprite.scr())
end

function start(load)
   deg2rad = mpi/180
   panosource = pixels.new 'panos/eq_greed.jpg'
   panoview = pixels.new (600, 400)
--   panoview = pixels.new (300, 200, 2)
   dest_width, dest_height = panoview:size()
   src_width, src_height = panosource:size()
   theta_fac = src_height / mpi;
   phi_fac = (src_width - 3) * 0.5  / mpi; --   это коэффициент для устранения шва на краях панорамы
   ratioUp = 2.0 * mtan(cam_fov* deg2rad / 2.0);
   ratioRight = ratioUp * 1.33;
   timer:set(10)
   place("zoom_in", me());
   place("zoom_out", me());
end

menu {
	nam = "zoom_in",
	disp = "Приблизить",
	dsc = "{Приблизить}",
	act = function()
		cam_fov = cam_fov - 5;
		ratioUp = 2.0 * mtan(cam_fov* deg2rad / 2.0);
		ratioRight = ratioUp * 1.33;
		pict_draw();
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
		step_h = 2;
		step_w = 2
		pict_draw();
	end,
};

room {
	nam = "main",
	disp = "Интро",
	title = ""
	}
