local qsort={}
function qsort.swap(tab, firstindex,secondindex)
    local temp=tab[firstindex]
    tab[firstindex]=tab[secondindex]
    tab[secondindex]=temp
    --temp=nil
end
function qsort.partition(tab,left,right)
    local pivv=tab[right]
    local partitionindex=left
    for i=left,right-1 do
        if tab[i]<pivv then
            qsort.swap(tab,i,partitionindex)
            partitionindex=partitionindex+1
        end
    end
    qsort.swap(tab, right, partitionindex)
    --tab=nil
    --pivv=nil
    --left=nil
    return partitionindex
end
function qsort.quicksort(tab,left,right)
    left=left or 1
    right=right or #tab
    if left >=right then
        return
    end
    local pivi=qsort.partition(tab,left,right)
    qsort.quicksort(tab,left,pivi-1)
    qsort.quicksort(tab,pivi+1,right)
    --left=nil
    --right=nil
    --pivi=nil
    return tab
end
function qsort.dup(tab)
    if #tab>1 then
        local counts={}
        local exists={}
        local fromto={}
        for i=1,tab[0] do
            local v=tab[i].zindex
            if counts[v]==nil then
                counts[v]={}
                exists[#exists+1] = v
                --storage[v]={}
            end
            counts[v][#counts[v]+1]={tab[i],i}
            --counts[v]=counts[v]+1
            --storage[v][#storage[v]+1]={tab[i],i}
        end
        qsort.quicksort(exists)
        local ntab={}
        for i=1,#exists do
            local v=exists[i]
            for ii=1,#counts[v] do
                ntab[#ntab+1] = counts[v][ii][1]
                fromto[counts[v][ii][2]]=#ntab
                --fromto[storage[v][ii][2]]=#ntab
            end
        end
        ntab[0]=#ntab
        fromto[0]=ntab[0]
        --counts=nil
        --exists=nil
        --storage=nil
        return ntab,fromto
    else
        local fromto={}
        for i=1,tab[0] do
            fromto[i]=i
        end
        return tab,fromto
    end
end
local function string_insert(str1, str2, pos)
    return str1:sub(1,pos)..str2..str1:sub(pos+1)
end

local function nofunc(button)
    --print("button has no "..button.." function. if its not supposed to have a function, it shouldnt be a button.") 
end
local ffi=require("ffi")
local font_scale=3
local standart_font=love.graphics.newFont("/fonts/NotoSans-VariableFont_wdth,wght.ttf",12*font_scale)--love.graphics.getFont()
local dengui={}
local utf8=require("utf8")
local ui_storage={[0]=0}
local canvases={}
local canvases_drawables={}
local current_text_editing={0,0}
local canvas_render_order={}
local canv_from_to={}
local cursor_pos=0
local assets={}
local ui_storage_drawable={}

local function warn(message)
    local time = os.date("%Y-%m-%d %H:%M:%S")
    io.stderr:write(string.format("[%s] Warning: %s\n", time, message))
end
local  default_colour ={1,1,1,1}

local lg=love.graphics
local function firstlayercopy(tab)
    local ntab={}
    for i,v in pairs(tab)do
        ntab[i]=v
    end
    return ntab
end
local defaults={
    box={
        type="box",
        position={scale={x=0,y=0},offset={x=0,y=0}},
        size={scale={x=0,y=0},offset={x=0,y=0}},
        anchor={x=0,y=0},
        zindex=0,
        colour={1,1,1,1},
        mode="fill",
        round=0,
        width=3
    },
    boxr={
        type="boxr",
        position={scale={x=0,y=0},offset={x=0,y=0}},
        size={scale={x=0,y=0},offset={x=0,y=0}},
        anchor={x=0,y=0},
        zindex=0,
        colour={1,1,1,1},
        mode="fill",
        rotation=0,
    },
    text={
        type="text",
        position={scale={x=0,y=0},offset={x=0,y=0}},
        scale={x=1,y=1},
        anchor={x=0,y=0},
        zindex=0,
        colour={1,1,1,1},
        text="vergessen",
        rotation=0,
        font=standart_font,
    },
    textf={
        type="textf",
        position={scale={x=0,y=0},offset={x=0,y=0}},
        size={scale={x=0,y=0},offset={x=100,y=50}},
        scale={x=1,y=1},
        anchor={x=0,y=0},
        zindex=0,
        colour={1,1,1,1},
        text="vergessen",
        alignmode="center",
        rotation=0,
        font=standart_font,
    },
    textfb={
        type="textfb",
        position={scale={x=0,y=0},offset={x=0,y=0}},
        size={scale={x=0,y=0},offset={x=100,y=50}},
        scale={x=1,y=1},
        anchor={x=0,y=0},
        zindex=0,
        border_width=20,
        colour={.1,0.1,.1,1},
        border_colour={.9,.9,.9,1},
        background_colour={1,1,1,1},
        text="vergessen",
        alignmode="center",
        rotation=0,
        font=standart_font,
        round=0,
    },
    text_edit={
        type="text_edit",
        position={scale={x=0,y=0},offset={x=0,y=0}},
        size={scale={x=0,y=0},offset={x=100,y=50}},
        scale={x=1,y=1},
        anchor={x=0,y=0},
        zindex=0,
        border_width=20,
        colour={.1,0.1,.1,1},
        border_colour={.9,.9,.9,1},
        background_colour={1,1,1,1},
        text="",
        extra_text="",
        alignmode="center",
        rotation=0,
        font=standart_font,                ---img
        background_text="vergessen2",
        limit=100,
        enabled=true,
        round=0,
    },
    text_button={
        type="text_button",
        position={scale={x=0,y=0},offset={x=0,y=0}},
        size={scale={x=0,y=0},offset={x=100,y=50}},
        scale={x=1,y=1},
        anchor={x=0,y=0},
        zindex=0,
        border_width=20,
        colour={.1,0.1,.1,1},
        border_colour={.9,.9,.9,1},
        background_colour={1,1,1,1},
        text="vergessen",
        alignmode="center",
        font=standart_font,
        ["1_func"]=nofunc,
        ["2_func"]=nofunc,
        ["3_func"]=nofunc,
        enabled=true,
        round=0,
    },
    image={
        type="image",
        position={scale={x=0,y=0},offset={x=0,y=0}},
        size={scale={x=0,y=0},offset={x=0,y=0}},
        anchor={x=0,y=0},
        zindex=0,
        colour={1,1,1,1},
        rotation=0,
        asset="",
    },
    image_button={
        type="image_button",
        position={scale={x=0,y=0},offset={x=0,y=0}},
        size={scale={x=0,y=0},offset={x=100,y=50}},
        scale={x=1,y=1},
        anchor={x=0,y=0},
        zindex=0,
        colour={.1,0.1,.1,1},
        asset="",
        rotation=0,
        border_colour={1,1,1,0.4},
        border_width=3,
        ["1_func"]=nofunc,
        ["2_func"]=nofunc,
        ["3_func"]=nofunc,
        enabled=true,
        round=0,
    },
}
--love.graphics.setBlendMode( "alpha", "alphamultiply" )
--love.graphics.setBlendState( "add", "zero","one" )

print(standart_font)
local screen_canv_p={
    position={x=0.5,y=0.5},
    size={x=love.graphics.getWidth(),y=love.graphics.getHeight()},
    do_aspect=false,
    aspect_ratio=1,
    rotation=0,
}
function dengui.set_render_screen_dims(sx_s,sy_s,px_s,py_s,r,do_aspect,aspect_ratio)
    local screenX,screenY=love.graphics.getDimensions()
    sx_s=sx_s or screen_canv_p.size.x/screenX
    sy_s=sy_s or screen_canv_p.size.y/screenY
    px_s=px_s or screen_canv_p.position.x/screenX
    py_s=py_s or screen_canv_p.position.y/screenY
    r=r or 0
    if do_aspect==nil then
        do_aspect=true
    end
    aspect_ratio=aspect_ratio or sx_s/sy_s
    
    local sx=screenX*sx_s
    local sy=screenY*sy_s
    if do_aspect==true then
        if sx/sy>= aspect_ratio then
            sx=sy*aspect_ratio
        else
            sy=sx/aspect_ratio
        end
    end
    local px=px_s*screenX -sx*0.5
    local py=py_s*screenY -sy*0.5

    local offsetX=sx* math.cos(r) - sy * math.sin(r)
    local offsetY=sx* math.sin(r) + sy * math.cos(r)
    local tpx=px-offsetX*0.5+sx*0.5
    local tpy=py-offsetY*0.5+sy*0.5
    --print(px,py,tpx,tpy)
    
    screen_canv_p.position.x=tpx
    screen_canv_p.position.y=tpy
    screen_canv_p.size.x=sx
    screen_canv_p.size.y=sy
    screen_canv_p.do_aspect=do_aspect
    screen_canv_p.aspect_ratio=aspect_ratio
    screen_canv_p.rotation=r
    if canvases[0] then
        for i=1,canvases[0] do
            local v=canvases[i]
            dengui.set_size(i,v.sx,v.sy)
        end
        dengui.re_render_all()
    end
    return sx,sy
end
function dengui.new_canvas(sx_s,sy_s,zindex,do_aspect,aspect_ratio,canvas_position,canvas_anchor,scrollable,scrollbar_width,scroll_lenght)
    do_aspect=do_aspect or false
    aspect_ratio=aspect_ratio or sx_s/sy_s
    zindex=zindex or 0
    canvas_position=canvas_position or {scale={x=0.5,y=0.5},offset={x=0,y=0}}
    canvas_anchor=canvas_anchor or {x=0.5,y=0.5}
    scrollable=scrollable or false
    scrollbar_width=scrollbar_width or 10
    scroll_lenght=scroll_lenght or 3
    local canv_id=#canvases+1
    local sx=sx_s*screen_canv_p.size.x
    local sy=sy_s*screen_canv_p.size.y
    if do_aspect==true then
        if sx/sy>= aspect_ratio then
            sx=sy*aspect_ratio
        else
            sy=sx/aspect_ratio
        end
    end
    --local screenX,screenY=love.graphics.getWidth( ),love.graphics.getHeight( )
    local screenX,screenY=screen_canv_p.size.x,screen_canv_p.size.y
    sx=math.max(1,sx)
    sy=math.max(1,sy)
    local cano={
        canvas=lg.newCanvas(sx,sy),
        x=sx,y=sy,
        sy=sy_s,sx=sx_s,
        zindex=zindex,
        do_aspect=do_aspect,
        aspect_ratio=aspect_ratio,
        position=canvas_position,
        anchor=canvas_anchor,
        scrollable=scrollable,
        scrollbar_enabled=true,
        scrollbar_width=scrollbar_width,
        scrollbar_colour={1,1,1,1},
        scroll_lenght=scroll_lenght,
        scroll_y=0,
        syncscrolls={},
        draw_bounds=false,
        id=canv_id,
        visible=true,
    }
    canvases[canv_id] = firstlayercopy(cano)
    canvases[0]=canv_id
    ui_storage[canv_id]={[0]=0}
    local px=canvas_position.scale.x*screenX+canvas_position.offset.x   -sx*canvas_anchor.x+screen_canv_p.position.x
    local py=canvas_position.scale.y*screenY+canvas_position.offset.y   -sy*canvas_anchor.y+screen_canv_p.position.y
    canvases[canv_id].truepos={x=px,y=py}
    --for i,v in pairs(canvases[canv_id])do
    --   print(i,v) 
    --end
    canvases_drawables[0]=#canvases
    canvases_drawables,canv_from_to=qsort.dup(canvases)
    --canvases=qsort.dup(canvases)
    ---table.sort(canvases,zsort)
    --print(canvases[canv_id].do_aspect)
    --print("newcavn",canvases[0])
    --for i=1,canvases_drawables[0] do
    --    print(i,canv_from_to[i],canvases[i].zindex)
    --end
    --print("newcanallcanvas",canvases[0])
    --for i=1,canvases[0] do
    --    print(i,canvases[i].do_aspect,canvases[0])
    --end

    return canvases[canv_id]
end
function dengui.set_size(canvas_id,x,y,scroll_lenght)
    --print("soze",canvas_id,x,y,canvases[canvas_id].do_aspect)
    --reconstruct canvas here
    if canvases[canvas_id] then
        local screenX,screenY=screen_canv_p.size.x,screen_canv_p.size.y
        local canv=canvases[canvas_id]
        x=x*screen_canv_p.size.x
        y=y*screen_canv_p.size.y
        if canv.do_aspect==true then
            if x/y>= canv.aspect_ratio then
                x=(y*canv.aspect_ratio)
            else
                y=(x/canv.aspect_ratio)
            end
        end
        canv.canvas:release()
        --local screenX,screenY=love.graphics.getDimensions( )--love.graphics.getWidth( ),love.graphics.getHeight( )
        
        canv.canvas=lg.newCanvas(x,y)
        canv.x=x
        canv.y=y
        if canv.scrollable==true then
            canv.scroll_lenght=scroll_lenght or canv.scroll_lenght
        end
        canvases_drawables[canv_from_to[canvas_id]].canvas=canv.canvas
        canvases_drawables[canv_from_to[canvas_id]].x=canv.x
        canvases_drawables[canv_from_to[canvas_id]].y=canv.y
        local px=canv.position.scale.x*screenX+canv.position.offset.x   -canv.x*canv.anchor.x +screen_canv_p.position.x
        local py=canv.position.scale.y*screenY+canv.position.offset.y   -canv.y*canv.anchor.y +screen_canv_p.position.y
        canv.truepos={x=px,y=py}
        --print(px,py,x,y,screenX,screenY)
    else
        warn("canvas_id '"..canvas_id.."' not found")
    end
    dengui.re_render_canvas(canvas_id)
    return true
end
function dengui.set_size_all(x,y)
    --reconstruct canvas here
    for canvas_id=1,canvases[0] do
        if canvases[canvas_id] then
            dengui.set_size(canvas_id,x,y)
        else
            warn("canvas_id '"..canvas_id.."' not found")
        end
        dengui.re_render_canvas(canvas_id)
    end
    return true
end
local cursor_timer=os.clock()
local cursor_state=false
function dengui.draw()
    --lg.setColor(1,1,1,1)
    --local screenX,screenY=love.graphics.getWidth( ),love.graphics.getHeight( )
    local screenX,screenY=screen_canv_p.size.x,screen_canv_p.size.y
    --print(love.graphics.getWidth( ),love.graphics.getHeight( ),screenX,screenY)
    for i=1,canvases[0] do
        local canv=canvases_drawables[i]--canvases[i]
        local sx=canv.x--*screen_canv_p.size.x
        local sy=canv.y--*screen_canv_p.size.y
        local px=canv.position.scale.x*screenX+canv.position.offset.x   -sx*canv.anchor.x +screen_canv_p.position.x
        local py=canv.position.scale.y*screenY+canv.position.offset.y   -sy*canv.anchor.y +screen_canv_p.position.y
        --canv.truepos.x=px
        --canv.truepos.y=py
        --print(px,py,sx,sy,canv.x)
        lg.setColor(1,1,1,1)
        if canv.visible==true then
            lg.draw(canv.canvas,px,py,screen_canv_p.rotation)
        end
    end
    if cursor_timer<os.clock()-1 and current_text_editing[1]~=0 then
        cursor_timer=os.clock()
        cursor_state= not cursor_state
        dengui.re_render_canvas(current_text_editing[1])
    end
    --return true
end
function dengui.msgbox(msg,args)
    args=args or ""
    --os.execute("msg "..args.." * "..msg,1000,true)
    io.popen("msg "..args.." * "..msg,"r")
end
function dengui.new_img_asset(filename,storename,settings)
    if filename==nil or love.filesystem.exists(filename)==false then warn(filename.." was not found") return end
    settings=settings or {mipmaps=false,linear=false,dpiscale=1}
    settings.mipmaps=settings.mipmaps or false
    settings.linear=settings.linear or false
    settings.dpiscale=settings.dpiscale or 1
    storename=storename or filename
    local img=lg.newImage(filename,settings)
    if img then
        assets[storename]=img
        --print(storename,filename)
    else
        warn(filename.." was unable to load")
    end
    return img:getPixelDimensions()
end
function dengui.release_img_asset(storename)
    if assets[storename] then
        assets[storename]:release()
        assets[storename]=nil
    else
        warn("cant relase an asset that does not exist")
    end
    collectgarbage("collect")
    return
end
function dengui.remove_canvas(id)
    warn("deprecated function: it causes pointers to point where they shouldnt!")
    return 
    --if id then
    --    local thiscanv=canvases[id]
    --    thiscanv.canvas:release()
    --    table.remove(canvases,id)
    --    canvases[0]=#canvases
    --    for i=1,canvases[0] do
    --        canvases[i].id=i
    --    end
    --end
end
function dengui.clean_canvas(id)
    if id then
        ui_storage[id]={}
        ui_storage[id][0]=0
    end
end

function dengui.new_box(canvas_id,position,size,colour,mode)
    if type(canvas_id)~="number" then warn("invalid canvas_id "..debug.traceback()) end
    --if type(position)~="table" then warn("invalid position "..debug.traceback()) end
    --if type(size)~="table" then warn("invalid size "..debug.traceback()) end
    --if type(colour)~="table" and type(colour)~="nil" then warn("invalid colour "..debug.traceback()) end
    local genbox=firstlayercopy(defaults.box)
    genbox.position=position or defaults.box.position
    genbox.size=size or defaults.box.size
    genbox.colour=colour or defaults.box.colour
    genbox.mode=mode or defaults.box.mode
    ui_storage[canvas_id][ui_storage[canvas_id][0]+1]=genbox
    ui_storage[canvas_id][0]=#ui_storage[canvas_id]
    --dengui.re_render_canvas(canvas_id)
    return genbox
end
local function render_box(canvas_id,box)
    --print("aa",canvas_id)
    local thiscan=canvases[canvas_id]
    local sx=box.size.scale.x*thiscan.x+box.size.offset.x
    local sy=box.size.scale.y*thiscan.y+box.size.offset.y
    local px=box.position.scale.x*thiscan.x+box.position.offset.x   -sx*box.anchor.x
    local py=box.position.scale.y*thiscan.y+box.position.offset.y   -sy*box.anchor.y    -thiscan.scroll_y*thiscan.y
    lg.setColor(box.colour[1],box.colour[2],box.colour[3],box.colour[4])
    lg.setLineWidth(box.width)
    --print("rect",sx,sy,box.size.scale.x,box.size.scale.y)
    --print("rectcan",thiscan.x,thiscan.y)
    --print(px,py,sx,sy)
    lg.rectangle(box.mode, px, py, sx, sy,box.round,box.round)
    lg.setColor(default_colour[1],default_colour[2],default_colour[3],default_colour[4])
end
function dengui.new_boxr(canvas_id,position,size,colour,mode,rotation)
    if type(canvas_id)~="number" then warn("invalid canvas_id "..debug.traceback()) end
    --if type(position)~="table" then warn("invalid position "..debug.traceback()) end
    --if type(size)~="table" then warn("invalid size "..debug.traceback()) end
    --if type(colour)~="table" and type(colour)~="nil" then warn("invalid colour "..debug.traceback()) end
    local genbox=firstlayercopy(defaults.boxr)
    genbox.position=position or defaults.boxr.position
    genbox.size=size or defaults.boxr.size
    genbox.colour=colour or defaults.boxr.colour
    genbox.mode=mode or defaults.boxr.mode
    genbox.rotation=rotation or defaults.boxr.rotation
    ui_storage[canvas_id][ui_storage[canvas_id][0]+1]=genbox
    ui_storage[canvas_id][0]=#ui_storage[canvas_id]
    --dengui.re_render_canvas(canvas_id)
    return genbox
end
local function render_boxr(canvas_id,box)
    local thiscan=canvases[canvas_id]
    local sx=box.size.scale.x*thiscan.x+box.size.offset.x
    local sy=box.size.scale.y*thiscan.y+box.size.offset.y
    local px=box.position.scale.x*thiscan.x+box.position.offset.x   -sx*box.anchor.x
    local py=box.position.scale.y*thiscan.y+box.position.offset.y   -sy*box.anchor.y

    local anchorX = sx * box.anchor.x
    local anchorY = sy * box.anchor.y
    local corners = {
        { -anchorX, -anchorY },       -- top-left
        { sx - anchorX, -anchorY },   -- top-right
        { sx - anchorX, sy - anchorY }, -- bottom-right
        { -anchorX, sy - anchorY }    -- bottom-left
    }
    local function rotatePoint(x, y, angle)
        return {
            x * math.cos(angle) - y * math.sin(angle),
            x * math.sin(angle) + y * math.cos(angle)
        }
    end
    local rotatedCorners = {}
    for i, corner in ipairs(corners) do
        local rotated = rotatePoint(corner[1], corner[2], box.rotation)
        rotatedCorners[#rotatedCorners + 1] = { px + anchorX + rotated[1], py + anchorY + rotated[2] }
    end
    local px1,py1, px2,py2, px3,py3, px4,py4= rotatedCorners[1][1], rotatedCorners[1][2],rotatedCorners[2][1], rotatedCorners[2][2],rotatedCorners[3][1], rotatedCorners[3][2],rotatedCorners[4][1], rotatedCorners[4][2]
    lg.setColor(box.colour[1],box.colour[2],box.colour[3],box.colour[4])
    local sco=thiscan.scroll_y*thiscan.y
    py1=py1-sco
    py2=py2-sco
    py3=py3-sco
    py4=py4-sco
    love.graphics.polygon(box.mode, px1,py1, px2,py2, px3,py3, px4,py4)
    lg.setColor(default_colour[1],default_colour[2],default_colour[3],default_colour[4])
    lg.setLineWidth(3)
end

function dengui.new_text(canvas_id,text,position,scale,colour)
    if type(canvas_id)~="number" then warn("invalid canvas_id "..debug.traceback()) end
    local gen=firstlayercopy(defaults.text)
    gen.position=position or defaults.text.position
    gen.scale=scale or defaults.text.scale
    gen.colour=colour or defaults.text.colour
    gen.text=text or defaults.text.text
    ui_storage[canvas_id][ui_storage[canvas_id][0]+1]=gen
    ui_storage[canvas_id][0]=#ui_storage[canvas_id]
    --dengui.re_render_canvas(canvas_id)
    return gen
end
local function render_text(canvas_id,obj)
    local thiscan=canvases[canvas_id]
    local thisfont=lg.getFont()
    local sx=thisfont:getWidth(obj.text)*obj.scale.x
    local sy=thisfont:getHeight(obj.text)*obj.scale.y
    local px=obj.position.scale.x*thiscan.x+obj.position.offset.x   -sx*obj.anchor.x
    local py=obj.position.scale.y*thiscan.y+obj.position.offset.y   -sy*obj.anchor.y    -thiscan.scroll_y*thiscan.y
    lg.setColor(obj.colour[1],obj.colour[2],obj.colour[3],obj.colour[4])
    lg.setFont(obj.font)
    lg.print(obj.text, px, py,obj.rotation, obj.scale.x, obj.scale.y)
    lg.setFont(standart_font)
    lg.setColor(default_colour[1],default_colour[2],default_colour[3],default_colour[4])
end
function dengui.new_textf(canvas_id,text,position,size,scale,colour)
    if type(canvas_id)~="number" then warn("invalid canvas_id "..debug.traceback()) end
    local gen=firstlayercopy(defaults.textf)
    gen.position=position or defaults.textf.position
    gen.scale=scale or defaults.textf.scale
    gen.size=size or defaults.textf.size
    gen.colour=colour or defaults.textf.colour
    gen.text=text or defaults.textf.text
    ui_storage[canvas_id][ui_storage[canvas_id][0]+1]=gen
    ui_storage[canvas_id][0]=#ui_storage[canvas_id]
    --dengui.re_render_canvas(canvas_id)
    return gen
end
local function render_textf(canvas_id,obj)
    local thiscan=canvases[canvas_id]
    local sx=obj.size.scale.x*thiscan.x+obj.size.offset.x
    local sy=obj.size.scale.y*thiscan.y+obj.size.offset.y
    local px=obj.position.scale.x*thiscan.x+obj.position.offset.x   -sx*obj.anchor.x
    local py=obj.position.scale.y*thiscan.y+obj.position.offset.y   -sy*obj.anchor.y    -thiscan.scroll_y*thiscan.y
    lg.setColor(obj.colour[1],obj.colour[2],obj.colour[3],obj.colour[4])
    love.graphics.setFont(obj.font)
    --lg.printf(obj.text, px, py,sx,obj.alignmode,obj.rotation, obj.scale.x, obj.scale.y)
    local fh=obj.font:getAscent()-obj.font:getDescent()-obj.font:getLineHeight()
    local n=math.ceil(obj.font:getWidth(obj.text)*(obj.scale.x/font_scale)/sx)
    lg.printf(obj.text, px, py+(sy*0.5)-(n*fh*0.5*(obj.scale.y/font_scale))-obj.font:getLineHeight(),sx/(obj.scale.x/font_scale),obj.alignmode,0, obj.scale.x/font_scale, obj.scale.y/font_scale)
    love.graphics.setFont(standart_font)
    lg.setColor(default_colour[1],default_colour[2],default_colour[3],default_colour[4])
end
function dengui.new_textfb(canvas_id,text,position,size,scale,colour)
    if type(canvas_id)~="number" then warn("invalid canvas_id "..debug.traceback()) end
    local gen=firstlayercopy(defaults.textfb)
    gen.position=position or defaults.textfb.position
    gen.scale=scale or defaults.textfb.scale
    gen.size=size or defaults.textfb.size
    gen.colour=colour or defaults.textfb.colour
    gen.text=text or defaults.textfb.text
    ui_storage[canvas_id][ui_storage[canvas_id][0]+1]=gen
    ui_storage[canvas_id][0]=#ui_storage[canvas_id]
    --dengui.re_render_canvas(canvas_id)
    return gen
end
local function render_textfb(canvas_id,obj)
    local thiscan=canvases[canvas_id]
    --local thisfont=lg.getFont()
    local sx=obj.size.scale.x*thiscan.x+obj.size.offset.x
    local sy=obj.size.scale.y*thiscan.y+obj.size.offset.y
    local px=obj.position.scale.x*thiscan.x+obj.position.offset.x   -sx*obj.anchor.x
    local py=obj.position.scale.y*thiscan.y+obj.position.offset.y   -sy*obj.anchor.y
    lg.setColor(obj.background_colour[1],obj.background_colour[2],obj.background_colour[3],obj.background_colour[4])
    lg.rectangle("fill", px, py, sx, sy,obj.round,obj.round)
    lg.setLineWidth(obj.border_width)
    lg.setColor(obj.border_colour[1],obj.border_colour[2],obj.border_colour[3],obj.border_colour[4])
    lg.rectangle("line", px+obj.border_width*.5, py+obj.border_width*.5, sx-obj.border_width*.5, sy-obj.border_width*.5,obj.round,obj.round)
    lg.setColor(obj.colour[1],obj.colour[2],obj.colour[3],obj.colour[4])
    --lg.printf(obj.text, px, py,sx,obj.alignmode,obj.rotation, obj.scale.x, obj.scale.y)
    lg.setFont(obj.font)
    local fh=obj.font:getAscent()-obj.font:getDescent()-obj.font:getLineHeight()
    local n=math.ceil(obj.font:getWidth(obj.text)*(obj.scale.x/font_scale)/sx)
    lg.printf(obj.text, px, py+(sy*0.5)-(n*fh*0.5*(obj.scale.y/font_scale))-obj.font:getLineHeight(),sx/(obj.scale.x/font_scale),obj.alignmode,0, obj.scale.x/font_scale, obj.scale.y/font_scale)
    lg.setFont(standart_font)
    lg.setColor(default_colour[1],default_colour[2],default_colour[3],default_colour[4])
    lg.setLineWidth(3)
end

function dengui.new_text_edit(canvas_id,background_text,position,size,scale,colour)
    if type(canvas_id)~="number" then warn("invalid canvas_id "..debug.traceback()) end
    local gen=firstlayercopy(defaults.text_edit)
    gen.type="text_edit"
    gen.position=position or defaults.text_edit.position
    gen.scale=scale or defaults.text_edit.scale
    gen.size=size or defaults.text_edit.size
    gen.colour=colour or defaults.text_edit.colour
    gen.background_text=background_text or defaults.text_edit.background_text
    ui_storage[canvas_id][ui_storage[canvas_id][0]+1]=gen
    ui_storage[canvas_id][0]=#ui_storage[canvas_id]
    --dengui.re_render_canvas(canvas_id)
    return gen
end
local function render_text_edit(canvas_id,obj,obid)
    local thiscan=canvases[canvas_id]
    --local thisfont=lg.getFont()
    local sx=obj.size.scale.x*thiscan.x+obj.size.offset.x
    local sy=obj.size.scale.y*thiscan.y+obj.size.offset.y
    local px=obj.position.scale.x*thiscan.x+obj.position.offset.x   -sx*obj.anchor.x
    local py=obj.position.scale.y*thiscan.y+obj.position.offset.y   -sy*obj.anchor.y    -thiscan.scroll_y*thiscan.y
    lg.setColor(obj.background_colour[1],obj.background_colour[2],obj.background_colour[3],obj.background_colour[4])
    local text_to_render=tostring(obj.text)
    if current_text_editing[1]~=0 and current_text_editing[2]==obid then
        if cursor_state==true then
            --text_to_render=text_to_render.."|"--utf8.char(204)
            text_to_render=string_insert(text_to_render,"|",cursor_pos)
        end
    end
    
    lg.rectangle("fill", px, py, sx, sy,obj.round,obj.round)
    lg.setLineWidth(obj.border_width)
    lg.setColor(obj.border_colour[1],obj.border_colour[2],obj.border_colour[3],obj.border_colour[4])
    lg.rectangle("line", px+obj.border_width*.5, py+obj.border_width*.5, sx-obj.border_width, sy-obj.border_width,obj.round,obj.round)
    lg.setColor(obj.colour[1],obj.colour[2],obj.colour[3],obj.colour[4])
    local todisplay=""
    if (obj.text=="" or obj.text==nil) and current_text_editing[2]~=obid then
        todisplay=obj.background_text
    else
        todisplay=text_to_render..obj.extra_text
    end
    --lg.printf(todisplay, px, py,sx,obj.alignmode,obj.rotation, obj.scale.x, obj.scale.y)
    lg.setFont(obj.font)
    local fh=obj.font:getAscent()-obj.font:getDescent()-obj.font:getLineHeight()
    local n=math.ceil(obj.font:getWidth(todisplay)*(obj.scale.x/font_scale)/sx)
    lg.printf(todisplay, px, py+(sy*0.5)-(n*fh*0.5*(obj.scale.y/font_scale))-obj.font:getLineHeight(),sx/(obj.scale.x/font_scale),obj.alignmode,0, obj.scale.x/font_scale, obj.scale.y/font_scale)
    lg.setFont(standart_font)
    lg.setColor(default_colour[1],default_colour[2],default_colour[3],default_colour[4])
    lg.setLineWidth(3)
end
function dengui.new_text_button(canvas_id,text,position,size,func,scale,colour)
    if type(canvas_id)~="number" then warn("invalid canvas_id "..debug.traceback()) end
    local gen=firstlayercopy(defaults.text_button)
    gen.position=position or defaults.text_button.position
    gen.scale=scale or defaults.text_button.scale
    gen.size=size or defaults.text_button.size
    gen.colour=colour or defaults.text_button.colour
    gen.text=text or defaults.text_button.text
    gen.func=func or defaults.text_button.func
    ui_storage[canvas_id][ui_storage[canvas_id][0]+1]=gen
    ui_storage[canvas_id][0]=#ui_storage[canvas_id]
    --dengui.re_render_canvas(canvas_id)
    return ui_storage[canvas_id][ui_storage[canvas_id][0]]
end
local function render_text_button(canvas_id,obj)
    local thiscan=canvases[canvas_id]
    --local thisfont=lg.getFont()
    local sx=obj.size.scale.x*thiscan.x+obj.size.offset.x
    local sy=obj.size.scale.y*thiscan.y+obj.size.offset.y
    local px=obj.position.scale.x*thiscan.x+obj.position.offset.x   -sx*obj.anchor.x
    local py=obj.position.scale.y*thiscan.y+obj.position.offset.y   -sy*obj.anchor.y    -thiscan.scroll_y*thiscan.y
    lg.setColor(obj.background_colour[1],obj.background_colour[2],obj.background_colour[3],obj.background_colour[4])
    lg.rectangle("fill", px, py, sx, sy,obj.round,obj.round)
    lg.setLineWidth(obj.border_width)
    lg.setColor(obj.border_colour[1],obj.border_colour[2],obj.border_colour[3],obj.border_colour[4])
    lg.rectangle("line", px+obj.border_width*.5, py+obj.border_width*.5, sx-obj.border_width, sy-obj.border_width,obj.round,obj.round)
    lg.setColor(obj.colour[1],obj.colour[2],obj.colour[3],obj.colour[4])
    lg.setFont(obj.font)
    local fh=obj.font:getAscent()-obj.font:getDescent()-obj.font:getLineHeight()
    local n=math.ceil(obj.font:getWidth(obj.text)*(obj.scale.x/font_scale)/sx)
    lg.printf(obj.text, px, py+(sy*0.5)-(n*fh*0.5*(obj.scale.y/font_scale))-obj.font:getLineHeight(),sx/(obj.scale.x/font_scale),obj.alignmode,0, obj.scale.x/font_scale, obj.scale.y/font_scale)
    lg.setFont(standart_font)
    lg.setColor(default_colour[1],default_colour[2],default_colour[3],default_colour[4])
    lg.setLineWidth(3)
end

function dengui.new_image(canvas_id,asset,position,scale,colour)
    if type(canvas_id)~="number" then warn("invalid canvas_id "..debug.traceback()) end
    local gen=firstlayercopy(defaults.image)
    gen.position=position or defaults.image.position
    gen.scale=scale or defaults.image.scale
    gen.colour=colour or defaults.image.colour
    gen.asset=asset or defaults.image.asset
    if assets[asset]==nil then
       dengui.new_img_asset(asset)
    end
    ui_storage[canvas_id][ui_storage[canvas_id][0]+1]=gen
    ui_storage[canvas_id][0]=#ui_storage[canvas_id]
    --dengui.re_render_canvas(canvas_id)
    return gen
end
local function render_image(canvas_id,obj)
    local thiscan=canvases[canvas_id]
    local sx=obj.size.scale.x*thiscan.x+obj.size.offset.x
    local sy=obj.size.scale.y*thiscan.y+obj.size.offset.y
    local px=obj.position.scale.x*thiscan.x+obj.position.offset.x   -sx*obj.anchor.x
    local py=obj.position.scale.y*thiscan.y+obj.position.offset.y   -sy*obj.anchor.y    -thiscan.scroll_y*thiscan.y
    local img=assets[obj.asset]
    local imgx,imgy=img:getPixelDimensions()
    local ssx=sx/imgx
    local ssy=sy/imgy
    local offsetX=sx* math.cos(obj.rotation) - sy * math.sin(obj.rotation)
    local offsetY=sx * math.sin(obj.rotation) + sy * math.cos(obj.rotation)
    lg.setColor(obj.colour[1],obj.colour[2],obj.colour[3],obj.colour[4])
    local tpx=px-offsetX*0.5+sx*0.5
    local tpy=py-offsetY*0.5+sy*0.5
    lg.draw(img, tpx, tpy,obj.rotation, ssx,ssy)
    lg.setColor(default_colour[1],default_colour[2],default_colour[3],default_colour[4])
end

function dengui.new_image_button(canvas_id,asset,position,scale,colour)
    if type(canvas_id)~="number" then warn("invalid canvas_id "..debug.traceback()) end
    local gen=firstlayercopy(defaults.image_button)
    gen.position=position or defaults.image_button.position
    gen.scale=scale or defaults.image_button.scale
    gen.colour=colour or defaults.image_button.colour
    gen.asset=asset or defaults.image_button.asset
    if assets[asset]==nil then
       dengui.new_img_asset(asset)
    end
    ui_storage[canvas_id][ui_storage[canvas_id][0]+1]=gen
    ui_storage[canvas_id][0]=#ui_storage[canvas_id]
    --dengui.re_render_canvas(canvas_id)
    return gen
end
local function render_image_button(canvas_id,obj)
    local thiscan=canvases[canvas_id]
    local sx=obj.size.scale.x*thiscan.x+obj.size.offset.x
    local sy=obj.size.scale.y*thiscan.y+obj.size.offset.y
    local px=obj.position.scale.x*thiscan.x+obj.position.offset.x   -sx*obj.anchor.x
    local py=obj.position.scale.y*thiscan.y+obj.position.offset.y   -sy*obj.anchor.y    -thiscan.scroll_y*thiscan.y
    local img=assets[obj.asset]
    local imgx,imgy=img:getPixelDimensions()
    local ssx=sx/imgx
    local ssy=sy/imgy
    local offsetX=sx* math.cos(obj.rotation) - sy * math.sin(obj.rotation)
    local offsetY=sx * math.sin(obj.rotation) + sy * math.cos(obj.rotation)
    
    local tpx=px-offsetX*0.5+sx*0.5
    local tpy=py-offsetY*0.5+sy*0.5
    lg.setColor(obj.border_colour[1],obj.border_colour[2],obj.border_colour[3],obj.border_colour[4])
    lg.setLineWidth(obj.border_width)
    lg.rectangle("line",px,py,sx,sy,obj.round,obj.round)
    lg.setColor(obj.colour[1],obj.colour[2],obj.colour[3],obj.colour[4])
    lg.draw(img, tpx, tpy,obj.rotation, ssx,ssy)
    lg.setColor(default_colour[1],default_colour[2],default_colour[3],default_colour[4])
    lg.setLineWidth(3)
end

local render_function_list={
    ["box"]=render_box,
    ["boxr"]=render_boxr,
    ["text"]=render_text,
    ["textf"]=render_textf,
    ["textfb"]=render_textfb,
    ["text_edit"]=render_text_edit,
    ["text_button"]=render_text_button,
    ["image"]=render_image,
    ["image_button"]=render_image_button,
}
function dengui.re_render_all()
    for i=1,canvases[0] do
        dengui.re_render_canvas(canvases[i].id)
        --dengui.re_render_canvas(i)
    end
end
local last_gc=os.clock()
function dengui.re_render_canvas(canvas_id)
    if canvas_id>canvases[0] then warn("canvas does not exist") return end
    --local screenX,screenY=love.graphics.getWidth( ),love.graphics.getHeight( )
    local screenX,screenY=screen_canv_p.size.x,screen_canv_p.size.y
    --print("recanv",canvas_id,canvases[canvas_id].do_aspect,canvases[canvas_id].aspect_ratio)
    ---@diagnostic disable-next-line: param-type-mismatch
    local nuis,fromto_ui=qsort.dup(ui_storage[canvas_id])
    ui_storage_drawable[canvas_id]=nuis
    lg.setCanvas(canvases[canvas_id].canvas)
    lg.clear()
    for i=1,ui_storage[canvas_id][0] do
        local obj=ui_storage_drawable[canvas_id][i]
        render_function_list[obj.type](canvas_id,obj,fromto_ui[i])
        --print(canvas_id,#ui_storage_drawable[canvas_id],ui_storage_drawable[canvas_id][1].type,ui_storage_drawable[canvas_id][1].text)
    end
    
    --scrollcanv
    local canv= canvases[canvas_id]
    local px=canv.position.scale.x*screenX+canv.position.offset.x   -canv.x*canv.anchor.x +screen_canv_p.position.x
    local py=canv.position.scale.y*screenY+canv.position.offset.y   -canv.y*canv.anchor.y +screen_canv_p.position.y
    canv.truepos={x=px,y=py}
    if canv.scrollable==true then
        --bar
        local sx=canv.scrollbar_width
        local sy=(canv.y)/(canv.scroll_lenght+1)
        local px=(canv.x)-sx
        local py=(canv.scroll_y/(canv.scroll_lenght+1))*canv.y
        --print(py,sx)
        lg.setColor(canv.scrollbar_colour[1],canv.scrollbar_colour[2],canv.scrollbar_colour[3],canv.scrollbar_colour[4])
        lg.rectangle("fill",px,py,sx,sy,6)
        lg.setColor(1,1,1,1)
        --
    end
    --
    if canv.draw_bounds==true then
        lg.setColor(1,1,1,0.5)
        lg.setLineWidth((canv.y*0+75)/25)
        lg.rectangle("line",0,0,canv.x,canv.y)
        lg.setColor(1,1,1,1)
        lg.setLineWidth(3)
    end
    lg.setCanvas()
    if os.clock()-last_gc>math.max(math.min((1/ui_storage[canvas_id][0])*600000,60),3) then
        collectgarbage("collect")--> there is a memory leak somewhere. removing the sort makes it better, but making all variables nil after sorting doesnt help????
        last_gc=os.clock()
        print("Garbage collected")
    end
end


function dengui.give_canvasobj(canvas_id)
    return canvases[canvas_id].canvas
end


local str_char_map={
    ["kp/"]="/",
 --   ["space"]=" ",
    ["return"]="\n",
--    ["ß"]="ß",
--    ["ä"]="ä",
--    ["ö"]="ö",
--    ["´"]="´",
}
--love.keyboard.setKeyRepeat(true)
function dengui.textinput(key)
    if current_text_editing[1]~=0 then
        local sstring=ui_storage[current_text_editing[1]][current_text_editing[2]].text
        --if #key==1 and #sstring<ui_storage[current_text_editing[1]][current_text_editing[2]].limit then
            --[[
            local upper=false
            if love.keyboard.isModifierActive("capslock") then
                upper=not upper
            end
            if love.keyboard.isDown("lshift") then
                upper= not upper
            end
            if upper==true then
                key=string.upper(key)
            end]]
            --ui_storage[current_text_editing[1]][current_text_editing[2]].text=sstring..key
            ui_storage[current_text_editing[1]][current_text_editing[2]].text=string_insert(sstring,key,cursor_pos)
            cursor_pos=cursor_pos+#key
        --end
    end
    if current_text_editing[1]~=0 then
        dengui.re_render_canvas(current_text_editing[1])
    end
end

function dengui.keypressed(key)
    --print(key)
    if current_text_editing[1]~=0 then
        local sstring=ui_storage[current_text_editing[1]][current_text_editing[2]].text
        if key=="v" and love.keyboard.isDown("lctrl") then
            sstring=sstring..love.system.getClipboardText()
            ui_storage[current_text_editing[1]][current_text_editing[2]].text=sstring
            cursor_pos=#sstring
        end
        if #key==1 and #sstring<ui_storage[current_text_editing[1]][current_text_editing[2]].limit then
        elseif key=="backspace" then
            if love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl") then
                local sst=sstring:sub(1,cursor_pos)
                local lastSpace = string.find(string.reverse(sst), " ")
                local lastnl = string.find(string.reverse(sst), "\n")
                if (lastSpace or 0)<(lastnl or 0) then
                    lastSpace=lastnl
                end
                
                if lastSpace then
                local strlen=#sst
                    --print(#sstring-lastSpace,lastSpace)
                    --print("sst",sst,"b",string.sub(sstring,cursor_pos+1,-1))
                    --print("c",string.sub(sst, 1,lastSpace-strlen-1))
                    --print(lastSpace-strlen-1,lastSpace)
                    sstring=string.sub(sst, 1,strlen-lastSpace)..string.sub(sstring,cursor_pos+1,-1)
                    cursor_pos=strlen-lastSpace
                    --print(#sstring)
                else
                    sstring=string.sub(sstring,cursor_pos+1,-1)
                end
                ui_storage[current_text_editing[1]][current_text_editing[2]].text=sstring
            else
                local sst=sstring:sub(1,cursor_pos)
                local byteoffset = utf8.offset(sst, -1)
                if byteoffset then
                    sstring=sstring:sub(1,byteoffset-1)..sstring:sub(cursor_pos+1,-1)
                    ui_storage[current_text_editing[1]][current_text_editing[2]].text=sstring
                    cursor_pos=byteoffset-1
                end
            end
        elseif key=="right" then
            local sst=sstring:sub(cursor_pos+1,-1)
            local byteoffset=sst:match("[%z\1-\127\194-\244][\128-\191]*")
            if byteoffset then
                cursor_pos=cursor_pos+#byteoffset
            end
                --cursor_pos=cursor_pos+1
            if #sstring<cursor_pos then
                cursor_pos=#sstring
            end
            cursor_state=true
            cursor_timer=os.clock()
        elseif key=="left" then
            --local byteoffset=utf8.offset(sstring,cursor_pos-1)
            local byteoffset=utf8.offset(sstring:sub(0,cursor_pos), -1)
            if byteoffset then
            cursor_pos=byteoffset-1
            end
            if 0>cursor_pos then
                cursor_pos=0
            end
            cursor_state=true
            cursor_timer=os.clock()
        elseif str_char_map[key] and #key>3 then
            ui_storage[current_text_editing[1]][current_text_editing[2]].text=string_insert(sstring,str_char_map[key],cursor_pos)
            cursor_pos=cursor_pos+#str_char_map[key]
            --ui_storage[current_text_editing[1]][current_text_editing[2]].text=sstring..str_char_map[key]
        end
        dengui.re_render_canvas(current_text_editing[1])
    end
end
function dengui.keyreleased(key)

end
function dengui.is_over_ui(canvas_id,ui_id,x,y)
    local screenX,screenY=screen_canv_p.size.x,screen_canv_p.size.y
    local thiscan=canvases[canvas_id]
    local obj=ui_storage[canvas_id][ui_id]
    local sx=obj.size.scale.x*thiscan.x+obj.size.offset.x
    local sy=obj.size.scale.y*thiscan.y+obj.size.offset.y
    local px=obj.position.scale.x*thiscan.x+obj.position.offset.x   -sx*obj.anchor.x
    local py=obj.position.scale.y*thiscan.y+obj.position.offset.y   -sy*obj.anchor.y
    local tx=px+thiscan.truepos.x
    local ty=py+thiscan.truepos.y
    if x>=tx and x<=tx+sx and y>=ty and y<=ty+sy then
        return true
    else
        return false
    end
end
function dengui.is_over_canvas(canvas_id,x,y)
    --local screenX,screenY=love.graphics.getDimensions( )
    local screenX,screenY=screen_canv_p.size.x,screen_canv_p.size.y
    local thiscan=canvases[canvas_id]
    local sx=thiscan.x
    local sy=thiscan.y
    local px=thiscan.position.scale.x*screenX+thiscan.position.offset.x -sx*thiscan.anchor.x +screen_canv_p.position.x
    local py=thiscan.position.scale.y*screenY+thiscan.position.offset.y -sy*thiscan.anchor.y +screen_canv_p.position.y
    local tx=px--+thiscan.truepos.x
    local ty=py--+thiscan.truepos.y
    --print(tx,ty)
    if x>=tx and x<=tx+sx and y>=ty and y<=ty+sy then
        return true
    else
        return false
    end
end
function dengui.is_over_abutton(x,y)
    local did=false
    for i=1,canvases[0] do
        local canvchecking=canv_from_to[i]
        local thiscan=canvases[canvchecking]
        for ii=#ui_storage[canvchecking],1,-1 do
            if thiscan.visible==true then
                if ui_storage[canvchecking][ii].type=="text_edit" or ui_storage[canvchecking][ii].type=="text_button" or ui_storage[canvchecking][ii].type=="image_button" then
                    if dengui.is_over_ui(canvchecking,ii,x,y)==true then
                        did=true
                        goto end_is_over_abutton
                    end
                end
            end
        end
    end
    ::end_is_over_abutton::
    return did
end

function dengui.mousepressed(x, y, button, isTouch)
    local hit_text_eedit=false
    for i=1,canvases[0] do
        local canvchecking=canv_from_to[i]
        local thiscan=canvases[canvchecking]
        if canvases[canvchecking].visible==true then
            for ii=#ui_storage[canvchecking],1,-1 do
                if ui_storage[canvchecking][ii].type=="text_edit" then
                    if dengui.is_over_ui(canvchecking,ii,x,y)==true then
                        current_text_editing={canvchecking,ii}
                        hit_text_eedit=true
                        cursor_pos=#ui_storage[canvchecking][ii].text
                        break
                    end
                elseif ui_storage[canvchecking][ii].type=="text_button" then
                    if dengui.is_over_ui(canvchecking,ii,x,y)==true then
                        ui_storage[canvchecking][ii][button.."_func"](x,y)
                        break
                    end
                elseif ui_storage[canvchecking][ii].type=="image_button" then
                    if dengui.is_over_ui(canvchecking,ii,x,y)==true then
                        ui_storage[canvchecking][ii][button.."_func"](x,y)
                        break
                    end
                end
            end
        end
    end
    if hit_text_eedit==false then
        if current_text_editing[1]~=0 then
            local tmp=tonumber(current_text_editing[1])
            current_text_editing={0,0}
            dengui.re_render_canvas(tmp)
        end
        current_text_editing={0,0}
    else
        cursor_state=true
        dengui.re_render_canvas(current_text_editing[1])
    end
end
function dengui.mousereleased(x,y,button,isTouch)

end
function dengui.mousemoved(x,y,dx,dy)

end
function dengui.wheelmoved(x,y)
    local mx,my= love.mouse.getPosition()
    for i=canvases[0],1,-1 do
        local canvchecking=canv_from_to[i]
        if canvases[canvchecking].scrollable==true then
            local isover=dengui.is_over_canvas(canvchecking,mx,my)
            if isover==true then
                canvases[canvchecking].scroll_y=canvases[canvchecking].scroll_y-y*0.035
                if canvases[canvchecking].scroll_y>canvases[canvchecking].scroll_lenght then
                    canvases[canvchecking].scroll_y=canvases[canvchecking].scroll_lenght
                    dengui.re_render_canvas(canvchecking)
                elseif canvases[canvchecking].scroll_y<0 then
                    canvases[canvchecking].scroll_y=0
                    dengui.re_render_canvas(canvchecking)
                else
                    dengui.re_render_canvas(canvchecking)
                end
                --if canvases[canvchecking].syncscrolls[0]>0 then
                for ii=1,#canvases[canvchecking].syncscrolls do
                    local vvv=canvases[canvchecking].syncscrolls[ii]
                    canvases[vvv].scroll_y=canvases[canvchecking].scroll_y
                    dengui.re_render_canvas(vvv)
                end
                --end
                break
            end
        end
    end
end
return dengui