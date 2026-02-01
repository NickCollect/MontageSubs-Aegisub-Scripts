--[[
Script Name: Batch Move (Safe Mode)
Description: 批量移动字幕坐标 (支持 X/Y 轴偏移)
Author: NickCollect
Version: 1.0
]]

script_name = "Batch Move"
script_description = "批量坐标位移"
script_author = "Gemini"
script_version = "1.0"

include("karaskel.lua")

function process_lines(subs, sel)
    local meta, styles = karaskel.collect_head(subs, false)
    
    -- Mac 兼容 GUI (纯文本框)
    local dialog_config = {
        -- X轴设置
        {class="label", label="X Offset (+Right, -Left):", x=0, y=0, width=1, height=1},
        {class="edit", name="off_x", x=1, y=0, width=1, height=1, value="0", hint="正数向右移，负数向左移"},
        
        -- Y轴设置
        {class="label", label="Y Offset (+Down, -Up):", x=0, y=1, width=1, height=1},
        {class="edit", name="off_y", x=1, y=1, width=1, height=1, value="0", hint="正数向下移，负数向上移"},
        
        -- 提示
        {class="label", label="Unit: Pixels (像素)", x=0, y=2, width=2, height=1}
    }
    
    local btn, res = aegisub.dialog.display(dialog_config, {"Move", "Cancel"})
    
    if btn == "Cancel" then aegisub.cancel() end
    
    -- 获取偏移量 (默认为0)
    local move_x = tonumber(res.off_x) or 0
    local move_y = tonumber(res.off_y) or 0
    
    -- 如果没填任何数值，直接退出，省得浪费时间
    if move_x == 0 and move_y == 0 then return end

    for i = #sel, 1, -1 do
        local line_index = sel[i]
        local line = subs[line_index]
        karaskel.preproc_line(subs, meta, styles, line)
        
        -- 检查是否有现成的 \pos(x,y)
        -- 正则逻辑：寻找 \pos(数字,数字)
        local cx, cy = line.text:match("\\pos%((%-?%d+%.?%d*),(%-?%d+%.?%d*)%)")
        
        if cx and cy then
            -- Case 1: 原本就有 \pos
            -- 直接在原数字上加减
            local new_x = tonumber(cx) + move_x
            local new_y = tonumber(cy) + move_y
            
            -- 替换旧标签
            -- 这里用了一个技巧：只替换匹配到的那个部分，防止误伤其他数字
            -- 使用 %1 %2 这种捕获组很难精确替换，所以我们重新构建字符串
            -- 简单的做法：gsub 整个匹配项
            local old_tag = string.format("\\pos(%s,%s)", cx, cy)
            local new_tag = string.format("\\pos(%.2f,%.2f)", new_x, new_y)
            
            -- 去掉可能产生的 .00 (美观)
            new_tag = new_tag:gsub("%.00", "")
            
            -- 字符串替换 (escape magic characters in old_tag)
            old_tag = old_tag:gsub("%(", "%%("):gsub("%)", "%%)"):gsub("%.", "%%.")
            line.text = line.text:gsub(old_tag, new_tag)
            
        else
            -- Case 2: 原本没有 \pos (依靠对齐或默认边距)
            -- 使用 karaskel 算出来的默认坐标
            local base_x = line.x
            local base_y = line.y
            
            local new_x = base_x + move_x
            local new_y = base_y + move_y
            
            local new_tag = string.format("\\pos(%.0f,%.0f)", new_x, new_y)
            
            -- 插入标签
            if line.text:match("^{") then
                line.text = line.text:gsub("^{", "{" .. new_tag, 1)
            else
                line.text = "{" .. new_tag .. "}" .. line.text
            end
            
            line.text = line.text:gsub("}{", "")
        end
        
        subs[line_index] = line
    end
    
    aegisub.set_undo_point("Batch Move")
end

aegisub.register_macro(script_name, script_description, process_lines)