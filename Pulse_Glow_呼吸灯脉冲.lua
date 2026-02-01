--[[
Script Name: Pulse Glow
Description: 呼吸灯/脉冲光晕特效
Author: NickCollect
Version: 1.0
]]

script_name = "Pulse Glow"
script_description = "呼吸灯/脉冲特效"
script_author = "Gemini"
script_version = "1.0"

function process_lines(subs, sel)
    local dialog_config = {
        {class="label", label="Min Blur (最小模糊):", x=0, y=0},
        {class="edit", name="min_b", x=1, y=0, value="2"},
        
        {class="label", label="Max Blur (最大模糊):", x=0, y=1},
        {class="edit", name="max_b", x=1, y=1, value="8"},
        
        {class="label", label="Pulse Speed (ms):", x=0, y=2},
        {class="edit", name="speed", x=1, y=2, value="1000", hint="呼吸一次完整的周期(毫秒)"}
    }
    
    local btn, res = aegisub.dialog.display(dialog_config, {"Pulse", "Cancel"})
    if btn == "Cancel" then aegisub.cancel() end
    
    local min_b = tonumber(res.min_b) or 2
    local max_b = tonumber(res.max_b) or 8
    local speed = tonumber(res.speed) or 1000
    local half_speed = math.floor(speed / 2)
    
    for i, idx in ipairs(sel) do
        local line = subs[idx]
        local duration = line.end_time - line.start_time
        
        -- 构建循环的 \t 动画
        -- ASS 没有自动 Loop，我们需要手动把 \t 串起来
        -- \t(t1,t2,\blurX)
        
        local tags = ""
        -- 设置初始状态
        tags = tags .. "\\blur" .. min_b
        
        local loops = math.ceil(duration / speed)
        
        for l = 0, loops do
            local t_start = l * speed
            local t_mid = t_start + half_speed
            local t_end = t_start + speed
            
            -- 变大
            tags = tags .. string.format("\\t(%d,%d,\\blur%d)", t_start, t_mid, max_b)
            -- 变小
            tags = tags .. string.format("\\t(%d,%d,\\blur%d)", t_mid, t_end, min_b)
        end
        
        -- 插入标签
        if line.text:match("^{") then
            line.text = line.text:gsub("^{", "{" .. tags, 1)
        else
            line.text = "{" .. tags .. "}" .. line.text
        end
        
        line.text = line.text:gsub("}{", "")
        subs[idx] = line
    end
    
    aegisub.set_undo_point("Pulse Glow")
end

aegisub.register_macro(script_name, script_description, process_lines)