-----------------------------
-- awful.screenshot script --
-----------------------------
-- Also uses xclip. Works whenever `awful.screenshot` feels
-- like following `args.directory`.

-- Imports
----------
local awful     = require('awful')
local beautiful = require('beautiful')
local naughty   = require('naughty')

local gfs       = require('gears.filesystem')
local gc        = require('gears.color')
local def_image = gc.recolor_image(
                    gfs.get_configuration_dir() .. "themes/assets/notification/image.svg",
                    beautiful.notification_accent
)

-- Screenshot
-------------
--- Immediate
local function saved_screenshot(args)
    args.directory   = "/tmp/"
    args.frame_color = beautiful.red

    local ss     = awful.screenshot(args)
    local save   = naughty.action { name = 'Save' }
    local delete = naughty.action { name = 'Discard' }
    local file_location

    local function notify(self)
        naughty.notification {
            title     = "Screenshot",
            message   = "Copied to clipboard!",
            icon      = self.surface,
            actions   = {
                save,
                delete
            }
        }
        file_location = self.file_path
    end

    if args.auto_save_delay > 0 then
        ss:connect_signal("file::saved", notify)
    else
        notify(ss)
    end
    awful.spawn("xclip -sel clip -t image/png '" .. file_location .. "'")

    -- click 'Save' to copy image to clipboard
    save:connect_signal('invoked', function()
        awful.spawn.with_shell("cp " .. file_location .. " " .. beautiful.screenshot_dir)
    end)
    -- click 'Discard' to remove image by path
    delete:connect_signal('invoked', function()
        awful.spawn.with_shell("rm " .. file_location)
    end)

    return ss
end

--- Delayed
local function delayed_screenshot(args)
    local ss = saved_screenshot(args)
    local notif = naughty.notification {
        title   = "Delayed Screenshot",
        icon    = def_image,
        timeout = args.auto_save_delay,
    }

    ss:connect_signal("timer::timeout", function()
        if notif then notif:destroy() end
    end)

    return ss
end

-- Screenshot Keybindings
-------------------------
client.connect_signal("request::default_keybindings", function()
    awful.keyboard.append_client_keybindings({
        -- Client screenshot
        awful.key({ "Shift" }, "Print",
            function (c) saved_screenshot { auto_save_delay = 0, client = c } end)
    })
end)

awful.keyboard.append_global_keybindings({
    -- Selection screenshot
    awful.key({           }, "Print",
        function () saved_screenshot { auto_save_delay = 0.1, interactive = true } end),
    -- Fullscreen screenshot
    awful.key({ modkey    }, "Print",
        function () saved_screenshot { auto_save_delay = 0 } end),
    -- Delayed fullscreen screenshot
    awful.key({ modkey, "Shift" }, "Print",
        function () delayed_screenshot { auto_save_delay = 5 } end)
})