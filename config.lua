
local function whitelist_init()
    if BFWC_Filter_SavedConfigs.whitelist then
       return
    end

    BFWC_Filter_SavedConfigs.whitelist = { }
end

local function is_exists(tbl,key)
    for _,k in ipairs(tbl) do
        if k == key then
            return true
        end
    end
    return false
end
local function blacklist_init()
    if BFWC_Filter_SavedConfigs_G.blacklist then
        return
    end

    BFWC_Filter_SavedConfigs_G.blacklist = {
        '一组','/组','邮寄','U寄','大量','带价','代价','位面','老板','支付',
        'VX','免费','ZFB','收G','无限收','大米','小米','G收','全区服','内销',
        'G团'
    }

end

local bf_channels={}
local function dungeons_init()
    BFWC_Filter_SavedConfigs.dungeons = {}
    if bfwf_player.level and bfwf_player.level>0 and BFWC_Filter_SavedConfigs.auto_filter_by_level then
        local lv = bfwf_player.level
        for _,d in ipairs(bfwf_dungeons) do
            if lv>=d.lmin and lv<= d.lmax then
                BFWC_Filter_SavedConfigs.dungeons[d.name] = true
            else
                BFWC_Filter_SavedConfigs.dungeons[d.name] = false
            end
        end
    end
end

local reset_width = false
local reset_height = false

local function reset_configs_character()
    reset_width = true
    reset_height = true
    BFWC_Filter_SavedConfigs = {
        saved = true,
        enable = true,
        interval = 10,
        dlg_width = 900,
        dlg_height = 600,
        hide_enter_leave = true,
        auto_filter_by_level = true,
        filter_request_to_join = true,
        autojoin_bigfoot = true,
        minimap = { hide = false},
        player = {},
        dungeons = {},
        white_to_chatframe_color={a=1,r=0.937,g=0.138,b=0.883},
        blacklist_enable = true,
        remain_unchanged_msg = false
    }
    BFWC_Filter_SavedConfigs.white_to_chatframe = true
    BFWC_Filter_SavedConfigs.white_to_chatframe_color={a=1,r=0.702,g=0.941,b=0.906,hex='ffb3f0e7'}
    dungeons_init()
    whitelist_init()
end

StaticPopupDialogs['BFWC_CONFIRM'] = {
    text = '',
    button1 = '是',
    button2 = '取消',
    timeout = 0,
    showAlert = true,
    whileDead = true,
    preferredIndex = STATICPOPUP_NUMDIALOGS,
    OnAccept = function(self)

    end
}

StaticPopupDialogs['BFWC_MSGBOX'] = {
    text = '',
    button1 = '好的'
}

function bfwf_msgbox(msg)
    StaticPopupDialogs['BFWC_MSGBOX'].text = msg
    local dlg = StaticPopup_Show('BFWC_MSGBOX')
    if dlg then
        --不设置成tooltip，会被设置窗口遮挡
        dlg:SetFrameStrata("TOOLTIP")
    end
end

function bfwf_confirm(msg,yes,no,func)
    StaticPopupDialogs['BFWC_CONFIRM'].text = msg
    if yes and yes:len()>0 then
        StaticPopupDialogs['BFWC_CONFIRM'].button1 = yes
    else
        StaticPopupDialogs['BFWC_CONFIRM'].button1 = '是'
    end
    if no and no:len()>0 then
        StaticPopupDialogs['BFWC_CONFIRM'].button2 = no
    else
        StaticPopupDialogs['BFWC_CONFIRM'].button2 = '取消'
    end
    StaticPopupDialogs['BFWC_CONFIRM'].OnAccept = func
    local dlg = StaticPopup_Show('BFWC_CONFIRM',"","")
    if dlg then
        --不设置成tooltip，会被设置窗口遮挡
        dlg:SetFrameStrata("TOOLTIP")
    end
end

local send_msg_time = {

}

local classes = {
    ['ROGUE']={'盗贼','盗贼','盗贼'},
    ['SHAMAN']={'萨满','奶萨','萨满'},
    ['PRIEST']={'牧师','奶牧','牧师'},
    ['WARLOCK']={'术士','术士','术士'},
    ['MAGE']={'法师','法师','法师'},
    ['HUNTER']={'猎人','猎人','猎人'},
    ['DRUID']={'德鲁伊','奶德','熊T'},
    ['PALADIN']={'骑士','奶骑','骑士T'},
    ['WARRIOR']={'战士','战士','战士T'},
}

function bfwf_myinfo(d1,d2)
    local info = ''
    local level = UnitLevel("player")
    if level and level<60 then
        info = info .. level .. '级'
    end

    local class = classes[bfwf_player.class]
    if bfwf_player.classes == 1 then
        info = info .. class[1]
        return info
    end

    --local d1 = BFWC_Filter_SavedConfigs.player[bfwf_g_data.myid].first_duty
    if d1=='T' then
        info = info .. class[3]
    elseif d1=='N' then
        info = info .. class[2]
    else
        info = info .. class[1]
    end

    --local d2 = BFWC_Filter_SavedConfigs.player[bfwf_g_data.myid].second_duty
    if not d2 or d2=='X' or d2==d1 then
        return info
    end
    if d2=='D' then
        info = info .. '，也可以DPS'
    elseif d2=='N' then
        info = info .. '，也可以奶'
    elseif d2=='T' then
        info = info .. '，也可以T'
    end
    return info
end

local last_select_team_leader
local last_whisper = {}
local function whisper_level_duty()
    if not last_select_team_leader then
        return
    end

    local d1 = BFWC_Filter_SavedConfigs.player[bfwf_g_data.myid].first_duty
    local d2 = BFWC_Filter_SavedConfigs.player[bfwf_g_data.myid].second_duty
    if bfwf_player.classes == 1 then
        d1 = 'D'
    end
    if not d1 then
        d1 = 'D'
        --bfwf_msgbox('先选择你的职责')
        --return
    end
    local dt = GetTime()-(last_whisper[last_select_team_leader.id] or 0)
    if dt < 60 then
        bfwf_msgbox('您刚给Ta发过申请，等会再发吧!')
        return
    end

    local info = bfwf_myinfo(d1,d2)
    if BFWC_Filter_SavedConfigs.addition_msg and string.len(BFWC_Filter_SavedConfigs.addition_msg)>0 then
        info = info .. ',' .. BFWC_Filter_SavedConfigs.addition_msg
    end
    local msg = '是否将您的信息\n|cffff7eff' .. info .. '|r\n发送给 |cffbb9e75' .. last_select_team_leader.name .. '|r ?'
    bfwf_confirm(msg,nil,nil,function ()
        SendChatMessage(info,"WHISPER", nil,last_select_team_leader.name)
        last_whisper[last_select_team_leader.id] = GetTime()
    end)
end

local function hex_color(r,g,b,a)
    local hex = string.format('%x',math.floor(255*a))
    hex = hex .. string.format('%x',math.floor(255*r))
    hex = hex .. string.format('%x',math.floor(255*g))
    hex = hex .. string.format('%x',math.floor(255*b))
    return hex
end

local debug_data = {}
local creating_team = false
-- https://www.wowace.com/projects/ace3/pages/ace-config-3-0-options-tables
local config_options = {
    type = 'group',
    name = '组队频道信息过滤器',
    args = {
        desc = {
            type = 'group',
            name = '说明',
            order = 1,
            args ={
                desc1 = {
                    type = 'description',
                    name = '|cffbb9e75从v1.0.5开始，为了避免重复造轮子，插件功能以【组队助手】为主，\n\n信息过滤仅作为辅助功能\n\n' ..
                '黑名单的信息会从【大脚世界频道】和【寻求组队】这两个频道过滤掉。\n\n' ..
                '白名单信息(包括选中的副本)会从这两个频道提取到【找队伍】的列表里\n\n' ..
                '玩家如果需要频道信息过滤功能，可以用其他频道信息过滤插件。|r\n\n' ..
                '副本关键词及建议等级不一定准确，欢迎到\n\nhttps://github.com/guoyongshi/BFFilter 或者NGA(maliangys)给我反馈。\n\n' ..
                '|cffffd100当前版本：'.. (GetAddOnMetadata('BFFilter','Version') or '??') .. '|r',
                    order = 1,
                },
            }
        },

        bfchannels={
            type = 'group',
            name = '大脚世界频道[|cffaa0000重要|r]',
            order = 1.1,
            args = {
                desc= {
                    type = 'description',
                    name = '|cffffd100说明：本插件依赖于大脚世界频道，不加入大脚世界频道，本插件是无法正常工作的。\n\n' ..
                            '但不同的服务器，使用的大脚世界频道不太一样，有的是大脚世界频道，有的是大脚世界频道1，有的是大脚世界频道2。。。，或者同时使用多个\n\n' ..
                            '如果本插件无法自动加入大脚世界频道，请使用下面的宏手动加入\n' ..
                            '/加入 大脚世界频道\n' ..
                            '/加入 大脚世界频道1\n' ..
                            '/加入 大脚世界频道2\n' ..
                            '/加入 大脚世界频道3\n' ..
                            '/加入 大脚世界频道4\n' ..
                            '/加入 大脚世界频道5\n' ..
                            '或者用下面的按钮尝试加入所有频道|r',

                    order = 1
                },
                join={
                    type = 'execute',
                    name = '加入大脚世界频道|/加入 大脚世界频道\n/加入 大脚世界频道1\n/加入 大脚世界频道2\n/加入 大脚世界频道3\n/加入 大脚世界频道4\n/加入 大脚世界频道5\n',
                    order = 2,
                    func = function()
                    end,
                    dialogControl = 'MacroButton'
                },

                sp1={
                    type='description',
                    name='|cff000001|r',
                    order = 3,
                    width = 'full',
                },

                desc1={
                    type='description',
                    name='选择一个聊天窗口显示大脚世界频道信息(可选)，\n也可以右键点击聊天窗口，选“设置”，再选“通用频道”，手动勾选大脚世界频道\n' ..
                    '如果必要，可以单独建立一个聊天窗口专门显示大脚世界频道信息',
                    order = 4,
                    width = 'full',
                },
                chatframe = {
                    type = 'select',
                    name = '聊天窗口',
                    order = 4.1,
                    width = 2,
                    values = function()
                        local arr = {}
                        for i=1,NUM_CHAT_WINDOWS do
                            local name,_=GetChatWindowInfo(i)
                            if name and string.len(name)>0 then
                                table.insert(arr,name)
                            end
                        end
                        return arr
                    end,
                    get = function()
                        for i=1,NUM_CHAT_WINDOWS do
                            local name,_=GetChatWindowInfo(i)
                            if name and name == BFWC_Filter_SavedConfigs.bigfoot_chatframe_name then
                                return i
                            end
                        end
                    end,
                    set = function(info,val)
                        local name,_=GetChatWindowInfo(val)
                        BFWC_Filter_SavedConfigs.bigfoot_chatframe_name=name


                    end,
                },

                addto={
                    type='execute',
                    name='绑定',
                    order = 4.2,
                    width = 'half',
                    disabled = function()
                        if not BFWC_Filter_SavedConfigs.bigfoot_chatframe_name then
                            return true
                        end

                        for i=1,NUM_CHAT_WINDOWS do
                            local name,_=GetChatWindowInfo(i)
                            if name == BFWC_Filter_SavedConfigs.bigfoot_chatframe_name then
                                return false
                            end
                        end

                        return true
                    end,
                    func=function()
                        local idx
                        for i=1,NUM_CHAT_WINDOWS do
                            local name,_=GetChatWindowInfo(i)
                            if name and name == BFWC_Filter_SavedConfigs.bigfoot_chatframe_name then
                                idx = i
                            end
                        end
                        if not idx then
                            return
                        end
                        local chatframe = _G['ChatFrame'..idx]
                        if not chatframe then
                            return
                        end
                        ChatFrame_AddChannel(chatframe, '大脚世界频道')
                        ChatFrame_AddChannel(chatframe, '大脚世界频道1')
                        ChatFrame_AddChannel(chatframe, '大脚世界频道2')
                        ChatFrame_AddChannel(chatframe, '大脚世界频道3')
                        ChatFrame_AddChannel(chatframe, '大脚世界频道4')
                        ChatFrame_AddChannel(chatframe, '大脚世界频道5')
                    end
                },

                sp2={
                    type='description',
                    name='|cff000002|r',
                    order = 5,
                    width = 'full',
                },

                autojoin = {
                    type = 'toggle',
                    name = '自动加入大脚世界频道(建议)',
                    order = 6,
                    width = 'full',
                    get = function(info)
                        return BFWC_Filter_SavedConfigs.autojoin_bigfoot
                    end,
                    set = function(info, val)
                        BFWC_Filter_SavedConfigs.autojoin_bigfoot = val
                        if val then
                            bfwf_update_ui = true
                        end
                    end
                },
            }
        },

        common = {
            type = 'group',
            name = '通用设置',
            order = 1.2,
            args = {
                reset = {
                    type = 'execute',
                    name = '恢复默认设置',
                    order = 1,
                    func = function()
                        reset_configs_character()
                        BFWC_Filter_SavedConfigs_G.blacklist = nil
                        blacklist_init()
                    end
                },

                enable = {
                    type = 'toggle',
                    name = '启用过滤器',
                    order = 7,
                    width = 'full',
                    get = function(info)
                        return BFWC_Filter_SavedConfigs.enable
                    end,
                    set = function(info, val)
                        BFWC_Filter_SavedConfigs.enable = val
                        bfwf_update_icon()
                    end
                },

                enterleave = {
                    type = 'toggle',
                    name = '不显示进入/离开频道信息',
                    order = 8,
                    width = 'full',
                    get = function(info)
                        return BFWC_Filter_SavedConfigs.hide_enter_leave
                    end,
                    set = function(info, val)
                        BFWC_Filter_SavedConfigs.hide_enter_leave = val
                    end,
                    disabled = function(info)
                        return not BFWC_Filter_SavedConfigs.enable
                    end
                },

                minimap = {
                    type = 'toggle',
                    name = '显示小地图按钮',
                    order = 9,
                    width = 'full',
                    set = function(info, val)
                        BFWC_Filter_SavedConfigs.minimap.hide = not val
                        if val then
                            LibStub("LibDBIcon-1.0"):Show(BFF_ADDON_NAME)
                        else
                            LibStub("LibDBIcon-1.0"):Hide(BFF_ADDON_NAME)
                        end
                    end,
                    get = function(info)
                        return not BFWC_Filter_SavedConfigs.minimap.hide
                    end
                },

                draghdl = {
                    type = 'toggle',
                    name = '显示全局可拖拽按钮(在一些整合UI里，小地图按钮不好找，可以用这个)\n',
                    order = 9.1,
                    width = 'full',
                    get = function() return BFWC_Filter_SavedConfigs.show_drag_handle end,
                    set = function(info,val)
                        BFWC_Filter_SavedConfigs.show_drag_handle = val
                        if val then
                            bfwf_show_drag_handle()
                        else
                            bfwf_hide_drag_handle()
                        end
                    end
                },

                interval = {
                    type = 'range',
                    name = '刷屏过滤(同一个人，间隔小于设定秒数的发言将被过滤掉)',
                    desc = '同一个人，间隔小于设定秒数的发言将被过滤掉',
                    min = 0,
                    max = 60,
                    step = 1,
                    width = 'full',
                    order = 10,
                    get = function(info)
                        return BFWC_Filter_SavedConfigs.interval
                    end,
                    set = function(info, val)
                        BFWC_Filter_SavedConfigs.interval = val
                    end,
                    disabled = function(info)
                        return not BFWC_Filter_SavedConfigs.enable
                    end
                },

                reducemsg = {
                    type = 'toggle',
                    name = '|cffffd100重复符号、词、句裁减|r',
                    desc = '|cffffd100比如：ZUL 4=1T++++++++++MMMMMMMMMMM压缩成ZUL 4=1T++MM|r',
                    descStyle = 'inline',
                    order = 10.1,
                    width = 'full',
                    get = function() return not BFWC_Filter_SavedConfigs.remain_unchanged_msg end,
                    set = function(info,val)
                        BFWC_Filter_SavedConfigs.remain_unchanged_msg=not val
                    end
                },

                whiteonly = {
                    type = 'toggle',
                    name = '|cffffd100只显示包含白名单关键词的信息|r',
                    desc = '|cffff0000危险：本选项会过滤掉所有白名单以外信息。这将导致大量信息被过滤!\n如果你不是明确明白该选项的用途，请不要勾选！|r',
                    descStyle = 'inline',
                    order = 11,
                    width = 'full',
                    get = function() return BFWC_Filter_SavedConfigs.whiteonly end,
                    set = function(info,val) BFWC_Filter_SavedConfigs.whiteonly=val end
                },

                classcolor = {
                    type = 'toggle',
                    name = '使用职业颜色',
                    order = 11.1,
                    width = 'full',
                    get = function()
                        local v,_ = GetCVarInfo('chatClassColorOverride')
                        if v == '0' then
                            return true
                        end
                        return false
                    end,
                    set = function(info,val)
                        if val then
                            BFWC_Filter_SavedConfigs.use_class_color = true
                            SetCVar("chatClassColorOverride", "0")
                        else
                            BFWC_Filter_SavedConfigs.use_class_color = false
                            SetCVar("chatClassColorOverride", "1")
                        end
                    end
                },

                blacklist_to_all_channel = {
                    type = 'toggle',
                    name = '黑名单过滤所有通用频道以及“说”、“大喊”',
                    desc = '(不含小队、团队、公会、私聊)',
                    descStyle='inline',
                    width = 'full',
                    order = 16,
                    get = function()
                        return BFWC_Filter_SavedConfigs.blacklist_to_all_channel~=false
                    end,
                    set = function(info,val)
                        BFWC_Filter_SavedConfigs.blacklist_to_all_channel = val
                    end
                }
            }
        },


        blacklist = {
            type = 'group',
            name = '黑名单',
            order = 2,
            width = 0.5,
            disabled = function(info)
                return not BFWC_Filter_SavedConfigs.enable
            end,
            args = {
                enable = {
                    type = 'toggle',
                    name = '启用黑名单',
                    order = 1,
                    disabled = false,
                    get = function(info) return BFWC_Filter_SavedConfigs.blacklist_enable end,
                    set = function(info, val) BFWC_Filter_SavedConfigs.blacklist_enable = val  end
                },
                editor = {
                    type = 'input',
                    name = '自定义关键词(用英文逗号分隔，不要回车)',
                    multiline = true,
                    usage = '关键词之间用英文逗号分隔，不要回车',
                    width = 'full',
                    order = 2,
                    disabled = function() return not BFWC_Filter_SavedConfigs.blacklist_enable end,
                    get = function()
                        return table.concat(BFWC_Filter_SavedConfigs_G.blacklist,',')
                    end,
                    set = function(info,val)
                        BFWC_Filter_SavedConfigs_G.blacklist = bfwf_split_str(val)
                    end
                }
            }
        },

        whitelist = {
            type = 'group',
            name = '白名单',
            order = 3,
            width = 0.5,
            disabled = function(info)
                return not BFWC_Filter_SavedConfigs.enable
            end,
            args = {
                desc1 = {
                    type = 'description',
                    name = '|cffffd100提示：|r\n  白名单关键词匹配通过的信息将作为组队信息提取到【|cffffd100找队伍|r】里\n',
                    order = 1
                },

                editor = {
                    type = 'input',
                    name = '自定义组队信息关键词(用英文逗号分隔，不要回车)',
                    multiline = true,
                    usage = '关键词之间用英文逗号分隔，不要回车',
                    width = 'full',
                    order = 2,
                    disabled = function() return not BFWC_Filter_SavedConfigs.enable end,
                    get = function()
                        return table.concat(BFWC_Filter_SavedConfigs.whitelist or {},',')
                    end,
                    set = function(info,val)
                        BFWC_Filter_SavedConfigs.whitelist = bfwf_split_str(val) or {}
                    end
                },
                unsel_as_black = {
                    type = 'toggle',
                    name = '|cffee0e00未勾选的副本当成黑名单|r|cffffee00(如果您不明白该选项的用途，不要勾选)|r',
                    order = 2.1,
                    width = 'full',
                    get = function() return BFWC_Filter_SavedConfigs.not_sel_dungeons_as_blacklist end,
                    set = function(info,val)
                        BFWC_Filter_SavedConfigs.not_sel_dungeons_as_blacklist = val
                    end
                },
                autosel = {
                    type = 'toggle',
                    name = '根据我的等级自动过滤组队信息！|cffffee00(建议您手动勾选副本，更精确)|r',
                    disabled = function() return not BFWC_Filter_SavedConfigs.enable end,
                    get = function(info) return BFWC_Filter_SavedConfigs.auto_filter_by_level end,
                    set = function(info,val)
                        BFWC_Filter_SavedConfigs.auto_filter_by_level = val
                        bfwf_update_dungeons_filter()
                    end,
                    width = 'full',
                    order = 3,
                },
                addtochatframe = {
                    type = 'toggle',
                    name = '白名单过滤出来的信息添加到指定聊天窗口',
                    order = 3.1,
                    width = 'full',
                    get = function() return BFWC_Filter_SavedConfigs.white_to_chatframe end,
                    set = function(info,val) BFWC_Filter_SavedConfigs.white_to_chatframe=val end
                },

                chatframe = {
                    type = 'select',
                    name = '聊天窗口',
                    order = 3.2,
                    values = function()
                        local arr = {}
                        for i=1,NUM_CHAT_WINDOWS do
                            local name,_=GetChatWindowInfo(i)
                            if name and string.len(name)>0 then
                                arr[''..i] = name
                            end
                        end
                        return arr
                    end,
                    get = function()
                        return BFWC_Filter_SavedConfigs.white_to_chatframe_num
                    end,
                    set = function(info,val)
                        BFWC_Filter_SavedConfigs.white_to_chatframe_num=val
                    end,
                    disabled = function() return not BFWC_Filter_SavedConfigs.white_to_chatframe end
                },

                chatcolor = {
                    type = 'color',
                    name = '文字颜色',
                    order = 3.3,
                    width=0.75,
                    hasAlpha = true,
                    disabled = function() return BFWC_Filter_SavedConfigs.use_class_color_for_text end,
                    get = function()
                        local r,g,b,a
                        r = BFWC_Filter_SavedConfigs.white_to_chatframe_color.r or 1
                        g = BFWC_Filter_SavedConfigs.white_to_chatframe_color.g or 1
                        b = BFWC_Filter_SavedConfigs.white_to_chatframe_color.b or 1
                        a = BFWC_Filter_SavedConfigs.white_to_chatframe_color.a or 1
                        return r,g,b,a
                    end,
                    set = function(info,r,g,b,a)
                        r = r or 1
                        g = g or 1
                        b = b or 1
                        a = a or 1
                        BFWC_Filter_SavedConfigs.white_to_chatframe_color = {
                            r=r,g=g,b=b,a=a,hex = hex_color(r,g,b,a)
                        }
                    end
                },

                txcolor = {
                    type = 'toggle',
                    name = '文字用职业颜色',
                    order = 3.4,
                    get = function() return BFWC_Filter_SavedConfigs.use_class_color_for_text end,
                    set = function(info,val) BFWC_Filter_SavedConfigs.use_class_color_for_text=val end
                },

                flash = {
                    type = 'toggle',
                    name = '新信息提醒',
                    order = 3.5,
                    get = function() return BFWC_Filter_SavedConfigs.new_msg_flash end,
                    set = function(info,val) BFWC_Filter_SavedConfigs.new_msg_flash=val end
                },

                desc2 = {
                    type = 'description',
                    name = '\n手动选择关心的副本组队信息\n|cffffee00中括号内文字是预设的关键字，如果不能满足需求可在上方编辑框自行添加白名单关键词。|r',
                    order = 4,
                    width = 'full'
                }
            }
        },

        teamlog1 = {
            type = 'group',
            name = '找队伍',
            order = 4,
            width = 'full',
            args = {
                desc1 = {
                    order = 1,
                    type = 'description',
                    name = '最近的组队喊话记录',
                    width = 1
                },
                beg = {
                    type = 'toggle',
                    order = 1.1,
                    name = '过滤|cffbb9e75求组|r信息',
                    get = function() return BFWC_Filter_SavedConfigs.filter_request_to_join  end,
                    set = function(info,val)
                        BFWC_Filter_SavedConfigs.filter_request_to_join = val
                    end
                },
	            dungeons_filter = {
		            type = 'select',
		            name = '地下城',
		            order = 1.1,
		            values = function()
			            local list = { [''] = '无' };
			            local ds = {};
			            local lv = bfwf_player.level
			            for _, d in ipairs(bfwf_dungeons) do
				            if lv >= d.lmin and lv <= d.lmax then
					            list[#list + 1] = d.name
					            ds[#ds + 1] = d;
				            end
			            end
			            BFWC_Filter_SavedConfigs.player[bfwf_g_data.myid].dungeons = ds;
			            return list;
		            end,
		            get = function(info)
			            return BFWC_Filter_SavedConfigs.player[bfwf_g_data.myid].dungeons_filter or ''
		            end,
		            set = function(info, val)
			            if not bfwf_g_data.myid or not BFWC_Filter_SavedConfigs.player[bfwf_g_data.myid] then
				            return
			            end
			            BFWC_Filter_SavedConfigs.player[bfwf_g_data.myid].dungeons_filter = (val ~= '' and val or nil)
			            if val and val ~= nil then
				            bfwf_chat_team_log = {};
				            for i, m in ipairs(bfwf_chat_team_all_log) do
					            local j = val;
					            local dungeon = BFWC_Filter_SavedConfigs.player[bfwf_g_data.myid].dungeons[j];
					            local find = false;
					            if not dungeon.keys then
						            return;
					            end
					            for _, key in ipairs(dungeon.keys) do
						            if string.find(string.lower(m.text), string.lower(key)) then
							            find = true;
						            end
					            end
					            if find then
						            table.insert(bfwf_chat_team_log, 1, m)
					            end
				            end
			            end
		            end,
	            },

                desc2 = {
                    order = 1.2,
                    type = 'description',
                    name = '|cffff0000您还没加入大脚世界频道，请在“通用设置”里先加入，大部分组队信息都在该频道|r',
                    hidden=function() return bfwf_big_foot_world_channel_joined  end,
                    width = 'full'
                },

                history = {
                    type = 'select',
                    name = '最近的喊话组队记录',
                    order = 2,
                    width = 'full',
                    dialogControl = 'ListBox',
                    values = function ()
                        local arr = {}
                        for _,m in ipairs(bfwf_chat_team_log) do
                            local dt = GetTime()-m.time
                            if dt < 180 then
                                local tlcolor = bfwf_player_color[m.name]
                                if not tlcolor then
                                    tlcolor = '|cff11d72a'
                                end
                                local text = '[|cff3ee157' .. bfwf_format_time(dt)
                                text = text .. '|r ' .. tlcolor .. m.name .. '|r ] '
                                text = text .. '|cffb3f0e7' .. m.text ..'|r'
                                --arr[#arr+1] = { text = text,id = m.playerid}
                                arr[#arr+1] = {text = text,id = m.playerid,name=m.fullname,time=m.time}
                            end
                        end
                        return arr
                    end,
                    width = 'full',
                    set = function(info,val)
                        last_select_team_leader = val
                    end,
                    get = function(info)
                        if last_select_team_leader and (GetTime()-last_select_team_leader.time)>180 then
                            last_select_team_leader = nil
                            return nil
                        end
                        return last_select_team_leader
                    end
                },

                desc3 = {
                    order = 3,
                    type = 'group',
                    name = '将我的等级、职责密给队长',
                    inline = true,
                    width = 'full',
                    args = {
                        first = {
                            type = 'select',
                            name = '主责',
                            order = 1,
                            width = 'half',
                            values = function ()
                                if bfwf_player.classes==1 then
                                    return {['D']='DPS'}
                                end

                                if bfwf_player.classes==2 then
                                    if bfwf_player.class == 'WARRIOR' then
                                        return {['D']='DPS',['T']='坦克'}
                                    end
                                    return {['D']='DPS',['N']='奶'}
                                end

                                return {['D']='DPS',['T']='坦克',['N']='奶'}
                            end,
                            get = function(info)
                                if bfwf_player.classes==1 then
                                    return 'D'
                                end
                                if not bfwf_g_data.myid or not BFWC_Filter_SavedConfigs.player[bfwf_g_data.myid]  then
                                    return 'D'
                                end
                                return BFWC_Filter_SavedConfigs.player[bfwf_g_data.myid].first_duty or 'D'
                            end,
                            set = function(info,val)
                                if not bfwf_g_data.myid or not BFWC_Filter_SavedConfigs.player[bfwf_g_data.myid]  then
                                    return
                                end

                                BFWC_Filter_SavedConfigs.player[bfwf_g_data.myid].first_duty = val
                            end,
                            disabled = function() return bfwf_player.classes==1 end
                        },
                        second = {
                            type = 'select',
                            name = '次责',
                            order = 2,
                            width = 'half',
                            values = function ()
                                if bfwf_player.classes==1 then
                                    return {['X']='无',['D']='DPS'}
                                end

                                if bfwf_player.classes==2 then
                                    if bfwf_player.class == 'WARRIOR' then
                                        return {['X']='无',['D']='DPS',['T']='坦克'}
                                    end
                                    return {['X']='无',['D']='DPS',['N']='奶'}
                                end

                                return {['X']='无',['D']='DPS',['T']='坦克',['N']='奶'}
                            end,
                            get = function(info)
                                if bfwf_player.classes==1 then
                                    return '无'
                                end
                                if not bfwf_g_data.myid or not BFWC_Filter_SavedConfigs.player[bfwf_g_data.myid]  then
                                    return
                                end
                                return BFWC_Filter_SavedConfigs.player[bfwf_g_data.myid].second_duty
                            end,
                            set = function(info,val)
                                if not bfwf_g_data.myid or not BFWC_Filter_SavedConfigs.player[bfwf_g_data.myid]  then
                                    return
                                end

                                BFWC_Filter_SavedConfigs.player[bfwf_g_data.myid].second_duty = val
                            end,
                            disabled = function() return bfwf_player.classes==1 end
                        },
                        addition = {
                            type = 'input',
                            name = '附加信息',
                            order = 3,
                            width = 1.5,
                            get = function(info) return BFWC_Filter_SavedConfigs.addition_msg or ''  end,
                            set = function(info,val) BFWC_Filter_SavedConfigs.addition_msg = val or '' end
                        },
                        send = {
                            type = 'execute',
                            name = '发送',
                            order = 4,
                            width = 'half',
                            disabled = function(info) return not last_select_team_leader end,
                            func = whisper_level_duty
                        }
                    }
                }
            }
        },

        orgteam = {
            type = 'group',
            name = '组队',
            order = 10,
            width = 'full',
            args = {
                desc1 = {
                    type = 'description',
                    name = '发布信息，招募队员(信息自动发布到[|cffcc7832|Hchannel:大脚世界频道|h大脚世界频道|h|r])\n',
                    order = 1,
                    width = 'full'
                },
                chns={
                    type='select',
                    name='选择信息发布频道',
                    order=1.1,
                    values=function()
                        bf_channels={}
                        local _,name,_=GetChannelName('大脚世界频道')
                        if name then
                            table.insert(bf_channels,name)
                        end
                        for i=1,5 do
                            local _,name,_=GetChannelName('大脚世界频道'..i)
                            if name then
                                table.insert(bf_channels,name)
                            end
                        end
                        return bf_channels
                    end,
                    get=function(info)
                        for i,name in ipairs(bf_channels) do
                            if name and name == BFWC_Filter_SavedConfigs.send_msg_channel then
                                return i
                            end
                        end
                    end,
                    set=function(info,val)
                        if val<=#bf_channels then
                            BFWC_Filter_SavedConfigs.send_msg_channel=bf_channels[val]
                        end
                    end
                },
                sp1={
                    type = 'description',
                    name = '|cff000001|r',
                    order = 1.2,
                    width = 'full'
                },
                task={
                    type = 'select',
                    name = '选择副本',
                    style = 'dropdown',
                    order = 2,
                    values = function()
                        local arr = {'自定义','任务队'}
                        for _,d in ipairs(bfwf_dungeons) do
                            local pos,_=string.find(d.name,'%(')
                            if pos then
                                table.insert(arr,'|cff0099ff' .. string.sub(d.name,1,pos-1) .. '|r')
                            else
                                table.insert(arr,'|cff0099ff' .. d.name .. '|r')
                            end
                        end
                        return arr
                    end,
                    get = function()
                        if not BFWC_Filter_SavedConfigs.last_orgteam then
                            BFWC_Filter_SavedConfigs.last_orgteam = 1
                        end
                        return BFWC_Filter_SavedConfigs.last_orgteam
                    end,
                    set = function(info,val)
                        BFWC_Filter_SavedConfigs.last_orgteam = val
                    end
                },
                note={
                    type = 'input',
                    name = '备注、说明(限制30字，文明组队，不要带一长串符号)',
                    multiline = 3,
                    width = 'full',
                    order = 3,
                    get = function()
                        return BFWC_Filter_SavedConfigs.last_orgteam_note or ''
                    end,
                    set = function(info,val)
                        local ws=bff_msg_split(val or '')
                        if #ws>30 then
                            BFWC_Filter_SavedConfigs.last_orgteam_note = table.concat(ws,'',1,30)
                        else
                            BFWC_Filter_SavedConfigs.last_orgteam_note = val or ''
                        end
                    end
                },
                space={
                    type = 'range',
                    name = '信息发送间隔',
                    min = 15,
                    max = 120,
                    step = 1,
                    width = 'full',
                    order = 3.1,
                    get = function(info)
                        return BFWC_Filter_SavedConfigs.interval_orgteam or 15
                    end,
                    set = function(info, val)
                        BFWC_Filter_SavedConfigs.interval_orgteam = val
                    end,
                },
                msg={
                    type = 'description',
                    name = function()
                        local msg = '自动发送的信息：\n    |cffffc0c0'
                        msg = msg .. bfwf_make_team_create_msg(true) .. '|r\n'
                        return msg
                    end,
                    order = 3.2,
                    width = 'full'
                },
                start={
                    type = 'execute',
                    order = 4,
                    name = function()
                        if bfwf_orging_team then
                            return '完成'
                        else
                            return '开始'
                        end
                    end,
                    func = function()
                        if bfwf_orging_team then
                            bfwf_finish_org_team()
                            return
                        end
                        if not bfwf_big_foot_world_channel_joined then
                            bfwf_msgbox('你需要先加入 大脚世界频道')
                            return
                        end
                        if not BFWC_Filter_SavedConfigs.send_msg_channel then
                            bfwf_msgbox('你需要先选择一个信息发送频道')
                            return
                        end
                        local idx=BFWC_Filter_SavedConfigs.last_orgteam
                        if not idx then
                            bfwf_msgbox('先选择组队目的')
                            return
                        end
                        if string.len(BFWC_Filter_SavedConfigs.last_orgteam_note or '')==0 then
                            bfwf_msgbox('备注信息不能为空')
                            return
                        end
                        if idx == 1 then
                            bfwf_org_team_count = 40
                        elseif idx==2 then
                            bfwf_org_team_count = 5
                        else
                            bfwf_org_team_count = bfwf_dungeons[idx-2].num
                        end
                        bfwf_orging_team = true
                        bfwf_send_team_create_msg()
                    end
                },
                autofin={
                    type='toggle',
                    name='满员自动结束',
                    order=4.1,
                    get=function()
                        return BFWC_Filter_SavedConfigs.auto_fin_org_team~='no'
                    end,
                    set=function(info,val)
                        if val then
                            BFWC_Filter_SavedConfigs.auto_fin_org_team='yes'
                        else
                            BFWC_Filter_SavedConfigs.auto_fin_org_team='no'
                        end
                    end,
                    disabled = function()
                        if not BFWC_Filter_SavedConfigs.last_orgteam then
                            return true
                        end
                        if BFWC_Filter_SavedConfigs.last_orgteam==1 then
                            return true
                        end
                        return false
                    end
                }
            }
        },
        job = {
            type = 'group',
            name = '求职',
            order = 11,
            width = 'full',
            args = {
                desc1 = {
                    type = 'description',
                    name = '发布求职信息(信息自动发布到[|cffcc7832|Hchannel:大脚世界频道|h大脚世界频道|h|r])\n',
                    order = 1,
                    width = 'full'
                },
                chns={
                    type='select',
                    name='选择信息发布频道',
                    order=1.1,
                    values=function()
                        bf_channels={}
                        local _,name,_=GetChannelName('大脚世界频道')
                        if name then
                            table.insert(bf_channels,name)
                        end
                        for i=1,5 do
                            local _,name,_=GetChannelName('大脚世界频道'..i)
                            if name then
                                table.insert(bf_channels,name)
                            end
                        end
                        return bf_channels
                    end,
                    get=function(info)
                        for i,name in ipairs(bf_channels) do
                            if name and name == BFWC_Filter_SavedConfigs.send_msg_channel then
                                return i
                            end
                        end
                    end,
                    set=function(info,val)
                        if val<=#bf_channels then
                            BFWC_Filter_SavedConfigs.send_msg_channel=bf_channels[val]
                        end
                    end
                },
                sp1={
                    type = 'description',
                    name = '|cff000001|r',
                    order = 1.2,
                    width = 'full'
                },
                task={
                    type = 'select',
                    name = '选择求职意向',
                    style = 'dropdown',
                    order = 2,
                    values = function()
                        local arr = {'自定义','任务队'}
                        for _,d in ipairs(bfwf_dungeons) do
                            local pos,_=string.find(d.name,'%(')
                            if pos then
                                table.insert(arr,'|cff0099ff' .. string.sub(d.name,1,pos-1) .. '|r')
                            else
                                table.insert(arr,'|cff0099ff' .. d.name .. '|r')
                            end
                        end
                        return arr
                    end,
                    get = function()
                        if not BFWC_Filter_SavedConfigs.last_job then
                            BFWC_Filter_SavedConfigs.last_job = 1
                        end
                        return BFWC_Filter_SavedConfigs.last_job
                    end,
                    set = function(info,val)
                        BFWC_Filter_SavedConfigs.last_job = val
                    end
                },
                note={
                    type = 'input',
                    name = '备注、说明(限制30字，文明求职，不要带一长串符号)',
                    multiline = 3,
                    width = 'full',
                    order = 3,
                    get = function()
                        return BFWC_Filter_SavedConfigs.last_job_note or ''
                    end,
                    set = function(info,val)
                        local ws=bff_msg_split(val or '')
                        if #ws>30 then
                            BFWC_Filter_SavedConfigs.last_job_note = table.concat(ws,'',1,30)
                        else
                            BFWC_Filter_SavedConfigs.last_job_note = val or ''
                        end
                    end
                },
                space={
                    type = 'range',
                    name = '信息发送间隔',
                    min = 15,
                    max = 120,
                    step = 1,
                    width = 'full',
                    order = 3.1,
                    get = function(info)
                        return BFWC_Filter_SavedConfigs.interval_wanted_job or 15
                    end,
                    set = function(info, val)
                        BFWC_Filter_SavedConfigs.interval_wanted_job = val
                    end,
                },
                msg={
                    type = 'description',
                    name = function()
                        local msg = '自动发送的信息(间隔约15秒)：\n    |cffffc0c0'
                        msg = msg .. bfwf_make_wanted_job_msg(true) .. '|r\n'
                        return msg
                    end,
                    order = 3.2,
                    width = 'full'
                },
                start={
                    type = 'execute',
                    order = 4,
                    name = function()
                        if bfwf_waiting_job then
                            return '结束'
                        else
                            return '开始'
                        end
                    end,
                    func = function()

                        if bfwf_waiting_job then
                            bfwf_waiting_job = false
                            return
                        end
                        if not bfwf_big_foot_world_channel_joined then
                            bfwf_msgbox('你需要先加入 大脚世界频道')
                            return
                        end
                        if not BFWC_Filter_SavedConfigs.send_msg_channel then
                            bfwf_msgbox('你需要先选择一个信息发送频道')
                            return
                        end
                        if GetNumGroupMembers()>0 then
                            bfwf_msgbox('你现在正在一个队伍里，无法发布求职信息！')
                            return
                        end
                        if bfwf_orging_team then
                            bfwf_msgbox('你已经发布了组队信息，无法发布求职信息！')
                            return
                        end
                        local idx=BFWC_Filter_SavedConfigs.last_job
                        if not idx then
                            idx = 1
                            BFWC_Filter_SavedConfigs.last_job = 1
                            --bfwf_msgbox('先选择求职意向')
                            --return
                        end
                        if string.len(BFWC_Filter_SavedConfigs.last_job_note or '')==0 then
                            bfwf_msgbox('备注信息不能为空')
                            return
                        end

                        bfwf_waiting_job = true
                        bfwf_send_wanted_job_msg()
                    end
                }
            }
        },
        debug = {
            type = 'group',
            name = '调试',
            order = 11,
            width = 'full',
            hidden = function() return not BFWC_Filter_SavedConfigs.enable_debug end,
            args = {
                split_input={
                    type = 'input',
                    name = '信息拆分',
                    multiline = true,
                    width = 'full',
                    get = function(info) return debug_data.msg_to_split end,
                    set = function(info,val)
                        a={string.byte(val,1,-1)}
                        print(table.concat(a,','))
                        debug_data.msg_to_split=val end,
                    order = 1,
                },
                split_result = {
                    type = 'input',
                    name = '结果',
                    disabled = true,
                    multiline = true,
                    get = function()
                        return table.concat(debug_data.msg_split_res or {},',')
                    end,
                    set = function() end,
                    width = 'full',
                    order = 2
                },
                split_btn = {
                    type = 'execute',
                    name = '拆分',
                    func = function()
                        debug_data.msg_split_res = bff_msg_split(debug_data.msg_to_split or '') or {}
                        print(table.concat(debug_data.msg_split_res or {},','))
                    end,
                    order = 3
                },
                test_btn = {
                    type = 'execute',
                    name = '测试',
                    func = function()
                    end,
                    order=4
                }
            }
        },
    }
}

local function str_cat(arr)
    local s = '    ['
    local first = true
    for _,k in ipairs(arr or {}) do
        if first then
            first = false
        else
            s = s .. ','
        end
        s = s .. '|cffbb9e75' .. string.upper(k) .. '|r'
        first = false
    end
    s = s .. ']'
    return s
end

bfwf_configs_init = function()
    if not BFWC_Filter_SavedConfigs or not BFWC_Filter_SavedConfigs.saved then
        reset_configs_character()
    end

    blacklist_init()
    whitelist_init()

    local args = config_options.args.whitelist.args

    if not BFWC_Filter_SavedConfigs.white_to_chatframe_color then
        BFWC_Filter_SavedConfigs.white_to_chatframe = true
        BFWC_Filter_SavedConfigs.white_to_chatframe_color={a=1,r=0.702,g=0.941,b=0.906,hex='ffb3f0e7'}
    end

    local order = 10
    for _,d in ipairs(bfwf_dungeons) do
        order = order + 1
        args[d.name] = {
            type = 'toggle',
            name = '|cff0099ff' .. d.name .. '|r' .. str_cat(d.keys),
            width = 'full',
            order = order,
            disabled = function(info) return BFWC_Filter_SavedConfigs.auto_filter_by_level end,
            get = function(info) return BFWC_Filter_SavedConfigs.dungeons[info[2]] end,
            set = function(info,val) BFWC_Filter_SavedConfigs.dungeons[info[2]] = val end
        }
    end
    LibStub("AceConfig-3.0"):RegisterOptionsTable(BFF_ADDON_NAME, config_options)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions(BFF_ADDON_NAME, "组队频道过滤")
end

--[[
"PARENT"
"BACKGROUND"
"LOW"
"MEDIUM"
"HIGH"
"DIALOG"
"FULLSCREEN"
"FULLSCREEN_DIALOG"
"TOOLTIP"
--]]
local cfgdlg = LibStub("AceConfigDialog-3.0")
local close_button = nil
local function close_dialog()
    if cfgdlg then
        cfgdlg:Close(BFF_ADDON_NAME)
    end
end
local function create_close_button()
    if close_button then
        return
    end

    if not cfgdlg.OpenFrames or not cfgdlg.OpenFrames[BFF_ADDON_NAME] then
        return
    end

    local frame = cfgdlg.OpenFrames[BFF_ADDON_NAME].frame

    local deco = CreateFrame("Frame", nil, frame)
    deco:SetSize(17, 40)

    local bg1 = deco:CreateTexture(nil, "BACKGROUND")
    bg1:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    bg1:SetTexCoord(0.31, 0.67, 0, 0.63)
    bg1:SetAllPoints(deco)

    local bg2 = deco:CreateTexture(nil, "BACKGROUND")
    bg2:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    bg2:SetTexCoord(0.235, 0.275, 0, 0.63)
    bg2:SetPoint("RIGHT", bg1, "LEFT")
    bg2:SetSize(10, 40)

    local bg3 = deco:CreateTexture(nil, "BACKGROUND")
    bg3:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    bg3:SetTexCoord(0.72, 0.76, 0, 0.63)
    bg3:SetPoint("LEFT", bg1, "RIGHT")
    bg3:SetSize(10, 40)

    deco:SetPoint("TOPRIGHT", -30, 12)

    close_button = CreateFrame("BUTTON", nil, deco, "UIPanelCloseButton")
    close_button:SetPoint("CENTER", deco, "CENTER", 1, -1)
    close_button:SetScript("OnClick", close_dialog)
end
local old_on_width_set_func
local old_on_height_set_func
local function OnWidthSet(self,width)
    if reset_width then
        reset_width = false
        width = 900
    end
    BFWC_Filter_SavedConfigs.dlg_width = math.floor(width or 900)
    if BFWC_Filter_SavedConfigs.dlg_width<640 then
        BFWC_Filter_SavedConfigs.dlg_width = 640
    end
    if old_on_width_set_func and old_on_width_set_func ~= OnWidthSet then
        old_on_width_set_func(self,width)
    end
end

local function OnHeightSet(self,height)
    if reset_height then
        reset_height = false
        height = 600
    end
    BFWC_Filter_SavedConfigs.dlg_height = math.floor(height or 600)
    if BFWC_Filter_SavedConfigs.dlg_height<480 then
        BFWC_Filter_SavedConfigs.dlg_height = 480
    end
    if old_on_height_set_func and old_on_height_set_func ~= OnHeightSet then
        old_on_height_set_func(self,height)
    end
end

bfwf_toggle_config_dialog = function()
    local w = BFWC_Filter_SavedConfigs.dlg_width or 950
    local h = BFWC_Filter_SavedConfigs.dlg_height or 600
    if cfgdlg.OpenFrames and cfgdlg.OpenFrames[BFF_ADDON_NAME] then
        if cfgdlg.OpenFrames[BFF_ADDON_NAME]:IsShown() then
            cfgdlg:Close(BFF_ADDON_NAME)
            old_on_width_set_func = nil
            old_on_height_set_func = nil
        else
            cfgdlg:SetDefaultSize(BFF_ADDON_NAME, w, h)
            cfgdlg:Open(BFF_ADDON_NAME)
            cfgdlg.OpenFrames[BFF_ADDON_NAME].frame:SetFrameStrata("MEDIUM")
            create_close_button()
            if not old_on_width_set_func then
                old_on_width_set_func = cfgdlg.OpenFrames[BFF_ADDON_NAME].OnWidthSet
            end
            if not old_on_height_set_func then
                old_on_height_set_func = cfgdlg.OpenFrames[BFF_ADDON_NAME].OnHeightSet
            end
            cfgdlg.OpenFrames[BFF_ADDON_NAME].OnWidthSet = OnWidthSet
            cfgdlg.OpenFrames[BFF_ADDON_NAME].OnHeightSet = OnHeightSet
        end
    else
        cfgdlg:SetDefaultSize(BFF_ADDON_NAME, w, h)
        cfgdlg:Open(BFF_ADDON_NAME)
        cfgdlg.OpenFrames[BFF_ADDON_NAME].frame:SetFrameStrata("MEDIUM")
        create_close_button()
        if not old_on_width_set_func then
            old_on_width_set_func = cfgdlg.OpenFrames[BFF_ADDON_NAME].OnWidthSet
        end
        if not old_on_height_set_func then
            old_on_height_set_func = cfgdlg.OpenFrames[BFF_ADDON_NAME].OnHeightSet
        end
        cfgdlg.OpenFrames[BFF_ADDON_NAME].OnWidthSet = OnWidthSet
        cfgdlg.OpenFrames[BFF_ADDON_NAME].OnHeightSet = OnHeightSet
    end
end
