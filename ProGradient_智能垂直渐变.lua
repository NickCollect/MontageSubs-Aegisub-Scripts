--[[
Script Name: Pro Gradient Smart Pos
Description: 自动读取 \pos 标签修正坐标，彻底解决错位问题
Author: NickCollect
Version: 10.0 (Final Fix)
]]

script_name = "Pro Gradient Smart Pos"
script_description = "垂直渐变 (自动识别pos)"
script_author = "Gemini"
script_version = "10.0"

include("karaskel.lua")

-- 辅助：解析颜色
function parse_color(input)
    local clean = input:gsub("[#%s&H]", "")
    if #clean ~= 6 then return 0, 0, 255 end 
    local r = tonumber(clean:sub(1,2), 16) or 0
    local g = tonumber(clean:sub(3,4), 16) or 0
    local b = tonumber(clean:sub(5,6), 16) or 0
    return r, g, b
end

-- 辅助：插值颜色
function interpolate_color(r1, g1, b1, r2, g2, b2, step, total)
    local factor = step / (total - 1)
    local r = math.floor(r1 + (r2 - r1) * factor)
    local g = math.floor(g1 + (g2 - g1) * factor)
    local b = math.floor(b1 + (b2 - b1) * factor)
    return string.format("&H%02X%02X%02X&", b, g, r)
end

function process_lines(subs, sel)
    local meta, styles = karaskel.collect_head(subs, false)
    
    local dialog_config = {
        -- 颜色设置
        {class="label", label="Top Color (#RRGGBB):", x=0, y=0, width=2, height=1},
        {class="edit", name="c_top", x=0, y=1, width=2, height=1, value="#0000FF"}, 
        
        {class="label", label="Bottom Color (#RRGGBB):", x=0, y=2, width=2, height=1},
        {class="edit", name="c_bottom", x=0, y=3, width=2, height=1, value="#FF0000"}, 
        
        -- 切片数量
        {class="label", label="Strips (5-8):", x=0, y=4, width=1, height=1},
        {class="edit", name="strips_txt", x=1, y=4, width=1, height=1, value="5"},
        
        -- 手动修正 (一般不需要动了，除非字特别大)
        {class="label", label="Manual Offset (Optional):", x=0, y=5, width=1, height=1},
        {class="edit", name="offset_txt", x=1, y=5, width=1, height=1, value="0"},
        
        -- 这里的 Checkbox 我默认设为 False (不保留原行)，方便你查看效果
        {class="checkbox", name="keep", x=0, y=6, width=2, height=1, label="Keep Original Line", value=false}
    }
    
    local btn, res = aegisub.dialog.display(dialog_config, {"Run", "Cancel"})
    
    if btn == "Cancel" then aegisub.cancel() end

    local r1, g1, b1 = parse_color(res.c_top)
    local r2, g2, b2 = parse_color(res.c_bottom)
    local strips = tonumber(res.strips_txt) or 5
    local manual_offset = tonumber(res.offset_txt) or 0
    if strips < 2 then strips = 2 end

    for i = #sel, 1, -1 do
        local line_index = sel[i]
        local line = subs[line_index]
        karaskel.preproc_line(subs, meta, styles, line)
        
        -- ==========================================
        -- 【智能定位核心逻辑】
        -- ==========================================
        local top_y = line.top
        local total_height = line.height
        if total_height < 10 then total_height = 50 end -- 兜底高度
        
        -- 1. 尝试从文本中读取 \pos(x, y)
        -- 正则匹配：找到 \pos(数字, 数字)
        local pos_x_str, pos_y_str = line.text:match("\\pos%((%-?%d+),(%-?%d+)%)")
        
        if pos_y_str then
            local pos_y = tonumber(pos_y_str)
            -- 找到了 pos！
            -- 假设是对齐方式是底部对齐 (\an2, 默认)，那么 pos_y 就是底边
            -- 所以 Top = pos_y - 高度
            
            -- 注意：如果你的对齐方式是 \an5 (居中)，计算方式会不同
            -- 但大多数对话字幕都是底部对齐。这里按底部对齐处理。
            top_y = pos_y - total_height
            
            -- Aegisub 的字体高度计算有时偏小，导致覆盖不全
            -- 这里稍微把 Top 往上提一点点 (5像素) 确保盖住头顶
            top_y = top_y - 5 
            
            -- 同时也把高度稍微加一点，确保盖住脚底
            total_height = total_height + 10
        end

        -- 2. 加上用户的手动修正值
        top_y = top_y + manual_offset
        
        local strip_height = total_height / strips
        
        for s = 0, strips - 1 do
            local new_line = table.copy(line)
            local y_start = math.floor(top_y + (s * strip_height))
            local y_end = math.floor(top_y + ((s + 1) * strip_height))
            
            -- 边缘防缝隙
            if s < strips - 1 then y_end = y_end + 1 end
            
            local color_code = interpolate_color(r1, g1, b1, r2, g2, b2, s, strips)
            
            new_line.text = string.format("{\\clip(0,%d,%d,%d)\\c%s}%s", y_start, meta.res_x, y_end, color_code, line.text)
            new_line.text = new_line.text:gsub("}{", "")
            
            subs.insert(line_index + 1 + s, new_line)
        end
        
        if res.keep then
            line.comment = true
            subs[line_index] = line
        else
            -- 建议删除原行，不然原来的白字会挡在后面
            subs.delete(line_index)
        end
    end
    
    aegisub.set_undo_point("Smart Gradient")
end

aegisub.register_macro(script_name, script_description, process_lines)