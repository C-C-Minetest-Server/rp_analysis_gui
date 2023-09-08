-- rp_analysis_gui/init.lua
-- Formspec GUI for rPlace Analysis
--[[
    Copyright (C) 2023  1F616EMO

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301
    USA
]]

local S = minetest.get_translator("rp_analysis_gui")
local gui = flow.widgets

rp_analysis_gui = {}

local function chtab(tab)
    return function(player, ctx)
        ctx.tab = tab
        return true
    end
end

rp_analysis_gui.gui = flow.make_gui(function(player, ctx)
    ctx.tab = ctx.tab or "main"

    if ctx.tab == "main" then
        return gui.VBox {
            w = 12,
            gui.HBox {
                gui.Label {
                    label = S("rPlace Analysis")
                },
                gui.Spacer {},
                gui.ButtonExit {
                    label = "x",
                    w = 0.7, h = 0.7,
                    align_h = "right",
                }
            },
            gui.Box {w = 1, h = 0.05, color = "grey"},
            gui.HBox {
                w = 9, expand = true, align_v = "center",
                gui.Spacer {},
                gui.VBox {
                    gui.ItemImageButton {
                        w = 3, h = 3,
                        item_name = "rp_mapgen_nodes:default_fill",
                        on_event = chtab("node"),
                        align_h = "center",
                    },
                    gui.Label {
                        label = S("Nodes"),
                        w = 3, align_h = "center",
                    },
                },
                gui.Spacer {},
                gui.VBox {
                    gui.ImageButton {
                        w = 3, h = 3,
                        texture_name = "rp_analysis_gui_player_head.png",
                        on_event = chtab("player"),
                        align_h = "center",
                    },
                    gui.Label {
                        label = S("Nodes"),
                        w = 3, align_h = "center",
                    },
                },
                gui.Spacer {},
            },
        }
    elseif ctx.tab == "node" then
        local cache = rp_analysis.get_cache().by_color
        local sorted = {}
        for hex, _ in pairs(rp_nodes.colors) do
            local nname = "rp_nodes:color_" .. hex
            local count = cache[nname] or 0
            sorted[#sorted+1] = {nname, count}
        end
        table.sort(sorted, function(a, b)
            return a[2] > b[2]
        end)

        local entries = {}
        for i, entry in pairs(sorted) do
            local nname = entry[1]
            local count = entry[2]
            local def = minetest.registered_nodes[nname]
            if def then
                local percent = (count / rp_core.area_size) * 100
                entries[i] = gui.VBox {
                    w = 2.5,
                    gui.ItemImage {
                        w = 2, h = 2,
                        item_name = nname,
                        align_h = "center",
                    },
                    gui.Label {
                        label = def.description,
                        align_h = "center",
                    },
                    gui.Label {
                        label = string.format("%d (%.1d%%)",count, percent),
                        align_h = "center",
                    },
                }
            end
        end

        local display = {}
        do
            local curr_row = {}
            local row_displayed = 0
            for _, entry in ipairs(entries) do
                if row_displayed >= 4 then
                    curr_row.align_h = "center"
                    display[#display + 1] = gui.HBox(curr_row)
                    curr_row = {}
                    row_displayed = 0
                end
                curr_row[#curr_row + 1] = entry
                row_displayed = row_displayed + 1
            end
            if #curr_row >= 1 then
                curr_row.align_h = "center"
                display[#display + 1] = gui.HBox(curr_row)
            end
        end
        display.name = "svb_node"
        display.h = 10
        
        return gui.VBox {
            w = 12,
            gui.HBox {
                gui.Button {
                    w = 0.7, h = 0.7,
                    label = "<",
                    on_event = chtab("main"),
                },
                gui.Label {
                    label = S("Node Analysis")
                },
                gui.Spacer {},
                gui.ButtonExit {
                    label = "x",
                    w = 0.7, h = 0.7,
                    align_h = "right",
                }
            },
            gui.Box {w = 1, h = 0.05, color = "grey"},
            gui.ScrollableVBox (display),
            gui.Label {
                label = minetest.translate("rp_analysis", "Total: @1", rp_core.area_size),
                expand = true, align_h = "right",
            }
        }
    elseif ctx.tab == "player" then
        local cache = rp_analysis.get_cache().by_player
        local entries = {}
        for name, count in pairs(cache) do
            if name ~= "" then
                entries[#entries+1] = {name, count}
            end
        end
        table.sort(entries, function(a, b)
            return a[2] > b[2]
        end)
        if cache[""] then
            entries[#entries+1] = {minetest.translate("rp_analysis", "Unknown"), cache[""]}
        end

        local list = {}
        for i, entry in ipairs(entries) do
            local count = entry[2]
            local percent = (count / rp_core.area_size) * 100
            list[i] = gui.HBox {
                gui.Label {
                    label = entry[1]
                },
                gui.Spacer{},
                gui.Label {
                    label = string.format("%d (%.1d%%)",count, percent)
                }
            }
        end
        list[#list + 1] = gui.Label {
            label = minetest.translate("rp_analysis", "Total: @1", rp_core.area_size),
            expand = true, align_h = "right",
        }

        return gui.VBox {
            w = 12,
            gui.HBox {
                gui.Button {
                    w = 0.7, h = 0.7,
                    label = "<",
                    on_event = chtab("main"),
                },
                gui.Label {
                    label = S("Player Analysis")
                },
                gui.Spacer {},
                gui.ButtonExit {
                    label = "x",
                    w = 0.7, h = 0.7,
                    align_h = "right",
                }
            },
            gui.Box {w = 1, h = 0.05, color = "grey"},
            gui.VBox(list)
        }
    else
        return gui.Nil{}
    end
end)

minetest.register_chatcommand("anal_gui", {
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if not player then return false end
        rp_analysis_gui.gui:show(player)
        return true
    end
})