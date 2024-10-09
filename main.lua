local dengui=require("libs.dengui")
function love.resize(w, h)
    dengui.set_render_screen_dims(1,1,0.5,0.5,0,false,1)
end
function love.keypressed(key)
    dengui.keypressed(key)
end
function love.textinput(key)
    dengui.textinput(key)
end
function love.keyreleased(key)
    dengui.keyreleased(key)
end
function love.mousepressed(x, y, button, isTouch)
    dengui.mousepressed(x, y, button, isTouch)
end
function love.mousereleased(x,y,button,isTouch)
    dengui.mousereleased(x,y,button,isTouch)
end
function love.mousemoved(x,y,dx,dy)
    dengui.mousemoved(x,y,dx,dy)
end
function love.wheelmoved(x,y)
    dengui.wheelmoved(x,y)
end
local berlin=love.graphics.newFont("fonts/BRLNSB.TTF", 64)
local function gen_tacho(linecount,canvas_id,tachcent,max,aspect,screen_size,scale,line_width,line_lenght,line_lenght_in,num_int,num_div)
    print(linecount)
    for i=0,linecount do
        local angle=i*math.rad(180)/linecount
        local xs=line_lenght*aspect*scale
        local sx=math.cos(angle)*scale
        local sy=-math.sin(angle)*scale*aspect
        if (((linecount-i)/linecount)*max)%num_int ==0 then
            xs=xs*line_lenght_in
            local num=dengui.new_textf(canvas_id,math.floor(0.5+(((linecount-i)/linecount)*max)/num_div))
            num.scale={x=5*scale,y=5*scale}
            local font_scale={x=(num.scale.x)*berlin:getWidth("1234")*scale/screen_size.x ,y=(num.scale.y)*berlin:getWidth("1234")*scale/screen_size.x}
            num.position={scale={x=sx*(font_scale.x+1.05)+tachcent.x,y=sy*(font_scale.y+1)+tachcent.y},offset={x=0,y=0}}
            num.font=berlin
            num.alignmode="center"
            num.size={scale={x=5*font_scale.x,y=font_scale.y},offset={x=0,y=0}}
            num.anchor={x=0.5,y=0.5}
            print(i,num.position.scale.x,num.anchor.x)
        end
        local line=dengui.new_boxr(canvas_id,{scale={x=sx+tachcent.x,y=sy+tachcent.y},offset={x=0,y=0}},{scale={x=line_width*scale,y=xs},offset={x=0,y=0}})
        line.anchor={x=0.5,y=0}
        line.zindex=10
        line.rotation=-angle +math.rad(90)
    end
end

local tachcentrpm={x=0.25,y=0.97}
local tachcentspeed={x=0.75,y=0.97}
local dash_canvas=dengui.new_canvas(0.85,0.3,10,true,3.5,{scale={x=0.5,y=1},offset={x=0,y=0}},{x=0.5,y=1})
dash_canvas.draw_bounds=true
local tach_line_rpm=dengui.new_boxr(dash_canvas.id,{scale={x=tachcentrpm.x,y=tachcentrpm.y},offset={x=0,y=0}},{scale={x=0.008,y=0.65},offset={x=0,y=0}})
tach_line_rpm.colour={1,0,0,1}
tach_line_rpm.anchor={x=0.5,y=0.1}
tach_line_rpm.zindex=100
local tach_line_speed=dengui.new_boxr(dash_canvas.id,{scale={x=tachcentspeed.x,y=tachcentspeed.y},offset={x=0,y=0}},{scale={x=0.008,y=0.65},offset={x=0,y=0}})
tach_line_speed.colour={1,0,0,1}
tach_line_speed.anchor={x=0.5,y=0.1}
tach_line_speed.zindex=100
dengui.set_render_screen_dims(1,1,0.5,0.5,0,false,1)
math.e=2.7182818284590452353602874713526624977572 --eulers number
local car={
    engine={
        w=1000*(2*math.pi)/60,
        idle_rpm=700,
        rev_limiter=6000,
        bounce_time=0.3,
        inertia=0.37,
        engine_braking_l=0.00025,              --Nm/rads
        engine_braking_q=0.00000003,         --Nm/rads²
        off_thottle_engine_braking_l=0.25,
        tq_curve={
            {-10e64,    0},
                {-1000,    1},
                {0,         1},         -->this is overridden with len of table anyways
                {1000,      37.1},
                {1500,      75},
                {2000,      103.4},
                {2500,      122.3},
                {3000,      131.8},
                {3250,      133},
                {3500,      132.8},
                {4000,      130.9},
                {4500,      127.2},
                {5000,      121.7},
                {5200,      119},
                {5300,      117.1},
                {5500,      112.9},
                {6000,      93.1},
                {6500,      3.1},
                {8000,       0},
                {10e64,      0},
            },
        throttle_curve={
            {0,0},
            {.1,.30},
            {.2,.40},
            {.3,.50},
            {.4,.60},
            {.5,.70},
            {.6,.75},
            {.7,.80},
            {.8,.85},
            {.9,.90},
            {1,1.00},
        }
    },
    transmission={
        l_gear=-1,
        h_gear=5,
        gears={
            [-1]=-3.583,
            [0]=0,
            [1]=3.636,
            [2]=1.95,
            [3]=1.281,
            [4]=0.975,
            [5]=0.767,
        },
        shift_time=0.35, --seconds
        loss=0.01,       --transmission torque loss in %     --nyi
        final_drive=4.54,
    },
    cgear=0,
    clutch={
        T_C=20,                 --Coulomb friction torque Nm
        T_brk=30,               --breakaway friction torque Nm
        w_brk=5,                --breakaway friction velocity drad/s
        f_viscous=0.025,         --viscous friction coefficient Nm/(drad/s))
        max_force=70,          --max clutch pressure N*m²
        oc_fix_mu=.05,            --oscilation_fix scale      -> n1 and n2 do the same thing when engine torque is exactly 0
        oc_fix_n1=1.5,            --oscilation_fix platue size         
        oc_fix_n2=4,            --oscilation_fix late correction factor
        oc_fix_tqf=0.2,         --oscilation_fix engine torque factor
        w=0,                    --auto
    },
    brakingNM=5000,
    wheel_radius=0.31725,
    car_mass=1200,
    speed=27.7777,
    engine_sound={
        firing_order = {1,2,4,5,3},--{1,6,5,10,2,7,3,8,4,9},--{1, 3, 4, 2},  -- Example: 4-cylinder inline engine
        num_cylinders = 5,
        intake_noise_amount = 0.3,
        exhaust_noise_amount = 0.5,
        mechanical_noise_amount = 0.2,
        exhaust_resonance = 0.4,
        intake_resonance = 0.3,
        crank_smoothing = 0, 
        noise_floor=0.15,
        noise_gate_threshold=.2,
    },
    cd=0.29,
    front_a=2.15
}
car.engine.throttle_curve[0]=#car.engine.throttle_curve
car.engine.tq_curve[0]=#car.engine.tq_curve
function love.load()
    gen_tacho(car.engine.rev_limiter/250,dash_canvas.id,tachcentrpm,car.engine.rev_limiter,dash_canvas.aspect_ratio,{x=dash_canvas.x,y=dash_canvas.y},0.2,0.025,0.3,1.3,7000/7,1000)
    gen_tacho(200/10,dash_canvas.id,tachcentspeed,200,dash_canvas.aspect_ratio,{x=dash_canvas.x,y=dash_canvas.y},0.2,0.025,0.3,1.3,20,1)
    dengui.re_render_all()
end
local changed=false
local curkw=0
local let=0

local SAMPLE_RATE = 44100
local BUFFER_SIZE = 1024


function love.update(dt)
    --physics
    local Iclutch=1
    local Ithrottle=0
    if love.keyboard.isDown("w") then
        Ithrottle=1
    else
        Ithrottle=0
    end
    if love.keyboard.isDown("lshift") then
        Iclutch=0
    else
        Iclutch=1
    end
    if love.keyboard.isDown("e")  then
        if changed==false then
            changed=true
            if car.cgear+1<=car.transmission.h_gear then
                car.cgear=car.cgear+1
            end
        end
    end
    if love.keyboard.isDown("q")  then
        if changed==false then
            changed=true
            if car.cgear-1>=car.transmission.l_gear then
                car.cgear=car.cgear-1
            end
        end
    end
    if love.keyboard.isDown("e") or love.keyboard.isDown("q") then
    else
        changed=false
    end
    --engine power
    local Ethrottle=0
    local engine_torque=0
    local engine_rpm=car.engine.w*60/(2*math.pi)
    for i=1,car.engine.throttle_curve[0],1 do
        local v=car.engine.throttle_curve[i]
        if Ithrottle>=v[1] and Ithrottle<=car.engine.throttle_curve[i+1][1] then
            Ethrottle=v[2]+(((Ithrottle-v[1])/(car.engine.throttle_curve[i+1][1]-v[1]))*(car.engine.throttle_curve[i+1][2]-v[2]))
            break
        end
    end
    let=Ethrottle
    for i=1,car.engine.tq_curve[0],1 do
        local v=car.engine.tq_curve[i]
        if engine_rpm>=v[1] and engine_rpm<=car.engine.tq_curve[i+1][1] then
            engine_torque=v[2]+(((engine_rpm-v[1])/(car.engine.tq_curve[i+1][1]-v[1]))*(car.engine.tq_curve[i+1][2]-v[2]))
            engine_torque=engine_torque*Ethrottle
            break
        end
    end
    
    if love.keyboard.isDown("f") then
        engine_torque=engine_torque*4
    end
    curkw=engine_torque*car.engine.w/1000
    local engine_A=engine_torque/car.engine.inertia
    car.engine.w=car.engine.w+engine_A*dt
    --car.engine.w=car.engine.w-((car.engine.w*car.engine.engine_braking_l+math.abs(car.engine.w)*car.engine.w*car.engine.engine_braking_q)/car.engine.inertia)*dt
    if Ethrottle==0 then
        car.engine.w=car.engine.w-((car.engine.w*car.engine.off_thottle_engine_braking_l)/car.engine.inertia)*dt
    end
    --clutch
    if car.cgear~=0 then
        car.clutch.w=(car.speed/car.wheel_radius)*car.transmission.final_drive*car.transmission.gears[car.cgear]
    else
        Iclutch=0
    end
    local w_C= car.engine.w-car.clutch.w
    local w_St=car.clutch.w_brk*math.sqrt(2)
    local w_Coul=car.clutch.w_brk/10
    local T=math.sqrt(2*math.e)*(car.clutch.T_brk-car.clutch.T_C)*math.exp(-((w_C/w_St)*(w_C/w_St)))*(w_C/w_St)+car.clutch.T_C*math.tanh(w_C/w_Coul)+car.clutch.f_viscous*w_C
    local clutch_force=Iclutch*car.clutch.max_force
    T=T*clutch_force
    car.engine.w=car.engine.w+((-T)/car.engine.inertia)*dt
    local T_loss=T*math.min(1,1/((w_C*0.0045)^2))--loss cuz slip and energy goes into heat yk
    T=T_loss
    --transmission
    local trans_torque=0
    if car.cgear==0 then
        trans_torque=0
    else
        trans_torque=T*1*car.transmission.gears[car.cgear]*car.transmission.final_drive*(1-car.transmission.loss)
    end

    if love.keyboard.isDown("s") then
        if car.speed>0 then
            trans_torque=trans_torque-car.brakingNM
        else
        trans_torque=trans_torque+car.brakingNM

        end
    end
    local car_F=trans_torque/car.wheel_radius
    car_F=car_F-0.5*1.214*car.speed*car.speed*car.cd*car.front_a-car.speed*car.speed*0.12--drag + rolling resitance estamite
    car.speed=car.speed+dt*car_F/car.car_mass
    --audio
    
end
function love.draw(dt)
    local engine_rpm=car.engine.w*60/(2*math.pi)
    local kmh=car.speed*3.6
    tach_line_rpm.rotation=math.pi*engine_rpm/car.engine.rev_limiter+math.pi*0.5
    tach_line_speed.rotation=math.pi*kmh/200+math.pi*0.5
    dengui.draw()
    love.graphics.print("fps: "..math.floor(((love.timer.getFPS()*100)+0.5))/100,400,200)
    dengui.re_render_canvas(dash_canvas.id)
    love.graphics.print("kmh: "..math.floor(((car.speed*3.6*100)+0.5))/100,100,100)
    if curkw>66 then
        love.graphics.print("NOS kw: "..math.floor(((curkw*100)+0.5))/100,100,150)
    else
        love.graphics.print("kw: "..math.floor(((curkw*100)+0.5))/100,100,150)
    end
    love.graphics.print("Ethrottle: "..math.floor(((let*100)+0.5))/100,100,200)


end
local TICK_RATE=1/5000
function love.run()
    if love.load then love.load(love.arg.parseGameArguments(arg), arg) end
    -- We don't want the first frame's dt to include time taken by love.load.
    if love.timer then love.timer.step() end
    local lag = 0.0
    local previus_updt=love.timer.getTime() 
    -- Main loop time.
    return function()
        -- Process events.
        if love.event then
            love.event.pump()
            for name, a,b,c,d,e,f in love.event.poll() do
                if name == "quit" then
                    if not love.quit or not love.quit() then
                        return a or 0
                    end
                end
                love.handlers[name](a,b,c,d,e,f)
            end
        end
        local ddt=love.timer.step()
        lag = lag + ddt
        while lag > TICK_RATE*0.5 do
            if love.update then love.update(TICK_RATE) end
            lag = lag - TICK_RATE
        end
        if love.graphics and love.graphics.isActive() then
            love.graphics.origin()
            love.graphics.clear(love.graphics.getBackgroundColor())
            if love.draw then love.draw(ddt) end
            love.graphics.present()
        end

        ---if love.timer then love.timer.sleep(0.001) end
    end
end
