--[[
Script Name: Text Shaker
Description: 让字幕产生震动效果 (Mac Compatible)
Author: NickCollect
Version: 1.0
]]

script_name = "Text Shaker"
script_description = "生成震动/抖动特效"
script_author = "Gemini"
script_version = "1.0"

include("karaskel.lua")

function process_lines(subs, sel)
    local meta, styles = karaskel.collect_head(subs, false)
    
    -- Mac 兼容 GUI
    local dialog_config = {
        {class="label", label="Shake Power (Pixel):", x=0, y=0, width=1, height=1},
        {class="edit", name="power", x=1, y=0, width=1, height=1, value="3", hint="震动幅度(像素)"},
        
        {class="label", label="Speed (ms/frame):", x=0, y=1, width=1, height=1},
        {class="edit", name="speed", x=1, y=1, width=1, height=1, value="40", hint="每隔多少毫秒抖一次(越小越快)"},
        
        {class="checkbox", name="keep", x=0, y=2, width=2, height=1, label="Keep Original Line", value=false}
    }
    
    local btn, res = aegisub.dialog.display(dialog_config, {"Shake!", "Cancel"})
    
    if btn == "Cancel" then aegisub.cancel() end
    
    -- 获取参数
    local power = tonumber(res.power) or 3
    local frame_dur = tonumber(res.speed) or 40
    
    -- 倒序循环，因为我们会插入很多新行
    for i = #sel, 1, -1 do
        local line_index = sel[i]
        local line = subs[line_index]
        karaskel.preproc_line(subs, meta, styles, line)
        
        -- 基础信息
        local start_time = line.start_time
        local end_time = line.end_time
        local duration = end_time - start_time
        
        -- 获取原始坐标 (如果没有 \pos，就用默认位置)
        local base_x = line.x
        local base_y = line.y
        
        -- 如果原文本里显式写了 \pos，karaskel 会更新 line.x/y
        -- 但为了保险，我们检查一下文本里有没有硬编码的 pos
        local px, py = line.text:match("\\pos%((%-?%d+),(%-?%d+)%)")
        if px then 
            base_x = tonumber(px)
            base_y = tonumber(py)
        end
        
        -- 计算一共要切多少帧
        local frames = math.ceil(duration / frame_dur)
        
        -- 开始生成抖动帧
        for f = 0, frames - 1 do
            local new_line = table.copy(line)
            
            -- 计算这一帧的时间轴
            new_line.start_time = start_time + (f * frame_dur)
            new_line.end_time = start_time + ((f + 1) * frame_dur)
            
            -- 最后一帧修正时间，防止溢出
            if new_line.end_time > end_time then new_line.end_time = end_time end
            if new_line.start_time >= new_line.end_time then break end -- 避免无效行
            
            -- 计算随机偏移量 (范围: -power 到 +power)
            local offset_x = math.random(-power, power)
            local offset_y = math.random(-power, power)
            
            local final_x = base_x + offset_x
            local final_y = base_y + offset_y
            
            -- 处理文本：替换或插入 \pos
            -- 1. 先移除旧的 \pos (如果有)
            local clean_text = line.text:gsub("\\pos%([^%)]+%)", "")
            
            -- 2. 插入新的 \pos
            -- 如果有大括号，插在第一个大括号里；如果没有，包一层
            if clean_text:match("^{") then
                new_line.text = clean_text:gsub("^{", string.format("{\\pos(%d,%d)", final_x, final_y), 1)
            else
                new_line.text = string.format("{\\pos(%d,%d)}%s", final_x, final_y, clean_text)
            end
            
            -- 3. 简单的格式清理
            new_line.text = new_line.text:gsub("}{", "")
            
            subs.insert(line_index + 1 + f, new_line)
        end
        
        if res.keep then
            line.comment = true
            subs[line_index] = line
        else
            subs.delete(line_index)
        end
    end
    
    aegisub.set_undo_point("Text Shake")
end

aegisub.register_macro(script_name, script_description, process_lines)